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
import '../base/backoff_policy.dart';
import '../base/retry_context.dart';

/// {@template fixed_backoff_policy}
/// A simple [BackoffPolicy] implementation that always returns a **fixed delay**
/// between retry attempts.
///
/// This policy does not perform any exponential growth or randomization — every
/// retry attempt waits for the exact same [_delay] duration.
///
/// ### Core Behavior
/// - Each retry attempt is separated by the same [_delay].
/// - Useful for predictable retry intervals or throttled retry strategies.
/// - Thread-safe and immutable.
///
/// ### Example
/// ```dart
/// final policy = FixedBackoffPolicy(Duration(seconds: 2));
///
/// final context = DefaultRetryContext('apiCall');
///
/// for (var i = 1; i <= 3; i++) {
///   context.setAttemptCount(i);
///   print('Attempt $i: ${policy.computeBackoff(context)}'); // Always 2 seconds
/// }
/// ```
///
/// ### Typical Use Cases
/// - Retrying HTTP requests with a constant interval.
/// - Limiting load on a remote service by spacing requests evenly.
/// - Simple retry strategies where exponential backoff is not required.
///
/// ### Thread Safety
/// This class is **immutable** and **thread-safe**.
///
/// ### See Also
/// - [BackoffPolicy] — Base interface for computing backoff durations.
/// - [ExponentialBackoffPolicy] — Provides exponential delay with optional jitter.
/// - [Retryable] — Annotation that defines retry and backoff behavior.
/// 
/// {@endtemplate}
final class FixedBackoffPolicy implements BackoffPolicy {
  /// The fixed delay duration to use for all retry attempts.
  late Duration _delay;

  /// Creates a new [FixedBackoffPolicy] with the specified [_delay].
  ///
  /// {@macro fixed_backoff_policy}
  FixedBackoffPolicy();

  @override
  BackoffPolicy backoff(Backoff backoff) {
    _delay = Duration(milliseconds: backoff.delay);
    return this;
  }

  @override
  Duration computeBackoff(RetryContext context) => _delay;
}