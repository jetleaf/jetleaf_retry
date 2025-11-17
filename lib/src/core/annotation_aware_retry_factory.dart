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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

import '../base/backoff_policy.dart';
import '../base/retry_executor.dart';
import '../base/retry_policy.dart';
import '../base/retry_statistics.dart';
import 'executable_retry_factory.dart';

/// {@template annotation_aware_retry_factory}
/// `AnnotationAwareRetryFactory` is an implementation of [ExecutableRetryFactory]
/// that automatically scans application components for `@Retryable` annotations
/// and registers retry metadata for eligible methods.
///
/// It integrates with the [ApplicationContext] to discover all pod definitions,
/// build [RetryDefinition] instances, and maintain a registry for efficient
/// runtime lookup and interception.
///
/// This factory also provides the configured:
/// - [RetryPolicy]
/// - [BackoffPolicy]  
/// - [RetryExecutor]  
/// - [RetryStatistics]  
/// for use in retryable method executions.
///
/// Implements:
/// - [ApplicationContextAware]: Allows the factory to access the application context
///   and scan for annotated components.
/// - [InitializingPod]: Executes initialization logic after construction, such as
///   building retry definitions.
///
/// ### Responsibilities
/// - Automatically detect methods annotated with `@Retryable`.
/// - Build and store [RetryDefinition] objects for all detected methods.
/// - Provide runtime access to configured retry, backoff, executor, and statistics.
/// - Serve as a bridge between application context and the retry execution infrastructure.
///
/// ### Lifecycle
/// 1. Instantiated with configured [RetryPolicy], [BackoffPolicy], [RetryExecutor], and [RetryStatistics].
/// 2. Receives [ApplicationContext] via [setApplicationContext].
/// 3. Invokes [onReady] after all pods are registered:
///    - Scans all definitions in the context.
///    - Builds retry definitions for methods annotated with `@Retryable`.
///    - Adds definitions to the internal registry for fast lookup during method interception.
///
/// ### Example Usage
/// ```dart
/// final factory = AnnotationAwareRetryFactory(
///   backoffPolicy,
///   retryPolicy,
///   statistics,
///   executor
/// );
///
/// factory.setApplicationContext(applicationContext);
/// await factory.onReady();
///
/// // Now all retryable methods in the context are registered and ready
/// final retryDef = factory.getDefinition(someMethod);
/// ```
/// {@endtemplate}
class AnnotationAwareRetryFactory extends ExecutableRetryFactory implements ApplicationContextAware, ApplicationEventBusAware, InitializingPod {
  /// The [ApplicationContext] instance associated with the current application.
  ///
  /// This is injected via [setApplicationContext] and provides access to all
  /// registered pods, their definitions, and reflective metadata necessary for
  /// scanning methods annotated with `@Retryable`.
  late ApplicationContext _applicationContext;

  /// The [RetryPolicy] that defines the rules for retrying method invocations.
  ///
  /// This policy determines whether an operation is eligible for retry, taking into
  /// account factors such as:
  /// - Maximum number of attempts
  /// - Exception types that trigger a retry
  /// - Circuit-breaker or cooldown constraints
  final RetryPolicy _retryPolicy;

  /// Collects and exposes retry metrics and statistics.
  ///
  /// The [RetryStatistics] instance tracks information such as:
  /// - Total retry attempts
  /// - Success/failure counts
  /// - Average or cumulative backoff durations
  /// - Most common exceptions encountered during retries
  final RetryStatistics _statistics;

  /// The [BackoffPolicy] that controls the delay between consecutive retry attempts.
  ///
  /// It can implement strategies like:
  /// - Fixed delay
  /// - Exponential backoff
  /// - Randomized jitter
  /// This ensures retries are appropriately spaced to reduce resource contention.
  final BackoffPolicy _backoffPolicy;

  /// The [RetryExecutor] responsible for orchestrating the execution of retryable methods.
  ///
  /// The executor integrates the retry policy, backoff policy, listeners, and
  /// optional recovery callbacks to perform safe and configurable retries.
  final RetryExecutor _executor;

  /// The event dispatcher
  late ApplicationEventBus _eventBus;

  /// {@macro annotation_aware_retry_factory}
  AnnotationAwareRetryFactory(this._backoffPolicy, this._retryPolicy, this._statistics, this._executor);

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  void setApplicationEventBus(ApplicationEventBus applicationEventBus) {
    _eventBus = applicationEventBus;
  }

  @override
  String getPackageName() => PackageNames.RETRY;

  @override
  List<Object?> equalizedProperties() => [AnnotationAwareRetryFactory];

  @override
  BackoffPolicy getBackoffPolicy() => _backoffPolicy;

  @override
  RetryExecutor getExecutor() => _executor;

  @override
  ApplicationEventBus getEventBus() => _eventBus;

  @override
  Log getLog() => LogFactory.getLog(AnnotationAwareRetryFactory);

  @override
  RetryPolicy getRetryPolicy() => _retryPolicy;

  @override
  RetryStatistics getStatistics() => _statistics;

  @override
  Future<void> onReady() async {
    final names = _applicationContext.getDefinitionNames();

    for (final name in names) {
      final def = _applicationContext.getDefinition(name);
      final cls = def.type;

      for (final method in cls.getMethods()) {
        final retryDef = buildDefinition(method);
        if (retryDef != null) {
          addDefinition(retryDef);
        }
      }
    }
  }
}