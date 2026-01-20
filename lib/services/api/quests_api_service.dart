import '../api_client.dart';

/// Quests & Challenges API Service
class QuestsApiService {
  final ApiClient _api = ApiClient();

  /// Get daily quests
  Future<List<dynamic>> getDailyQuests() async {
    return await _api.get<List<dynamic>>('/quests/daily');
  }

  /// Claim quest reward
  Future<Map<String, dynamic>> claimQuestReward(String questId) async {
    return await _api.post<Map<String, dynamic>>(
      '/quests/daily/$questId/claim',
    );
  }

  /// Update quest progress
  Future<Map<String, dynamic>> updateQuestProgress({
    required String questId,
    required String questType,
    required int increment,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/quests/daily/$questId/progress',
      body: {
        'questType': questType,
        'increment': increment,
      },
    );
  }

  /// Claim all quests bonus
  Future<Map<String, dynamic>> claimAllQuestsBonus() async {
    return await _api.post<Map<String, dynamic>>(
      '/quests/daily/bonus/claim',
    );
  }

  /// Get daily challenge status
  Future<Map<String, dynamic>> getDailyChallengeStatus() async {
    return await _api.get<Map<String, dynamic>>('/challenges/daily/status');
  }

  /// Get daily challenge questions
  Future<Map<String, dynamic>> getDailyChallengeQuestions() async {
    return await _api.get<Map<String, dynamic>>(
      '/challenges/daily/questions',
    );
  }

  /// Get daily challenge reward
  Future<Map<String, dynamic>> getDailyChallengeReward() async {
    return await _api.get<Map<String, dynamic>>('/challenges/daily/reward');
  }

  /// Get weekly challenges
  Future<List<dynamic>> getWeeklyChallenges() async {
    return await _api.get<List<dynamic>>('/challenges/weekly');
  }

  /// Update weekly challenge progress
  Future<Map<String, dynamic>> updateWeeklyChallengeProgress({
    required String challengeId,
    required String challengeType,
    required int increment,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/challenges/weekly/$challengeId/progress',
      body: {
        'challengeType': challengeType,
        'increment': increment,
      },
    );
  }

  /// Claim weekly challenge reward
  Future<Map<String, dynamic>> claimWeeklyChallengeReward(
    String challengeId,
  ) async {
    return await _api.post<Map<String, dynamic>>(
      '/challenges/weekly/$challengeId/claim',
    );
  }
}

