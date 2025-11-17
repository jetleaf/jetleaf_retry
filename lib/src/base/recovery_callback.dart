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

import 'package:jetleaf_lang/lang.dart';

import 'retry_context.dart';

/// Defines a recovery strategy that executes **after all retry attempts fail**.
///
/// A [RecoveryCallback] provides the fallback or compensation logic that runs
/// when a retry operation exhausts all configured attempts without success.
/// It receives the active [RetryContext], which includes details about the
/// last exception, total attempts, and any user-defined attributes.
///
/// ### Purpose
/// The main goal of this callback is to gracefully handle a terminal failure
/// scenario — for example, returning a default value, performing cleanup,
/// compensating for partial side effects, or logging failure details.
///
/// Unlike [RetryCallback], which encapsulates the main retriable action,
/// [RecoveryCallback] is responsible for defining what should happen **after**
/// retries are no longer possible.
///
/// ### Responsibilities
/// - Provide a controlled response to an unrecoverable failure.
/// - Allow system resilience through graceful degradation.
/// - Optionally rethrow exceptions if no recovery action is appropriate.
///
/// ### Example
/// ```dart
/// final retryCallback = UploadFileCallback();
/// final recoveryCallback = UploadFailureRecovery();
///
/// try {
///   final result = await retryTemplate.execute(
///     retryCallback,
///     recoveryCallback,
///   );
///   print('Result: $result');
/// } catch (e) {
///   print('Unrecoverable error: $e');
/// }
///
/// class UploadFailureRecovery implements RecoveryCallback<String> {
///   @override
///   FutureOr<String> recover(RetryContext context) {
///     final lastError = context.getLastException();
///     logError('Upload failed after ${context.getAttemptCount()} attempts', lastError);
///     return 'UPLOAD_FAILED';
///   }
/// }
/// ```
///
/// ### Type Parameter
/// - [T] — the return type of the recovery result, which may be the same as the
///   original retried operation or an alternate fallback representation.
///
/// ### Integration Points
/// - Used by JetLeaf retry mechanisms alongside [RetryCallback].
/// - Often paired with declarative `@Retryable` methods or templates.
/// - May be auto-wired in custom retry infrastructure or global fault handlers.
///
/// ### See Also
/// - [RetryCallback] — defines the primary operation to retry.
/// - [RetryContext] — provides state and metadata for both retry and recovery.
/// - [RetryPolicy] — controls retry behavior.
/// - [BackoffPolicy] — governs delay between retries.
///
/// {@category Retry}
@Generic(RecoveryCallback)
abstract interface class RecoveryCallback<T> {
  /// Executes the recovery logic once retries have been exhausted.
  ///
  /// Implementations can log the failure, emit fallback values, notify other
  /// components, or take corrective action based on [context].  
  ///
  /// Returns a [FutureOr] of [T] representing the result of the recovery
  /// operation. If no suitable recovery is possible, this method may rethrow
  /// the final exception.
  ///
  /// Throws:
  /// - Any unrecoverable [Exception] that cannot be handled gracefully.
  FutureOr<T> recover(RetryContext context);
}