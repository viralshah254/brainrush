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
  
  // Level/XP System
  final int level;
  final int xp;
  final int totalXpEarned;
  
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
    // Level/XP
    this.level = 1,
    this.xp = 0,
    this.totalXpEarned = 0,
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
    int? level,
    int? xp,
    int? totalXpEarned,
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
      level: level ?? this.level,
      xp: xp ?? this.xp,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
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
      'level': level,
      'xp': xp,
      'totalXpEarned': totalXpEarned,
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
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      totalXpEarned: json['totalXpEarned'] as int? ?? 0,
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
      level: 1,
      xp: 0,
      totalXpEarned: 0,
    );
  }
  
  // Calculate XP needed for next level
  int get xpForNextLevel {
    // Formula: level * 100 (e.g., level 2 needs 200 XP, level 3 needs 300 XP)
    return level * 100;
  }
  
  // Calculate XP needed for current level
  int get xpForCurrentLevel {
    if (level == 1) return 0;
    return (level - 1) * 100;
  }
  
  // Get progress to next level (0.0 to 1.0)
  double get levelProgress {
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    final xpInLevel = xp - xpForCurrentLevel;
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  }
  
  // Check if user can claim free coins (once per day)
  bool get canClaimFreeCoins {
    if (lastFreeCoinsClaimDate == null) return true;
    final lastClaim = DateTime(lastFreeCoinsClaimDate!.year, lastFreeCoinsClaimDate!.month, lastFreeCoinsClaimDate!.day);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return today.isAfter(lastClaim);
  }
  
  // Get time until next free coins (not used anymore since it's daily)
  Duration get timeUntilNextFreeCoins {
    if (lastFreeCoinsClaimDate == null) return Duration.zero;
    final lastClaim = DateTime(lastFreeCoinsClaimDate!.year, lastFreeCoinsClaimDate!.month, lastFreeCoinsClaimDate!.day);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (today.isAfter(lastClaim)) return Duration.zero;
    
    // Calculate time until midnight (next day)
    final tomorrow = today.add(const Duration(days: 1));
    return tomorrow.difference(DateTime.now());
  }
  
  // Check if user can spin the lucky wheel (once per day)
  bool get canSpinLuckyWheel {
    if (lastLuckySpinDate == null) return true;
    final lastSpin = DateTime(lastLuckySpinDate!.year, lastLuckySpinDate!.month, lastLuckySpinDate!.day);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return today.isAfter(lastSpin);
  }
}

