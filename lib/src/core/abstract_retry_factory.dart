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
import 'package:jetleaf_logging/logging.dart';

import '../annotations/recover.dart';
import '../annotations/retryable.dart';
import '../base/retry_listener.dart';
import 'retry_definition.dart';
import 'retry_factory.dart';

/// Provides the foundational implementation for JetLeaf’s [RetryFactory],
/// responsible for constructing, caching, and resolving retry-related metadata
/// from annotated application methods.
///
/// This abstract base class serves as the backbone for annotation-driven
/// resilience management (i.e., [Retryable] and [Recover]), offering:
///
/// - Thread-safe caching of [RetryDefinition] metadata.
/// - Efficient reflection and lookup for annotated retry methods.
/// - Discovery and binding of recovery handlers.
/// - Integration with JetLeaf’s logging system.
///
/// Subclasses (e.g., `DefaultRetryFactory`) may extend this to provide
/// customized discovery logic, additional caching layers, or enhanced diagnostics.
abstract class AbstractRetryFactory implements RetryFactory {
  /// --------------------------------------------------------------------------------------------------------
  /// Retry Definition Registry
  /// --------------------------------------------------------------------------------------------------------

  /// Internal in-memory registry that maintains a mapping between method identifiers
  /// and their associated [RetryDefinition] metadata.
  ///
  /// This registry ensures fast lookup of retry configuration during method
  /// invocation, avoiding repeated annotation scans or reflection overhead.
  ///
  /// Each entry is keyed by a unique string built from the declaring class and
  /// method name (e.g. `package:example/example.dart.User#doWork`), ensuring stable identifiers
  /// across reflection and caching contexts.
  final Map<String, RetryDefinition> _definitions = {};

  /// {@template add_definition}
  /// Adds (or replaces) a [RetryDefinition] in the internal retry metadata registry.
  ///
  /// This operation is **thread-safe** thanks to the use of the [synchronized] block,
  /// ensuring consistent state in concurrent environments such as async request
  /// handling or parallel initialization.
  ///
  /// ### Behavior
  /// - Builds a unique cache key using [_buildKey].
  /// - Removes any existing entry for the same method.
  /// - Registers the new [RetryDefinition] for fast retrieval.
  ///
  /// ### Parameters
  /// - [definition]: The retry definition to register.
  ///
  /// ### Example
  /// ```dart
  /// final def = RetryDefinition(method, recover, retryable);
  /// addDefinition(def);
  ///
  /// // Later...
  /// final key = _buildKey(method);
  /// print(_definitions[key]); // -> RetryDefinition instance
  /// ```
  ///
  /// ### Notes
  /// - Existing definitions for the same method will be replaced.
  /// - Synchronization ensures thread safety but does not prevent concurrent reads.
  /// {@endtemplate}
  void addDefinition(RetryDefinition definition) {
    return synchronized(_definitions, () {
      final key = _buildKey(definition.method);

      // Replace any existing definition for the same method
      _definitions.remove(key);
      _definitions.add(key, definition);
    });
  }

  /// {@template build_key}
  /// Constructs a unique cache key for the given [method] based on its declaring
  /// class and method name.
  ///
  /// The resulting key follows the format:
  /// ```
  /// — <qualified-class-name>#<method-name>
  /// ```
  ///
  /// This convention ensures that methods with the same name but different
  /// declaring types (or packages) are properly distinguished.
  ///
  /// ### Example
  /// ```dart
  /// final key = _buildKey(method);
  /// print(key); // "com.example.service.UserService#saveUser"
  /// ```
  ///
  /// ### Parameters
  /// - [method]: The reflective representation of a class method.
  ///
  /// ### Returns
  /// - A unique key string suitable for use in internal registries or caches.
  /// {@endtemplate}
  String _buildKey(Method method) => "${method.getDeclaringClass().getQualifiedName()}#${method.getName()}";

  @override
  RetryDefinition? getDefinition(Method method) {
    return synchronized(_definitions, () {
      final key = _buildKey(method);
      return _definitions[key];
    });
  }

  /// --------------------------------------------------------------------------------------------------------
  /// Retry Definition Builder & Recovery Resolver
  /// --------------------------------------------------------------------------------------------------------

