import '../api_client.dart';

/// Questions & Quiz API Service
class QuestionsApiService {
  final ApiClient _api = ApiClient();

  /// Get practice questions
  Future<Map<String, dynamic>> getPracticeQuestions({
    String? category,
    int questionCount = 10,
    String? gradeLevel,
    bool excludeAnswered = true,
  }) async {
    final body = <String, dynamic>{
      'questionCount': questionCount,
      'excludeAnswered': excludeAnswered,
    };
    if (category != null) body['category'] = category;
    if (gradeLevel != null) body['gradeLevel'] = gradeLevel;

    return await _api.post<Map<String, dynamic>>(
      '/questions/practice',
      body: body,
    );
  }

  /// Get education questions
  Future<Map<String, dynamic>> getEducationQuestions({
    String? category,
    int questionCount = 10,
    String? gradeLevel,
    String? examFocus,
  }) async {
    final body = <String, dynamic>{
      'questionCount': questionCount,
    };
    if (category != null) body['category'] = category;
    if (gradeLevel != null) body['gradeLevel'] = gradeLevel;
    if (examFocus != null) body['examFocus'] = examFocus;

    return await _api.post<Map<String, dynamic>>(
      '/questions/education',
      body: body,
    );
  }

  /// Get question categories
  Future<List<String>> getCategories() async {
    return await _api.get<List<String>>('/questions/categories');
  }

  /// Get daily questions
  Future<Map<String, dynamic>> getDailyQuestions() async {
    return await _api.get<Map<String, dynamic>>('/questions/daily');
  }

  /// Get daily question pool
  Future<List<dynamic>> getDailyQuestionPool() async {
    return await _api.get<List<dynamic>>('/questions/daily-pool');
  }

  /// Submit answer
  Future<Map<String, dynamic>> submitAnswer({
    required String sessionId,
    required String questionId,
    required int selectedIndex,
    required int timeRemaining,
    bool isRetry = false,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/quiz/sessions/$sessionId/answer',
      body: {
        'questionId': questionId,
        'selectedIndex': selectedIndex,
        'timeRemaining': timeRemaining,
        'isRetry': isRetry,
      },
    );
  }

  /// Request extra time
  Future<Map<String, dynamic>> requestExtraTime({
    required String sessionId,
    required bool adWatched,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/quiz/sessions/$sessionId/extra-time',
      body: {'adWatched': adWatched},
    );
  }

  /// Try again (watch ad)
  Future<void> tryAgain({
    required String sessionId,
    required bool adWatched,
  }) async {
    await _api.post(
      '/quiz/sessions/$sessionId/try-again',
      body: {'adWatched': adWatched},
    );
  }

  /// Record question timeout
  Future<Map<String, dynamic>> recordTimeout({
    required String sessionId,
    required String questionId,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/quiz/sessions/$sessionId/timeout',
      body: {'questionId': questionId},
    );
  }

  /// Complete session
  Future<Map<String, dynamic>> completeSession({
    required String sessionId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required int timeSpent,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/quiz/sessions/$sessionId/complete',
      body: {
        'score': score,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'timeSpent': timeSpent,
      },
    );
  }

  /// Get session history
  Future<List<dynamic>> getSessionHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    return await _api.get<List<dynamic>>(
      '/quiz/sessions',
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  /// Get question bank
  Future<Map<String, dynamic>> getQuestionBank({
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (category != null) queryParams['category'] = category;

    return await _api.get<Map<String, dynamic>>(
      '/questions/bank',
      queryParams: queryParams,
    );
  }

  /// Report question
  Future<void> reportQuestion({
    required String questionId,
    required String reason,
  }) async {
    await _api.post(
      '/questions/$questionId/report',
      body: {'reason': reason},
    );
  }

  /// Validate question
  Future<void> validateQuestion({
    required String questionId,
    required bool valid,
    String? notes,
  }) async {
    final body = <String, dynamic>{'valid': valid};
    if (notes != null) body['notes'] = notes;

    await _api.post(
      '/questions/$questionId/validate',
      body: body,
    );
  }

  /// Generate questions
  Future<Map<String, dynamic>> generateQuestions({
    required String category,
    required int count,
    String? difficulty,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'count': count,
    };
    if (difficulty != null) body['difficulty'] = difficulty;

    return await _api.post<Map<String, dynamic>>(
      '/questions/generate',
      body: body,
    );
  }

  /// Get session statistics
  Future<Map<String, dynamic>> getSessionStatistics(String sessionId) async {
    return await _api.get<Map<String, dynamic>>(
      '/quiz/sessions/$sessionId/stats',
    );
  }

  /// Create new session
  Future<Map<String, dynamic>> createNewSession() async {
    return await _api.post<Map<String, dynamic>>('/quiz/sessions/new');
  }

  /// Save answered questions
  Future<void> saveAnsweredQuestions({
    required List<String> questionIds,
  }) async {
    await _api.post(
      '/quiz/answered-questions',
      body: {'questionIds': questionIds},
    );
  }
}

