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

import 'retry_context.dart';

/// Defines lifecycle hooks for monitoring and reacting to retry operations.
///
/// A [RetryListener] provides callbacks that allow developers or framework
/// components to observe and respond to key retry lifecycle events — such as
/// the start, each retry attempt, errors, and final closure of a retry context.
///
/// These listeners are often used for **instrumentation, metrics collection,
/// logging, or custom side-effects** that occur around the retry process.
/// Unlike [RetryCallback] or [RecoveryCallback], which handle business logic,
/// listeners are purely observational and should not alter retry flow
/// or outcomes.
///
/// ### Typical Use Cases
/// - Logging retry attempts, delays, and failure reasons.
/// - Emitting telemetry or metrics (e.g. Prometheus, OpenTelemetry).
/// - Auditing or tracing retry sequences.
/// - Custom alerting or circuit-breaking integrations.
///
/// ### Example
/// ```dart
/// class LoggingRetryListener implements RetryListener {
///   @override
///   void onOpen(RetryContext context) {
///     print('[Retry] Starting operation: ${context.getName()}');
///   }
///
///   @override
///   void onRetry(RetryContext context) {
///     print('[Retry] Attempt #${context.getAttemptCount()}');
///   }
///
///   @override
///   void onError(RetryContext context, Exception exception) {
///     print('[Retry] Error: ${exception.toString()}');
///   }
///
///   @override
///   void onClose(RetryContext context, Exception? lastException) {
///     if (lastException == null) {
///       print('[Retry] Operation succeeded after ${context.getAttemptCount()} attempts');
///     } else {
///       print('[Retry] Operation failed after ${context.getAttemptCount()} attempts: $lastException');
///     }
///   }
/// }
/// ```
///
/// ### Integration Points
/// - Automatically registered by the JetLeaf retry infrastructure when defined
///   in the application context or configured via the `@Retryable` annotation.
/// - Used by [RetryExecutor] and related retry orchestration utilities.
/// - Supports both synchronous and asynchronous retry flows.
///
/// ### Lifecycle Summary
/// | Stage | Method | Description |
/// |--------|---------|-------------|
/// | **Start** | [onOpen] | Invoked when a retry operation begins. |
/// | **Before Attempt** | [onRetry] | Called prior to each retry after the initial execution. |
/// | **On Error** | [onError] | Triggered when an exception occurs during execution. |
/// | **End** | [onClose] | Invoked when the retry sequence completes — either successfully or after all attempts fail. |
///
/// ### Thread Safety
/// Implementations **must be thread-safe** if used in concurrent retry contexts.
///
/// ### See Also
/// - [RetryCallback] — Defines the main retriable action.
/// - [RecoveryCallback] — Defines fallback behavior after failure.
/// - [RetryContext] — Provides contextual state for each retry.
/// - [RetryPolicy] — Governs retry eligibility.
/// - [BackoffPolicy] — Governs retry delays.
///
/// {@category Retry}
abstract interface class RetryListener {
  /// Called when a retry operation is **first opened or started**.
  ///
  /// This is typically the first lifecycle event, occurring before any
  /// execution or retry attempts. Implementations may record start time,
  /// initialize tracking, or prepare external observers.
  void onOpen(RetryContext context);

  /// Called **before each retry attempt**, excluding the initial one.
  ///
  /// This method can be used to log or track each retry attempt.  
  /// The attempt count can be obtained via [RetryContext.getAttemptCount].
  void onRetry(RetryContext context);

  /// Called when an **exception is caught** during execution.
  ///
  /// Provides both the [context] and the encountered [exception].
  /// Implementations can record diagnostic data or perform conditional logging.
  void onError(RetryContext context, Exception exception);

  /// Called when the retry operation **completes or closes**.
  ///
  /// This is invoked once per retry lifecycle, either after a successful
  /// execution or after all retry attempts have failed.  
  ///
  /// The optional [lastException] will be `null` if the operation eventually
  /// succeeded, or contain the last failure if it did not.
  void onClose(RetryContext context, Exception? lastException);
}