  /// {@template build_definition}
  /// Builds a [RetryDefinition] for the given [method] by analyzing its
  /// annotations and constructing any configured retry listeners.
  ///
  /// This function inspects the method for the presence of the [Retryable]
  /// annotation. If no such annotation is found, it returns `null`, indicating
  /// that the method is **not retryable**.
  ///
  /// If the annotation is present:
  /// - It loads and instantiates all configured [RetryListener] classes.
  /// - Handles both direct listener instances and listener class names.
  /// - Performs robust error handling and logging for failed instantiations.
  /// - Constructs and returns a [RetryDefinition] binding together:
  ///   - The reflective [Method] reference
  ///   - The [Retryable] annotation metadata
  ///   - The list of listener instances
  ///
  /// ### Parameters
  /// - [method]: The reflective method being analyzed.
  ///
  /// ### Returns
  /// - A fully constructed [RetryDefinition] if the method is retryable.
  /// - `null` if no [Retryable] annotation is present.
  ///
  /// ### Logging
  /// - Debug logs are emitted for non-[RetryListener] types or ignored listeners.
  /// - Warnings are logged for listener instantiation failures.
  ///
  /// ### Example
  /// ```dart
  /// final method = MyService.getClass().getMethod('doWork');
  /// final definition = buildDefinition(method);
  ///
  /// if (definition != null) {
  ///   print('Retryable method: ${definition.method.getName()}');
  /// }
  /// ```
  /// {@endtemplate}
  RetryDefinition? buildDefinition(Method method) {
    final logger = getLog();
    final retryable = method.getDirectAnnotation<Retryable>();

    // Skip non-retryable methods
    if (retryable == null) {
      return null;
    }

    // Collect retry listeners, instantiating if necessary
    final listeners = <RetryListener>[];
    for (final listener in retryable.listeners) {
      if (listener is RetryListener) {
        listeners.add(listener);
      } else {
        final type = ClassUtils.loadClass(listener);

        if (type != null) {
          try {
            final listenerInstance = type.newInstance();

            if (listenerInstance is RetryListener) {
              listeners.add(listenerInstance);
            } else {
              if (logger.getIsDebugEnabled()) {
                logger.debug('Ignoring $listenerInstance since it is not a type of [RetryListener]');
              }
            }
          } catch (e, st) {
            if (logger.getIsWarnEnabled()) {
              logger.warn('Failed to instantiate retry listener: $listener', error: e, stacktrace: st);
            }
          }
        }
      }
    }

    return RetryDefinition(method, retryable, listeners);
  }

  /// {@template find_recovery_method}
  /// Searches for a suitable recovery method annotated with [Recover]
  /// within the given [target] object for a specific [method].
  ///
  /// The recovery method serves as a fallback mechanism that executes
  /// when all retry attempts fail, allowing controlled recovery or graceful
  /// degradation of functionality.
  ///
  /// ### Matching Rules
  /// A method qualifies as a recovery method if it satisfies all of:
  /// 1. Annotated with [Recover].
  /// 2. Label matches the one in the [Retryable] definition:
  ///    - If a `label` is provided, only recover methods with the same label match.
  ///    - If no `label` is provided, recover methods with labels are ignored.
  /// 3. Return type is assignable to the original method's return type.
  /// 4. First parameter must be an [Exception] (or subclass).
  /// 5. Additional parameters should correspond to the original method’s parameters.
  ///
  /// ### Parameters
  /// - [target]: The instance whose class should be scanned for recovery methods.
  /// - [method]: The original method for which a recovery candidate is sought.
  /// - [label]: An optional label to match specific recovery methods.
  ///
  /// ### Returns
  /// - A [MapEntry] pairing the [Recover] annotation and its corresponding [Method],
  ///   if a valid recovery method is found.
  /// - `null` if no suitable recovery method exists.
  ///
  /// ### Logging
  /// - Debug logs are emitted when a recovery method is found.
  /// - No logs for unmatched methods to reduce noise.
  ///
  /// ### Example
  /// ```dart
  /// final entry = findRecoveryMethod(service, failingMethod, 'network');
  /// if (entry != null) {
  ///   print('Recovery handler: ${entry.value.getName()}');
  /// }
  /// ```
  /// {@endtemplate}
  MapEntry<Recover, Method>? findRecoveryMethod(Object target, Method method, String? label) {
    final logger = getLog();
    final targetClass = target.getClass();
    final methods = targetClass.getMethods();

    for (final m in methods) {
      final recover = m.getDirectAnnotation<Recover>();
      if (recover == null) continue;

      // Label filtering
      if (label != null && recover.label != label) continue;
      if (label == null && recover.label != null) continue;

      // Return type compatibility
      if (!m.getReturnClass().isAssignableTo(method.getReturnClass())) continue;

      // Parameter validation
      final params = m.getParameters();
      if (params.isEmpty) continue;

      final firstParam = params.first.getClass();
      if (!ClassUtils.isAssignableToError(firstParam)) continue;

      if (logger.getIsTraceEnabled()) {
        logger.trace('Found recovery method: ${m.getName()} for ${method.getName()}');
      }

      return MapEntry(recover, m);
    }

    return null;
  }

  /// {@template get_log}
  /// Returns the logger instance used for diagnostic, warning, and debugging
  /// messages emitted by this factory.
  ///
  /// This logger should be context-aware and integrate with the JetLeaf
  /// logging infrastructure, supporting lazy evaluation of log messages
  /// and consistent formatting.
  ///
  /// ### Returns
  /// - A [Log] instance for emitting framework logs.
  /// {@endtemplate}
  Log getLog();
}