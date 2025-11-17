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

import '../annotations/retryable.dart';
import 'retry_context.dart';

/// {@template retry_policy}
/// Strategy interface for retry control and decision-making.
///
/// A **RetryPolicy** defines the rules governing whether an operation
/// should be retried after failure, and under what conditions.
///
/// This is the core policy abstraction used by JetLeaf's retry
/// infrastructure (such as `RetryInterceptor`, `RetryExecutor`, or
/// `@Retryable` annotated pods).
///
/// Implementations encapsulate the retry semantics, including:
///
/// - Maximum number of attempts
/// - Backoff or delay strategies
/// - Exception inclusion/exclusion rules
/// - Contextual state tracking (via [RetryContext])
///
/// ## Key Responsibilities
/// 1. **Decision Making:** Determine if a retry should occur
///    ([canRetry]) and whether a given exception qualifies for retry
///    ([shouldRetryForException]).
/// 2. **Annotation Integration:** Use [retryable] to apply metadata
///    from a [Retryable] configuration (for declarative retry setup).
/// 3. **Context Awareness:** Evaluate decisions based on attempt count,
///    last thrown exception, and other context data.
///
/// ## Typical Lifecycle
/// 1. A `RetryInterceptor` or `RetryExecutor` invokes a callable.
/// 2. Upon failure, it consults this [RetryPolicy].
/// 3. If [canRetry] returns `true`, it retries; otherwise it propagates
///    the exception.
///
/// ## Example
/// ```dart
/// final policy = SimpleRetryPolicy(maxAttempts: 3);
///
/// final context = RetryContext();
/// while (policy.canRetry(context)) {
///   try {
///     await service.call();
///     break; // success
///   } catch (e) {
///     if (!policy.shouldRetryForException(e, context)) rethrow;
///     context.registerException(e);
///     context.incrementAttempts();
///   }
/// }
/// ```
///
/// ## Integration with @Retryable
/// JetLeaf can map annotation metadata (e.g. `maxAttempts`, `retryFor`,
/// `noRetryFor`) into runtime policy configuration via [retryable].
///
/// {@endtemplate}
abstract interface class RetryPolicy {
  /// {@macro retry_policy}
  const RetryPolicy();

  /// Applies metadata from a [Retryable] configuration (e.g. from
  /// annotations or external configuration) to this policy, returning
  /// a new configured instance.
  ///
  /// This allows the retry policy to be declaratively customized at
  /// runtime — for example, a method annotated with:
  /// ```dart
  /// @Retryable(maxAttempts: 5, retryFor: [NetworkException])
  /// ```
  /// can be transformed into a corresponding runtime policy.
  ///
  /// Returns:
  /// - The configured [RetryPolicy] instance.
  ///
  /// Throws:
  /// - [IllegalArgumentException] if [retryable] is null or invalid.
  RetryPolicy retryable(Retryable retryable);

  /// Determines whether a retry attempt is allowed given the current
  /// [RetryContext].
  ///
  /// Implementations typically enforce:
  /// - Maximum allowed attempts (`maxAttempts`)
  /// - Cooldown or backoff timing windows
  /// - Circuit-breaker or throttling conditions
  ///
  /// Returns:
  /// - `true` if another retry is permitted.
  /// - `false` if no further attempts should be made.
  bool canRetry(RetryContext context);

  /// Determines whether the provided [exception] qualifies for retry
  /// under the current policy configuration and [RetryContext].
  ///
  /// This may involve checking:
  /// - Inclusion rules (`retryFor` exception types)
  /// - Exclusion rules (`noRetryFor`)
  /// - Attempt-based or context-based conditional logic
  ///
  /// Returns:
  /// - `true` if the given [exception] should trigger a retry.
  /// - `false` if it should propagate immediately.
  bool shouldRetryForException(Exception exception, RetryContext context);
}