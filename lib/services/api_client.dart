import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    if (json['success'] == true) {
      return ApiResponse<T>(
        success: true,
        data: fromJsonT != null && json['data'] != null
            ? fromJsonT(json['data'])
            : json['data'] as T?,
      );
    } else {
      return ApiResponse<T>(
        success: false,
        error: json['error'] != null
            ? ApiError.fromJson(json['error'])
            : ApiError(message: 'Unknown error', code: 'UNKNOWN_ERROR'),
      );
    }
  }
}

/// API Error model
class ApiError {
  final String message;
  final String code;
  final String? field; // Field that caused the validation error
  final List<Map<String, dynamic>>? validationErrors; // Detailed validation errors array

  ApiError({
    required this.message,
    required this.code,
    this.field,
    this.validationErrors,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'Unknown error',
      code: json['code'] ?? json['error'] ?? 'UNKNOWN_ERROR',
      field: json['field'],
      validationErrors: json['errors'] != null
          ? List<Map<String, dynamic>>.from(json['errors'])
          : null,
    );
  }

  /// Get a detailed error message including all validation errors
  String getDetailedMessage() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      final errorMessages = validationErrors!.map((error) {
        final path = error['path'] as List?;
        final field = path != null && path.isNotEmpty ? path.join('.') : 'unknown';
        final message = error['message'] ?? 'Validation error';
        return '$field: $message';
      }).join('\n   ');
      return '$code: $message\n   $errorMessages';
    }
    if (field != null) {
      return '$code: $message (field: $field)';
    }
    return '$code: $message';
  }

  @override
  String toString() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return getDetailedMessage();
    }
    if (field != null) {
      return '$code: $message (field: $field)';
    }
    return '$code: $message';
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final ApiError error;
  final int? statusCode;

  ApiException(this.error, [this.statusCode]);

  @override
  String toString() => error.toString();
}

/// Cache entry for response caching
class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  final DateTime lastAccessed;

  _CacheEntry({
    required this.data,
    required this.expiresAt,
  }) : lastAccessed = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Queued request for offline support
class _QueuedRequest {
  final String method;
  final String endpoint;
  final Map<String, dynamic>? body;
  final Map<String, String>? queryParams;
  final int priority; // 0 = highest (auth), 1 = user actions, 2 = analytics
  final DateTime queuedAt;

  _QueuedRequest({
    required this.method,
    required this.endpoint,
    this.body,
    this.queryParams,
    this.priority = 1,
  }) : queuedAt = DateTime.now();
}

/// Request/Response Interceptor
typedef RequestInterceptor = Future<Map<String, dynamic>?> Function(
  String method,
  String endpoint,
  Map<String, dynamic>? body,
  Map<String, String>? headers,
);

typedef ResponseInterceptor = Future<void> Function(
  String method,
  String endpoint,
  http.Response response,
);

