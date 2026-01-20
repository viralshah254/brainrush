import '../api_client.dart';

/// Friends API Service
class FriendsApiService {
  final ApiClient _api = ApiClient();

  /// Get friends list
  Future<List<dynamic>> getFriends() async {
    return await _api.get<List<dynamic>>('/friends');
  }

  /// Get friends list (alias)
  Future<List<dynamic>> getFriendsList() async {
    return await _api.get<List<dynamic>>('/friends/list');
  }

  /// Search users for friends
  Future<List<dynamic>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    return await _api.get<List<dynamic>>(
      '/friends/search',
      queryParams: {
        'query': query,
        'limit': limit.toString(),
      },
    );
  }

  /// Send friend request
  Future<void> sendFriendRequest(String userId) async {
    await _api.post(
      '/friends/request',
      body: {'userId': userId},
    );
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    await _api.post('/friends/request/$requestId/accept');
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    await _api.post('/friends/request/$requestId/reject');
  }

  /// Decline friend request
  Future<void> declineFriendRequest(String requestId) async {
    await _api.put('/friends/request/$requestId/decline');
  }

  /// Get friend requests
  Future<Map<String, dynamic>> getFriendRequests() async {
    return await _api.get<Map<String, dynamic>>('/friends/requests');
  }

  /// Remove friend
  Future<void> removeFriend(String userId) async {
    await _api.delete('/friends/$userId/remove');
  }

  /// Invite friend to play
  Future<Map<String, dynamic>> inviteFriend({
    required String userId,
    required String roomCode,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/friends/$userId/invite',
      body: {'roomCode': roomCode},
    );
  }

  /// Find friends from contacts
  Future<Map<String, dynamic>> findFriendsFromContacts({
    required List<String> phoneNumbers,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/friends/find-from-contacts',
      body: {'phoneNumbers': phoneNumbers},
    );
  }

  /// Get friends presence
  Future<List<dynamic>> getFriendsPresence() async {
    return await _api.get<List<dynamic>>('/friends/presence');
  }

  /// Update presence
  Future<Map<String, dynamic>> updatePresence({
    required String status,
    String? activity,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (activity != null) body['activity'] = activity;

    return await _api.put<Map<String, dynamic>>(
      '/friends/presence',
      body: body,
    );
  }
}

