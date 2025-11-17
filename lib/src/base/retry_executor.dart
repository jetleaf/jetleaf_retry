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

import 'backoff_policy.dart';
import 'recovery_callback.dart';
import 'retry_callback.dart';
import 'retry_context.dart';
import 'retry_listener.dart';
import 'retry_policy.dart';
import 'retry_statistics.dart';

/// `RetryExecutor` defines the **core execution engine** for retryable operations.
/// It coordinates retry policies, backoff strategies, listeners, and recovery callbacks
/// to provide robust resilience handling for method invocations.
///
/// ### Responsibilities
/// - Executes a retryable operation via a [RetryCallback].
/// - Applies the configured [RetryPolicy] to determine retry eligibility.
/// - Uses [BackoffPolicy] to compute delays between attempts.
/// - Notifies [RetryListener] instances of retry lifecycle events.
/// - Invokes [RecoveryCallback] if retries are exhausted and recovery is defined.
/// - Tracks execution metrics via [RetryStatistics].
///
/// ### Typical Usage
/// ```dart
/// final executor = factory.getExecutor()
///     .withRetryPolicy(retryPolicy)
///     .withBackoffPolicy(backoffPolicy)
///     .withListeners([LoggingListener()])
///     .withStatistics(statistics);
///
/// final result = await executor.execute<String>(
///   _MethodInvocationRetryCallback(invocation),
///   _MethodInvocationRecoveryCallback(invocation.getTarget(), recoveryMethod, invocation.getArgument())
/// );
/// ```
///
/// ### Notes
/// - [withRetryPolicy] **must be called** before executing an operation.
/// - [withBackoffPolicy], [withListeners], and [withStatistics] are optional but recommended
///   for full observability and control over retry behavior.
/// - Implementations should handle both synchronous and asynchronous operations seamlessly.
///
abstract interface class RetryExecutor {
  /// {@template retry_executor_with_listeners}
  /// Registers one or more [RetryListener]s that will be notified of retry lifecycle events.
  ///
  /// Events include:
  /// - Retry attempt started
  /// - Retry attempt succeeded
  /// - Retry attempt failed
  /// - Retry exhausted
  ///
  /// ### Parameters
  /// - [listeners]: The list of listeners to attach.
  ///
  /// ### Returns
  /// - The executor instance for fluent chaining.
  /// {@endtemplate}
  RetryExecutor withListeners(List<RetryListener> listeners);

  /// {@template retry_executor_with_statistics}
  /// Sets a [RetryStatistics] collector to track metrics about retry executions.
  ///
  /// Statistics can include:
  /// - Number of attempts
  /// - Success and failure rates
  /// - Average backoff durations
  ///
  /// ### Parameters
  /// - [statistics]: The statistics collector instance.
  ///
  /// ### Returns
  /// - The executor instance for fluent chaining.
  /// {@endtemplate}
  RetryExecutor withStatistics(RetryStatistics statistics);

  /// {@template retry_executor_with_retry_policy}
  /// Configures the [RetryPolicy] that determines whether additional retry
  /// attempts are permitted.
  ///
  /// ### Important
  /// This **must be called** before executing a retryable operation, otherwise
  /// retries cannot be enforced.
  ///
  /// ### Parameters
  /// - [policy]: The retry policy instance.
  ///
  /// ### Returns
  /// - The executor instance for fluent chaining.
  /// {@endtemplate}
  RetryExecutor withRetryPolicy(RetryPolicy policy);

  /// {@template retry_executor_with_backoff_policy}
  /// Sets the [BackoffPolicy] that calculates delays between retry attempts.
  ///
  /// ### Parameters
  /// - [backoff]: The backoff policy instance.
  ///
  /// ### Returns
  /// - The executor instance for fluent chaining.
  /// {@endtemplate}
  RetryExecutor withBackoffPolicy(BackoffPolicy backoff);

  /// {@template retry_executor_execute}
  /// Executes the provided [RetryCallback] according to the configured
  /// [RetryPolicy] and [BackoffPolicy].
  ///
  /// If retries are exhausted, the optional [RecoveryCallback] is invoked
  /// to provide a fallback result.
  ///
  /// ### Parameters
  /// - [callback]: The retryable operation to execute.
  /// - [recovery]: An optional recovery callback to invoke if all retries fail.
  /// - [context]: The [RetryContext] to use for the execution
  ///
  /// ### Returns
  /// - The result of the operation as type `T`.
  /// - May throw [RetryExhaustedException] if no recovery is defined.
  ///
  /// ### Example
  /// ```dart
  /// final result = await executor.execute<String>(
  ///   _MethodInvocationRetryCallback(invocation),
  ///   _MethodInvocationRecoveryCallback(target, recoveryMethod, originalArgs)
  /// );
  /// ```
  /// {@endtemplate}
  FutureOr<T> execute<T>(RetryCallback<T> callback, RecoveryCallback<T>? recovery, RetryContext context);
}