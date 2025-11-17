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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_lang/lang.dart';

import '../annotations/retryable.dart';
import '../base/backoff_policy.dart';
import '../base/recovery_callback.dart';
import '../base/retry_callback.dart';
import '../base/retry_context.dart';
import '../base/retry_executor.dart';
import '../base/retry_policy.dart';
import '../base/retry_statistics.dart';
import '../event/retry_event.dart';
import '../impl/simple_retry_context.dart';
import 'abstract_retry_factory.dart';
import '../exceptions.dart';

/// {@template executable_retry_factory}
/// The `ExecutableResilienceFactory` provides a fully functional, **intercepting
/// retry factory** for retryable operations. It extends [AbstractRetryFactory]
/// and implements both [MethodInterceptor] and [AroundMethodInterceptor] to integrate
/// retry logic transparently into method invocations.
///
/// ### Responsibilities
/// - Detects methods annotated with [Retryable] and constructs retry definitions.
/// - Builds and applies [RetryPolicy] and [BackoffPolicy] dynamically for each method.
/// - Instantiates and executes retry listeners to react to events like:
///   - Retry attempts
///   - Retry success
///   - Retry exhaustion
/// - Finds and invokes recovery methods annotated with [Recover] when retries fail.
/// - Orchestrates retries via [RetryExecutor], including statistical tracking.
///
/// ### Features
/// - Transparent integration with JetLeaf method interception.
/// - Robust handling of exceptions and errors during retry.
/// - Dynamic recovery method resolution.
/// - Full observability with logging and retry statistics.
///
/// ### Example Usage
/// ```dart
/// class MyService {
///   @Retryable(maxAttempts: 3, listeners: [LoggingListener])
///   Future<String> fetchData() async {
///     // Implementation that may fail intermittently
///   }
/// }
///
/// final factory = MyResilienceFactory(); // extends ExecutableResilienceFactory
/// final invocation = MethodInvocation.of(myService, 'fetchData');
///
/// final result = await factory.aroundInvocation(invocation);
/// print(result);
/// ```
///
/// ### Integration Notes
/// - This class delegates actual execution to a [RetryExecutor], using policy and
///   backoff rules defined per method.
/// - Recovery methods are resolved at runtime based on exception type, return type,
///   and optional labels.
/// - Logging integrates with JetLeaf's [Log] system for debug, warning, and error outputs.
/// {@endtemplate}
abstract class ExecutableRetryFactory extends AbstractRetryFactory {
  @override
  bool canIntercept(Method method) => method.hasDirectAnnotation<Retryable>();
  
  @override
  Future<T?> aroundInvocation<T>(MethodInvocation<T> invocation) async {
    final logger = getLog();
    final method = invocation.getMethod();
    final definition = getDefinition(method);

    if (definition == null) {
      // No @Retryable annotation, proceed normally
      return null;
    }

    if (logger.getIsTraceEnabled()) {
      logger.trace('Intercepting retryable method: ${method.getName()}');
    }

    // Set up dependencies
    final context = SimpleRetryContext();
    final retryable = definition.retryable;
    final retryPolicy = getRetryPolicy().retryable(retryable);
    final backoffPolicy = getBackoffPolicy().backoff(retryable.backoff);
    final listeners = definition.listeners;
    final executor = getExecutor();
    final invoker = _MethodInvocationRetryCallback<T>(invocation);
    invoker.setApplicationEventBus(getEventBus());

    // Find recovery method
    RecoveryCallback<T>? recovery;
    final recover = findRecoveryMethod(invocation.getTarget(), method, retryable.label);

    if (recover != null) {
      recovery = _MethodInvocationRecoveryCallback<T>(invocation.getTarget(), recover.value, invocation.getArgument());
    }

    // Execute with retry
    try {
      final result = await executor
        .withListeners(listeners)
        .withStatistics(getStatistics())
        .withRetryPolicy(retryPolicy)
        .withBackoffPolicy(backoffPolicy)
        .execute<T>(invoker, recovery, context);

      return result;
    } on RetryExhaustedException catch (e, st) {
      if (logger.getIsErrorEnabled()) {
        logger.error('Retries exhausted for ${method.getName()}', error: e.cause, stacktrace: st);
      }

      rethrow;
    }
  }
  
  /// {@template get_retry_policy}
  /// Returns the configured [RetryPolicy] responsible for determining whether
  /// additional retry attempts are permitted for a given [RetryContext].
  ///
  /// The retry policy governs **how many times** and **under what conditions**
  /// an operation should be retried. Typical considerations include:
  /// - Maximum retry attempts
  /// - Allowed exception types
  /// - Circuit-breaker state or cooldown constraints
  ///
  /// ### Example
  /// ```dart
  /// final policy = factory.getRetryPolicy();
  /// if (policy.canRetry(context)) {
  ///   // Proceed with another attempt
  /// }
  /// ```
  ///
  /// ### See also
  /// - [BackoffPolicy] for delay computation between retries.
  /// - [RetryExecutor] for orchestration of actual retry cycles.
  /// {@endtemplate}
  RetryPolicy getRetryPolicy();

