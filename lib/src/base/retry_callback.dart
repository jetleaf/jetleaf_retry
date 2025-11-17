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

import 'dart:async';

import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';

import 'retry_context.dart';

/// Represents a unit of work that should be executed within a **retry operation**.
///
/// A [RetryCallback] defines the logic that will be invoked by a retry
/// mechanism (e.g. a retry template, interceptor, or aspect) and may throw
/// exceptions that trigger retries as defined by the configured [RetryPolicy].
///
/// This interface abstracts the retriable action itself — such as performing
/// an HTTP request, a database operation, or any transient task — and provides
/// access to the current [RetryContext] for introspection and control.
///
/// ### Responsibilities
/// - Encapsulate the core operation to be retried.
/// - Provide integration with the JetLeaf retry infrastructure.
/// - Allow developers to write retryable logic in a clean, declarative manner.
///
/// ### Example
/// ```dart
/// final callback = MyRetryCallback();
/// final context = DefaultRetryContext(name: 'uploadFile');
///
/// try {
///   final result = await callback.execute(context);
///   print('Upload succeeded: $result');
/// } on Exception catch (e) {
///   context.registerException(e);
///   if (retryPolicy.canRetry(context)) {
///     final delay = backoffPolicy.computeBackoff(context);
///     await Future.delayed(delay);
///     // retry logic...
///   } else {
///     throw e;
///   }
/// }
/// ```
///
/// ### Type Parameter
/// - [T] — the return type of the callback result, which may represent a value
///   (e.g. a response object) or be `void` for side-effect-only operations.
///
/// ### Typical Use Cases
/// - Encapsulating retryable API calls.
/// - Defining retry logic for message processing or database access.
/// - Integrating with JetLeaf’s `@Retryable` annotation for declarative retries.
///
/// ### See Also
/// - [RetryContext] — provides state and metadata across retry attempts.
/// - [RetryPolicy] — determines when retries are permitted.
/// - [BackoffPolicy] — computes delay durations between retry attempts.
/// - [Retryable] — declarative retry annotation.
///
/// {@category Retry}
@Generic(RetryCallback)
abstract interface class RetryCallback<T> implements ApplicationEventBusAware {
  /// Executes the callback logic within the given [RetryContext].
  ///
  /// The implementation should contain the main operation that may fail and
  /// potentially trigger retries. Any exception thrown from this method will
  /// be evaluated against the active [RetryPolicy] to determine whether a retry
  /// should occur.
  ///
  /// Returns a [FutureOr] of [T], allowing both synchronous and asynchronous
  /// operations to participate in the retry mechanism.
  ///
  /// Throws:
  /// - Any [Exception] type configured as retryable.
  FutureOr<T> execute(RetryContext context);
}