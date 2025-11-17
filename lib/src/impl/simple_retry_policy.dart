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

import 'package:jetleaf_lang/lang.dart';

import '../annotations/retryable.dart';
import '../base/retry_context.dart';
import '../base/retry_policy.dart';

/// {@template simple_retry_policy}
/// A straightforward implementation of [RetryPolicy] that limits the number
/// of retry attempts and determines retry eligibility based on exception type.
///
/// The [SimpleRetryPolicy] is the default retry strategy used in many
/// JetLeaf retry mechanisms. It defines a maximum number of attempts and
/// class-based inclusion/exclusion rules for retryable exceptions.
///
/// ### Core Behavior
/// - Retries are **bounded** by [_maxAttempts].
/// - Exceptions listed in [_nonRetryableExceptions] **will never** trigger a retry.
/// - If [_retryableExceptions] is **non-empty**, only those exceptions will be retried.
/// - If both sets are empty, **all exceptions** are considered retryable.
///
/// ### Example
/// ```dart
/// final policy = SimpleRetryPolicy();
///
/// final context = DefaultRetryContext('networkCall');
///
/// final canRetry = policy.shouldRetryForException(
///   TimeoutException('connection lost'),
///   context,
/// );
///
/// print(canRetry); // true (retryable)
/// ```
///
/// ### Configuration Notes
/// - The first execution counts as **attempt #1**.  
///   Retrying up to `maxAttempts` means at most `maxAttempts - 1` retries.
/// - The policy uses reflective `Class` matching for exception assignability.
///   For example, a subclass of a retryable type will also qualify.
///
/// ### Typical Use Cases
/// - Retrying transient network errors such as `TimeoutException`.
/// - Avoiding retries for user or configuration errors (e.g. `FormatException`).
/// - Providing a baseline policy for higher-level abstractions like `RetryTemplate`.
///
/// ### Thread Safety
/// This class is **immutable** and **thread-safe**.
///
/// ### See Also
/// - [RetryPolicy] — The interface that defines retry decision logic.
/// - [RetryContext] — Provides state about current retry attempts.
/// - [Retryable] — Annotation for declarative retry configuration.
/// - [ExponentialBackoffPolicy] — A complementary policy for retry delay control.
///
/// {@endtemplate}
final class SimpleRetryPolicy implements RetryPolicy {
  /// The maximum number of attempts allowed for a retry operation.
  ///
  /// This includes the initial attempt.  
  /// For example, a value of `3` allows one initial attempt plus two retries.
  int _maxAttempts = 3;

  /// The set of exception types that should trigger retries.
  ///
  /// If this set is empty, **all exceptions** (except those listed in
  /// [_nonRetryableExceptions]) are treated as retryable.
  Set<Class> _retryableExceptions = {};

  /// The set of exception types that should **not** trigger retries.
  ///
  /// These take precedence over [_retryableExceptions].
  Set<Class> _nonRetryableExceptions = {};

  /// Creates a new [SimpleRetryPolicy] with the specified parameters.
  ///
  /// {@macro simple_retry_policy}
  SimpleRetryPolicy();

  @override
  bool canRetry(RetryContext context) => context.getAttemptCount() < _maxAttempts;

  @override
  RetryPolicy retryable(Retryable retryable) {
    _maxAttempts = retryable.maxAttempts;
    _nonRetryableExceptions = retryable.noRetryFor.map(ClassUtils.loadClass).whereType<Class>().toSet();
    _retryableExceptions = retryable.retryFor.map(ClassUtils.loadClass).whereType<Class>().toSet();

    return this;
  }

  @override
  bool shouldRetryForException(Exception exception, RetryContext context) {
    if (!canRetry(context)) {
      return false;
    }

    final exceptionClass = exception.getClass();

    // Check if explicitly non-retryable
    if (_nonRetryableExceptions.any((type) => exceptionClass.isAssignableTo(type))) {
      return false;
    }

    // If retryable exceptions are specified, check if exception matches
    return _retryableExceptions.any((type) => exceptionClass.isAssignableTo(type));
  }
}