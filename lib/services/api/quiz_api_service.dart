import '../api_client.dart';

/// Quiz Session API Service
class QuizApiService {
  final ApiClient _api = ApiClient();

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

  /// Question timeout
  Future<Map<String, dynamic>> questionTimeout({
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
}

