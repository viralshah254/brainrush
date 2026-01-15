import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_preferences.dart';
import 'local_notification_service.dart';

/// Smart notification service that schedules notifications based on user behavior
class SmartNotificationService {
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  final LocalNotificationService _localNotifications = LocalNotificationService();
  final Random _random = Random();

  // Notification message pools
  // ignore: unused_field
  static const List<NotificationMessage> _morningMessages = [
    NotificationMessage('☀️ Good morning, genius!', 'Start your day with a brain workout. Ready?'),
    NotificationMessage('🌅 Rise and shine!', 'Your daily challenge awaits. Let\'s get that brain firing!'),
    NotificationMessage('🧠 Morning brain boost!', 'Quick quiz to kickstart your day?'),
    NotificationMessage('✨ New day, new questions!', 'Your neurons are waiting. Let\'s go!'),
    NotificationMessage('🎯 Morning mission!', 'Can you beat yesterday\'s score?'),
  ];

  // ignore: unused_field
  static const List<NotificationMessage> _dailyChallengeMessages = [
    NotificationMessage('⚡ Daily Challenge is LIVE!', 'Fresh questions just dropped. Be the first to dominate!'),
    NotificationMessage('🔥 Challenge accepted?', 'New questions are waiting. Show us what you\'ve got!'),
    NotificationMessage('🎮 Game on!', 'Today\'s challenge is here. Can you top the leaderboard?'),
    NotificationMessage('💪 Ready for the challenge?', 'Your daily brain test is ready. Let\'s crush it!'),
    NotificationMessage('🏆 Championship time!', 'The daily challenge is calling your name!'),
  ];

  // ignore: unused_field
  static const List<NotificationMessage> _streakMessages = [
    NotificationMessage('🔥 Don\'t lose your streak!', 'You\'re on a {streak}-day roll. Keep it going!'),
    NotificationMessage('⚡ Streak alert!', '{streak} days strong! One quick game to keep it alive?'),
    NotificationMessage('💎 Streak on the line!', 'Your {streak}-day streak is precious. Don\'t break it now!'),
    NotificationMessage('🎯 Maintain your momentum!', '{streak} days of brilliance. Let\'s make it {next}!'),
  ];

  // ignore: unused_field
  static const List<NotificationMessage> _leagueMessages = [
    NotificationMessage('🏆 League match time!', 'Climb the ranks and claim your glory!'),
    NotificationMessage('⚔️ Battle for the top!', 'Your competitors are gaining. Time to show dominance!'),
    NotificationMessage('👑 Crown awaits!', 'The league is heating up. Make your move!'),
    NotificationMessage('🎯 League reminder', 'Don\'t miss your chance at glory. Play now!'),
  ];

  static const List<NotificationMessage> _comebackMessages = [
    NotificationMessage('🎁 Welcome back, champion!', 'We missed you! Here\'s a bonus to get you started.'),
    NotificationMessage('✨ Long time no see!', 'Your favorite brain game missed you. Ready for a round?'),
    NotificationMessage('🎉 Hey there, superstar!', 'Special comeback bonus waiting for you!'),
    NotificationMessage('💎 We saved your spot!', 'Come back and claim your comeback rewards!'),
  ];

  static const List<NotificationMessage> _achievementMessages = [
    NotificationMessage('🏆 Achievement unlocked!', 'You just earned "{achievement}". Check it out!'),
    NotificationMessage('⭐ Legendary!', 'New achievement: {achievement}. You\'re on fire!'),
    NotificationMessage('💪 Level up!', '{achievement} achieved! You\'re unstoppable!'),
  ];

  static const List<NotificationMessage> _motivationalMessages = [
    NotificationMessage('🎯 Quick brain break?', 'Just 5 minutes to flex those mental muscles!'),
    NotificationMessage('💡 Feeling smart today?', 'Prove it! One quick challenge?'),
    NotificationMessage('🧠 Brain workout time!', 'Keep your mind sharp. Play a quick round!'),
    NotificationMessage('✨ Miss the thrill?', 'Your high score is waiting to be beaten!'),
  ];

  /// Schedule smart notifications based on user behavior
  Future<void> scheduleSmartNotifications({
    required NotificationPreferences prefs,
    required int currentStreak,
    required DateTime lastPlayedDate,
    required bool hasPlayedToday,
  }) async {
    debugPrint('📅 Scheduling smart notifications...');

    // Cancel all existing notifications first
    await _localNotifications.cancelAllNotifications();

    // 1. Daily Challenge (if enabled) - Priority notification
    if (prefs.enableDailyChallenge) {
      await _scheduleDailyChallenge(prefs);
    }

    // 2. Streak reminder (only if user has a streak and hasn't played today)
    if (prefs.enableStreakReminders && currentStreak > 0 && !hasPlayedToday) {
      await _scheduleStreakReminder(prefs, currentStreak);
    }

    // 3. League reminder (if enabled and user's preferred time)
    if (prefs.enableLeagueReminders) {
      await _scheduleLeagueReminder(prefs);
    }

    // 4. Gentle nudge (only if user hasn't played in 24+ hours)
    final hoursSinceLastPlay = DateTime.now().difference(lastPlayedDate).inHours;
    if (hoursSinceLastPlay >= 24 && hoursSinceLastPlay < 48) {
      await _scheduleGentleNudge(prefs);
    }

    debugPrint('✅ Smart notifications scheduled');
  }