/// Main API Client Service
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  // Base URL - using localhost for now
  static const String baseUrl = 'http://localhost:3000/api/v1';
  
  // WebSocket URL
  static const String wsUrl = 'ws://localhost:3000';
  
  // Token storage keys
  static const String _tokenKey = 'api_access_token';
  static const String _refreshTokenKey = 'api_refresh_token';
  static const String _queueKey = 'api_request_queue';

  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;

  // Response caching
  final Map<String, _CacheEntry> _cache = {};
  static const int _maxCacheSize = 100;
  static const Duration _defaultCacheTTL = Duration(minutes: 5);

  // Request deduplication
  final Map<String, Future<dynamic>> _inFlightRequests = {};

  // Offline queue
  final List<_QueuedRequest> _requestQueue = [];
  bool _isProcessingQueue = false;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // HTTP client with connection pooling
  late final http.Client _httpClient;

  // Interceptors
  final List<RequestInterceptor> _requestInterceptors = [];
  final List<ResponseInterceptor> _responseInterceptors = [];

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 1);

  ApiClient._internal() {
    _httpClient = http.Client();
    debugPrint('🚀 ApiClient initialized with base URL: $baseUrl');
    _startConnectivityMonitoring();
  }

  /// Initialize and load tokens from storage
  Future<void> initialize() async {
    try {
      debugPrint('🔧 Initializing ApiClient...');
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      
      if (_accessToken != null) {
        debugPrint('✅ Access token loaded from storage');
      } else {
        debugPrint('ℹ️ No access token found in storage');
      }
      
      if (_refreshToken != null) {
        debugPrint('✅ Refresh token loaded from storage');
      } else {
        debugPrint('ℹ️ No refresh token found in storage');
      }
      
      // Load queued requests
      await _loadQueuedRequests();
      
      // Process queue if online
      final isOnline = await _isOnline();
      if (isOnline) {
        debugPrint('🌐 Online - processing queued requests');
        _processRequestQueue();
      } else {
        debugPrint('📴 Offline - queued requests will be processed when connection is restored');
      }
      
      debugPrint('✅ ApiClient initialization complete');
    } catch (e) {
      debugPrint('❌ Error initializing ApiClient: $e');
    }
  }

  /// Generate cache key from endpoint and query params
  String _generateCacheKey(String endpoint, Map<String, String>? queryParams) {
    final key = endpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        queryParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      final paramsString = sortedParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      return '$key?$paramsString';
    }
    return key;
  }

  /// Get from cache
  T? _getFromCache<T>(String cacheKey) {
    final entry = _cache[cacheKey];
    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _cache.remove(cacheKey);
      }
      return null;
    }
    // Update last accessed for LRU
    _cache[cacheKey] = _CacheEntry(
      data: entry.data,
      expiresAt: entry.expiresAt,
    );
    return entry.data as T?;
  }

  /// Store in cache
  void _storeInCache(String cacheKey, dynamic data, {Duration? ttl}) {
    // Evict oldest entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
      // Remove oldest 10%
      final toRemove = (_maxCacheSize * 0.1).ceil();
      for (var i = 0; i < toRemove && i < sortedEntries.length; i++) {
        _cache.remove(sortedEntries[i].key);
      }
    }

    _cache[cacheKey] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(ttl ?? _defaultCacheTTL),
    );
  }

  /// Invalidate cache for endpoint pattern
  void _invalidateCache(String endpointPattern) {
    _cache.removeWhere((key, _) => key.startsWith(endpointPattern));
  }

  /// Check if online
  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.isNotEmpty && !result.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Start connectivity monitoring
  void _startConnectivityMonitoring() {
    debugPrint('📡 Starting connectivity monitoring...');
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
        if (isOnline) {
          debugPrint('🌐 Connection restored: ${results.join(", ")}');
          if (_requestQueue.isNotEmpty) {
            debugPrint('   Processing ${_requestQueue.length} queued requests');
            _processRequestQueue();
          }
        } else {
          debugPrint('📴 Connection lost: ${results.join(", ")}');
        }
      },
    );
  }

  /// Load queued requests from storage
  Future<void> _loadQueuedRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      if (queueJson != null) {
        final queueList = json.decode(queueJson) as List;
        _requestQueue.clear();
        _requestQueue.addAll(
          queueList.map((q) => _QueuedRequest(
            method: q['method'] as String,
            endpoint: q['endpoint'] as String,
            body: q['body'] != null
                ? Map<String, dynamic>.from(q['body'])
                : null,
            queryParams: q['queryParams'] != null
                ? Map<String, String>.from(q['queryParams'])
                : null,
            priority: q['priority'] as int? ?? 1,
          )),
        );
        debugPrint('📦 Loaded ${_requestQueue.length} queued requests from storage');
      } else {
        debugPrint('📦 No queued requests found in storage');
      }
    } catch (e) {
      debugPrint('❌ Error loading queued requests: $e');
    }
  }

  /// Save queued requests to storage
  Future<void> _saveQueuedRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueList = _requestQueue.map((q) => {
        'method': q.method,
        'endpoint': q.endpoint,
        'body': q.body,
        'queryParams': q.queryParams,
        'priority': q.priority,
      }).toList();
      await prefs.setString(_queueKey, json.encode(queueList));
    } catch (e) {
      debugPrint('❌ Error saving queued requests: $e');
    }
  }

  /// Process request queue
  Future<void> _processRequestQueue() async {
    if (_isProcessingQueue || _requestQueue.isEmpty) {
      if (_requestQueue.isEmpty) {
        debugPrint('📦 Request queue is empty');
      }
      return;
    }
    if (!await _isOnline()) {
      debugPrint('📴 Cannot process queue: offline');
      return;
    }

    debugPrint('🔄 Processing ${_requestQueue.length} queued requests...');
    _isProcessingQueue = true;
    try {
      // Sort by priority (lower = higher priority)
      _requestQueue.sort((a, b) => a.priority.compareTo(b.priority));

      int processed = 0;
      while (_requestQueue.isNotEmpty && await _isOnline()) {
        final request = _requestQueue.removeAt(0);
        try {
          debugPrint('🔄 Processing queued: ${request.method} ${request.endpoint}');
          switch (request.method.toUpperCase()) {
            case 'GET':
              await get(
                request.endpoint,
                queryParams: request.queryParams,
              );
              break;
            case 'POST':
              await post(request.endpoint, body: request.body);
              break;
            case 'PUT':
              await put(request.endpoint, body: request.body);
              break;
            case 'PATCH':
              await patch(request.endpoint, body: request.body);
              break;
            case 'DELETE':
              await delete(request.endpoint);
              break;
          }
          processed++;
          debugPrint('✅ Processed queued request: ${request.method} ${request.endpoint}');
        } catch (e) {
          debugPrint('❌ Failed to process queued request: ${request.method} ${request.endpoint}');
          debugPrint('   Error: $e');
          // Re-queue if it's a network error
          if (e is ApiException && e.error.code == 'NETWORK_ERROR') {
            _requestQueue.add(request);
            debugPrint('   Re-queued for retry');
          }
        }
        await _saveQueuedRequests();
      }
      debugPrint('✅ Queue processing complete: $processed/${_requestQueue.length + processed} processed');
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Queue request for offline processing
  Future<void> _queueRequest(_QueuedRequest request) async {
    _requestQueue.add(request);
    await _saveQueuedRequests();
    debugPrint('📦 Queued request: ${request.method} ${request.endpoint}');
  }

  /// Retry request with exponential backoff
  Future<T> _retryRequest<T>(
    Future<T> Function() requestFn, {
    int maxRetries = _maxRetries,
    Duration initialDelay = _initialRetryDelay,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await requestFn();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;

        // Only retry on network errors or 5xx errors
        final shouldRetry = e is SocketException ||
            e is TimeoutException ||
            (e is ApiException && e.statusCode != null && e.statusCode! >= 500);

        if (!shouldRetry) rethrow;

        debugPrint('⚠️ Request failed (attempt $attempt/$maxRetries), retrying in ${delay.inSeconds}s...');
        debugPrint('   Error: $e');
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2); // Exponential backoff
      }
    }

    debugPrint('❌ Max retries exceeded for request');
    throw Exception('Max retries exceeded');
  }

  /// Add request interceptor
  void addRequestInterceptor(RequestInterceptor interceptor) {
    _requestInterceptors.add(interceptor);
  }

  /// Add response interceptor
  void addResponseInterceptor(ResponseInterceptor interceptor) {
    _responseInterceptors.add(interceptor);
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Clear request queue
  Future<void> clearRequestQueue() async {
    _requestQueue.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  /// Set authentication tokens
  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    
    debugPrint('🔑 Setting authentication tokens');
    debugPrint('   Access Token: ${accessToken.substring(0, 20)}...');
    debugPrint('   Refresh Token: ${refreshToken.substring(0, 20)}...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      debugPrint('✅ Tokens saved to storage');
    } catch (e) {
      debugPrint('❌ Error saving tokens: $e');
    }
  }

  /// Clear authentication tokens
  Future<void> clearTokens() async {
    debugPrint('🔓 Clearing authentication tokens');
    _accessToken = null;
    _refreshToken = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      debugPrint('✅ Tokens cleared from storage');
    } catch (e) {
      debugPrint('❌ Error clearing tokens: $e');
    }
  }

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Refresh access token using refresh token
  Future<bool> refreshToken() async {
    if (_isRefreshing || _refreshToken == null) {
      if (_isRefreshing) {
        debugPrint('🔄 Token refresh already in progress');
      } else {
        debugPrint('❌ Cannot refresh token: no refresh token available');
      }
      return false;
    }

    debugPrint('🔄 Refreshing access token...');
    _isRefreshing = true;
    try {
      final uri = Uri.parse('$baseUrl/auth/refresh');
      debugPrint('📤 POST /auth/refresh');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': _refreshToken}),
      );

      debugPrint('📥 Token refresh response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final newToken = jsonResponse['data']['token'] as String;
          _accessToken = newToken;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, newToken);
          
          debugPrint('✅ Token refreshed successfully');
          _isRefreshing = false;
          return true;
        } else {
          debugPrint('❌ Token refresh failed: invalid response format');
        }
      } else {
        debugPrint('❌ Token refresh failed: status ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error refreshing token: $e');
    }
    
    _isRefreshing = false;
    return false;
  }

  /// Build headers for requests
  Map<String, String> _buildHeaders({bool requiresAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Handle response and extract data
  T _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    final statusCode = response.statusCode;
    
    // Handle rate limiting
    if (statusCode == 429) {
      throw ApiException(
        ApiError(
          message: 'Too many requests. Please try again later.',
          code: 'RATE_LIMIT_EXCEEDED',
        ),
        statusCode,
      );
    }

    // Parse response
    try {
      final jsonResponse = json.decode(response.body);
      final apiResponse = ApiResponse.fromJson(jsonResponse, fromJson);

      if (apiResponse.success) {
        if (apiResponse.data == null) {
          throw ApiException(
            ApiError(message: 'No data in response', code: 'NO_DATA'),
            statusCode,
          );
        }
        return apiResponse.data as T;
      } else {
        // Log the full error response for debugging
        debugPrint('❌ API Error Response:');
        debugPrint('   Status Code: $statusCode');
        debugPrint('   Response Body: ${response.body}');
        debugPrint('   Parsed Error: ${apiResponse.error}');
        
        throw ApiException(apiResponse.error!, statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      
      // Log raw response for debugging parse errors
      debugPrint('❌ Response Parse Error:');
      debugPrint('   Status Code: $statusCode');
      debugPrint('   Response Body: ${response.body}');
      debugPrint('   Error: $e');
      
      throw ApiException(
        ApiError(
          message: 'Failed to parse response: ${e.toString()}',
          code: 'PARSE_ERROR',
        ),
        statusCode,
      );
    }
  }

  /// Make GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool retryOnAuthError = true,
    bool useCache = true,
    Duration? cacheTTL,
    int priority = 1, // For offline queue
  }) async {
    // Generate cache key and check cache
    final cacheKey = _generateCacheKey(endpoint, queryParams);
    if (useCache) {
      final cached = _getFromCache<T>(cacheKey);
      if (cached != null) {
        debugPrint('💾 Cache hit: GET $endpoint');
        return cached;
      }
      debugPrint('💾 Cache miss: GET $endpoint');
    }

    debugPrint('📤 GET $endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      debugPrint('   Query Params: $queryParams');
    }

    // Check for duplicate in-flight request
    final requestKey = 'GET:$cacheKey';
    if (_inFlightRequests.containsKey(requestKey)) {
      debugPrint('🔄 Deduplicating request: GET $endpoint');
      return await _inFlightRequests[requestKey] as Future<T>;
    }

    // Check if online
    final isOnline = await _isOnline();
    if (!isOnline) {
      debugPrint('📴 Offline: GET $endpoint - queuing request');
      // Queue request for later
      await _queueRequest(_QueuedRequest(
        method: 'GET',
        endpoint: endpoint,
        queryParams: queryParams,
        priority: priority,
      ));
      throw ApiException(
        ApiError(
          message: 'No internet connection. Request queued for later.',
          code: 'OFFLINE',
        ),
      );
    }

    // Create request future
    final requestFuture = _retryRequest<T>(
      () async {
        var uri = Uri.parse('$baseUrl$endpoint');
        if (queryParams != null && queryParams.isNotEmpty) {
          uri = uri.replace(queryParameters: queryParams);
        }

        var headers = _buildHeaders(requiresAuth: requiresAuth);

        // Apply request interceptors
        for (final interceptor in _requestInterceptors) {
          final modified = await interceptor('GET', endpoint, null, headers);
          if (modified != null) {
            headers = Map<String, String>.from(modified);
          }
        }

        debugPrint('🌐 Sending GET request to: $uri');
        var response = await _httpClient.get(uri, headers: headers);
        debugPrint('📥 GET Response: ${response.statusCode} $endpoint');

        // Apply response interceptors
        for (final interceptor in _responseInterceptors) {
          await interceptor('GET', endpoint, response);
        }

        // Handle 401 - try to refresh token
        if (response.statusCode == 401 && 
            requiresAuth && 
            retryOnAuthError && 
            _refreshToken != null) {
          debugPrint('🔄 Token expired, refreshing...');
          final refreshed = await refreshToken();
          if (refreshed) {
            debugPrint('✅ Token refreshed, retrying GET $endpoint');
            // Retry request with new token
            response = await _httpClient.get(
              uri,
              headers: _buildHeaders(requiresAuth: requiresAuth),
            );
            debugPrint('📥 GET Retry Response: ${response.statusCode} $endpoint');
          }
        }

        final result = _handleResponse<T>(response, fromJson);

        // Cache successful GET responses
        if (useCache && response.statusCode == 200) {
          _storeInCache(cacheKey, result, ttl: cacheTTL);
          debugPrint('💾 Cached response: GET $endpoint');
        }

        if (response.statusCode == 200) {
          debugPrint('✅ GET Success: $endpoint');
        }

        return result;
      },
    );

    // Store in-flight request
    _inFlightRequests[requestKey] = requestFuture;

    try {
      final result = await requestFuture;
      return result;
    } finally {
      _inFlightRequests.remove(requestKey);
    }
  }

  /// Make POST request
  Future<T> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool retryOnAuthError = true,
    int priority = 0, // Higher priority for POST (user actions)
  }) async {
    // Invalidate related cache
    _invalidateCache(endpoint);

    // Check for duplicate in-flight request
    final requestKey = 'POST:$endpoint:${body != null ? json.encode(body) : ''}';
    if (_inFlightRequests.containsKey(requestKey)) {
      debugPrint('🔄 Deduplicating request: POST $endpoint');
      return await _inFlightRequests[requestKey] as Future<T>;
    }

    // Check if online
    final isOnline = await _isOnline();
    if (!isOnline) {
      debugPrint('📴 Offline: POST $endpoint - queuing request');
      // Queue request for later
      await _queueRequest(_QueuedRequest(
        method: 'POST',
        endpoint: endpoint,
        body: body,
        priority: priority,
      ));
      throw ApiException(
        ApiError(
          message: 'No internet connection. Request queued for later.',
          code: 'OFFLINE',
        ),
      );
    }

    // Create request future
    final requestFuture = _retryRequest<T>(
      () async {
        final uri = Uri.parse('$baseUrl$endpoint');
        
        // Log request details for debugging
        debugPrint('📤 POST $endpoint');
        if (body != null) {
          final requestBody = json.encode(body);
          debugPrint('   Request Body: $requestBody');
        }
        
        var headers = _buildHeaders(requiresAuth: requiresAuth);
        var requestBody = body != null ? json.encode(body) : null;

        // Apply request interceptors
        for (final interceptor in _requestInterceptors) {
          final modified = await interceptor('POST', endpoint, body, headers);
          if (modified != null) {
            headers = Map<String, String>.from(modified);
          }
        }
        
        debugPrint('🌐 Sending POST request to: $uri');
        var response = await _httpClient.post(
          uri,
          headers: headers,
          body: requestBody,
        );
        debugPrint('📥 POST Response: ${response.statusCode} $endpoint');

        // Apply response interceptors
        for (final interceptor in _responseInterceptors) {
          await interceptor('POST', endpoint, response);
        }

        // Handle 401 - try to refresh token
        if (response.statusCode == 401 && 
            requiresAuth && 
            retryOnAuthError && 
            _refreshToken != null) {
          debugPrint('🔄 Token expired, refreshing...');
          final refreshed = await refreshToken();
          if (refreshed) {
            debugPrint('✅ Token refreshed, retrying POST $endpoint');
            // Retry request with new token
            response = await _httpClient.post(
              uri,
              headers: _buildHeaders(requiresAuth: requiresAuth),
              body: requestBody,
            );
            debugPrint('📥 POST Retry Response: ${response.statusCode} $endpoint');
          }
        }

        final result = _handleResponse<T>(response, fromJson);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('✅ POST Success: $endpoint');
        }

        return result;
      },
    );

    // Store in-flight request
    _inFlightRequests[requestKey] = requestFuture;

    try {
      final result = await requestFuture;
      // Invalidate cache after successful POST
      _invalidateCache(endpoint);
      return result;
    } finally {
      _inFlightRequests.remove(requestKey);
    }
  }

  /// Make PUT request
  Future<T> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool retryOnAuthError = true,
    int priority = 0,
  }) async {
    _invalidateCache(endpoint);

    debugPrint('📤 PUT $endpoint');
    if (body != null) {
      debugPrint('   Request Body: ${json.encode(body)}');
    }

    final requestKey = 'PUT:$endpoint:${body != null ? json.encode(body) : ''}';
    if (_inFlightRequests.containsKey(requestKey)) {
      debugPrint('🔄 Deduplicating request: PUT $endpoint');
      return await _inFlightRequests[requestKey] as Future<T>;
    }

    final isOnline = await _isOnline();
    if (!isOnline) {
      debugPrint('📴 Offline: PUT $endpoint - queuing request');
      await _queueRequest(_QueuedRequest(
        method: 'PUT',
        endpoint: endpoint,
        body: body,
        priority: priority,
      ));
      throw ApiException(
        ApiError(
          message: 'No internet connection. Request queued for later.',
          code: 'OFFLINE',
        ),
      );
    }

    final requestFuture = _retryRequest<T>(
      () async {
        final uri = Uri.parse('$baseUrl$endpoint');
        var headers = _buildHeaders(requiresAuth: requiresAuth);
        var requestBody = body != null ? json.encode(body) : null;

        for (final interceptor in _requestInterceptors) {
          final modified = await interceptor('PUT', endpoint, body, headers);
          if (modified != null) headers = Map<String, String>.from(modified);
        }
        
        debugPrint('🌐 Sending PUT request to: $uri');
        var response = await _httpClient.put(uri, headers: headers, body: requestBody);
        debugPrint('📥 PUT Response: ${response.statusCode} $endpoint');

        for (final interceptor in _responseInterceptors) {
          await interceptor('PUT', endpoint, response);
        }

        if (response.statusCode == 401 && requiresAuth && retryOnAuthError && _refreshToken != null) {
          debugPrint('🔄 Token expired, refreshing...');
          final refreshed = await refreshToken();
          if (refreshed) {
            debugPrint('✅ Token refreshed, retrying PUT $endpoint');
            response = await _httpClient.put(
              uri,
              headers: _buildHeaders(requiresAuth: requiresAuth),
              body: requestBody,
            );
            debugPrint('📥 PUT Retry Response: ${response.statusCode} $endpoint');
          }
        }

        final result = _handleResponse<T>(response, fromJson);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('✅ PUT Success: $endpoint');
        }

        return result;
      },
    );

    _inFlightRequests[requestKey] = requestFuture;
    try {
      final result = await requestFuture;
      _invalidateCache(endpoint);
      return result;
    } finally {
      _inFlightRequests.remove(requestKey);
    }
  }

  /// Make PATCH request
  Future<T> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool retryOnAuthError = true,
    int priority = 0,
  }) async {
    _invalidateCache(endpoint);

    debugPrint('📤 PATCH $endpoint');
    if (body != null) {
      debugPrint('   Request Body: ${json.encode(body)}');
    }

    final requestKey = 'PATCH:$endpoint:${body != null ? json.encode(body) : ''}';
    if (_inFlightRequests.containsKey(requestKey)) {
      debugPrint('🔄 Deduplicating request: PATCH $endpoint');
      return await _inFlightRequests[requestKey] as Future<T>;
    }

    final isOnline = await _isOnline();
    if (!isOnline) {
      debugPrint('📴 Offline: PATCH $endpoint - queuing request');
      await _queueRequest(_QueuedRequest(
        method: 'PATCH',
        endpoint: endpoint,
        body: body,
        priority: priority,
      ));
      throw ApiException(
        ApiError(
          message: 'No internet connection. Request queued for later.',
          code: 'OFFLINE',
        ),
      );
    }

    final requestFuture = _retryRequest<T>(
      () async {
        final uri = Uri.parse('$baseUrl$endpoint');
        var headers = _buildHeaders(requiresAuth: requiresAuth);
        var requestBody = body != null ? json.encode(body) : null;

        for (final interceptor in _requestInterceptors) {
          final modified = await interceptor('PATCH', endpoint, body, headers);
          if (modified != null) headers = Map<String, String>.from(modified);
        }
        
        debugPrint('🌐 Sending PATCH request to: $uri');
        var response = await _httpClient.patch(uri, headers: headers, body: requestBody);
        debugPrint('📥 PATCH Response: ${response.statusCode} $endpoint');

        for (final interceptor in _responseInterceptors) {
          await interceptor('PATCH', endpoint, response);
        }

        if (response.statusCode == 401 && requiresAuth && retryOnAuthError && _refreshToken != null) {
          debugPrint('🔄 Token expired, refreshing...');
          final refreshed = await refreshToken();
          if (refreshed) {
            debugPrint('✅ Token refreshed, retrying PATCH $endpoint');
            response = await _httpClient.patch(
              uri,
              headers: _buildHeaders(requiresAuth: requiresAuth),
              body: requestBody,
            );
            debugPrint('📥 PATCH Retry Response: ${response.statusCode} $endpoint');
          }
        }

        final result = _handleResponse<T>(response, fromJson);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('✅ PATCH Success: $endpoint');
        }

        return result;
      },
    );

    _inFlightRequests[requestKey] = requestFuture;
    try {
      final result = await requestFuture;
      _invalidateCache(endpoint);
      return result;
    } finally {
      _inFlightRequests.remove(requestKey);
    }
  }

  /// Make DELETE request
  Future<T> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool retryOnAuthError = true,
    int priority = 0,
  }) async {
    _invalidateCache(endpoint);

    debugPrint('📤 DELETE $endpoint');

    final requestKey = 'DELETE:$endpoint';
    if (_inFlightRequests.containsKey(requestKey)) {
      debugPrint('🔄 Deduplicating request: DELETE $endpoint');
      return await _inFlightRequests[requestKey] as Future<T>;
    }

    final isOnline = await _isOnline();
    if (!isOnline) {
      debugPrint('📴 Offline: DELETE $endpoint - queuing request');
      await _queueRequest(_QueuedRequest(
        method: 'DELETE',
        endpoint: endpoint,
        priority: priority,
      ));
      throw ApiException(
        ApiError(
          message: 'No internet connection. Request queued for later.',
          code: 'OFFLINE',
        ),
      );
    }

    final requestFuture = _retryRequest<T>(
      () async {
        final uri = Uri.parse('$baseUrl$endpoint');
        var headers = _buildHeaders(requiresAuth: requiresAuth);

        for (final interceptor in _requestInterceptors) {
          final modified = await interceptor('DELETE', endpoint, null, headers);
          if (modified != null) headers = Map<String, String>.from(modified);
        }
        
        debugPrint('🌐 Sending DELETE request to: $uri');
        var response = await _httpClient.delete(uri, headers: headers);
        debugPrint('📥 DELETE Response: ${response.statusCode} $endpoint');

        for (final interceptor in _responseInterceptors) {
          await interceptor('DELETE', endpoint, response);
        }

        if (response.statusCode == 401 && requiresAuth && retryOnAuthError && _refreshToken != null) {
          debugPrint('🔄 Token expired, refreshing...');
          final refreshed = await refreshToken();
          if (refreshed) {
            debugPrint('✅ Token refreshed, retrying DELETE $endpoint');
            response = await _httpClient.delete(
              uri,
              headers: _buildHeaders(requiresAuth: requiresAuth),
            );
            debugPrint('📥 DELETE Retry Response: ${response.statusCode} $endpoint');
          }
        }

        final result = _handleResponse<T>(response, fromJson);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('✅ DELETE Success: $endpoint');
        }

        return result;
      },
    );

    _inFlightRequests[requestKey] = requestFuture;
    try {
      final result = await requestFuture;
      _invalidateCache(endpoint);
      return result;
    } finally {
      _inFlightRequests.remove(requestKey);
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _httpClient.close();
    _cache.clear();
    _requestQueue.clear();
    _inFlightRequests.clear();
  }
}

