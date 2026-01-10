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
  
  // Education Mode fields
  final int? age;
  final String? country;
  final String? schoolSystem; // SchoolSystem enum code
  final String? gradeLevel; // GradeLevel code (e.g., "GRADE_6")
  final String? challengeGradeLevel; // Override for harder challenges
  final String? examFocus; // ExamFocus enum code (NONE, SAT, GMAT)
  final bool educationModeEnabled;
  
  // Subscription entitlements
  final bool hasSatSubscription;
  final bool hasGmatSubscription;
  final bool hasAllAccessSubscription;

  const User({
    required this.id,
    required this.username,
    this.coins = 100,
    this.streakCount = 0,
    this.stats = const UserStats(),
    this.isGuest = true,
    DateTime? lastDailyChallenge,
    // Education fields
    this.age,
    this.country = 'Kenya',
    this.schoolSystem,
    this.gradeLevel,
    this.challengeGradeLevel,
    this.examFocus = 'NONE',
    this.educationModeEnabled = false,
    // Subscriptions
    this.hasSatSubscription = false,
    this.hasGmatSubscription = false,
    this.hasAllAccessSubscription = false,
  }) : lastDailyChallenge = lastDailyChallenge ?? const Duration(days: -1) as DateTime;

  User copyWith({
    String? id,
    String? username,
    int? coins,
    int? streakCount,
    UserStats? stats,
    bool? isGuest,
    DateTime? lastDailyChallenge,
    int? age,
    String? country,
    String? schoolSystem,
    String? gradeLevel,
    String? challengeGradeLevel,
    String? examFocus,
    bool? educationModeEnabled,
    bool? hasSatSubscription,
    bool? hasGmatSubscription,
    bool? hasAllAccessSubscription,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      coins: coins ?? this.coins,
      streakCount: streakCount ?? this.streakCount,
      stats: stats ?? this.stats,
      isGuest: isGuest ?? this.isGuest,
      lastDailyChallenge: lastDailyChallenge ?? this.lastDailyChallenge,
      age: age ?? this.age,
      country: country ?? this.country,
      schoolSystem: schoolSystem ?? this.schoolSystem,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      challengeGradeLevel: challengeGradeLevel ?? this.challengeGradeLevel,
      examFocus: examFocus ?? this.examFocus,
      educationModeEnabled: educationModeEnabled ?? this.educationModeEnabled,
      hasSatSubscription: hasSatSubscription ?? this.hasSatSubscription,
      hasGmatSubscription: hasGmatSubscription ?? this.hasGmatSubscription,
      hasAllAccessSubscription: hasAllAccessSubscription ?? this.hasAllAccessSubscription,
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
      'age': age,
      'country': country,
      'schoolSystem': schoolSystem,
      'gradeLevel': gradeLevel,
      'challengeGradeLevel': challengeGradeLevel,
      'examFocus': examFocus,
      'educationModeEnabled': educationModeEnabled,
      'hasSatSubscription': hasSatSubscription,
      'hasGmatSubscription': hasGmatSubscription,
      'hasAllAccessSubscription': hasAllAccessSubscription,
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
      age: json['age'] as int?,
      country: json['country'] as String? ?? 'Kenya',
      schoolSystem: json['schoolSystem'] as String?,
      gradeLevel: json['gradeLevel'] as String?,
      challengeGradeLevel: json['challengeGradeLevel'] as String?,
      examFocus: json['examFocus'] as String? ?? 'NONE',
      educationModeEnabled: json['educationModeEnabled'] as bool? ?? false,
      hasSatSubscription: json['hasSatSubscription'] as bool? ?? false,
      hasGmatSubscription: json['hasGmatSubscription'] as bool? ?? false,
      hasAllAccessSubscription: json['hasAllAccessSubscription'] as bool? ?? false,
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