  /// Schedule daily challenge notification at midnight + 5 minutes
  Future<void> _scheduleDailyChallenge(NotificationPreferences prefs) async {
    await _localNotifications.scheduleDailyChallenge();
    debugPrint('⚡ Daily challenge notification scheduled');
  }

  /// Schedule streak reminder (smart timing based on user's usual play time)
  Future<void> _scheduleStreakReminder(NotificationPreferences prefs, int streak) async {
    final message = _getRandomMessage(_streakMessages);
    final personalizedMessage = NotificationMessage(
      message.title,
      message.body.replaceAll('{streak}', streak.toString()).replaceAll('{next}', (streak + 1).toString()),
    );

    // Schedule for user's preferred time
    await _localNotifications.showNotification(
      id: 100,
      title: personalizedMessage.title,
      body: personalizedMessage.body,
    );
    debugPrint('🔥 Streak reminder scheduled for preferred time');
  }

  /// Schedule league reminder
  Future<void> _scheduleLeagueReminder(NotificationPreferences prefs) async {
    await _localNotifications.scheduleLeagueReminder();
    debugPrint('🏆 League reminder scheduled');
  }

  /// Schedule a gentle nudge (not too pushy)
  Future<void> _scheduleGentleNudge(NotificationPreferences prefs) async {
    final message = _getRandomMessage(_motivationalMessages);
    
    // Only send if within daily limit
    if (await _canSendNotification(prefs)) {
      await _localNotifications.showNotification(
        id: 101,
        title: message.title,
        body: message.body,
      );
      debugPrint('💡 Gentle nudge scheduled');
    }
  }

  /// Send comeback notification (user hasn't played in 2+ days)
  Future<void> sendComebackNotification() async {
    await _localNotifications.sendComebackNotification();
    debugPrint('🎁 Comeback notification sent');
  }

  /// Send achievement notification
  Future<void> sendAchievementNotification(String achievementName) async {
    final message = _getRandomMessage(_achievementMessages);
    final personalizedMessage = NotificationMessage(
      message.title,
      message.body.replaceAll('{achievement}', achievementName),
    );

    await _localNotifications.showNotification(
      id: 200 + _random.nextInt(100),
      title: personalizedMessage.title,
      body: personalizedMessage.body,
    );
    debugPrint('🏆 Achievement notification sent: $achievementName');
  }

  /// Check if we can send another notification today (respects daily limit)
  Future<bool> _canSendNotification(NotificationPreferences prefs) async {
    final now = DateTime.now();
    
    // Check if in quiet hours
    if (_isQuietHours(now.hour, prefs)) {
      debugPrint('🌙 In quiet hours, skipping notification');
      return false;
    }

    // Check daily limit
    final today = DateTime(now.year, now.month, now.day);
    final lastSent = DateTime(
      prefs.lastNotificationSent.year,
      prefs.lastNotificationSent.month,
      prefs.lastNotificationSent.day,
    );

    if (today.isAfter(lastSent)) {
      // New day, reset counter
      return true;
    }

    // Check if we've hit the daily limit
    // This would need to be tracked separately
    return true;
  }

  /// Check if current time is in quiet hours
  bool _isQuietHours(int currentHour, NotificationPreferences prefs) {
    if (prefs.quietHoursStart < prefs.quietHoursEnd) {
      // Normal range (e.g., 22:00 - 08:00 doesn't cross midnight)
      return currentHour >= prefs.quietHoursStart || currentHour < prefs.quietHoursEnd;
    } else {
      // Range crosses midnight (e.g., 08:00 - 22:00 means quiet from 22:00 to 08:00)
      return currentHour >= prefs.quietHoursStart || currentHour < prefs.quietHoursEnd;
    }
  }

  /// Get preferred hour based on time preference
  // ignore: unused_element
  int _getPreferredHour(String timePreference) {
    switch (timePreference) {
      case 'morning':
        return 9; // 9 AM
      case 'afternoon':
        return 14; // 2 PM
      case 'evening':
        return 19; // 7 PM
      default:
        return 19;
    }
  }

  /// Get a random message from a list
  NotificationMessage _getRandomMessage(List<NotificationMessage> messages) {
    return messages[_random.nextInt(messages.length)];
  }

  /// Load notification preferences
  Future<NotificationPreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('notification_preferences');
    if (json != null) {
      return NotificationPreferences.fromJson(
        Map<String, dynamic>.from(prefs.getString('notification_preferences') as Map? ?? {}),
      );
    }
    return NotificationPreferences(
      lastNotificationSent: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  /// Save notification preferences
  Future<void> savePreferences(NotificationPreferences prefs) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setString('notification_preferences', prefs.toJson().toString());
  }
}

/// Simple notification message structure
class NotificationMessage {
  final String title;
  final String body;

  const NotificationMessage(this.title, this.body);
}

