import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int targetValue;
  final int coinReward;
  final int xpReward;
  int currentProgress;
  bool isCompleted;

  WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.targetValue,
    this.coinReward = 0,
    this.xpReward = 0,
    this.currentProgress = 0,
    this.isCompleted = false,
  });

  WeeklyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    int? targetValue,
    int? coinReward,
    int? xpReward,
    int? currentProgress,
    bool? isCompleted,
  }) {
    return WeeklyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      targetValue: targetValue ?? this.targetValue,
      coinReward: coinReward ?? this.coinReward,
      xpReward: xpReward ?? this.xpReward,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  double get progressPercentage {
    return (currentProgress / targetValue * 100).clamp(0.0, 100.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'targetValue': targetValue,
      'coinReward': coinReward,
      'xpReward': xpReward,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
    };
  }

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) {
    return WeeklyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      targetValue: json['targetValue'] as int,
      coinReward: json['coinReward'] as int? ?? 0,
      xpReward: json['xpReward'] as int? ?? 0,
      currentProgress: json['currentProgress'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class WeeklyChallengeService extends ChangeNotifier {
  static final WeeklyChallengeService _instance = WeeklyChallengeService._internal();
  factory WeeklyChallengeService() => _instance;
  WeeklyChallengeService._internal();

  List<WeeklyChallenge> _challenges = [];
  DateTime? _weekStartDate;
  bool _initialized = false;

  List<WeeklyChallenge> get challenges => _challenges;
  DateTime? get weekStartDate => _weekStartDate;
  
  int get completedCount => _challenges.where((c) => c.isCompleted).length;
  int get totalCount => _challenges.length;
  bool get allCompleted => completedCount == totalCount && totalCount > 0;

  Future<void> initialize() async {
    if (_initialized) return;
    
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    
    // Load saved week start
    final prefs = await SharedPreferences.getInstance();
    final savedWeekStartStr = prefs.getString('weekly_challenge_week_start');
    
    if (savedWeekStartStr != null) {
      final savedWeekStart = DateTime.parse(savedWeekStartStr);
      if (savedWeekStart.isBefore(weekStart)) {
        // New week - generate new challenges
        _generateNewChallenges();
        _weekStartDate = weekStart;
        await prefs.setString('weekly_challenge_week_start', weekStart.toIso8601String());
      } else {
        // Same week - load existing challenges
        await _loadChallenges();
        _weekStartDate = savedWeekStart;
      }
    } else {
      // First time - generate challenges
      _generateNewChallenges();
      _weekStartDate = weekStart;
      await prefs.setString('weekly_challenge_week_start', weekStart.toIso8601String());
    }
    
    await _saveChallenges();
    _initialized = true;
    notifyListeners();
  }

  DateTime _getWeekStart(DateTime date) {
    // Week starts on Monday
    final weekday = date.weekday;
    final daysFromMonday = weekday == 7 ? 0 : weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  void _generateNewChallenges() {
    final random = Random();
    final challengeTemplates = [
      {
        'id': 'play_20_games',
        'title': 'Game Marathon',
        'description': 'Play 20 games this week',
        'emoji': '🎮',
        'targetValue': 20,
        'coinReward': 300,
        'xpReward': 100,
      },
      {
        'id': 'correct_100_answers',
        'title': 'Century Club',
        'description': 'Answer 100 questions correctly',
        'emoji': '💯',
        'targetValue': 100,
        'coinReward': 400,
        'xpReward': 150,
      },
      {
        'id': 'perfect_5_games',
        'title': 'Perfect Week',
        'description': 'Get 5 perfect games (100% accuracy)',
        'emoji': '⭐',
        'targetValue': 5,
        'coinReward': 500,
        'xpReward': 200,
      },
      {
        'id': 'campaign_10_rounds',
        'title': 'Campaign Crusher',
        'description': 'Complete 10 campaign rounds',
        'emoji': '🏆',
        'targetValue': 10,
        'coinReward': 350,
        'xpReward': 120,
      },
      {
        'id': 'earn_2000_coins',
        'title': 'Coin Collector',
        'description': 'Earn 2,000 coins this week',
        'emoji': '💰',
        'targetValue': 2000,
        'coinReward': 600,
        'xpReward': 250,
      },
    ];

    // Select 3 random challenges
    final selected = challengeTemplates.toList()..shuffle(random);
    _challenges = selected.take(3).map((t) => WeeklyChallenge(
      id: t['id'] as String,
      title: t['title'] as String,
      description: t['description'] as String,
      emoji: t['emoji'] as String,
      targetValue: t['targetValue'] as int,
      coinReward: t['coinReward'] as int,
      xpReward: t['xpReward'] as int,
    )).toList();
  }

  Future<void> _loadChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = prefs.getString('weekly_challenges');
      
      if (challengesJson != null) {
        // Parse challenges (simplified - in production use proper JSON)
        // For now, regenerate if loading fails
        _generateNewChallenges();
      } else {
        _generateNewChallenges();
      }
    } catch (e) {
      debugPrint('Error loading weekly challenges: $e');
      _generateNewChallenges();
    }
  }

  Future<void> _saveChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = _challenges.map((c) => c.toJson()).toList();
      await prefs.setString('weekly_challenges', challengesJson.toString());
    } catch (e) {
      debugPrint('Error saving weekly challenges: $e');
    }
  }

  /// Update progress for a challenge
  /// Returns the challenge if it was just completed, null otherwise
  Future<WeeklyChallenge?> updateProgress(String challengeId, int increment) async {
    final index = _challenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) return null;

    final challenge = _challenges[index];
    if (challenge.isCompleted) return null;

    final newProgress = (challenge.currentProgress + increment).clamp(0, challenge.targetValue);
    final wasCompleted = challenge.isCompleted;
    final isNowCompleted = newProgress >= challenge.targetValue;

    _challenges[index] = challenge.copyWith(
      currentProgress: newProgress,
      isCompleted: isNowCompleted,
    );

    await _saveChallenges();
    notifyListeners();

    if (!wasCompleted && isNowCompleted) {
      return _challenges[index];
    }

    return null;
  }

  /// Get total rewards for all completed challenges
  Map<String, int> getTotalRewards() {
    int totalCoins = 0;
    int totalXp = 0;

    for (final challenge in _challenges) {
      if (challenge.isCompleted) {
        totalCoins += challenge.coinReward;
        totalXp += challenge.xpReward;
      }
    }

    return {'coins': totalCoins, 'xp': totalXp};
  }
}





