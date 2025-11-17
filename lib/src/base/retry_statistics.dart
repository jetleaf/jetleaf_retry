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

/// Provides statistical metrics and counters for retry operations.
///
/// A [RetryStatistics] implementation maintains aggregated metrics that track
/// the lifecycle outcomes of retryable operations — including how many retries
/// have started, succeeded, failed, or required recovery.
///
/// These statistics are primarily used for **monitoring, diagnostics, and
/// performance tuning** of retry strategies within the JetLeaf framework.
/// Implementations may expose live metrics to dashboards, logs, or telemetry
/// systems.
///
/// ### Typical Use Cases
/// - Exposing retry metrics to observability platforms (e.g. Prometheus).
/// - Logging retry performance trends over time.
/// - Resetting counters between test runs or operational cycles.
/// - Feeding adaptive retry policies that adjust behavior based on history.
///
/// ### Example
/// ```dart
/// class SimpleRetryStatistics implements RetryStatistics {
///   int _started = 0;
///   int _success = 0;
///   int _exhausted = 0;
///   int _recovered = 0;
///
///   @override
///   int getStartedCount() => _started;
///
///   @override
///   int getSuccessCount() => _success;
///
///   @override
///   int getExhaustedCount() => _exhausted;
///
///   @override
///   int getRecoveryCount() => _recovered;
///
///   void recordStart() => _started++;
///   void recordSuccess() => _success++;
///   void recordExhausted() => _exhausted++;
///   void recordRecovery() => _recovered++;
///
///   @override
///   void reset() {
///     _started = _success = _exhausted = _recovered = 0;
///   }
/// }
/// ```
///
/// ### Integration Points
/// - Used internally by the JetLeaf retry infrastructure (e.g. `RetryExecutor`)
///   to expose runtime metrics.
/// - Can be extended by monitoring adapters or custom retry executors.
/// - May be integrated with external metrics collectors such as Micrometer
///   or OpenTelemetry.
///
/// ### Metrics Summary
/// | Metric | Method | Description |
/// |---------|---------|-------------|
/// | **Started** | [getStartedCount] | Total number of retry operations initiated. |
/// | **Success** | [getSuccessCount] | Count of operations completed successfully before exhausting retries. |
/// | **Exhausted** | [getExhaustedCount] | Count of operations that failed even after all retry attempts. |
/// | **Recovered** | [getRecoveryCount] | Count of recovery callbacks successfully invoked after failure. |
///
/// ### Thread Safety
/// Implementations **should be thread-safe** if used in concurrent retry
/// environments.
///
/// ### See Also
/// - [RetryContext] — Tracks the state of individual retry executions.
/// - [RetryPolicy] — Governs retry eligibility.
/// - [RetryListener] — Observes retry lifecycle events.
/// - [Retryable] — Annotation that declares retryable methods.
///
/// {@category Retry}
abstract interface class RetryStatistics {
  /// Returns the total number of retry operations that have been **started**.
  ///
  /// This count increases when a new retryable operation begins, regardless
  /// of whether it ultimately succeeds or fails.
  int getStartedCount();

  /// Returns the total number of operations that **completed successfully**
  /// without exhausting their retry limit.
  ///
  /// This includes operations that succeeded either on the first attempt
  /// or after one or more retries.
  int getSuccessCount();

  /// Returns the total number of operations that **exhausted all retry
  /// attempts** and still failed.
  ///
  /// This typically represents operations that ended in a terminal failure
  /// without recovery.
  int getExhaustedCount();

  /// Returns the total number of **recovery callbacks** that were invoked
  /// after retry exhaustion.
  ///
  /// Recovery callbacks typically correspond to [RecoveryCallback] executions.
  int getRecoveryCount();

  /// Increments the counter of retry operations that have started.
  ///
  /// Call this at the beginning of a retry operation to track its initiation.
  void incrementStarted([int? count]);

  /// Increments the counter of retry operations that succeeded.
  ///
  /// Call this when an operation completes successfully before exhausting all
  /// allowed retries.
  void incrementSuccess([int? count]);

  /// Increments the counter of retry operations that exhausted all attempts.
  ///
  /// Call this when an operation fails despite reaching the maximum number of
  /// retries.
  void incrementExhausted([int? count]);

  /// Increments the counter of recovery callbacks invoked.
  ///
  /// Call this when a recovery strategy is executed after retries fail.
  void incrementRecovery([int? count]);

  /// Resets all recorded statistics to zero.
  ///
  /// Implementations should ensure atomic reset of all counters.
  void reset();
}