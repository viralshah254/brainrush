import '../api_client.dart';

/// Authentication API Service
class AuthApiService {
  final ApiClient _api = ApiClient();

  /// Sign up with email
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String username,
    required String password,
    required String provider,
    int? age,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/signup',
      body: {
        'email': email,
        'username': username,
        'password': password,
        'provider': provider,
        if (age != null) 'age': age,
      },
      requiresAuth: false,
    );

    // Save tokens if present
    if (response['token'] != null) {
      // If refreshToken is provided, use it; otherwise use the same token for both
      final accessToken = response['token'] as String;
      final refreshToken = response['refreshToken'] as String? ?? accessToken;
      await _api.setTokens(accessToken, refreshToken);
    }

    return response;
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    // Save tokens
    if (response['token'] != null && response['refreshToken'] != null) {
      await _api.setTokens(
        response['token'] as String,
        response['refreshToken'] as String,
      );
    }

    return response;
  }

  /// OAuth Login - Google
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/google',
      body: {'idToken': idToken},
      requiresAuth: false,
    );

    if (response['token'] != null && response['refreshToken'] != null) {
      await _api.setTokens(
        response['token'] as String,
        response['refreshToken'] as String,
      );
    }

    return response;
  }

  /// OAuth Login - Facebook
  Future<Map<String, dynamic>> loginWithFacebook({
    required String accessToken,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/facebook',
      body: {'accessToken': accessToken},
      requiresAuth: false,
    );

    if (response['token'] != null && response['refreshToken'] != null) {
      await _api.setTokens(
        response['token'] as String,
        response['refreshToken'] as String,
      );
    }

    return response;
  }

  /// OAuth Login - Apple
  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    required String authorizationCode,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/apple',
      body: {
        'identityToken': identityToken,
        'authorizationCode': authorizationCode,
      },
      requiresAuth: false,
    );

    if (response['token'] != null && response['refreshToken'] != null) {
      await _api.setTokens(
        response['token'] as String,
        response['refreshToken'] as String,
      );
    }

    return response;
  }

  /// Create guest account
  Future<Map<String, dynamic>> createGuestAccount() async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/guest',
      requiresAuth: false,
    );

    if (response['token'] != null) {
      await _api.setTokens(
        response['token'] as String,
        response['token'] as String, // Guest accounts may not have refresh token
      );
    }

    return response;
  }

  /// Upgrade guest account to permanent
  Future<Map<String, dynamic>> upgradeGuestAccount({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/guest/upgrade',
      body: {
        'email': email,
        'password': password,
        'username': username,
      },
    );

    if (response['token'] != null && response['refreshToken'] != null) {
      await _api.setTokens(
        response['token'] as String,
        response['refreshToken'] as String,
      );
    }

    return response;
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } finally {
      await _api.clearTokens();
    }
  }

  /// Validate session
  Future<Map<String, dynamic>> validateSession() async {
    return await _api.get<Map<String, dynamic>>('/auth/session');
  }

  /// Refresh access token
  Future<bool> refreshAccessToken() async {
    return await _api.refreshToken();
  }
}

