import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isGuest => _user?.isGuest ?? true;

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

  void spendCoins(int amount) {
    if (_user == null) return;
    final newCoins = (_user!.coins - amount).clamp(0, double.infinity).toInt();
    _user = _user!.copyWith(coins: newCoins);
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
}

