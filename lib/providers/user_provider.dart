import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _showOutOfCoinsDialog = false;

  User? get user => _user;
  bool get isGuest => _user?.isGuest ?? true;
  bool get shouldShowOutOfCoinsDialog => _showOutOfCoinsDialog;
  bool get isOutOfCoins => (_user?.coins ?? 0) == 0;
  
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
}

