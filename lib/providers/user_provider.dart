import 'package:flutter/foundation.dart';
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

  void init() {
    // Initialize with a guest user
    _user = User.guest();
    notifyListeners();
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void addCoins(int amount) {
    if (_user == null) return;
    _user = _user!.copyWith(coins: _user!.coins + amount);
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
    
    notifyListeners();
    return true;
  }

  void deductCoins(int amount) {
    // Deduct coins even if balance goes negative (for wrong answers, etc.)
    if (_user == null) return;
    final newCoins = (_user!.coins - amount).clamp(0, double.infinity).toInt();
    _user = _user!.copyWith(coins: newCoins);
    
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
  int checkDailyLogin() {
    if (_user == null) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = DateTime(
      _user!.lastLoginDate.year,
      _user!.lastLoginDate.month,
      _user!.lastLoginDate.day,
    );
    
    // Check if already claimed today
    if (_user!.hasClaimedDailyLoginReward && today == lastLogin) {
      return 0; // Already claimed today
    }
    
    final daysDifference = today.difference(lastLogin).inDays;
    
    int newConsecutiveDays;
    if (daysDifference == 0) {
      // Same day, no update needed
      return 0;
    } else if (daysDifference == 1) {
      // Consecutive day - increment streak
      newConsecutiveDays = _user!.consecutiveLoginDays + 1;
    } else {
      // Streak broken - reset to 1
      newConsecutiveDays = 1;
    }
    
    // Update user
    _user = _user!.copyWith(
      consecutiveLoginDays: newConsecutiveDays,
      lastLoginDate: now,
      hasClaimedDailyLoginReward: false, // Reset claim status for new day
    );
    notifyListeners();
    
    return daysDifference; // Return days away for comeback bonus
  }
  
  // Claim daily login reward
  void claimDailyLoginReward() {
    if (_user == null) return;
    _user = _user!.copyWith(hasClaimedDailyLoginReward: true);
    notifyListeners();
  }
  
  // Claim free coins (4-hour timer)
  void claimFreeCoins() {
    if (_user == null) return;
    _user = _user!.copyWith(lastFreeCoinsClaimDate: DateTime.now());
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
