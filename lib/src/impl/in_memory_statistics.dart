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

import '../base/retry_statistics.dart';

/// {@template in_retry_statistics}
/// A simple, in-memory implementation of [RetryStatistics] for tracking
/// the lifecycle and outcomes of retry operations.
///
/// This class is intended to be used with retry mechanisms to collect
/// operational metrics, providing visibility into retry attempts, successes,
/// failures, and recovery actions. It can serve as a diagnostic tool for
/// monitoring retry behavior and fine-tuning retry policies.
///
/// ### Features
/// - Tracks total number of retry operations started.
/// - Tracks number of retry operations that completed successfully.
/// - Tracks number of retry operations that exhausted all allowed attempts.
/// - Tracks number of recovery callbacks triggered after failed retries.
/// - Allows resetting all counters to start fresh measurement cycles.
///
/// ### Usage
/// ```dart
/// final stats = InMemoryStatistics();
///
/// // During a retry operation:
/// stats.incrementStarted();
/// try {
///   await retryableOperation();
///   stats.incrementSuccess();
/// } catch (e) {
///   if (retryExhausted) {
///     stats.incrementExhausted();
///     stats.incrementRecovery();
///   }
/// }
///
/// print('Started: ${stats.getStartedCount()}');
/// print('Succeeded: ${stats.getSuccessCount()}');
/// print('Exhausted: ${stats.getExhaustedCount()}');
/// print('Recovery triggered: ${stats.getRecoveryCount()}');
/// ```
///
/// ### Thread Safety
/// This implementation is **not inherently thread-safe**. If used in
/// multi-threaded or async concurrent environments, proper synchronization
/// (e.g., mutexes or synchronized blocks) should be applied around
/// increment operations to ensure accurate counting.
///
/// {@endtemplate}
final class InMemoryStatistics implements RetryStatistics {
  /// Total number of retry operations that have been started.
  ///
  /// Incremented each time a retryable operation begins. Useful for measuring
  /// retry throughput and frequency.
  int _startedCount = 0;

  /// Total number of retry operations that completed successfully.
  ///
  /// Incremented when an operation completes successfully without exhausting
  /// all allowed retries.
  int _successCount = 0;

  /// Total number of retry operations that exhausted all retry attempts.
  ///
  /// Incremented when a retry operation reaches the maximum allowed attempts
  /// and still fails. This metric is useful for identifying operations that
  /// consistently fail despite retry attempts.
  int _exhaustedCount = 0;

  /// Total number of recovery callbacks that have been invoked.
  ///
  /// Incremented each time a recovery mechanism is triggered after a failed
  /// retry operation.
  int _recoveryCount = 0;

  /// Creates a new [InMemoryStatistics] instance with all counters initialized
  /// to zero.
  ///
  /// Counters are mutable and can be updated as retry operations progress.
  /// 
  /// {@macro in_retry_statistics}
  InMemoryStatistics();

  @override
  int getStartedCount() => _startedCount;

  @override
  int getSuccessCount() => _successCount;

  @override
  int getExhaustedCount() => _exhaustedCount;

  @override
  int getRecoveryCount() => _recoveryCount;

  @override
  void incrementStarted([int? count]) => _startedCount++;

  @override
  void incrementSuccess([int? count]) => _successCount++;

  @override
  void incrementExhausted([int? count]) => _exhaustedCount++;

  @override
  void incrementRecovery([int? count]) => _recoveryCount++;

  @override
  void reset() {
    _startedCount = 0;
    _successCount = 0;
    _exhaustedCount = 0;
    _recoveryCount = 0;
  }
}