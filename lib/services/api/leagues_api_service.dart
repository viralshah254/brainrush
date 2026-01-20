import '../api_client.dart';

/// Leagues API Service
class LeaguesApiService {
  final ApiClient _api = ApiClient();

  /// Get all leagues
  Future<List<dynamic>> getAllLeagues() async {
    return await _api.get<List<dynamic>>('/leagues');
  }

  /// Get active leagues
  Future<Map<String, dynamic>> getActiveLeagues() async {
    return await _api.get<Map<String, dynamic>>('/leagues/active');
  }

  /// Get league tiers
  Future<List<dynamic>> getLeagueTiers() async {
    return await _api.get<List<dynamic>>('/leagues/tiers');
  }

  /// Join league
  Future<void> joinLeague(String leagueId) async {
    await _api.post('/leagues/$leagueId/join');
  }

  /// Leave league
  Future<void> leaveLeague(String leagueId) async {
    await _api.post('/leagues/$leagueId/leave');
  }

  /// Get my rank in league
  Future<Map<String, dynamic>> getMyRank(String leagueId) async {
    return await _api.get<Map<String, dynamic>>(
      '/leagues/$leagueId/rank/me',
    );
  }

  /// Get education league by grade
  Future<Map<String, dynamic>> getEducationLeagueByGrade(
    String gradeLevel,
  ) async {
    return await _api.get<Map<String, dynamic>>(
      '/leagues/education/grade/$gradeLevel',
    );
  }

  /// Start league match
  Future<Map<String, dynamic>> startLeagueMatch(String leagueId) async {
    return await _api.post<Map<String, dynamic>>(
      '/leagues/$leagueId/match/start',
    );
  }

  /// Get league leaderboard
  Future<Map<String, dynamic>> getLeagueLeaderboard({
    required String leagueId,
    int limit = 100,
    int offset = 0,
  }) async {
    return await _api.get<Map<String, dynamic>>(
      '/leagues/$leagueId/leaderboard',
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  /// Get league match questions
  Future<Map<String, dynamic>> getLeagueMatchQuestions(String leagueId) async {
    return await _api.get<Map<String, dynamic>>('/leagues/$leagueId/match/questions');
  }

  /// Get league results
  Future<Map<String, dynamic>> getLeagueResults(String leagueId) async {
    return await _api.get<Map<String, dynamic>>('/leagues/$leagueId/results');
  }

  /// Submit league score
  Future<Map<String, dynamic>> submitLeagueScore({
    required String leagueId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/leagues/$leagueId/score',
      body: {
        'score': score,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
      },
    );
  }

  /// Complete league match
  Future<void> completeLeagueMatch({
    required String leagueId,
    required String matchId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required int timeSpent,
  }) async {
    await _api.post(
      '/leagues/$leagueId/match/$matchId/complete',
      body: {
        'score': score,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'timeSpent': timeSpent,
      },
    );
  }
}

