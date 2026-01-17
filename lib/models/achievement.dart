import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum AchievementCategory {
  gameplay,
  milestones,
  streaks,
  accuracy,
  coins,
  campaign,
  social,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int targetValue;
  final int coinReward;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.rarity,
    required this.targetValue,
    this.coinReward = 0,
    this.xpReward = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'category': category.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'targetValue': targetValue,
      'coinReward': coinReward,
      'xpReward': xpReward,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      category: AchievementCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => AchievementCategory.gameplay,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.toString().split('.').last == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      targetValue: json['targetValue'] as int,
      coinReward: json['coinReward'] as int? ?? 0,
      xpReward: json['xpReward'] as int? ?? 0,
    );
  }
}

class UserAchievement {
  final String achievementId;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const UserAchievement({
    required this.achievementId,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  UserAchievement copyWith({
    String? achievementId,
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return UserAchievement(
      achievementId: achievementId ?? this.achievementId,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  double get progressPercentage {
    // We'll get the target from AchievementService
    return currentProgress.clamp(0, 100).toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'currentProgress': currentProgress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      achievementId: json['achievementId'] as String,
      currentProgress: json['currentProgress'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }
}

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  static final List<Achievement> _allAchievements = [
    // Gameplay Achievements
    Achievement(
      id: 'first_game',
      name: 'First Steps',
      description: 'Complete your first game',
      emoji: '🎮',
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.common,
      targetValue: 1,
      coinReward: 50,
      xpReward: 10,
    ),
    Achievement(
      id: 'play_10_games',
      name: 'Getting Started',
      description: 'Play 10 games',
      emoji: '🏁',
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.common,
      targetValue: 10,
      coinReward: 100,
      xpReward: 25,
    ),
    Achievement(
      id: 'play_50_games',
      name: 'Regular Player',
      description: 'Play 50 games',
      emoji: '🎯',
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.rare,
      targetValue: 50,
      coinReward: 250,
      xpReward: 50,
    ),
    Achievement(
      id: 'play_100_games',
      name: 'Dedicated Gamer',
      description: 'Play 100 games',
      emoji: '💪',
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.epic,
      targetValue: 100,
      coinReward: 500,
      xpReward: 100,
    ),
    Achievement(
      id: 'play_500_games',
      name: 'Quiz Master',
      description: 'Play 500 games',
      emoji: '👑',
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.legendary,
      targetValue: 500,
      coinReward: 2000,
      xpReward: 500,
    ),

    // Question Milestones
    Achievement(
      id: 'answer_100_questions',
      name: 'Century Club',
      description: 'Answer 100 questions correctly',
      emoji: '💯',
      category: AchievementCategory.milestones,
      rarity: AchievementRarity.common,
      targetValue: 100,
      coinReward: 150,
      xpReward: 30,
    ),
    Achievement(
      id: 'answer_500_questions',
      name: 'Half Grand',
      description: 'Answer 500 questions correctly',
      emoji: '🎖️',
      category: AchievementCategory.milestones,
      rarity: AchievementRarity.rare,
      targetValue: 500,
      coinReward: 500,
      xpReward: 100,
    ),
    Achievement(
      id: 'answer_1000_questions',
      name: 'Grand Master',
      description: 'Answer 1,000 questions correctly',
      emoji: '🏆',
      category: AchievementCategory.milestones,
      rarity: AchievementRarity.epic,
      targetValue: 1000,
      coinReward: 1500,
      xpReward: 250,
    ),
    Achievement(
      id: 'answer_5000_questions',
      name: 'Knowledge Seeker',
      description: 'Answer 5,000 questions correctly',
      emoji: '🌟',
      category: AchievementCategory.milestones,
      rarity: AchievementRarity.legendary,
      targetValue: 5000,
      coinReward: 5000,
      xpReward: 1000,
    ),

    // Streak Achievements
    Achievement(
      id: 'streak_3',
      name: 'On Fire',
      description: 'Maintain a 3-day streak',
      emoji: '🔥',
      category: AchievementCategory.streaks,
      rarity: AchievementRarity.common,
      targetValue: 3,
      coinReward: 100,
      xpReward: 20,
    ),
    Achievement(
      id: 'streak_7',
      name: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      emoji: '⚡',
      category: AchievementCategory.streaks,
      rarity: AchievementRarity.rare,
      targetValue: 7,
      coinReward: 300,
      xpReward: 50,
    ),
    Achievement(
      id: 'streak_14',
      name: 'Fortnight Fighter',
      description: 'Maintain a 14-day streak',
      emoji: '💎',
      category: AchievementCategory.streaks,
      rarity: AchievementRarity.epic,
      targetValue: 14,
      coinReward: 750,
      xpReward: 150,
    ),
    Achievement(
      id: 'streak_30',
      name: 'Monthly Master',
      description: 'Maintain a 30-day streak',
      emoji: '👑',
      category: AchievementCategory.streaks,
      rarity: AchievementRarity.legendary,
      targetValue: 30,
      coinReward: 2000,
      xpReward: 500,
    ),

    // Accuracy Achievements
    Achievement(
      id: 'perfect_game',
      name: 'Perfect Score',
      description: 'Get 100% accuracy in a game',
      emoji: '✨',
      category: AchievementCategory.accuracy,
      rarity: AchievementRarity.rare,
      targetValue: 1,
      coinReward: 200,
      xpReward: 50,
    ),
    Achievement(
      id: 'perfect_10',
      name: 'Perfect Ten',
      description: 'Get 10 perfect games',
      emoji: '⭐',
      category: AchievementCategory.accuracy,
      rarity: AchievementRarity.epic,
      targetValue: 10,
      coinReward: 1000,
      xpReward: 200,
    ),
    Achievement(
      id: 'accuracy_90',
      name: 'Sharp Shooter',
      description: 'Maintain 90%+ accuracy over 50 games',
      emoji: '🎯',
      category: AchievementCategory.accuracy,
      rarity: AchievementRarity.epic,
      targetValue: 1,
      coinReward: 750,
      xpReward: 150,
    ),

    // Coin Achievements
    Achievement(
      id: 'earn_1000_coins',
      name: 'Coin Collector',
      description: 'Earn 1,000 coins total',
      emoji: '🪙',
      category: AchievementCategory.coins,
      rarity: AchievementRarity.common,
      targetValue: 1000,
      coinReward: 100,
      xpReward: 25,
    ),
    Achievement(
      id: 'earn_10000_coins',
      name: 'Coin Millionaire',
      description: 'Earn 10,000 coins total',
      emoji: '💰',
      category: AchievementCategory.coins,
      rarity: AchievementRarity.epic,
      targetValue: 10000,
      coinReward: 2000,
      xpReward: 400,
    ),

    // Campaign Achievements
    Achievement(
      id: 'campaign_round_10',
      name: 'Campaign Starter',
      description: 'Complete 10 campaign rounds',
      emoji: '🎪',
      category: AchievementCategory.campaign,
      rarity: AchievementRarity.common,
      targetValue: 10,
      coinReward: 150,
      xpReward: 30,
    ),
    Achievement(
      id: 'campaign_round_50',
      name: 'Campaign Veteran',
      description: 'Complete 50 campaign rounds',
      emoji: '🎖️',
      category: AchievementCategory.campaign,
      rarity: AchievementRarity.rare,
      targetValue: 50,
      coinReward: 500,
      xpReward: 100,
    ),
    Achievement(
      id: 'campaign_round_100',
      name: 'Campaign Champion',
      description: 'Complete 100 campaign rounds',
      emoji: '🏅',
      category: AchievementCategory.campaign,
      rarity: AchievementRarity.epic,
      targetValue: 100,
      coinReward: 1500,
      xpReward: 300,
    ),
    Achievement(
      id: 'campaign_3_stars',
      name: 'Three Star Master',
      description: 'Get 3 stars in 20 campaign rounds',
      emoji: '⭐',
      category: AchievementCategory.campaign,
      rarity: AchievementRarity.epic,
      targetValue: 20,
      coinReward: 1000,
      xpReward: 200,
    ),
  ];

  Map<String, UserAchievement> _userAchievements = {};

  List<Achievement> get allAchievements => _allAchievements;

  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _allAchievements.where((a) => a.category == category).toList();
  }

  UserAchievement? getUserAchievement(String achievementId) {
    return _userAchievements[achievementId];
  }

  List<UserAchievement> getAllUserAchievements() {
    return _userAchievements.values.toList();
  }

  int get unlockedCount {
    return _userAchievements.values.where((ua) => ua.isUnlocked).length;
  }

  int get totalCount => _allAchievements.length;

  double get completionPercentage {
    if (_allAchievements.isEmpty) return 0.0;
    return (unlockedCount / totalCount) * 100;
  }

  Future<void> loadUserAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString('user_achievements');
      
      if (achievementsJson != null) {
        final Map<String, dynamic> data = json.decode(achievementsJson);
        _userAchievements.clear();
        data.forEach((id, json) {
          _userAchievements[id] = UserAchievement.fromJson(json);
        });
      } else {
        // Initialize all achievements with 0 progress
        for (final achievement in _allAchievements) {
          _userAchievements[achievement.id] = UserAchievement(
            achievementId: achievement.id,
            currentProgress: 0,
            isUnlocked: false,
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading achievements: $e');
    }
  }

  Future<void> saveUserAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {};
      _userAchievements.forEach((id, ua) {
        data[id] = ua.toJson();
      });
      await prefs.setString('user_achievements', json.encode(data));
    } catch (e) {
      // ignore: avoid_print
      print('Error saving achievements: $e');
    }
  }

  /// Update progress for an achievement
  /// Returns the achievement if it was just unlocked, null otherwise
  Future<Achievement?> updateProgress(
    String achievementId,
    int increment, {
    int? currentValue,
  }) async {
    final achievement = _allAchievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => _allAchievements.first,
    );

    final userAchievement = _userAchievements[achievementId] ??
        UserAchievement(achievementId: achievementId);

    final newProgress = currentValue ??
        (userAchievement.currentProgress + increment).clamp(0, achievement.targetValue);

    final wasUnlocked = userAchievement.isUnlocked;
    final isNowUnlocked = newProgress >= achievement.targetValue;

    _userAchievements[achievementId] = userAchievement.copyWith(
      currentProgress: newProgress,
      isUnlocked: isNowUnlocked,
      unlockedAt: !wasUnlocked && isNowUnlocked ? DateTime.now() : userAchievement.unlockedAt,
    );

    await saveUserAchievements();

    // Return achievement if just unlocked
    if (!wasUnlocked && isNowUnlocked) {
      return achievement;
    }

    return null;
  }

  /// Get progress percentage for an achievement
  double getProgressPercentage(String achievementId) {
    final achievement = _allAchievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => _allAchievements.first,
    );
    final userAchievement = _userAchievements[achievementId];
    if (userAchievement == null) return 0.0;
    return (userAchievement.currentProgress / achievement.targetValue * 100).clamp(0.0, 100.0);
  }
}

