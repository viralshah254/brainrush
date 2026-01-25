import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter/foundation.dart';

/// Local Notification Service for scheduling timezone-aware notifications
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification IDs
  static const int morningReminderId = 1;
  static const int dailyChallengeId = 2;
  static const int globalLeagueId = 3;
  static const int comebackId = 4;

  /// Initialize local notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/New_York')); // Default timezone

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      debugPrint('✅ Local Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Local notification initialization error: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
  }

  /// Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'mindrush_channel',
        'MindRush Notifications',
        channelDescription: 'General notifications from MindRush',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
      debugPrint('✅ Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  /// Schedule morning reminder (8 AM daily)
  Future<void> scheduleMorningReminder() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        8, // 8 AM
        0,
      );

      // If 8 AM has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        morningReminderId,
        '🌅 Good morning, MindRush awaits!',
        'Start your day with brain training and keep your streak alive!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'morning_reminder',
            'Morning Reminders',
            channelDescription: 'Daily morning reminders',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('✅ Morning reminder scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      debugPrint('❌ Error scheduling morning reminder: $e');
    }
  }

  /// Schedule daily challenge notification (12:05 AM daily)
  Future<void> scheduleDailyChallenge() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        0, // 12 AM
        5, // 5 minutes past
      );

      // If 12:05 AM has passed, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        dailyChallengeId,
        '⚡ Daily Challenge is LIVE!',
        'A new set of questions awaits you. Test your knowledge now!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_challenge',
            'Daily Challenge',
            channelDescription: 'Daily challenge notifications',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('✅ Daily challenge scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      debugPrint('❌ Error scheduling daily challenge: $e');
    }
  }

  /// Schedule global league reminder (11 AM daily)
  Future<void> scheduleLeagueReminder() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        11, // 11 AM
        0,
      );

      // If 11 AM has passed, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        globalLeagueId,
        '🏆 Global League Reminder',
        'Don\'t miss your chance to climb the ranks and win big!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'league_reminder',
            'League Reminders',
            channelDescription: 'Global league reminders',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('✅ League reminder scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      debugPrint('❌ Error scheduling league reminder: $e');
    }
  }

  /// Send comeback notification (immediate)
  Future<void> sendComebackNotification() async {
    await showNotification(
      id: comebackId,
      title: '🎁 We miss you! Comeback Bonus Inside!',
      body: 'Come back to MindRush and claim your special reward!',
    );
  }

  /// Schedule all recurring notifications
  Future<void> scheduleAllNotifications() async {
    await scheduleMorningReminder();
    await scheduleDailyChallenge();
    await scheduleLeagueReminder();
    debugPrint('✅ All recurring notifications scheduled');
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('✅ Cancelled notification: $id');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('✅ All notifications cancelled');
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Request permissions (iOS)
  Future<bool> requestPermissions() async {
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Android doesn't need explicit permission request
  }
}










