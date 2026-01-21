import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum LeaderboardType {
  global,
  weekly,
  monthly,
  category,
  friends,
  education, // Education mode leaderboard
}

enum LeaderboardCategory {
  all,
  math,
  science,
  history,
  geography,
  literature,
  mixed,
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final int score;
  final int rank;
  final int level;
  final double accuracy;
  final int gamesPlayed;
  final bool isCurrentUser;
  final String? avatarUrl;
  final bool isEducationMode;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.score,
    required this.rank,
    this.level = 1,
    this.accuracy = 0.0,
    this.gamesPlayed = 0,
    this.isCurrentUser = false,
    this.avatarUrl,
    this.isEducationMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'score': score,
      'rank': rank,
      'level': level,
      'accuracy': accuracy,
      'gamesPlayed': gamesPlayed,
      'isCurrentUser': isCurrentUser,
      'avatarUrl': avatarUrl,
      'isEducationMode': isEducationMode,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      score: json['score'] as int,
      rank: json['rank'] as int,
      level: json['level'] as int? ?? 1,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
      isEducationMode: json['isEducationMode'] as bool? ?? false,
    );
  }
}





