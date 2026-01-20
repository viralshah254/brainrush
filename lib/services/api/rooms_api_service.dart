import '../api_client.dart';

/// Multiplayer Rooms API Service
class RoomsApiService {
  final ApiClient _api = ApiClient();

  /// Create room
  Future<Map<String, dynamic>> createRoom({
    required String category,
    required int questionCount,
    required int maxPlayers,
    bool isPrivate = true,
    String mode = 'GENERAL',
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/rooms/create',
      body: {
        'category': category,
        'questionCount': questionCount,
        'maxPlayers': maxPlayers,
        'isPrivate': isPrivate,
        'mode': mode,
      },
    );
  }

  /// Join room by code
  Future<Map<String, dynamic>> joinRoom(String roomCode) async {
    return await _api.post<Map<String, dynamic>>('/rooms/$roomCode/join');
  }

  /// Join room via invite token
  Future<Map<String, dynamic>> joinRoomViaInvite(String inviteToken) async {
    return await _api.post<Map<String, dynamic>>(
      '/rooms/join/$inviteToken',
    );
  }

  /// Join room lobby
  Future<Map<String, dynamic>> joinRoomLobby(String roomCode) async {
    return await _api.post<Map<String, dynamic>>(
      '/rooms/$roomCode/lobby',
    );
  }

  /// Leave room
  Future<void> leaveRoom(String roomCode) async {
    await _api.post('/rooms/$roomCode/leave');
  }

  /// Get room details
  Future<Map<String, dynamic>> getRoomDetails(String roomCode) async {
    return await _api.get<Map<String, dynamic>>('/rooms/$roomCode');
  }

  /// Update room settings
  Future<void> updateRoomSettings({
    required String roomCode,
    String? category,
    int? questionCount,
    int? maxPlayers,
    String? mode,
  }) async {
    final body = <String, dynamic>{};
    if (category != null) body['category'] = category;
    if (questionCount != null) body['questionCount'] = questionCount;
    if (maxPlayers != null) body['maxPlayers'] = maxPlayers;
    if (mode != null) body['mode'] = mode;

    await _api.put('/rooms/$roomCode/settings', body: body);
  }

  /// Kick player from room
  Future<void> kickPlayer({
    required String roomCode,
    required String userId,
  }) async {
    await _api.post('/rooms/$roomCode/kick/$userId');
  }

  /// Get room questions
  Future<Map<String, dynamic>> getRoomQuestions(String roomCode) async {
    return await _api.get<Map<String, dynamic>>('/rooms/$roomCode/questions');
  }

  /// Complete match
  Future<Map<String, dynamic>> completeMatch({
    required String roomCode,
    required String matchId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required int timeSpent,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/rooms/$roomCode/complete',
      body: {
        'matchId': matchId,
        'score': score,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'timeSpent': timeSpent,
      },
    );
  }

  /// Get match time remaining
  Future<Map<String, dynamic>> getMatchTimeRemaining({
    required String roomCode,
    required String matchId,
  }) async {
    return await _api.get<Map<String, dynamic>>(
      '/rooms/$roomCode/match/$matchId/time-remaining',
    );
  }

  /// Toggle ready status
  Future<Map<String, dynamic>> toggleReady({
    required String roomCode,
    required bool ready,
  }) async {
    return await _api.patch<Map<String, dynamic>>(
      '/rooms/$roomCode/ready',
      body: {'ready': ready},
    );
  }

  /// Start game (host only)
  Future<Map<String, dynamic>> startGame(String roomCode) async {
    return await _api.post<Map<String, dynamic>>('/rooms/$roomCode/start');
  }

  /// Rematch
  Future<void> rematch(String roomCode) async {
    await _api.post('/rooms/$roomCode/rematch');
  }
}

