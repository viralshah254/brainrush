import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../models/leaderboard_entry.dart';

/// Social Sharing Service - Share achievements, scores, streaks, etc.
class SocialSharingService {
  static final SocialSharingService _instance = SocialSharingService._internal();
  factory SocialSharingService() => _instance;
  SocialSharingService._internal();

  /// Share an achievement
  Future<void> shareAchievement({
    required Achievement achievement,
    String? username,
  }) async {
    try {
      final emoji = achievement.emoji;
      final name = achievement.name;
      final rarity = achievement.rarity.toString().split('.').last;
      
      final message = username != null
          ? '$emoji I just unlocked the "$name" achievement in MindRush! 🎮\n\n'
            'Rarity: ${rarity.toUpperCase()}\n'
            'Can you beat my progress? Download MindRush and challenge me! 🚀'
          : '$emoji Just unlocked the "$name" achievement in MindRush! 🎮\n\n'
            'Rarity: ${rarity.toUpperCase()}\n'
            'Download MindRush and start your quiz journey! 🚀';

      await Share.share(
        message,
        subject: 'MindRush Achievement Unlocked!',
      );
      
      debugPrint('✅ Achievement shared');
    } catch (e) {
      debugPrint('❌ Error sharing achievement: $e');
    }
  }

  /// Share a game score
  Future<void> shareScore({
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required double accuracy,
    String? gameMode,
    String? username,
    bool isEducationMode = false,
  }) async {
    try {
      final modeText = isEducationMode 
          ? 'Education Mode'
          : (gameMode ?? 'MindRush');
      
      final accuracyPercent = (accuracy * 100).toStringAsFixed(0);
      
      final message = username != null
          ? '🎯 I just scored $score points in $modeText! 🎮\n\n'
            'Got $correctAnswers/$totalQuestions correct ($accuracyPercent% accuracy)\n\n'
            'Can you beat my score? Download MindRush and challenge me! 🚀'
          : '🎯 Just scored $score points in $modeText! 🎮\n\n'
            'Got $correctAnswers/$totalQuestions correct ($accuracyPercent% accuracy)\n\n'
            'Download MindRush and test your knowledge! 🚀';

      await Share.share(
        message,
        subject: 'MindRush Score Share',
      );
      
      debugPrint('✅ Score shared');
    } catch (e) {
      debugPrint('❌ Error sharing score: $e');
    }
  }

  /// Share a streak
  Future<void> shareStreak({
    required int streakDays,
    String? username,
  }) async {
    try {
      final message = username != null
          ? '🔥 I\'ve been playing MindRush for $streakDays days straight! 🔥\n\n'
            'Can you beat my streak? Download MindRush and challenge me! 🚀'
          : '🔥 $streakDays day streak in MindRush! 🔥\n\n'
            'Download MindRush and start your own streak! 🚀';

      await Share.share(
        message,
        subject: 'MindRush Streak',
      );
      
      debugPrint('✅ Streak shared');
    } catch (e) {
      debugPrint('❌ Error sharing streak: $e');
    }
  }

  /// Share level up
  Future<void> shareLevelUp({
    required int newLevel,
    String? username,
  }) async {
    try {
      final message = username != null
          ? '⭐ I just reached Level $newLevel in MindRush! ⭐\n\n'
            'Leveling up feels amazing! Can you catch up? Download MindRush! 🚀'
          : '⭐ Just reached Level $newLevel in MindRush! ⭐\n\n'
            'Download MindRush and start leveling up! 🚀';

      await Share.share(
        message,
        subject: 'MindRush Level Up!',
      );
      
      debugPrint('✅ Level up shared');
    } catch (e) {
      debugPrint('❌ Error sharing level up: $e');
    }
  }

  /// Share a collectible card
  Future<void> shareCard({
    required String cardName,
    required String cardEmoji,
    required String rarity,
    String? username,
  }) async {
    try {
      final message = username != null
          ? '$cardEmoji I just collected the "$cardName" card in MindRush! 🎴\n\n'
            'Rarity: ${rarity.toUpperCase()}\n'
            'Can you collect them all? Download MindRush! 🚀'
          : '$cardEmoji Just collected the "$cardName" card in MindRush! 🎴\n\n'
            'Rarity: ${rarity.toUpperCase()}\n'
            'Download MindRush and start collecting! 🚀';

      await Share.share(
        message,
        subject: 'MindRush Card Collection',
      );
      
      debugPrint('✅ Card shared');
    } catch (e) {
      debugPrint('❌ Error sharing card: $e');
    }
  }

  /// Share leaderboard rank
  Future<void> shareRank({
    required int rank,
    required LeaderboardType type,
    String? username,
    bool isEducationMode = false,
  }) async {
    try {
      final typeText = type == LeaderboardType.weekly
          ? 'Weekly'
          : type == LeaderboardType.monthly
              ? 'Monthly'
              : 'Global';
      
      final modeText = isEducationMode ? 'Education Mode ' : '';
      
      final message = username != null
          ? '🏆 I\'m ranked #$rank in the $modeText$typeText Leaderboard! 🏆\n\n'
            'Can you beat my rank? Download MindRush and challenge me! 🚀'
          : '🏆 Ranked #$rank in the $modeText$typeText Leaderboard! 🏆\n\n'
            'Download MindRush and compete for the top spot! 🚀';

      await Share.share(
        message,
        subject: 'MindRush Leaderboard Rank',
      );
      
      debugPrint('✅ Rank shared');
    } catch (e) {
      debugPrint('❌ Error sharing rank: $e');
    }
  }

  /// Share app invite
  Future<void> shareAppInvite({
    String? username,
  }) async {
    try {
      // TODO: Replace with actual app store URLs
      const appStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID';
      const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.dvtechventures.mindrush';

      final message = username != null
          ? '🧠 Join me on MindRush - The ultimate quiz game! 🧠\n\n'
            'Challenge yourself with thousands of questions, compete in leaderboards, '
            'and collect amazing cards!\n\n'
            'Download now:\n'
            'iOS: $appStoreUrl\n'
            'Android: $playStoreUrl\n\n'
            'Let\'s see who\'s smarter! 🚀'
          : '🧠 MindRush - The ultimate quiz game! 🧠\n\n'
            'Challenge yourself with thousands of questions, compete in leaderboards, '
            'and collect amazing cards!\n\n'
            'Download now:\n'
            'iOS: $appStoreUrl\n'
            'Android: $playStoreUrl\n\n'
            'Start your quiz journey today! 🚀';

      await Share.share(
        message,
        subject: 'Join me on MindRush!',
      );
      
      debugPrint('✅ App invite shared');
    } catch (e) {
      debugPrint('❌ Error sharing app invite: $e');
    }
  }
}

