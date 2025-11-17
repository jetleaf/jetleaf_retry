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

import '../base/retry_context.dart';

/// {@template simple_retry_context}
/// A basic implementation of [RetryContext] that tracks retry attempts,
/// the last exception thrown, and arbitrary attributes.
///
/// This context is used by [RetryPolicy], [RetryCallback], and [RecoveryCallback]
/// implementations to maintain state across retry operations.
///
/// ### Core Behavior
/// - Tracks the **number of attempts** made (`_attemptCount`).
/// - Stores the **last exception** thrown during execution (`_lastException`).
/// - Allows storing **custom attributes** in a key-value map (`_attributes`).
/// - Optionally, assigns a **name/label** for identification (`_name`).
///
/// ### Example
/// ```dart
/// final context = SimpleRetryContext('apiCall');
///
/// try {
///   // Execute some retryable operation
/// } catch (e) {
///   context.registerException(e as Exception);
/// }
///
/// print('Attempt: ${context.getAttemptCount()}');
/// print('Last Exception: ${context.getLastException()}');
/// ```
///
/// ### Thread Safety
/// This class is **not inherently thread-safe**. If using across multiple
/// threads or isolates, synchronization must be handled externally.
///
/// {@endtemplate}
final class SimpleRetryContext implements RetryContext {
  /// The current number of retry attempts (1-based).
  int _attemptCount = 0;

  /// The last exception thrown during the retry operation, if any.
  Exception? _lastException;

  /// Custom attribute storage for this retry context.
  final Map<String, Object> _attributes = {};

  /// Optional name/label for this retry operation.
  final String? _name;

  /// Creates a new [SimpleRetryContext] with an optional [name].
  ///
  /// {@macro simple_retry_context}
  SimpleRetryContext([this._name]);

  @override
  int getAttemptCount() => _attemptCount;

  @override
  Exception? getLastException() => _lastException;

  @override
  void registerException(Exception exception) {
    _attemptCount++;
    _lastException = exception;
  }

  @override
  Object? getAttribute(String key) => _attributes[key];

  @override
  void setAttribute(String key, Object value) => _attributes[key] = value;

  @override
  String? getName() => _name;
}