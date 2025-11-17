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

/// JetLeaf Retry Library 🍃
///
/// Provides fault tolerance and resilience patterns for JetLeaf applications,
/// enabling declarative retry logic, circuit breakers, and recovery mechanisms
/// through annotations and AOP-style interception.
///
/// ### Key Features
/// - Declarative retry logic using `@Retryable` annotations.
/// - Flexible backoff strategies (exponential, fixed, random).
/// - Recovery callbacks via `@Recover` annotation.
/// - Retry listeners for monitoring and observability.
/// - Integration with JetLeaf's dependency injection and environment configuration.
/// - AOP-style method interception for transparent retry behavior.
///
/// ### Exports
/// - `annotations.dart` — Core resilience annotations (@Retryable, @Recover, @Backoff).
/// - `base.dart` — Foundational interfaces and contracts.
/// - `base_impl.dart` — Default implementations of policies and strategies.
/// - `retry_executor.dart` — Core retry execution engine.
/// - `resilience_factory.dart` — Main factory with interceptor logic.
/// - `resilience_auto_configuration.dart` — Auto-configuration for DI.
/// - `exceptions.dart` — Retry-related exception types.
///
/// ### Example
/// ```dart
/// import 'package:jetleaf_resilience/jetleaf_resilience.dart';
///
/// class ApiService {
///   @Retryable(
///     maxAttempts: 3,
///     backoff: Backoff(delay: 1000, multiplier: 2.0),
///     retryFor: [IOException],
///   )
///   Future<Response> fetchData() async {
///     // This method will be retried up to 3 times on IOException
///     return await http.get('https://api.example.com/data');
///   }
///
///   @Recover()
///   Future<Response> fetchDataRecovery(IOException e) async {
///     // Fallback logic when retries are exhausted
///     return Response.cached();
///   }
/// }
/// ```
///
/// {@category JetLeaf Retry}
library;

export 'src/annotations/recover.dart';
export 'src/annotations/retryable.dart';

export 'src/base/backoff_policy.dart';
export 'src/base/recovery_callback.dart';
export 'src/base/retry_callback.dart';
export 'src/base/retry_context.dart';
export 'src/base/retry_executor.dart';
export 'src/base/retry_listener.dart';
export 'src/base/retry_policy.dart';
export 'src/base/retry_statistics.dart';

export 'src/event/retry_event.dart';

export 'src/impl/default_retry_executor.dart';
export 'src/impl/exponential_backoff_policy.dart';
export 'src/impl/fixed_backoff_policy.dart';
export 'src/impl/in_memory_statistics.dart';
export 'src/impl/simple_retry_context.dart';
export 'src/impl/simple_retry_policy.dart';

export 'src/core/abstract_retry_factory.dart';
export 'src/core/annotation_aware_retry_factory.dart';
export 'src/core/executable_retry_factory.dart';
export 'src/core/retry_definition.dart';
export 'src/core/retry_factory.dart';

export 'src/retry_auto_configuration.dart';
export 'src/exceptions.dart';