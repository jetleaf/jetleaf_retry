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

import 'package:jetleaf_core/annotation.dart';

import 'base/backoff_policy.dart';
import 'base/retry_executor.dart';
import 'base/retry_policy.dart';
import 'base/retry_statistics.dart';
import 'core/annotation_aware_retry_factory.dart';
import 'core/retry_factory.dart';
import 'impl/default_retry_executor.dart';
import 'impl/exponential_backoff_policy.dart';
import 'impl/fixed_backoff_policy.dart';
import 'impl/in_memory_statistics.dart';
import 'impl/simple_retry_policy.dart';

/// {@template retry_auto_configuration}
/// JetLeaf **auto-configuration entry point** for the retry subsystem.
///
/// The [RetryAutoConfiguration] class registers the default
/// [RetryFactory] pod in the application context, making it available
/// for dependency injection and method-level retry interception.
///
/// This configuration is loaded automatically when the
/// `"jetleaf.retry.configuration"` profile is active, or when the
/// JetLeaf application context performs component scanning.
///
/// ### Purpose
/// - Provide a preconfigured instance of [RetryFactory].
/// - Enable **annotation-driven retry logic** (e.g., `@Retryable`, `@Recover`).
/// - Integrate the retry subsystem into the JetLeaf dependency
///   injection lifecycle.
///
/// ### Example
/// ```dart
/// final context = JetLeafApplication.run();
/// final factory = context.getPod<RetryFactory>("jetleaf.retry.factory");
/// print(factory.statistics.getStartedCount());
/// ```
/// {@endtemplate}
@Configuration(RetryAutoConfiguration.RETRY_AUTO_CONFIGURATION_POD_NAME)
final class RetryAutoConfiguration {
  /// {@macro retry_auto_configuration}
  const RetryAutoConfiguration();

  /// Pod name for the **RetryAutoConfiguration**.
  static const String RETRY_AUTO_CONFIGURATION_POD_NAME = "jetleaf.retry.configuration";

  /// Pod name for the **RetryFactory**.
  static const String RETRY_FACTORY_POD_NAME = "jetleaf.retry.retryFactory";

  /// Pod name for the **RetryPolicy**.
  static const String RETRY_POLICY_POD_NAME = "jetleaf.retry.retryPolicy";

  /// Pod name for the **RetryStatistics**.
  static const String RETRY_STATISTICS_POD_NAME = "jetleaf.retry.retryStatistics";

  /// Pod name for the **RetryExecutor**.
  static const String RETRY_EXECUTOR_POD_NAME = "jetleaf.retry.retryExecutor";

  /// Pod name for the **ExponentialBackoffPolicy**.
  static const String EXPONENTIAL_BACKOFF_POLICY_POD_NAME = "jetleaf.retry.exponentialBackoffPolicy";

  /// Pod name for the **FixedBackoffPolicy**.
  static const String FIXED_BACKOFF_POLICY_POD_NAME = "jetleaf.retry.fixedBackoffPolicy";

  /// Declares a [RetryPolicy] pod.
  @Pod(value: RETRY_POLICY_POD_NAME)
  @ConditionalOnMissingPod(values: [RetryPolicy])
  RetryPolicy retryPolicy() => SimpleRetryPolicy();

  /// Declares a [RetryStatistics] pod.
  @Pod(value: RETRY_STATISTICS_POD_NAME)
  @ConditionalOnMissingPod(values: [RetryStatistics])
  RetryStatistics retryStatistics() => InMemoryStatistics();

  /// Declares a [RetryExecutor] pod.
  @Pod(value: RETRY_EXECUTOR_POD_NAME)
  @ConditionalOnMissingPod(values: [RetryExecutor])
  RetryExecutor retryExecutor() => DefaultRetryExecutor();

  /// Declares an exponential [BackoffPolicy] pod.
  @Pod(value: EXPONENTIAL_BACKOFF_POLICY_POD_NAME)
  @ConditionalOnMissingPod(values: [BackoffPolicy])
  @ConditionalOnProperty(
    prefix: "jetleaf",
    havingValue: 'exponential',
    matchIfMissing: true,
    names: ["backoff", "policy"],
  )
  BackoffPolicy exponentialBackoffPolicy() => ExponentialBackoffPolicy();

  /// Declares a fixed [BackoffPolicy] pod.
  @Pod(value: FIXED_BACKOFF_POLICY_POD_NAME)
  @ConditionalOnMissingPod(values: [BackoffPolicy])
  @ConditionalOnProperty(
    prefix: "jetleaf",
    havingValue: 'fixed',
    matchIfMissing: true,
    names: ["backoff", "policy"],
  )
  BackoffPolicy fixedBackoffPolicy() => FixedBackoffPolicy();

  /// Declares and exposes the default [RetryFactory] pod.
  @Pod(value: RETRY_FACTORY_POD_NAME)
  @ConditionalOnMissingPod(values: [RetryFactory])
  RetryFactory retryFactory(
    BackoffPolicy backoffPolicy,
    RetryPolicy retryPolicy,
    RetryStatistics retryStatistics,
    RetryExecutor retryExecutor
  ) => AnnotationAwareRetryFactory(backoffPolicy, retryPolicy, retryStatistics, retryExecutor);
}