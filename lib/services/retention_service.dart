import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_quest.dart';

class RetentionService extends ChangeNotifier {
  static final RetentionService _instance = RetentionService._internal();
  factory RetentionService() => _instance;
  RetentionService._internal() {
    _initializeQuests(); // Will be async but that's okay
  }

  List<DailyQuest> _dailyQuests = [];
  DateTime? _questsLastRefreshed;
  bool _allQuestsBonusClaimed = false;

  List<DailyQuest> get dailyQuests => _dailyQuests.where((q) => q.type != QuestType.playWithFriends).toList();
  
  int get completedQuestsCount => _dailyQuests.where((q) => q.isCompleted && q.type != QuestType.playWithFriends).length;
  int get totalQuestsCount => _dailyQuests.where((q) => q.type != QuestType.playWithFriends).length;
  
  bool get allQuestsCompleted => completedQuestsCount == totalQuestsCount && totalQuestsCount > 0;
  
  /// Returns whether the all quests completion bonus has been claimed
  bool get allQuestsBonusClaimed {
    return _allQuestsBonusClaimed;
  }

  Future<void> _initializeQuests() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Load last refresh date from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final lastRefreshStr = prefs.getString('daily_quests_last_refresh');
    DateTime? lastRefresh;
    
    if (lastRefreshStr != null) {
      lastRefresh = DateTime.parse(lastRefreshStr);
    }
    
    // Check if we need to refresh quests (new day)
    if (lastRefresh == null || 
        DateTime(lastRefresh.year, lastRefresh.month, lastRefresh.day)
            .isBefore(today)) {
      // New day - generate fresh quests
      _dailyQuests = DailyQuest.generateDailyQuests();
      _questsLastRefreshed = now;
      _allQuestsBonusClaimed = false;
      
      // Save refresh date
      await prefs.setString('daily_quests_last_refresh', now.toIso8601String());
      await _saveQuestsState();
    } else {
      // Same day - load saved quest state
      await _loadQuestsState();
      _questsLastRefreshed = lastRefresh;
    }
    
    notifyListeners();
  }

  Future<void> _saveQuestsState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questsJson = _dailyQuests.map((q) => q.toJson()).toList();
      await prefs.setString('daily_quests_state', questsJson.toString());
      await prefs.setBool('all_quests_bonus_claimed', _allQuestsBonusClaimed);
    } catch (e) {
      debugPrint('❌ Error saving quests state: $e');
    }
  }

  Future<void> _loadQuestsState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questsStr = prefs.getString('daily_quests_state');
      _allQuestsBonusClaimed = prefs.getBool('all_quests_bonus_claimed') ?? false;
      
      if (questsStr != null && questsStr.isNotEmpty) {
        // Parse quests from saved state
        // For simplicity, we'll regenerate and update progress
        _dailyQuests = DailyQuest.generateDailyQuests();
        
        // Load individual quest progress
        for (var quest in _dailyQuests) {
          final currentValue = prefs.getInt('quest_${quest.id}_progress') ?? 0;
          final isCompleted = prefs.getBool('quest_${quest.id}_completed') ?? false;
          
          final index = _dailyQuests.indexWhere((q) => q.id == quest.id);
          if (index != -1) {
            _dailyQuests[index] = quest.copyWith(
              currentValue: currentValue,
              isCompleted: isCompleted,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading quests state: $e');
      // Fallback to generating new quests
      _dailyQuests = DailyQuest.generateDailyQuests();
    }
  }

  // Check for quest refreshes
  void checkQuestRefresh() {
    _initializeQuests();
  }

  // Update quest progress
  Future<void> updateQuestProgress(QuestType type, {int increment = 1}) async {
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
        
        // Save individual quest progress
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('quest_${quest.id}_progress', newValue);
        await prefs.setBool('quest_${quest.id}_completed', isCompleted);
        
        updated = true;
      }
    }
    
    if (updated) {
      await _saveQuestsState();
      notifyListeners();
    }
  }

  // Claim quest reward
  Future<int> claimQuestReward(String questId) async {
    final questIndex = _dailyQuests.indexWhere((q) => q.id == questId);
    if (questIndex != -1) {
      final quest = _dailyQuests[questIndex];
      if (quest.isCompleted) {
        // Mark as claimed
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('quest_${questId}_claimed', true);
        await _saveQuestsState();
        return quest.coinReward;
      }
    }
    return 0;
  }

  /// Claims the bonus reward for completing all daily quests
  /// Returns the bonus coin amount (500) if successful, 0 otherwise
  Future<int> claimAllQuestsBonus() async {
    if (allQuestsCompleted && !_allQuestsBonusClaimed) {
      _allQuestsBonusClaimed = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('all_quests_bonus_claimed', true);
      await _saveQuestsState();
      notifyListeners();
      return 500; // Bonus coins for completing all quests
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

