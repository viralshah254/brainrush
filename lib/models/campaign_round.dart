import 'package:flutter/material.dart';

enum RoundDifficulty {
  easy,
  medium,
  hard,
  superHard;

  String get displayName {
    switch (this) {
      case RoundDifficulty.easy:
        return 'Easy';
      case RoundDifficulty.medium:
        return 'Medium';
      case RoundDifficulty.hard:
        return 'Hard';
      case RoundDifficulty.superHard:
        return 'Super Hard';
    }
  }

  Color get color {
    switch (this) {
      case RoundDifficulty.easy:
        return Colors.green;
      case RoundDifficulty.medium:
        return Colors.orange;
      case RoundDifficulty.hard:
        return Colors.red;
      case RoundDifficulty.superHard:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case RoundDifficulty.easy:
        return Icons.emoji_events;
      case RoundDifficulty.medium:
        return Icons.military_tech;
      case RoundDifficulty.hard:
        return Icons.whatshot;
      case RoundDifficulty.superHard:
        return Icons.auto_awesome;
    }
  }

  int get baseScore {
    switch (this) {
      case RoundDifficulty.easy:
        return 100;
      case RoundDifficulty.medium:
        return 150;
      case RoundDifficulty.hard:
        return 200;
      case RoundDifficulty.superHard:
        return 300;
    }
  }

  int get entryCost {
    // All rounds cost 50 coins to enter
    return 50;
  }
}

class CampaignRound {
  final int roundNumber;
  final String title;
  final String description;
  final RoundDifficulty difficulty;
  final int questionCount;
  final String category;
  final int coinsReward;
  final int starsRequired; // Stars needed to unlock
  final bool isLocked;
  final bool isCompleted;
  final int? bestScore;
  final int? starsEarned; // 1-3 stars based on performance

  CampaignRound({
    required this.roundNumber,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.questionCount,
    required this.category,
    required this.coinsReward,
    this.starsRequired = 0,
    this.isLocked = false,
    this.isCompleted = false,
    this.bestScore,
    this.starsEarned,
  });

  CampaignRound copyWith({
    int? roundNumber,
    String? title,
    String? description,
    RoundDifficulty? difficulty,
    int? questionCount,
    String? category,
    int? coinsReward,
    int? starsRequired,
    bool? isLocked,
    bool? isCompleted,
    int? bestScore,
    int? starsEarned,
  }) {
    return CampaignRound(
      roundNumber: roundNumber ?? this.roundNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      questionCount: questionCount ?? this.questionCount,
      category: category ?? this.category,
      coinsReward: coinsReward ?? this.coinsReward,
      starsRequired: starsRequired ?? this.starsRequired,
      isLocked: isLocked ?? this.isLocked,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
      starsEarned: starsEarned ?? this.starsEarned,
    );
  }

  factory CampaignRound.fromJson(Map<String, dynamic> json) {
    return CampaignRound(
      roundNumber: json['roundNumber'],
      title: json['title'],
      description: json['description'],
      difficulty: RoundDifficulty.values[json['difficulty']],
      questionCount: json['questionCount'],
      category: json['category'],
      coinsReward: json['coinsReward'],
      starsRequired: json['starsRequired'] ?? 0,
      isLocked: json['isLocked'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      bestScore: json['bestScore'],
      starsEarned: json['starsEarned'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'title': title,
      'description': description,
      'difficulty': difficulty.index,
      'questionCount': questionCount,
      'category': category,
      'coinsReward': coinsReward,
      'starsRequired': starsRequired,
      'isLocked': isLocked,
      'isCompleted': isCompleted,
      'bestScore': bestScore,
      'starsEarned': starsEarned,
    };
  }

  // Calculate stars based on score percentage
  static int calculateStars(int score, int maxScore) {
    final percentage = (score / maxScore * 100);
    if (percentage >= 90) return 3; // ⭐⭐⭐
    if (percentage >= 70) return 2; // ⭐⭐
    if (percentage >= 50) return 1; // ⭐
    return 0;
  }
}

