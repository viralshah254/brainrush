import '../api_client.dart';

/// Notifications API Service
class NotificationsApiService {
  final ApiClient _api = ApiClient();

  /// Get notifications
  Future<List<dynamic>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    return await _api.get<List<dynamic>>(
      '/notifications',
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'unreadOnly': unreadOnly.toString(),
      },
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _api.put('/notifications/$notificationId/read');
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _api.put('/notifications/read-all');
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _api.delete('/notifications/$notificationId');
  }

  /// Register device for push notifications
  Future<Map<String, dynamic>> registerDevice({
    required String deviceToken,
    required String platform,
    required String appVersion,
    required String osVersion,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/notifications/device',
      body: {
        'deviceToken': deviceToken,
        'platform': platform,
        'appVersion': appVersion,
        'osVersion': osVersion,
      },
    );
  }

  /// Get notification history
  Future<List<dynamic>> getNotificationHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    return await _api.get<List<dynamic>>(
      '/notifications/history',
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  /// Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    return await _api.get<Map<String, dynamic>>('/notifications/preferences');
  }

  /// Update notification preferences
  Future<Map<String, dynamic>> updateNotificationPreferences({
    bool? dailyReminder,
    bool? friendRequests,
    bool? leagueUpdates,
    bool? matchInvites,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) async {
    final body = <String, dynamic>{};
    if (dailyReminder != null) body['dailyReminder'] = dailyReminder;
    if (friendRequests != null) body['friendRequests'] = friendRequests;
    if (leagueUpdates != null) body['leagueUpdates'] = leagueUpdates;
    if (matchInvites != null) body['matchInvites'] = matchInvites;
    if (quietHoursStart != null) body['quietHoursStart'] = quietHoursStart;
    if (quietHoursEnd != null) body['quietHoursEnd'] = quietHoursEnd;

    return await _api.put<Map<String, dynamic>>(
      '/notifications/preferences',
      body: body,
    );
  }
}









