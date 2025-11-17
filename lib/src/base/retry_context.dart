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

/// Represents the **state and metadata** of an ongoing retry operation within
/// the JetLeaf retry management framework.
///
/// A [RetryContext] tracks essential information such as:
/// - The current attempt count (starting from 1),
/// - The most recent exception encountered,
/// - Custom attributes or metadata shared across retries,
/// - The logical name or label of the retry operation.
///
/// This context is passed to [RetryPolicy] and [BackoffPolicy] implementations
/// to drive decisions such as whether a retry is permitted, or how long to
/// wait before the next attempt.
///
/// ### Responsibilities
/// - Keep track of the retry lifecycle for a single operation.
/// - Store contextual data that may influence retry or backoff logic.
/// - Provide a consistent interface for introspection across multiple retries.
///
/// ### Example
/// ```dart
/// final context = DefaultRetryContext(name: 'fetchUser');
///
/// try {
///   await makeHttpRequest();
/// } on Exception catch (e) {
///   context.registerException(e);
///
///   if (retryPolicy.canRetry(context)) {
///     final delay = backoffPolicy.computeBackoff(context);
///     await Future.delayed(delay);
///     // Retry again...
///   } else {
///     throw e;
///   }
/// }
/// ```
///
/// ### Typical Use Cases
/// - Logging and tracing retry progress.
/// - Adaptive retry behavior based on error patterns.
/// - Sharing correlation IDs or metadata between retry attempts.
///
/// ### See Also
/// - [RetryPolicy] — determines whether retries are allowed.
/// - [BackoffPolicy] — computes delay durations between retries.
/// - [Retryable] — annotation to apply retry behavior to methods.
///
/// {@category Retry}
abstract interface class RetryContext {
  /// Returns the current attempt count (1-based).
  ///
  /// The first attempt always returns `1`, even if no exception has occurred yet.
  /// Each subsequent failure increments this count before the next retry.
  int getAttemptCount();

  /// Returns the last [Exception] encountered during the retry process, if any.
  ///
  /// This allows retry policies or backoff strategies to analyze the nature
  /// of previous failures to make informed retry decisions.
  Exception? getLastException();

  /// Registers a new retry attempt with the given [exception].
  ///
  /// Implementations should:
  /// - Increment the attempt count,
  /// - Record the provided exception as the last encountered error,
  /// - Optionally update any internal metrics or attributes.
  void registerException(Exception exception);

  /// Retrieves a custom attribute value by its [key].
  ///
  /// Custom attributes allow developers to attach additional contextual
  /// information to the retry lifecycle — for example:
  /// - `"correlationId"` for distributed tracing,
  /// - `"startTime"` for measuring total retry duration.
  Object? getAttribute(String key);

  /// Sets a custom attribute with the given [key] and [value].
  ///
  /// This enables storage of arbitrary metadata or state that can be
  /// inspected by retry or backoff policies across multiple attempts.
  void setAttribute(String key, Object value);

  /// Returns the logical name or label of this retry operation.
  ///
  /// This name may originate from the `label` in a [Retryable] annotation,
  /// or be set programmatically to help identify specific retry contexts
  /// in logs or metrics.
  String? getName();
}