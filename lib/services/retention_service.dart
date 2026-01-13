import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/daily_quest.dart';

class RetentionService extends ChangeNotifier {
  static final RetentionService _instance = RetentionService._internal();
  factory RetentionService() => _instance;
  RetentionService._internal() {
    _initializeQuests();
  }

  List<DailyQuest> _dailyQuests = [];
  DateTime? _questsLastRefreshed;

  List<DailyQuest> get dailyQuests => _dailyQuests;
  
  int get completedQuestsCount => _dailyQuests.where((q) => q.isCompleted).length;
  int get totalQuestsCount => _dailyQuests.length;
  
  bool get allQuestsCompleted => completedQuestsCount == totalQuestsCount && totalQuestsCount > 0;

  void _initializeQuests() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if we need to refresh quests (new day)
    if (_questsLastRefreshed == null || 
        DateTime(_questsLastRefreshed!.year, _questsLastRefreshed!.month, _questsLastRefreshed!.day)
            .isBefore(today)) {
      _dailyQuests = DailyQuest.generateDailyQuests();
      _questsLastRefreshed = now;
      notifyListeners();
    }
  }

  // Check for quest refreshes
  void checkQuestRefresh() {
    _initializeQuests();
  }

  // Update quest progress
  void updateQuestProgress(QuestType type, {int increment = 1}) {
    bool updated = false;
    
    for (int i = 0; i < _dailyQuests.length; i++) {
      final quest = _dailyQuests[i];
      if (quest.type == type && !quest.isCompleted) {
        final newValue = (quest.currentValue + increment).clamp(0, quest.targetValue);
        final isCompleted = newValue >= quest.targetValue;
        
        _dailyQuests[i] = quest.copyWith(
          currentValue: newValue,
          isCompleted: isCompleted,
        );
        updated = true;
      }
    }
    
    if (updated) {
      notifyListeners();
    }
  }

  // Claim quest reward
  int claimQuestReward(String questId) {
    final questIndex = _dailyQuests.indexWhere((q) => q.id == questId);
    if (questIndex != -1) {
      final quest = _dailyQuests[questIndex];
      if (quest.isCompleted) {
        return quest.coinReward;
      }
    }
    return 0;
  }

  // Lucky wheel spin
  int spinLuckyWheel() {
    final random = Random();
    final spin = random.nextInt(100);
    
    // Prize distribution:
    // 50% chance: 50 coins
    // 25% chance: 100 coins
    // 15% chance: 200 coins
    // 8% chance: 500 coins
    // 2% chance: 1000 coins (JACKPOT!)
    
    if (spin < 50) {
      return 50;
    } else if (spin < 75) {
      return 100;
    } else if (spin < 90) {
      return 200;
    } else if (spin < 98) {
      return 500;
    } else {
      return 1000; // JACKPOT!
    }
  }

  // Get comeback bonus (if user hasn't logged in for multiple days)
  int getComebackBonus(int daysAway) {
    if (daysAway < 2) return 0;
    
    // Progressive comeback bonus
    if (daysAway >= 7) {
      return 500; // Week or more
    } else if (daysAway >= 3) {
      return 250; // 3-6 days
    } else {
      return 100; // 2 days
    }
  }

  // Calculate login streak bonus multiplier
  double getStreakMultiplier(int consecutiveDays) {
    if (consecutiveDays >= 30) return 2.0; // 2x for 30+ days
    if (consecutiveDays >= 14) return 1.5; // 1.5x for 14+ days
    if (consecutiveDays >= 7) return 1.25; // 1.25x for 7+ days
    return 1.0;
  }
}

