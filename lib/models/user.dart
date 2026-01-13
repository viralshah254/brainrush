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
  
  // Retention fields
  final int consecutiveLoginDays;
  final DateTime lastLoginDate;
  final DateTime? lastFreeCoinsClaimDate;
  final bool hasClaimedDailyLoginReward;
  final DateTime? lastLuckySpinDate;
  
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
    // Retention fields
    this.consecutiveLoginDays = 1,
    DateTime? lastLoginDate,
    this.lastFreeCoinsClaimDate,
    this.hasClaimedDailyLoginReward = false,
    this.lastLuckySpinDate,
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
  }) : lastDailyChallenge = lastDailyChallenge ?? const Duration(days: -1) as DateTime,
       lastLoginDate = lastLoginDate ?? const Duration(days: 0) as DateTime;

  User copyWith({
    String? id,
    String? username,
    int? coins,
    int? streakCount,
    UserStats? stats,
    bool? isGuest,
    DateTime? lastDailyChallenge,
    int? consecutiveLoginDays,
    DateTime? lastLoginDate,
    DateTime? lastFreeCoinsClaimDate,
    bool? hasClaimedDailyLoginReward,
    DateTime? lastLuckySpinDate,
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
      consecutiveLoginDays: consecutiveLoginDays ?? this.consecutiveLoginDays,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      lastFreeCoinsClaimDate: lastFreeCoinsClaimDate ?? this.lastFreeCoinsClaimDate,
      hasClaimedDailyLoginReward: hasClaimedDailyLoginReward ?? this.hasClaimedDailyLoginReward,
      lastLuckySpinDate: lastLuckySpinDate ?? this.lastLuckySpinDate,
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
      'consecutiveLoginDays': consecutiveLoginDays,
      'lastLoginDate': lastLoginDate.toIso8601String(),
      'lastFreeCoinsClaimDate': lastFreeCoinsClaimDate?.toIso8601String(),
      'hasClaimedDailyLoginReward': hasClaimedDailyLoginReward,
      'lastLuckySpinDate': lastLuckySpinDate?.toIso8601String(),
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
      consecutiveLoginDays: json['consecutiveLoginDays'] as int? ?? 1,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'] as String)
          : DateTime.now(),
      lastFreeCoinsClaimDate: json['lastFreeCoinsClaimDate'] != null
          ? DateTime.parse(json['lastFreeCoinsClaimDate'] as String)
          : null,
      hasClaimedDailyLoginReward: json['hasClaimedDailyLoginReward'] as bool? ?? false,
      lastLuckySpinDate: json['lastLuckySpinDate'] != null
          ? DateTime.parse(json['lastLuckySpinDate'] as String)
          : null,
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
      lastLoginDate: DateTime.now(),
      consecutiveLoginDays: 1,
    );
  }
  
  // Check if user can claim free coins (every 4 hours)
  bool get canClaimFreeCoins {
    if (lastFreeCoinsClaimDate == null) return true;
    final hoursSinceLastClaim = DateTime.now().difference(lastFreeCoinsClaimDate!).inHours;
    return hoursSinceLastClaim >= 4;
  }
  
  // Get time until next free coins
  Duration get timeUntilNextFreeCoins {
    if (lastFreeCoinsClaimDate == null) return Duration.zero;
    final nextClaimTime = lastFreeCoinsClaimDate!.add(const Duration(hours: 4));
    final diff = nextClaimTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
  
  // Check if user can spin the lucky wheel (once per day)
  bool get canSpinLuckyWheel {
    if (lastLuckySpinDate == null) return true;
    final lastSpin = DateTime(lastLuckySpinDate!.year, lastLuckySpinDate!.month, lastLuckySpinDate!.day);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return today.isAfter(lastSpin);
  }
}

