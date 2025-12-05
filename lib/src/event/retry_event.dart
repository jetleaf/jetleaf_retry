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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_lang/lang.dart';

/// {@template jetleaf_retry_event}
/// A base **event class** representing a retry operation triggered during
/// method invocation.
///
/// This event is emitted when a method execution is retried, typically due
/// to transient failures, exceptions, or configured retry policies.
///
/// ### Features
/// - Holds a reference to the [MethodInvocation] that is being retried.
/// - Supports timestamping via an optional clock.
/// - Can be extended for more specific retry events.
///
/// ### Usage Example
/// ```dart
/// class CustomRetryEvent<T> extends RetryEvent<T> {
///   CustomRetryEvent(MethodInvocation<T> invocation) : super(invocation);
/// }
/// ```
///
/// ### Design Notes
/// - Extends [ApplicationEvent], making it compatible with event-driven
///   architectures.
/// - Provides [getPackageName] for categorizing events.
/// - The generic [T] represents the return type of the retried method.
///
/// ### See Also
/// - [InvocationRetryEvent]
/// - [MethodInvocation]
/// - [ApplicationEvent]
/// {@endtemplate}
@Generic(RetryEvent)
abstract class RetryEvent<T> extends ApplicationEvent {
  /// Constructs a retry event for a given [source] method invocation.
  /// 
  /// {@macro jetleaf_retry_event}
  const RetryEvent(MethodInvocation<T> super.source, super.timestamp);

  /// Constructs a retry event with an explicit [timestamp].
  /// 
  /// {@macro jetleaf_retry_event}
  RetryEvent.withClock(MethodInvocation<T> super.source, super.timestamp);

  /// Returns the package name for this event type.
  ///
  /// Used for categorization and event dispatching.
  @override
  String getPackageName() => PackageNames.RETRY;
}

/// {@template jetleaf_invocation_retry_event}
/// A concrete retry event emitted specifically for a method invocation,
/// extending [RetryEvent].
///
/// ### Features
/// - Carries the [MethodInvocation] that triggered the retry.
/// - Preserves timestamp information via [withClock] constructor.
///
/// ### Usage Example
/// ```dart
/// final event = InvocationRetryEvent.withClock(invocation, timestamp);
/// ```
///
/// ### See Also
/// - [RetryEvent]
/// - [MethodInvocation]
/// {@endtemplate}
@Generic(InvocationRetryEvent)
final class InvocationRetryEvent<T> extends RetryEvent<T> {
  /// Constructs an invocation retry event with a [source] and [timestamp].
  /// 
  /// {@macro jetleaf_invocation_retry_event}
  const InvocationRetryEvent(super.source, super.timestamp);

  /// Constructs an invocation retry event with a [source] and [timestamp].
  /// 
  /// {@macro jetleaf_invocation_retry_event}
  InvocationRetryEvent.withClock(super.source, super.timestamp) : super.withClock();
}