  /// {@template get_backoff_policy}
  /// Returns the [BackoffPolicy] governing the computation of delay durations
  /// between consecutive retry attempts.
  ///
  /// The backoff policy controls the **timing** of retries, helping to mitigate
  /// overload or network congestion by spacing out repeated invocations.
  ///
  /// Typical backoff strategies include:
  /// - Constant delay (fixed interval)
  /// - Exponential backoff with jitter
  /// - Custom adaptive delays
  ///
  /// ### Example
  /// ```dart
  /// final delay = factory.getBackoffPolicy().computeBackoff(context);
  /// await Future.delayed(delay);
  /// ```
  ///
  /// ### See also
  /// - [RetryPolicy] for controlling whether retries are allowed.
  /// - [RetryExecutor] for coordinating retries and delays.
  /// {@endtemplate}
  BackoffPolicy getBackoffPolicy();

  /// {@template get_retry_executor}
  /// Returns the [RetryExecutor] instance responsible for orchestrating
  /// the execution of retryable operations.
  ///
  /// The retry executor coordinates:
  /// - Invocation of the retryable method or callback.
  /// - Evaluation of [RetryPolicy] and [BackoffPolicy].
  /// - Handling of exceptions and recovery callbacks.
  /// - Tracking of retry attempt statistics and lifecycle events.
  ///
  /// ### Example
  /// ```dart
  /// final result = await factory.getExecutor().execute(context, () async {
  ///   return await httpClient.fetchData();
  /// });
  /// ```
  ///
  /// ### Notes
  /// - This component serves as the runtime engine of the retry subsystem.
  /// - It integrates policy evaluation, delay computation, and error handling
  ///   into a unified execution flow.
  /// {@endtemplate}
  RetryExecutor getExecutor();

  /// {@template get_retry_statistics}
  /// Returns the [RetryStatistics] collector that aggregates metrics related
  /// to retry executions over time.
  ///
  /// This includes data such as:
  /// - Total number of retry attempts
  /// - Success/failure rates
  /// - Average backoff delay
  /// - Most frequent exception types
  ///
  /// ### Example
  /// ```dart
  /// final stats = factory.getStatistics();
  /// print('Retries attempted: ${stats.totalAttempts}');
  /// print('Failures: ${stats.failureCount}');
  /// ```
  ///
  /// ### Use Cases
  /// - Monitoring retry health and performance trends.
  /// - Integrating with observability platforms (e.g. metrics or tracing).
  /// - Debugging retry behavior in production systems.
  ///
  /// ### See also
  /// - [RetryExecutor] for real-time retry coordination.
  /// - [RetryPolicy] for decision-making logic.
  /// - [BackoffPolicy] for timing behavior.
  /// {@endtemplate}
  RetryStatistics getStatistics();

  /// {@template get_event_bus}
  /// Returns the [ApplicationEventBus] associated with this context or factory.
  ///
  /// The event bus provides a central mechanism for publishing and subscribing
  /// to domain or system events. It allows decoupled components to communicate
  /// asynchronously without direct references to each other.
  ///
  /// ### Capabilities
  /// - **Publish events:** Components can emit events to notify interested listeners.
  /// - **Broadcasting:** Events can be delivered to multiple subscribers.
  /// - **Asynchronous handling:** Supports non-blocking event propagation.
  ///
  /// ### Example
  /// ```dart
  /// final bus = factory.getEventBus();
  /// bus.publish(MyEvent('Hello World'));
  /// ```
  ///
  /// ### Use Cases
  /// - Integrating with retry or cache mechanisms to emit lifecycle events.
  /// - Broadcasting domain events across services or modules.
  /// - Observability: logging or metrics triggered by events.
  ///
  /// ### Notes
  /// - This bus is typically singleton-scoped within the application or module.
  /// - Event delivery order is generally preserved per event type, but may be
  ///   asynchronous depending on implementation.
  /// {@endtemplate}
  ApplicationEventBus getEventBus();
}

