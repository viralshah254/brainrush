import '../api_client.dart';

/// Achievements API Service
class AchievementsApiService {
  final ApiClient _api = ApiClient();

  /// Get all achievements
  Future<List<dynamic>> getAchievements() async {
    return await _api.get<List<dynamic>>('/achievements');
  }

  /// Get achievement progress
  Future<Map<String, dynamic>> getAchievementProgress(String achievementId) async {
    return await _api.get<Map<String, dynamic>>('/achievements/$achievementId/progress');
  }
}

