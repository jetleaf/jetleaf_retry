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

/// {@template backoff_policy}
/// Strategy interface for controlling retry **delay behavior** between attempts.
///
/// A **BackoffPolicy** defines how long the system should wait before
/// performing the next retry attempt after a failure.
///
/// It works hand-in-hand with [RetryPolicy] to shape the retry lifecycle:
/// - The [RetryPolicy] decides *if* a retry should happen.
/// - The [BackoffPolicy] decides *when* the next retry should happen.
///
/// ## Responsibilities
/// - Compute the delay interval (backoff duration) before each retry.
/// - Support exponential, fixed, random jitter, or custom backoff algorithms.
/// - Optionally adapt behavior based on the [RetryContext] (e.g., number of attempts).
///
/// ## Key Concepts
/// - **Deterministic Backoff:** Returns predictable intervals (e.g., fixed 1 second delay).
/// - **Exponential Backoff:** Doubles the delay with each retry.
/// - **Jittered Backoff:** Adds randomness to prevent synchronized retry storms.
/// - **Annotation-Driven:** Configurable via the [Backoff] metadata used with `@Retryable`.
///
/// ## Typical Usage
/// ```dart
/// final backoffPolicy = ExponentialBackoffPolicy(initial: Duration(milliseconds: 200));
///
/// final context = RetryContext();
/// for (var attempt = 0; attempt < 3; attempt++) {
///   final delay = backoffPolicy.computeBackoff(context);
///   await Future.delayed(delay);
///   // perform retry attempt...
///   context.incrementAttempts();
/// }
/// ```
///
/// ## Integration with @Retryable
/// When combined with `@Retryable(backoff: Backoff(delay: ..., multiplier: ...))`,
/// the framework will call [backoff] to apply annotation metadata dynamically.
///
/// {@endtemplate}
abstract interface class BackoffPolicy {
  /// {@macro backoff_policy}
  const BackoffPolicy();

  /// Applies configuration metadata from a [Backoff] definition, usually
  /// provided via the `@Retryable` annotation or programmatic configuration.
  ///
  /// This method allows a single backoff policy implementation to adapt
  /// its parameters (e.g. initial delay, multiplier, max delay) at runtime
  /// without needing to create a new subclass.
  ///
  /// Example:
  /// ```dart
  /// final basePolicy = ExponentialBackoffPolicy();
  /// final configuredPolicy = basePolicy.backoff(
  ///   Backoff(delay: Duration(milliseconds: 500), multiplier: 2.0)
  /// );
  /// ```
  ///
  /// Returns:
  /// - A configured [BackoffPolicy] instance.
  ///
  /// Throws:
  /// - [IllegalArgumentException] if [backoff] is null or contains invalid values.
  BackoffPolicy backoff(Backoff backoff);

  /// Computes the backoff duration for the current retry attempt.
  ///
  /// Implementations should calculate the delay using properties from
  /// the given [RetryContext], such as:
  /// - The number of attempts (`context.attempt`)
  /// - The last exception encountered
  /// - Any configured backoff metadata (delay, multiplier, jitter, etc.)
  ///
  /// Returns:
  /// - A [Duration] representing how long to wait before performing the next retry.
  ///
  /// Notes:
  /// - The returned duration should **never** be negative.
  /// - A zero duration means "retry immediately."
  /// - Implementations should **cap** excessively large delays if a
  ///   maximum duration is defined.
  ///
  /// Example:
  /// ```dart
  /// final duration = policy.computeBackoff(context);
  /// print('Retrying in ${duration.inMilliseconds}ms');
  /// await Future.delayed(duration);
  /// ```
  Duration computeBackoff(RetryContext context);
}