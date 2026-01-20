import '../api_client.dart';

/// Campaign Mode API Service
class CampaignApiService {
  final ApiClient _api = ApiClient();

  /// Get all campaigns
  Future<List<dynamic>> getAllCampaigns() async {
    return await _api.get<List<dynamic>>('/campaign');
  }

  /// Get campaign progress (current campaign)
  Future<Map<String, dynamic>> getCampaignProgress() async {
    return await _api.get<Map<String, dynamic>>('/campaign/progress');
  }

  /// Get campaign progress by ID
  Future<Map<String, dynamic>> getCampaignProgressById(String campaignId) async {
    return await _api.get<Map<String, dynamic>>('/campaign/$campaignId/progress');
  }

  /// Get campaign rounds
  Future<Map<String, dynamic>> getCampaignRounds() async {
    return await _api.get<Map<String, dynamic>>('/campaign/rounds');
  }

  /// Start campaign round
  Future<Map<String, dynamic>> startCampaignRound(String roundId) async {
    return await _api.post<Map<String, dynamic>>('/campaign/rounds/$roundId/start');
  }

  /// Get campaign round questions
  Future<Map<String, dynamic>> getCampaignRoundQuestions(String roundId) async {
    return await _api.get<Map<String, dynamic>>('/campaign/rounds/$roundId/questions');
  }

  /// Submit campaign answer
  Future<void> submitCampaignAnswer({
    required String campaignId,
    required String roundId,
    required String questionId,
    required int selectedIndex,
    required int timeRemaining,
  }) async {
    await _api.post(
      '/campaign/$campaignId/round/$roundId/answer',
      body: {
        'questionId': questionId,
        'selectedIndex': selectedIndex,
        'timeRemaining': timeRemaining,
      },
    );
  }

  /// Complete campaign round
  Future<Map<String, dynamic>> completeCampaignRound({
    required String campaignId,
    required String roundId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required int timeSpent,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/campaign/$campaignId/round/$roundId/complete',
      body: {
        'score': score,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'timeSpent': timeSpent,
      },
    );
  }

  /// Get campaign leaderboard
  Future<Map<String, dynamic>> getCampaignLeaderboard() async {
    return await _api.get<Map<String, dynamic>>('/campaign/leaderboard');
  }

  /// Check round unlock status
  Future<Map<String, dynamic>> checkRoundUnlockStatus(String roundId) async {
    return await _api.get<Map<String, dynamic>>(
      '/campaign/rounds/$roundId/unlock',
    );
  }

  /// Get round results
  Future<Map<String, dynamic>> getRoundResults(String roundId) async {
    return await _api.get<Map<String, dynamic>>(
      '/campaign/rounds/$roundId/results',
    );
  }

  /// Get next round
  Future<Map<String, dynamic>> getNextRound(String roundId) async {
    return await _api.get<Map<String, dynamic>>(
      '/campaign/rounds/$roundId/next',
    );
  }

  /// Replay round
  Future<Map<String, dynamic>> replayRound(String roundId) async {
    return await _api.post<Map<String, dynamic>>(
      '/campaign/rounds/$roundId/replay',
    );
  }

  /// Submit campaign answer (alternative path without campaignId)
  Future<Map<String, dynamic>> submitAnswer({
    required String roundId,
    required String questionId,
    required int selectedIndex,
    required int timeRemaining,
    bool adWatched = false,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/campaign/rounds/$roundId/answer',
      body: {
        'questionId': questionId,
        'selectedIndex': selectedIndex,
        'timeRemaining': timeRemaining,
        'adWatched': adWatched,
      },
    );
  }

  /// Complete campaign round (alternative path without campaignId)
  Future<Map<String, dynamic>> completeRound({
    required String roundId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required int timeSpent,
    List<Map<String, dynamic>>? answers,
  }) async {
    final body = <String, dynamic>{
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'timeSpent': timeSpent,
    };
    if (answers != null) body['answers'] = answers;

    return await _api.post<Map<String, dynamic>>(
      '/campaign/rounds/$roundId/complete',
      body: body,
    );
  }
}

