import '../api_client.dart';

/// Leaderboards API Service
class LeaderboardsApiService {
  final ApiClient _api = ApiClient();

  /// Get global leaderboard
  Future<Map<String, dynamic>> getGlobalLeaderboard({
    String period = 'all',
    int limit = 100,
    int offset = 0,
  }) async {
    return await _api.get<Map<String, dynamic>>(
      '/leaderboards/global',
      queryParams: {
        'period': period,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  /// Get weekly leaderboard
  Future<Map<String, dynamic>> getWeeklyLeaderboard() async {
    return await _api.get<Map<String, dynamic>>('/leaderboards/weekly');
  }

  /// Get monthly leaderboard
  Future<Map<String, dynamic>> getMonthlyLeaderboard() async {
    return await _api.get<Map<String, dynamic>>('/leaderboards/monthly');
  }

  /// Get category leaderboard
  Future<Map<String, dynamic>> getCategoryLeaderboard({
    required String category,
    String period = 'all',
    int limit = 100,
  }) async {
    return await _api.get<Map<String, dynamic>>(
      '/leaderboards/category/$category',
      queryParams: {
        'period': period,
        'limit': limit.toString(),
      },
    );
  }

  /// Get friends leaderboard
  Future<Map<String, dynamic>> getFriendsLeaderboard() async {
    return await _api.get<Map<String, dynamic>>('/leaderboards/friends');
  }
}




