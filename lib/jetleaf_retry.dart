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

/// 🔄 **JetLeaf Retry Library**
///
/// This library provides a comprehensive retry mechanism for JetLeaf
/// applications, allowing developers to automatically retry failed
/// operations, handle recoveries, and track retry metrics.
///
/// It supports annotations, configurable retry policies, backoff strategies,
/// event publishing, and extensible retry factories.
///
///
/// ## 🔑 Key Concepts
///
/// ### 📝 Annotations
/// - `@Retryable` — declarative method-level retry configuration  
/// - `@Recover` — defines fallback behavior when retries are exhausted
///
///
/// ### ⚙ Core Retry Infrastructure
/// - `RetryFactory` — main factory for creating retry-enabled operations  
/// - `AbstractRetryFactory` — base type for factory implementations  
/// - `AnnotationAwareRetryFactory` — supports annotation-driven retries  
/// - `ExecutableRetryFactory` — runtime execution factory  
/// - `RetryDefinition` — metadata describing retry rules
///
///
/// ### 🔄 Retry Execution
/// - `RetryExecutor` — orchestrates retry attempts  
/// - `RetryPolicy` — interface for controlling retry logic  
/// - `RetryContext` — maintains state for an operation attempt  
/// - `RetryListener` — hooks for observing retry events  
/// - `RecoveryCallback` — invoked after retries fail  
/// - `RetryCallback` — user-provided retryable operation
///
///
/// ### ⏱ Backoff Policies
/// - `BackoffPolicy` — interface for waiting strategies  
/// - `FixedBackoffPolicy` — fixed interval between retries  
/// - `ExponentialBackoffPolicy` — exponential growth intervals
///
///
/// ### 📊 Retry Metrics
/// - `RetryStatistics` — interface for tracking attempts and results  
/// - `InMemoryStatistics` — simple in-memory implementation
///
///
/// ### 📦 Events
/// - `RetryEvent` — emitted on retry attempts for observability
///
///
/// ### 🛠 Implementations
/// - `DefaultRetryExecutor` — default executor implementation  
/// - `SimpleRetryPolicy` — basic retry policy  
/// - `SimpleRetryContext` — default retry context holder
///
///
/// ### ⚙ Auto-Configuration
/// - `RetryAutoConfiguration` — provides default beans and setups for JetLeaf applications
///
///
/// ### ⚠ Exceptions
/// - Framework-level errors for invalid retry definitions or execution failures
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to enable retries with minimal configuration:
/// ```dart
/// import 'package:jetleaf_retry/jetleaf_retry.dart';
///
/// @Retryable(maxAttempts: 3, backoff: FixedBackoffPolicy(1000))
/// void fetchData() {
///   // code that might fail
/// }
/// ```
///
/// Supports annotation-driven retries, custom policies, and fallback recoveries.
///
///
/// © 2025 Hapnium & JetLeaf Contributors
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