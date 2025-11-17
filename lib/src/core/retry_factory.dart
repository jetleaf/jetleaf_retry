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

import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_lang/lang.dart';

import 'retry_definition.dart';

/// {@template retry_factory}
/// Factory interface responsible for discovering and providing
/// **retry-related metadata** (e.g., retry and recovery rules)
/// associated with annotated methods.
///
/// Implementations of this interface bridge JetLeaf’s annotation model
/// with its runtime retry execution engine, mapping method-level
/// annotations such as [Retryable] and [Recover] to concrete
/// [RetryDefinition] descriptors.
///
/// ## Responsibilities
/// - Introspect target classes or methods to find retry annotations.
/// - Build metadata describing retry behavior and recovery methods.
/// - Supply [RetryDefinition] instances to the retry infrastructure.
///
/// ## Typical Usage
/// The framework automatically uses a `ResilienceFactory` implementation
/// when initializing retry-capable components. For example, a reflective
/// factory might inspect pods and register retry metadata for methods
/// annotated with `@Retryable`.
///
/// ```dart
/// final factory = ReflectiveResilienceFactory();
/// final definition = factory.getDefinition(targetMethod);
///
/// if (definition != null) {
///   print('Retry policy found for: ${definition.method.name}');
/// }
/// ```
///
/// ## Integration Points
/// - [Retryable]: Defines retry rules and backoff configuration.
/// - [Recover]: Defines the fallback method to invoke after retries fail.
/// - [RetryDefinition]: Encapsulates metadata discovered by the factory.
///
/// {@endtemplate}
abstract interface class RetryFactory implements MethodInterceptor, AroundMethodInterceptor {
  /// Retrieves the [RetryDefinition] associated with the given [method],
  /// if any retry-related annotations are present.
  ///
  /// If the [method] is not annotated with [Retryable], this method
  /// should return `null`.
  ///
  /// ### Parameters
  /// - [method]: The method to analyze for retry annotations.
  ///
  /// ### Returns
  /// - A [RetryDefinition] describing the retry and recovery configuration.
  /// - `null` if no retry metadata is associated with the method.
  ///
  /// ### Example
  /// ```dart
  /// final definition = factory.getDefinition(method);
  /// if (definition != null) {
  ///   print('Retry attempts: ${definition.retryable.maxAttempts}');
  /// }
  /// ```
  RetryDefinition? getDefinition(Method method);
}