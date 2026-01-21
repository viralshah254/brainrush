import '../api_client.dart';

/// Analytics API Service
class AnalyticsApiService {
  final ApiClient _api = ApiClient();

  /// Track event
  Future<void> trackEvent({
    required String event,
    Map<String, dynamic>? properties,
  }) async {
    await _api.post(
      '/analytics/event',
      body: {
        'event': event,
        if (properties != null) 'properties': properties,
      },
    );
  }

  /// Track screen view
  Future<void> trackScreenView({
    required String screen,
    Map<String, dynamic>? properties,
  }) async {
    await _api.post(
      '/analytics/screen',
      body: {
        'screen': screen,
        if (properties != null) 'properties': properties,
      },
    );
  }

  /// Track performance metric
  Future<void> trackPerformance({
    required String metric,
    required num value,
    Map<String, dynamic>? properties,
  }) async {
    await _api.post(
      '/analytics/performance',
      body: {
        'metric': metric,
        'value': value,
        if (properties != null) 'properties': properties,
      },
    );
  }

  /// Track error
  Future<void> trackError({
    required String error,
    required String message,
    String? stack,
    Map<String, dynamic>? properties,
  }) async {
    await _api.post(
      '/analytics/error',
      body: {
        'error': error,
        'message': message,
        if (stack != null) 'stack': stack,
        if (properties != null) 'properties': properties,
      },
    );
  }
}





