// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:async';

import 'package:jetleaf_logging/logging.dart';

import '../base/backoff_policy.dart';
import '../base/recovery_callback.dart';
import '../base/retry_callback.dart';
import '../base/retry_context.dart';
import '../base/retry_executor.dart';
import '../base/retry_listener.dart';
import '../base/retry_policy.dart';
import '../base/retry_statistics.dart';
import '../exceptions.dart';

/// {@template default_retry_executor}
/// The default implementation of [RetryExecutor], responsible for orchestrating
/// the execution of retryable operations with configured policies, backoff,
/// listeners, and statistics.
///
/// This class provides a concrete executor that integrates:
/// - [RetryPolicy] for deciding if retries are allowed.
/// - [BackoffPolicy] for computing delays between retries.
/// - [RetryListener] notifications during the retry lifecycle.
/// - [RetryStatistics] for collecting metrics and monitoring retry behavior.
///
/// Typically used in combination with [ExecutableResilienceFactory] or
/// [AnnotationAwareRetryFactory] to automatically handle retry logic for
/// annotated methods.
///
/// Example usage:
/// ```dart
/// final executor = DefaultRetryExecutor()
///   .withRetryPolicy(retryPolicy)
///   .withBackoffPolicy(backoffPolicy)
///   .withListeners([loggingListener])
///   .withStatistics(statistics);
///
/// final result = await executor.execute(callback, recoveryCallback);
/// ```
/// {@endtemplate}
final class DefaultRetryExecutor implements RetryExecutor {
  /// The [BackoffPolicy] used to determine the delay between retry attempts.
  ///
  /// This policy computes the duration to wait before each subsequent retry, supporting
  /// strategies like fixed delay, exponential backoff, or custom adaptive delays.
  late BackoffPolicy _backoffPolicy;

  /// The [RetryPolicy] that governs whether a retry should be attempted.
  ///
  /// It enforces rules such as:
  /// - Maximum number of retry attempts
  /// - Exception types that trigger a retry
  /// - Any other contextual constraints for retry eligibility
  late RetryPolicy _retryPolicy;

  /// Collects metrics and statistics for retries executed via this executor.
  ///
  /// The [RetryStatistics] instance tracks:
  /// - Number of retry attempts
  /// - Success and failure counts
  /// - Average or cumulative backoff durations
  /// - Exception patterns observed
  late RetryStatistics _retryStatistics;

  /// Default constructor for the executor.
  ///
  /// Initializes the [DefaultRetryExecutor] instance without pre-configured
  /// policies or statistics. These should be set via the relevant setters
  /// before executing retryable operations.
  /// 
  /// {@macro default_retry_executor}
  DefaultRetryExecutor();

  /// A list of [RetryListener] instances that will be notified during retry
  /// lifecycle events.
  ///
  /// Listeners can observe:
  /// - Retry attempts
  /// - Failures
  /// - Recovery executions
  List<RetryListener> _listeners = [];

  @override
  FutureOr<T> execute<T>(RetryCallback<T> callback, RecoveryCallback<T>? recovery, RetryContext context) async {
    final logger = LogFactory.getLog("executor");

    _retryStatistics.incrementStarted();

    // Notify listeners: operation opened
    for (final listener in _listeners) {
      listener.onOpen(context);
    }

    Exception? lastException;

    try {
      while (true) {
        try {
          // First attempt or retry attempt
          if (context.getAttemptCount() > 0) {
            // Notify _listeners: retry attempt
            for (final listener in _listeners) {
              listener.onRetry(context);
            }

            // Apply backoff delay
            final delay = _backoffPolicy.computeBackoff(context);
            if (delay > Duration.zero) {
              if (logger.getIsTraceEnabled()) {
                logger.trace('Sleeping for ${delay.inMilliseconds}ms before retry attempt ${context.getAttemptCount() + 1}');
              }

              await Future.delayed(delay);
            }
          }

          // Execute the callback
          final result = await callback.execute(context);

          // Success!
          _retryStatistics.incrementSuccess();
          for (final listener in _listeners) {
            listener.onClose(context, null);
          }

          return result;
        } on Exception catch (e) {
          lastException = e;
          context.registerException(e);

          if (logger.getIsTraceEnabled()) {
            logger.trace('Exception on attempt ${context.getAttemptCount()}: $e');
          }

          // Notify _listeners: error occurred
          for (final listener in _listeners) {
            listener.onError(context, e);
          }

          // Check if we should retry
          if (!_retryPolicy.shouldRetryForException(e, context)) {
            if (logger.getIsTraceEnabled()) {
              logger.trace('Retry policy determined not to retry for exception: $e');
            }

            break;
          }

          if (!_retryPolicy.canRetry(context)) {
            if (logger.getIsTraceEnabled()) {
              logger.trace('Retry policy exhausted after ${context.getAttemptCount()} attempts');
            }

            break;
          }

          // Continue to next retry attempt
        }
      }

      // Retries exhausted - try recovery
      _retryStatistics.incrementExhausted();

      if (recovery != null) {
        if (logger.getIsTraceEnabled()) {
          logger.trace('Invoking recovery callback after ${context.getAttemptCount()} failed attempts');
        }

        _retryStatistics.incrementRecovery();
        
        final result = await recovery.recover(context);
        
        for (final listener in _listeners) {
          listener.onClose(context, lastException);
        }
        
        return result;
      }

      // No recovery available - throw exception
      for (final listener in _listeners) {
        listener.onClose(context, lastException);
      }

      throw RetryExhaustedException('Retry attempts exhausted after ${context.getAttemptCount()} attempts', cause: lastException, context);
    } catch (e) {
      // Unexpected error
      for (final listener in _listeners) {
        listener.onClose(context, e is Exception ? e : null);
      }

      rethrow;
    }
  }

  @override
  RetryExecutor withBackoffPolicy(BackoffPolicy backoff) {
    _backoffPolicy = backoff;
    return this;
  }

  @override
  RetryExecutor withListeners(List<RetryListener> listeners) {
    _listeners = listeners;
    return this;
  }

  @override
  RetryExecutor withRetryPolicy(RetryPolicy policy) {
    _retryPolicy = policy;
    return this;
  }

  @override
  RetryExecutor withStatistics(RetryStatistics retryStatistics) {
    _retryStatistics = retryStatistics;
    return this;
  }
}