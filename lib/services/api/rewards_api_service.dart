import '../api_client.dart';

/// Rewards API Service
class RewardsApiService {
  final ApiClient _api = ApiClient();

  /// Get available rewards
  Future<List<dynamic>> getAvailableRewards() async {
    return await _api.get<List<dynamic>>('/rewards/available');
  }

  /// Claim reward
  Future<void> claimReward(String rewardId) async {
    await _api.post('/rewards/$rewardId/claim');
  }

  /// Get reward history
  Future<List<dynamic>> getRewardHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    return await _api.get<List<dynamic>>(
      '/rewards/history',
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  /// Get today's daily reward
  Future<Map<String, dynamic>> getTodaysDailyReward() async {
    return await _api.get<Map<String, dynamic>>('/rewards/daily/today');
  }

  /// Claim daily reward
  Future<Map<String, dynamic>> claimDailyReward() async {
    return await _api.post<Map<String, dynamic>>('/rewards/daily/claim');
  }

  /// Get daily reward calendar
  Future<List<dynamic>> getDailyRewardCalendar() async {
    return await _api.get<List<dynamic>>('/rewards/daily/calendar');
  }
}

