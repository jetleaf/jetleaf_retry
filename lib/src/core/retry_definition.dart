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
import '../base/retry_listener.dart';

/// {@template retry_definition}
/// Immutable metadata descriptor encapsulating retry and recovery
/// configuration for a specific method.
///
/// A **RetryDefinition** combines:
/// - The [method] to which the retry rules apply.
/// - The [Retryable] annotation defining retry policy and backoff.
/// - An optional [Recover] annotation specifying the fallback handler.
///
/// ## Purpose
/// This class acts as a lightweight, pre-processed metadata holder used
/// by the retry execution engine to apply consistent, precomputed
/// retry logic at runtime.
///
/// ## Example
/// ```dart
/// @Retryable(maxAttempts: 3)
/// Future<void> performOperation() async {
///   // retryable operation
/// }
///
/// @Recover()
/// void onFailure(Exception e) {
///   print('Operation failed after all retries: $e');
/// }
///
/// // In runtime:
/// final def = RetryDefinition(method, retryableAnnotation, listeners);
/// print(def.retryable.maxAttempts); // 3
/// ```
///
/// ## Fields
/// - [method]: The reflective representation of the annotated method.
/// - [retryable]: The retry configuration metadata.
/// - [listeners]: Loaded listeners, if given.
///
/// {@endtemplate}
final class RetryDefinition {
  /// The reflective representation of the method annotated with `@Retryable`.
  final Method method;

  /// The retry configuration metadata extracted from `@Retryable`.
  final Retryable retryable;

  /// List of listeners on the [retryable] annotation
  final List<RetryListener> listeners;

  /// {@macro retry_definition}
  const RetryDefinition(this.method, this.retryable, this.listeners);
}