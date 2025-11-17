# JetLeaf Resilience 🍃

Fault tolerance and resilience patterns for JetLeaf applications.

## Features

- 🔄 **Declarative Retry Logic** — Use `@Retryable` annotations for transparent retry behavior
- ⏱️ **Flexible Backoff Strategies** — Exponential, fixed, and random backoff policies
- 🛡️ **Recovery Mechanisms** — Graceful degradation with `@Recover` callbacks
- 📊 **Observability** — Built-in retry listeners and statistics
- 🎯 **AOP Integration** — Seamless method interception via JetLeaf's IoC container
- ⚙️ **Environment-Aware** — Configure retry behavior via application properties

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf_resilience:
    path: ../jetleaf_resilience
```

## Quick Start

### Basic Retry

```dart
import 'package:jetleaf_resilience/jetleaf_resilience.dart';

class ApiService {
  @Retryable(maxAttempts: 3)
  Future<Response> fetchData() async {
    return await httpClient.get('/api/data');
  }
}
```

### Retry with Backoff

```dart
@Retryable(
  maxAttempts: 5,
  backoff: Backoff(
    delay: 1000,       // 1 second initial delay
    multiplier: 2.0,   // Double delay each retry
    maxDelay: 30000,   // Cap at 30 seconds
    random: true,      // Add random jitter
  ),
)
Future<User> fetchUser(String id) async {
  return await apiClient.getUser(id);
}
```

### Retry Specific Exceptions

```dart
@Retryable(
  maxAttempts: 3,
  retryFor: [IOException, TimeoutException],
  noRetryFor: [AuthenticationException],
)
Future<Data> fetchSecureData() async {
  // Retries on IOException or TimeoutException
  // Does NOT retry on AuthenticationException
  return await secureApi.getData();
}
```

### Recovery Callback

```dart
class DataService {
  @Retryable(maxAttempts: 3, label: 'fetchUserData')
  Future<UserData> fetchUserData(String userId) async {
    return await apiClient.getUserData(userId);
  }

  @Recover(label: 'fetchUserData')
  Future<UserData> fetchUserDataRecovery(Exception e, String userId) async {
    // Fallback: return cached data
    return await cache.getUserData(userId) ?? UserData.empty();
  }
}
```

## Configuration

### Via Annotations

```dart
@Retryable(
  maxAttempts: 5,
  backoff: Backoff(
    delay: 1000,
    multiplier: 2.0,
    maxDelay: 30000,
    random: true,
  ),
  retryFor: [IOException],
  label: 'fetchCriticalData',
)
```

### Via Environment Properties

```dart
@ConfigurationProperties(prefix: 'app.retry')
class RetryConfiguration implements EnvironmentAware {
  late Environment _environment;
  
  int get maxAttempts => _environment.getProperty('max-attempts', int, defaultValue: 3);
  int get delay => _environment.getProperty('delay', int, defaultValue: 1000);
  
  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }
}
```

## Retry Listeners

Monitor retry operations for observability:

```dart
@RetryListenerAnnotation()
class MetricsRetryListener implements RetryListener {
  @override
  void onOpen(RetryContext context) {
    print('🔄 Retry operation started: ${context.getName()}');
  }

  @override
  void onRetry(RetryContext context) {
    print('⚠️ Retry attempt ${context.getAttemptCount()}');
  }

  @override
  void onError(RetryContext context, Exception exception) {
    print('❌ Error: $exception');
  }

  @override
  void onClose(RetryContext context, Exception? lastException) {
    print('✅ Operation completed after ${context.getAttemptCount()} attempts');
  }
}
```

## Manual Retry Execution

For programmatic control:

```dart
final executor = RetryExecutor(
  retryPolicy: SimpleRetryPolicy(maxAttempts: 3),
  backoffPolicy: ExponentialBackoffPolicy(initialDelay: 1000),
  listeners: [LoggingRetryListener()],
);

final result = await executor.execute(
  callback: () async => await apiClient.fetchData(),
  recovery: () async => cachedData,
);
```

## Statistics

Track retry operations:

```dart
final factory = context.getPod<ResilienceFactory>();
final stats = factory.statistics;

print('Started: ${stats.getStartedCount()}');
print('Success: ${stats.getSuccessCount()}');
print('Exhausted: ${stats.getExhaustedCount()}');
print('Recovered: ${stats.getRecoveryCount()}');
```

## Architecture

```
@Retryable method call
       ↓
Proxy created by JetLeaf AOP
       ↓
ResilienceFactory (intercepts method)
       ↓
RetryExecutor.execute(RetryCallback, RecoveryCallback)
       ↓
Policy and backoff control loop
       ↓
Method succeeds → return result
       ↓ OR
Retries exhausted → call @Recover method
```

## License

Part of the JetLeaf framework.