/// {@template _method_invocation_retry_callback}
/// Internal callback wrapper that adapts a [MethodInvocation] to the
/// [RetryCallback] interface used by the JetLeaf retry subsystem.
///
/// This class serves as a **bridge** between the AOP-style method interception
/// mechanism and the retry execution engine. It allows a method invocation
/// (typically intercepted via JetLeaf’s proxy mechanism) to be executed
/// repeatedly under a configured [RetryPolicy].
///
/// ### Behavior
/// - Executes the original method via [_invocation.proceed()].
/// - Catches and normalizes thrown errors to ensure consistent retry behavior.
/// - Re-throws caught [Exception] instances directly, allowing the retry
///   framework to decide whether a retry should be attempted.
/// - Converts any Dart [Error] (e.g., `StateError`, `TypeError`) into an
///   [IllegalStateException] to maintain a unified exception contract within
///   the retry pipeline.
///
/// ### Type Parameters
/// - **T** — The result type returned by the intercepted method.
///
/// ### Example
/// ```dart
/// final callback = _MethodInvocationRetryCallback<String>(invocation);
/// final result = await retryTemplate.execute(callback);
/// print('Invocation result: $result');
/// ```
///
/// ### Notes
/// This class is **not intended for public use** — it is used internally
/// by the retry interceptor that wraps annotated methods with retry logic.
///
/// See also:
/// - [RetryCallback]
/// - [MethodInvocation]
/// - [RetryExecutor]
/// 
/// {@endtemplate}
class _MethodInvocationRetryCallback<T> implements RetryCallback<T> {
  /// The reflective method invocation being executed within the retry context.
  final MethodInvocation<T> _invocation;

  /// The event dispatcher
  late ApplicationEventBus _eventBus;

  /// Creates a new [_MethodInvocationRetryCallback] wrapping the given
  /// [MethodInvocation].
  /// 
  /// {@macro _method_invocation_retry_callback}
  _MethodInvocationRetryCallback(this._invocation);

  /// Tells me when the request was successful to avoid recreating the invocation.
  bool _retry = true;

  @override
  Future<T> execute(RetryContext context) async {
    bool threwError = false;

    try {
      await _eventBus.onEvent(InvocationRetryEvent.withClock(_invocation, DateTime.now()));
      
      final result = await _invocation.proceed(_retry);
      _retry = false;
      return result;
    } catch (e) {
      _retry = true;
      threwError = true;

      if (e is Exception) {
        rethrow;
      }

      // Convert Error to Exception for retry handling
      throw IllegalStateException('Execution failed: $e');
    } finally {
      if (threwError) {
        _retry = true;
      }
    }
  }
  
  @override
  void setApplicationEventBus(ApplicationEventBus applicationEventBus) {
    _eventBus = applicationEventBus;
  }
}

/// {@template _method_invocation_recovery_callback}
/// Internal callback adapter that bridges a recovery method invocation
/// to the [RecoveryCallback] interface within the JetLeaf retry framework.
///
/// This class is used when a retryable method (annotated with `@Retryable`)
/// exhausts all retry attempts and a corresponding recovery handler
/// (annotated with `@Recover`) must be invoked.
///
/// ### Behavior
/// - Retrieves the last failure from the [RetryContext].
/// - Invokes the designated recovery method (`@Recover`) on the target object.
/// - Propagates both positional and named arguments from the original method call.
/// - Ensures the recovery method receives the exception as its **first argument**,
///   followed by the original method parameters.
///
/// ### Type Parameters
/// - **T** — The expected result type of the recovery method.
///
/// ### Example
/// ```dart
/// // Example: recovery method in a service
/// @Recover()
/// Future<String> handleFailure(Exception e, String requestId) async {
///   return 'Fallback for $requestId due to ${e.runtimeType}';
/// }
///
/// // Internally wrapped during retry exhaustion:
/// final callback = _MethodInvocationRecoveryCallback<String>(
///   target,
///   recoveryMethod,
///   originalArgs,
/// );
///
/// final result = await callback.recover(context);
/// print(result); // "Fallback for req-42 due to TimeoutException"
/// ```
///
/// ### Notes
/// - This class is **internal** to the retry subsystem and is not intended
///   for direct use by application code.
/// - It plays a key role in the recovery path of JetLeaf’s declarative
///   retry pipeline.
///
/// See also:
/// - [RecoveryCallback]
/// - [RetryContext]
/// - [RetryExecutor]
/// - [Recover]
/// 
/// {@endtemplate}
class _MethodInvocationRecoveryCallback<T> implements RecoveryCallback<T> {
  /// The target object instance on which the recovery method will be invoked.
  final Object _target;

  /// The reflective representation of the recovery method annotated with `@Recover`.
  final Method _method;

  /// The original method arguments from the failed invocation, if available.
  final MethodArgument? _originalArguments;

  /// Creates a new recovery callback that binds a target, recovery method,
  /// and original invocation arguments.
  ///
  /// {@macro _method_invocation_recovery_callback}
  _MethodInvocationRecoveryCallback(
    this._target,
    this._method,
    this._originalArguments,
  );

  @override
  Future<T> recover(RetryContext context) async {
    // Build arguments: [exception, ...originalArgs]
    final args = <Object?>[];
    final namedArgs = <String, Object?>{};
    
    final lastException = context.getLastException();
    args.add(lastException);

    if (_originalArguments != null) {
      args.addAll(_originalArguments.getPositionalArguments());
      namedArgs.addAll(_originalArguments.getNamedArguments());
    }

    final result = await _method.invoke(_target, namedArgs, args);
    return result as T;
  }
}