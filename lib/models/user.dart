class UserStats {
  final int questionsAnswered;
  final int correctAnswers;
  final int totalScore;
  final double accuracy;

  const UserStats({
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.totalScore = 0,
    this.accuracy = 0.0,
  });

  UserStats copyWith({
    int? questionsAnswered,
    int? correctAnswers,
    int? totalScore,
    double? accuracy,
  }) {
    return UserStats(
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalScore: totalScore ?? this.totalScore,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionsAnswered': questionsAnswered,
      'correctAnswers': correctAnswers,
      'totalScore': totalScore,
      'accuracy': accuracy,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      questionsAnswered: json['questionsAnswered'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      accuracy: json['accuracy'] as double? ?? 0.0,
    );
  }
}

class User {
  final String id;
  final String username;
  final int coins;
  final int streakCount;
  final UserStats stats;
  final bool isGuest;
  final DateTime lastDailyChallenge;

  const User({
    required this.id,
    required this.username,
    this.coins = 100,
    this.streakCount = 0,
    this.stats = const UserStats(),
    this.isGuest = true,
    DateTime? lastDailyChallenge,
  }) : lastDailyChallenge = lastDailyChallenge ?? const Duration(days: -1) as DateTime;

  User copyWith({
    String? id,
    String? username,
    int? coins,
    int? streakCount,
    UserStats? stats,
    bool? isGuest,
    DateTime? lastDailyChallenge,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      coins: coins ?? this.coins,
      streakCount: streakCount ?? this.streakCount,
      stats: stats ?? this.stats,
      isGuest: isGuest ?? this.isGuest,
      lastDailyChallenge: lastDailyChallenge ?? this.lastDailyChallenge,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'coins': coins,
      'streakCount': streakCount,
      'stats': stats.toJson(),
      'isGuest': isGuest,
      'lastDailyChallenge': lastDailyChallenge.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      coins: json['coins'] as int? ?? 100,
      streakCount: json['streakCount'] as int? ?? 0,
      stats: json['stats'] != null
          ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const UserStats(),
      isGuest: json['isGuest'] as bool? ?? true,
      lastDailyChallenge: json['lastDailyChallenge'] != null
          ? DateTime.parse(json['lastDailyChallenge'] as String)
          : DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  factory User.guest() {
    return User(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      username: 'Guest',
      isGuest: true,
      lastDailyChallenge: DateTime.now().subtract(const Duration(days: 1)),
    );
  }
}

