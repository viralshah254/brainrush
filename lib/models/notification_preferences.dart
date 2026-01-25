/// Notification preferences and settings
class NotificationPreferences {
  final bool enableMorningReminder;
  final bool enableDailyChallenge;
  final bool enableLeagueReminders;
  final bool enableStreakReminders;
  final bool enableAchievementNotifications;
  final bool enableFriendInvites;
  final String preferredTime; // "morning", "afternoon", "evening"
  final int quietHoursStart; // 22 (10 PM)
  final int quietHoursEnd; // 8 (8 AM)
  final int maxNotificationsPerDay;
  final DateTime lastNotificationSent;

  const NotificationPreferences({
    this.enableMorningReminder = true,
    this.enableDailyChallenge = true,
    this.enableLeagueReminders = true,
    this.enableStreakReminders = true,
    this.enableAchievementNotifications = true,
    this.enableFriendInvites = true,
    this.preferredTime = 'evening',
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.maxNotificationsPerDay = 3,
    required this.lastNotificationSent,
  });

  NotificationPreferences copyWith({
    bool? enableMorningReminder,
    bool? enableDailyChallenge,
    bool? enableLeagueReminders,
    bool? enableStreakReminders,
    bool? enableAchievementNotifications,
    bool? enableFriendInvites,
    String? preferredTime,
    int? quietHoursStart,
    int? quietHoursEnd,
    int? maxNotificationsPerDay,
    DateTime? lastNotificationSent,
  }) {
    return NotificationPreferences(
      enableMorningReminder: enableMorningReminder ?? this.enableMorningReminder,
      enableDailyChallenge: enableDailyChallenge ?? this.enableDailyChallenge,
      enableLeagueReminders: enableLeagueReminders ?? this.enableLeagueReminders,
      enableStreakReminders: enableStreakReminders ?? this.enableStreakReminders,
      enableAchievementNotifications: enableAchievementNotifications ?? this.enableAchievementNotifications,
      enableFriendInvites: enableFriendInvites ?? this.enableFriendInvites,
      preferredTime: preferredTime ?? this.preferredTime,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      maxNotificationsPerDay: maxNotificationsPerDay ?? this.maxNotificationsPerDay,
      lastNotificationSent: lastNotificationSent ?? this.lastNotificationSent,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enableMorningReminder: json['enableMorningReminder'] ?? true,
      enableDailyChallenge: json['enableDailyChallenge'] ?? true,
      enableLeagueReminders: json['enableLeagueReminders'] ?? true,
      enableStreakReminders: json['enableStreakReminders'] ?? true,
      enableAchievementNotifications: json['enableAchievementNotifications'] ?? true,
      enableFriendInvites: json['enableFriendInvites'] ?? true,
      preferredTime: json['preferredTime'] ?? 'evening',
      quietHoursStart: json['quietHoursStart'] ?? 22,
      quietHoursEnd: json['quietHoursEnd'] ?? 8,
      maxNotificationsPerDay: json['maxNotificationsPerDay'] ?? 3,
      lastNotificationSent: json['lastNotificationSent'] != null
          ? DateTime.parse(json['lastNotificationSent'])
          : DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableMorningReminder': enableMorningReminder,
      'enableDailyChallenge': enableDailyChallenge,
      'enableLeagueReminders': enableLeagueReminders,
      'enableStreakReminders': enableStreakReminders,
      'enableAchievementNotifications': enableAchievementNotifications,
      'enableFriendInvites': enableFriendInvites,
      'preferredTime': preferredTime,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'maxNotificationsPerDay': maxNotificationsPerDay,
      'lastNotificationSent': lastNotificationSent.toIso8601String(),
    };
  }
}










