import '../api_client.dart';

/// User Management API Service
class UserApiService {
  final ApiClient _api = ApiClient();

  /// Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _api.get<Map<String, dynamic>>('/users/me');
  }

  /// Update username
  Future<Map<String, dynamic>> updateUsername(String username) async {
    return await _api.put<Map<String, dynamic>>(
      '/users/me/username',
      body: {'username': username},
    );
  }

  /// Update age
  Future<Map<String, dynamic>> updateAge(int age) async {
    return await _api.put<Map<String, dynamic>>(
      '/users/me/age',
      body: {'age': age},
    );
  }

  /// Update photo URL
  Future<Map<String, dynamic>> updatePhoto(String photoUrl) async {
    return await _api.put<Map<String, dynamic>>(
      '/users/me/photo',
      body: {'photoUrl': photoUrl},
    );
  }

  /// Get user stats
  Future<Map<String, dynamic>> getUserStats() async {
    return await _api.get<Map<String, dynamic>>('/users/me/stats');
  }

  /// Get wallet
  Future<Map<String, dynamic>> getWallet() async {
    return await _api.get<Map<String, dynamic>>('/users/me/wallet');
  }

  /// Get streak
  Future<Map<String, dynamic>> getStreak() async {
    return await _api.get<Map<String, dynamic>>('/users/me/streak');
  }

  /// Update preferences
  Future<Map<String, dynamic>> updatePreferences({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? notificationsEnabled,
    String? language,
    String? theme,
  }) async {
    final body = <String, dynamic>{};
    if (soundEnabled != null) body['soundEnabled'] = soundEnabled;
    if (musicEnabled != null) body['musicEnabled'] = musicEnabled;
    if (notificationsEnabled != null) body['notificationsEnabled'] = notificationsEnabled;
    if (language != null) body['language'] = language;
    if (theme != null) body['theme'] = theme;

    return await _api.put<Map<String, dynamic>>(
      '/users/me/preferences',
      body: body,
    );
  }

  /// Update language
  Future<Map<String, dynamic>> updateLanguage(String language) async {
    return await _api.put<Map<String, dynamic>>(
      '/users/me/language',
      body: {'language': language},
    );
  }

  /// Search users
  Future<List<dynamic>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    return await _api.get<List<dynamic>>(
      '/users/search',
      queryParams: {
        'query': query,
        'limit': limit.toString(),
      },
    );
  }

  /// Claim daily login reward
  Future<Map<String, dynamic>> claimLoginReward() async {
    return await _api.post<Map<String, dynamic>>('/users/me/login-reward');
  }

  /// Get free coins (watch ad)
  Future<Map<String, dynamic>> getFreeCoins({
    required int amount,
    required String source,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/users/me/free-coins',
      body: {
        'amount': amount,
        'source': source,
      },
    );
  }

  /// Spin lucky wheel
  Future<Map<String, dynamic>> spinLuckyWheel({required int spinCost}) async {
    return await _api.post<Map<String, dynamic>>(
      '/users/me/lucky-spin',
      body: {'spinCost': spinCost},
    );
  }

  /// Delete account
  Future<void> deleteAccount() async {
    await _api.delete('/users/me');
    await _api.clearTokens();
  }

  /// Get user achievements
  Future<List<dynamic>> getUserAchievements() async {
    return await _api.get<List<dynamic>>('/users/me/achievements');
  }

  /// Get education profile
  Future<Map<String, dynamic>> getEducationProfile() async {
    return await _api.get<Map<String, dynamic>>('/users/me/education');
  }

  /// Get match history
  Future<List<dynamic>> getMatchHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    return await _api.get<List<dynamic>>(
      '/users/me/matches',
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  /// Get transaction history
  Future<List<dynamic>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    return await _api.get<List<dynamic>>(
      '/users/me/transactions',
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  /// Save answered questions
  Future<void> saveAnsweredQuestions({
    required List<String> questionIds,
  }) async {
    await _api.post(
      '/users/me/answered-questions',
      body: {'questionIds': questionIds},
    );
  }

  /// Link social account
  Future<Map<String, dynamic>> linkSocialAccount({
    required String provider,
    required String providerId,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'provider': provider,
      'providerId': providerId,
    };
    if (email != null) body['email'] = email;

    return await _api.post<Map<String, dynamic>>(
      '/users/me/social/link',
      body: body,
    );
  }

  /// Unlink social account
  Future<void> unlinkSocialAccount(String provider) async {
    await _api.delete('/users/me/social/$provider/unlink');
  }

  /// Update app mode
  Future<Map<String, dynamic>> updateAppMode(String mode) async {
    return await _api.put<Map<String, dynamic>>(
      '/users/me/mode',
      body: {'mode': mode},
    );
  }
}

