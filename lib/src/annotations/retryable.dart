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
import 'package:meta/meta_meta.dart';

/// {@template retryable}
/// Annotation that marks a method as *retryable*, indicating that the JetLeaf
/// runtime should automatically retry its invocation when certain exceptions
/// occur.
///
/// The [Retryable] annotation allows developers to declaratively configure
/// retry logic for transient failures, network instability, or service
/// unavailability. When applied, JetLeaf intercepts method invocations and
/// transparently re-executes the operation according to the provided retry
/// policy.
///
/// ### Example
/// ```dart
/// @Retryable(
///   maxAttempts: 5,
///   backoff: Backoff(delay: Duration(milliseconds: 200), multiplier: 2.0),
///   retryFor: [TimeoutException, NetworkException],
///   noRetryFor: [ValidationException],
///   label: 'user-sync',
/// )
/// Future<void> synchronizeUserData() async {
///   // May be retried automatically if transient network failures occur.
/// }
/// ```
///
/// ### Retry Policy Components
///
/// | Parameter | Description | Default |
/// |------------|-------------|----------|
/// | `maxAttempts` | Maximum number of total attempts (including the initial call). | `3` |
/// | `backoff` | Strategy controlling retry delays and growth behavior. | `Backoff()` (no delay) |
/// | `retryFor` | List of exception types that should trigger a retry. | `[]` (retry all) |
/// | `noRetryFor` | List of exception types explicitly excluded from retrying. | `[]` |
/// | `label` | Optional identifier for this retry configuration, used in logging or metrics. | `null` |
/// | `listeners` | List of listener classes that handle retry lifecycle events (e.g. before retry, after failure). | `[]` |
///
/// ### Exception Type Resolution
/// Elements in [retryFor] and [noRetryFor] can be represented as:
/// - A **Dart Type** (e.g. `HttpException`)
/// - A **`ClassType<T>`** reference for runtime lookup
/// - A **fully-qualified string** (e.g. `"package:example/example.dart.Exception"`)
///
/// ### Listener Integration
/// Retry listeners (provided in [listeners]) can observe or modify retry
/// behavior dynamically. Each listener may respond to lifecycle callbacks such
/// as:
/// - `onRetry()` — called before a retry attempt
/// - `onError()` — called when an exception occurs
/// - `onExhausted()` — called when all retry attempts fail
///
/// ### Target
/// This annotation may only be applied to methods:
/// ```dart
/// @Target({TargetKind.method})
/// ```
///
/// ### See Also
/// - [Backoff] for defining retry delay strategies.
/// - [RetryListener] (if available) for event-driven retry extensions.
/// - [ReflectableAnnotation] for reflection-based runtime processing.
///{@endtemplate}
@Target({TargetKind.method})
final class Retryable extends ReflectableAnnotation {
  /// Maximum number of attempts (including the first invocation).
  final int maxAttempts;

  /// Backoff policy configuration.
  final Backoff backoff;

  /// Exception types that should trigger a retry.
  /// If empty, all exceptions will trigger retries (except those in [noRetryFor]).
  ///
  /// Can take shape like [HttpException, ClassType<NotFoundException>(), "package:example/example.dart.Exception"]
  final List<Object> retryFor;

  /// Exception types that should NOT trigger a retry.
  ///
  /// Can take shape like [HttpException, ClassType<NotFoundException>(), "package:example/example.dart.Exception"]
  final List<Object> noRetryFor;

  /// Optional label for this retry configuration.
  final String? label;

  /// Custom listener classes for retry events.
  ///
  /// Can take shape like [HttpListener, ClassType<NotFoundListener>(), HttpListener(), "package:example/example.dart.Listener"]
  final List<Object> listeners;

  /// {@macro retryable}
  const Retryable({
    this.maxAttempts = 3,
    this.backoff = const Backoff(),
    this.retryFor = const [],
    this.noRetryFor = const [],
    this.label,
    this.listeners = const [],
  });

  @override
  Type get annotationType => Retryable;
}

/// {@template backoff}
/// Configures the backoff strategy for retry delays.
///
/// Supports exponential backoff with configurable delay, multiplier, and
/// maximum delay constraints.
///
/// ### Parameters
/// - [delay]: Initial delay in milliseconds (default: 1000ms)
/// - [multiplier]: Multiplier for exponential backoff (default: 2.0)
/// - [maxDelay]: Maximum delay in milliseconds (default: 30000ms)
/// - [random]: Whether to apply randomization to delays (default: false)
///
/// ### Example
/// ```dart
/// // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s (capped)
/// const Backoff(delay: 1000, multiplier: 2.0, maxDelay: 30000)
///
/// // Fixed backoff: 500ms between each retry
/// const Backoff(delay: 500, multiplier: 1.0)
/// ```
/// {@endtemplate}
final class Backoff {
  /// Initial delay between retries in milliseconds.
  final int delay;

  /// Multiplier for exponential backoff.
  final double multiplier;

  /// Maximum delay between retries in milliseconds.
  final int maxDelay;

  /// Whether to apply random jitter to the delay.
  final bool random;

  /// {@macro backoff}
  const Backoff({this.delay = 1000, this.multiplier = 2.0, this.maxDelay = 30000, this.random = false});
}