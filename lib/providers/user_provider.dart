import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/smart_notification_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _showOutOfCoinsDialog = false;
  DateTime _lastPlayTime = DateTime.now();
  final SmartNotificationService _notificationService = SmartNotificationService();

  User? get user => _user;
  bool get isGuest => _user?.isGuest ?? true;
  bool get shouldShowOutOfCoinsDialog => _showOutOfCoinsDialog;
  bool get isOutOfCoins => (_user?.coins ?? 0) == 0;
  DateTime get lastPlayTime => _lastPlayTime;
  
  void resetOutOfCoinsFlag() {
    _showOutOfCoinsDialog = false;
    notifyListeners();
  }

  Future<void> init() async {
    // Initialize with a guest user
    _user = User.guest();
    await loadUserData();
    notifyListeners();
  }
  
  /// Load user data from SharedPreferences
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_user == null) return;
      
      // Load coins
      final coins = prefs.getInt('user_coins') ?? 100;
      
      // Load consecutive login days
      final consecutiveDays = prefs.getInt('consecutive_login_days') ?? 1;
      
      // Load last daily reward claim date
      final lastClaimStr = prefs.getString('last_daily_reward_claim');
      bool hasClaimedToday = false;
      
      if (lastClaimStr != null) {
        final lastClaimed = DateTime.parse(lastClaimStr);
        final today = DateTime.now();
        
        // Check if already claimed today
        hasClaimedToday = lastClaimed.year == today.year &&
                          lastClaimed.month == today.month &&
                          lastClaimed.day == today.day;
      }
      
      // Load last login date
      final lastLoginStr = prefs.getString('last_login_date');
      DateTime lastLoginDate = DateTime.now();
      if (lastLoginStr != null) {
        lastLoginDate = DateTime.parse(lastLoginStr);
      }
      
      // Load last play time
      final lastPlayStr = prefs.getString('last_play_time');
      if (lastPlayStr != null) {
        _lastPlayTime = DateTime.parse(lastPlayStr);
      }
      
      // Load education settings
      final educationAge = prefs.getInt('education_age');
      final educationSchoolSystem = prefs.getString('education_school_system');
      final educationGradeLevel = prefs.getString('education_grade_level');
      final educationChallengeGradeLevel = prefs.getString('education_challenge_grade_level');
      final educationExamFocus = prefs.getString('education_exam_focus') ?? 'NONE';
      final educationModeEnabled = prefs.getBool('education_mode_enabled') ?? false;
      
      // Load last free coins claim date
      final lastFreeCoinsStr = prefs.getString('last_free_coins_claim_date');
      DateTime? lastFreeCoinsClaimDate;
      if (lastFreeCoinsStr != null) {
        lastFreeCoinsClaimDate = DateTime.parse(lastFreeCoinsStr);
      }
      
      // Load last lucky spin date
      final lastLuckySpinStr = prefs.getString('last_lucky_spin_date');
      DateTime? lastLuckySpinDate;
      if (lastLuckySpinStr != null) {
        lastLuckySpinDate = DateTime.parse(lastLuckySpinStr);
      }
      
      // Update user with loaded data
      _user = _user!.copyWith(
        coins: coins,
        consecutiveLoginDays: consecutiveDays,
        hasClaimedDailyLoginReward: hasClaimedToday,
        lastLoginDate: lastLoginDate,
        lastFreeCoinsClaimDate: lastFreeCoinsClaimDate,
        lastLuckySpinDate: lastLuckySpinDate,
        age: educationAge,
        schoolSystem: educationSchoolSystem,
        gradeLevel: educationGradeLevel,
        challengeGradeLevel: educationChallengeGradeLevel,
        examFocus: educationExamFocus,
        educationModeEnabled: educationModeEnabled,
      );
      
      debugPrint('✅ User data loaded: Coins=$coins, Streak=$consecutiveDays, ClaimedToday=$hasClaimedToday, EducationEnabled=$educationModeEnabled');
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
    }
  }
  
  /// Save user data to SharedPreferences
  Future<void> saveUserData() async {
    try {
      if (_user == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      
      // Save coins
      await prefs.setInt('user_coins', _user!.coins);
      
      // Save consecutive login days
      await prefs.setInt('consecutive_login_days', _user!.consecutiveLoginDays);
      
      // Save last login date
      await prefs.setString('last_login_date', _user!.lastLoginDate.toIso8601String());
      
      // Save last play time
      await prefs.setString('last_play_time', _lastPlayTime.toIso8601String());
      
      // Save daily reward claim status
      if (_user!.hasClaimedDailyLoginReward) {
        await prefs.setString('last_daily_reward_claim', DateTime.now().toIso8601String());
      }
      
      // Save education settings
      if (_user!.age != null) {
        await prefs.setInt('education_age', _user!.age!);
      }
      if (_user!.schoolSystem != null) {
        await prefs.setString('education_school_system', _user!.schoolSystem!);
      }
      if (_user!.gradeLevel != null) {
        await prefs.setString('education_grade_level', _user!.gradeLevel!);
      }
      if (_user!.challengeGradeLevel != null) {
        await prefs.setString('education_challenge_grade_level', _user!.challengeGradeLevel!);
      }
      await prefs.setString('education_exam_focus', _user!.examFocus ?? 'NONE');
      await prefs.setBool('education_mode_enabled', _user!.educationModeEnabled);
      
      // Save last free coins claim date
      if (_user!.lastFreeCoinsClaimDate != null) {
        await prefs.setString('last_free_coins_claim_date', _user!.lastFreeCoinsClaimDate!.toIso8601String());
      }
      
      // Save last lucky spin date
      if (_user!.lastLuckySpinDate != null) {
        await prefs.setString('last_lucky_spin_date', _user!.lastLuckySpinDate!.toIso8601String());
      }
      
      debugPrint('💾 User data saved: Coins=${_user!.coins}, EducationEnabled=${_user!.educationModeEnabled}');
    } catch (e) {
      debugPrint('❌ Error saving user data: $e');
    }
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void addCoins(int amount) {
    if (_user == null) return;
    _user = _user!.copyWith(coins: _user!.coins + amount);
    saveUserData(); // Persist coins
    notifyListeners();
  }

  bool hasEnoughCoins(int amount) {
    if (_user == null) return false;
    return _user!.coins >= amount;
  }

  bool spendCoins(int amount) {
    if (_user == null) return false;
    if (!hasEnoughCoins(amount)) return false;
    
    final newCoins = _user!.coins - amount;
    _user = _user!.copyWith(coins: newCoins);
    saveUserData(); // Persist coins
    notifyListeners();
    return true;
  }

  void deductCoins(int amount) {
    // Deduct coins even if balance goes negative (for wrong answers, etc.)
    if (_user == null) return;
    final newCoins = (_user!.coins - amount).clamp(0, double.infinity).toInt();
    _user = _user!.copyWith(coins: newCoins);
    saveUserData(); // Persist coins
    notifyListeners();
  }
  
  void triggerOutOfCoinsDialog() {
    _showOutOfCoinsDialog = true;
    notifyListeners();
  }

  void updateStats({
    required int questionsAnswered,
    required int correctAnswers,
    required int score,
  }) {
    if (_user == null) return;

    final newStats = UserStats(
      questionsAnswered: _user!.stats.questionsAnswered + questionsAnswered,
      correctAnswers: _user!.stats.correctAnswers + correctAnswers,
      totalScore: _user!.stats.totalScore + score,
      accuracy: correctAnswers / questionsAnswered,
    );

    _user = _user!.copyWith(stats: newStats);
    notifyListeners();
  }

  void incrementStreak() {
    if (_user == null) return;
    _user = _user!.copyWith(
      streakCount: _user!.streakCount + 1,
      lastDailyChallenge: DateTime.now(),
    );
    notifyListeners();
  }

  void resetStreak() {
    if (_user == null) return;
    _user = _user!.copyWith(streakCount: 0);
    notifyListeners();
  }
  
  // Check and update daily login
  
  /// Check if daily reward has been claimed today
  /// Returns true if reward was claimed today, false otherwise
  Future<bool> hasClaimedDailyRewardToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastClaimStr = prefs.getString('last_daily_reward_claim');
      
      if (lastClaimStr == null) {
        return false;
      }
      
      final lastClaimed = DateTime.parse(lastClaimStr);
      final today = DateTime.now();
      
      // Check if already claimed today
      final isSameDay = lastClaimed.year == today.year &&
                        lastClaimed.month == today.month &&
                        lastClaimed.day == today.day;
      
      return isSameDay;
    } catch (e) {
      debugPrint('❌ Error checking daily reward claim: $e');
      return false;
    }
  }
  
  int checkDailyLogin() {
    if (_user == null) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = DateTime(
      _user!.lastLoginDate.year,
      _user!.lastLoginDate.month,
      _user!.lastLoginDate.day,
    );
    
    final daysDifference = today.difference(lastLogin).inDays;
    
    // If same day and already claimed, don't update anything
    if (daysDifference == 0 && _user!.hasClaimedDailyLoginReward) {
      return 0; // Already claimed today, no update needed
    }
    
    int newConsecutiveDays;
    bool shouldResetClaim = false;
    
    if (daysDifference == 0) {
      // Same day, no streak update needed
      newConsecutiveDays = _user!.consecutiveLoginDays;
    } else if (daysDifference == 1) {
      // Consecutive day - increment streak
      newConsecutiveDays = _user!.consecutiveLoginDays + 1;
      shouldResetClaim = true; // New day, reset claim status
    } else {
      // Streak broken - reset to 1
      newConsecutiveDays = 1;
      shouldResetClaim = true; // New day, reset claim status
    }
    
    // Update user
    _user = _user!.copyWith(
      consecutiveLoginDays: newConsecutiveDays,
      lastLoginDate: now,
      hasClaimedDailyLoginReward: shouldResetClaim ? false : _user!.hasClaimedDailyLoginReward,
    );
    saveUserData(); // Persist login streak
    notifyListeners();
    
    return daysDifference; // Return days away for comeback bonus
  }
  
  /// Claim daily login reward
  /// Marks the reward as claimed and saves the current date to SharedPreferences
  void claimDailyLoginReward() {
    if (_user == null) return;
    _user = _user!.copyWith(hasClaimedDailyLoginReward: true);
    saveUserData(); // Persist claim status (saves date to SharedPreferences)
    notifyListeners();
  }
  
  // Claim free coins (4-hour timer)
  void claimFreeCoins() {
    if (_user == null) return;
    _user = _user!.copyWith(lastFreeCoinsClaimDate: DateTime.now());
    saveUserData(); // Persist the date
    notifyListeners();
  }
  
  // ===== SMART NOTIFICATIONS =====
  
  /// Schedule smart notifications on app launch
  Future<void> initializeSmartNotifications() async {
    if (_user == null) return;
    
    try {
      final prefs = await _notificationService.loadPreferences();
      final hasPlayedToday = _hasPlayedToday();
      final daysSinceLastPlay = DateTime.now().difference(_lastPlayTime).inDays;

      // Check for lapsed users (2-7 days)
      if (daysSinceLastPlay >= 2 && daysSinceLastPlay < 7) {
        await _notificationService.sendComebackNotification();
        debugPrint('🎁 Comeback notification sent ($daysSinceLastPlay days inactive)');
      }

      // Schedule smart notifications
      await _notificationService.scheduleSmartNotifications(
        prefs: prefs,
        currentStreak: _user!.streakCount,
        lastPlayedDate: _lastPlayTime,
        hasPlayedToday: hasPlayedToday,
      );
      
      debugPrint('✅ Smart notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing smart notifications: $e');
    }
  }
  
  /// Record that user played (call after every game)
  Future<void> recordGamePlayed() async {
    _lastPlayTime = DateTime.now();
    notifyListeners();
    
    // Reschedule smart notifications based on updated behavior
    await _scheduleSmartNotifications();
  }
  
  /// Schedule smart notifications based on current user state
  Future<void> _scheduleSmartNotifications() async {
    if (_user == null) return;
    
    try {
      final prefs = await _notificationService.loadPreferences();
      final hasPlayedToday = _hasPlayedToday();
      
      await _notificationService.scheduleSmartNotifications(
        prefs: prefs,
        currentStreak: _user!.streakCount,
        lastPlayedDate: _lastPlayTime,
        hasPlayedToday: hasPlayedToday,
      );
    } catch (e) {
      debugPrint('❌ Error scheduling smart notifications: $e');
    }
  }
  
  /// Check if user played today
  bool _hasPlayedToday() {
    final now = DateTime.now();
    final lastPlay = _lastPlayTime;
    return now.year == lastPlay.year &&
           now.month == lastPlay.month &&
           now.day == lastPlay.day;
  }
}
