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

/// {@template recover}
/// Marks a method as a recovery callback for failed retry attempts.
///
/// Recovery methods are invoked when all retry attempts have been exhausted.
/// They provide a fallback mechanism to gracefully handle failures.
///
/// ### Requirements
/// - Must have the same return type as the `@Retryable` method it recovers.
/// - Must accept at least one parameter: the exception that caused the failure.
/// - May accept additional parameters matching the original method's parameters.
///
/// ### Example
/// ```dart
/// @Retryable(maxAttempts: 3)
/// Future<User> fetchUser(String userId) async {
///   return await apiClient.getUser(userId);
/// }
///
/// @Recover()
/// Future<User> fetchUserRecovery(Exception e, String userId) async {
///   // Fallback: return cached user or default user
///   return await cache.getUser(userId) ?? User.guest();
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class Recover extends ReflectableAnnotation {
  /// Optional label to match with a specific `@Retryable` method.
  final String? label;

  /// {@macro recover}
  const Recover({this.label});

  @override
  Type get annotationType => Recover;
}