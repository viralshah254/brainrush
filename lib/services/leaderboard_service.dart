import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/leaderboard_entry.dart';

/// Leaderboard Service - Works for both General and Education modes
/// Uses local storage (can be extended to backend later)
class LeaderboardService extends ChangeNotifier {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  // Cache for leaderboards
  Map<String, List<LeaderboardEntry>> _leaderboardCache = {};
  DateTime? _lastWeeklyReset;
  DateTime? _lastMonthlyReset;

  /// Get leaderboard entries
  /// [type] - Type of leaderboard
  /// [category] - Category filter (for category leaderboards)
  /// [isEducationMode] - Whether to show education mode leaderboard
  /// [limit] - Maximum number of entries to return
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardType type,
    LeaderboardCategory category = LeaderboardCategory.all,
    bool isEducationMode = false,
    int limit = 100,
    String? currentUserId,
  }) async {
    final cacheKey = '${type}_${category}_${isEducationMode}';
    
    // Check cache first
    if (_leaderboardCache.containsKey(cacheKey)) {
      final cached = _leaderboardCache[cacheKey]!;
      // Mark current user
      if (currentUserId != null) {
        return cached.map((entry) => entry.userId == currentUserId
            ? LeaderboardEntry(
                userId: entry.userId,
                username: entry.username,
                score: entry.score,
                rank: entry.rank,
                level: entry.level,
                accuracy: entry.accuracy,
                gamesPlayed: entry.gamesPlayed,
                isCurrentUser: true,
                avatarUrl: entry.avatarUrl,
                isEducationMode: entry.isEducationMode,
              )
            : entry).toList();
      }
      return cached;
    }

    // Load from storage
    final entries = await _loadLeaderboardFromStorage(
      type: type,
      category: category,
      isEducationMode: isEducationMode,
      limit: limit,
      currentUserId: currentUserId,
    );

    // Cache results
    _leaderboardCache[cacheKey] = entries;
    
    return entries;
  }

  /// Load leaderboard from SharedPreferences
  Future<List<LeaderboardEntry>> _loadLeaderboardFromStorage({
    required LeaderboardType type,
    required LeaderboardCategory category,
    required bool isEducationMode,
    required int limit,
    String? currentUserId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get the appropriate storage key
      String storageKey;
      switch (type) {
        case LeaderboardType.weekly:
          storageKey = isEducationMode 
              ? 'leaderboard_weekly_education'
              : 'leaderboard_weekly';
          // Check if we need to reset weekly leaderboard
          await _checkWeeklyReset();
          break;
        case LeaderboardType.monthly:
          storageKey = isEducationMode
              ? 'leaderboard_monthly_education'
              : 'leaderboard_monthly';
          // Check if we need to reset monthly leaderboard
          await _checkMonthlyReset();
          break;
        case LeaderboardType.category:
          storageKey = isEducationMode
              ? 'leaderboard_category_${category}_education'
              : 'leaderboard_category_${category}';
          break;
        case LeaderboardType.friends:
          storageKey = 'leaderboard_friends';
          break;
        case LeaderboardType.education:
          storageKey = 'leaderboard_education';
          break;
        default:
          storageKey = isEducationMode
              ? 'leaderboard_global_education'
              : 'leaderboard_global';
      }

      final entriesJson = prefs.getString(storageKey);
      if (entriesJson == null || entriesJson.isEmpty) {
        // Return empty list or generate demo data for testing
        return _generateDemoLeaderboard(
          limit: limit,
          isEducationMode: isEducationMode,
          currentUserId: currentUserId,
        );
      }

      final List<dynamic> decoded = json.decode(entriesJson);
      final entries = decoded
          .map((json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      // Mark current user
      if (currentUserId != null) {
        return entries.map((entry) => entry.userId == currentUserId
            ? LeaderboardEntry(
                userId: entry.userId,
                username: entry.username,
                score: entry.score,
                rank: entry.rank,
                level: entry.level,
                accuracy: entry.accuracy,
                gamesPlayed: entry.gamesPlayed,
                isCurrentUser: true,
                avatarUrl: entry.avatarUrl,
                isEducationMode: entry.isEducationMode,
              )
            : entry).toList();
      }

      return entries.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error loading leaderboard: $e');
      return [];
    }
  }

  /// Update user's leaderboard entry after a game
  Future<void> updateUserScore({
    required String userId,
    required String username,
    required int score,
    required int level,
    required double accuracy,
    required int gamesPlayed,
    bool isEducationMode = false,
    LeaderboardCategory? category,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update all relevant leaderboards
      final leaderboardTypes = [
        LeaderboardType.global,
        LeaderboardType.weekly,
        LeaderboardType.monthly,
      ];

      if (category != null) {
        leaderboardTypes.add(LeaderboardType.category);
      }

      for (final type in leaderboardTypes) {
        String storageKey;
        switch (type) {
          case LeaderboardType.weekly:
            storageKey = isEducationMode
                ? 'leaderboard_weekly_education'
                : 'leaderboard_weekly';
            break;
          case LeaderboardType.monthly:
            storageKey = isEducationMode
                ? 'leaderboard_monthly_education'
                : 'leaderboard_monthly';
            break;
          case LeaderboardType.category:
            if (category == null) continue;
            storageKey = isEducationMode
                ? 'leaderboard_category_${category}_education'
                : 'leaderboard_category_${category}';
            break;
          case LeaderboardType.education:
            storageKey = 'leaderboard_education';
            break;
          default:
            storageKey = isEducationMode
                ? 'leaderboard_global_education'
                : 'leaderboard_global';
        }

        // Load existing entries
        final entriesJson = prefs.getString(storageKey);
        List<LeaderboardEntry> entries = [];
        
        if (entriesJson != null && entriesJson.isNotEmpty) {
          final List<dynamic> decoded = json.decode(entriesJson);
          entries = decoded
              .map((json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        // Find or create user entry
        final userIndex = entries.indexWhere((e) => e.userId == userId);
        if (userIndex != -1) {
          // Update existing entry
          final existing = entries[userIndex];
          entries[userIndex] = LeaderboardEntry(
            userId: userId,
            username: username,
            score: score > existing.score ? score : existing.score, // Keep highest score
            rank: 0, // Will be recalculated
            level: level,
            accuracy: accuracy,
            gamesPlayed: gamesPlayed,
            isCurrentUser: existing.isCurrentUser,
            avatarUrl: existing.avatarUrl,
            isEducationMode: isEducationMode,
          );
        } else {
          // Add new entry
          entries.add(LeaderboardEntry(
            userId: userId,
            username: username,
            score: score,
            rank: 0,
            level: level,
            accuracy: accuracy,
            gamesPlayed: gamesPlayed,
            isEducationMode: isEducationMode,
          ));
        }

        // Sort by score (descending) and update ranks
        entries.sort((a, b) => b.score.compareTo(a.score));
        entries = entries.asMap().entries.map((entry) {
          final index = entry.key;
          final e = entry.value;
          return LeaderboardEntry(
            userId: e.userId,
            username: e.username,
            score: e.score,
            rank: index + 1,
            level: e.level,
            accuracy: e.accuracy,
            gamesPlayed: e.gamesPlayed,
            isCurrentUser: e.isCurrentUser,
            avatarUrl: e.avatarUrl,
            isEducationMode: e.isEducationMode,
          );
        }).toList();

        // Save back to storage
        final updatedJson = json.encode(entries.map((e) => e.toJson()).toList());
        await prefs.setString(storageKey, updatedJson);
      }

      // Clear cache
      _leaderboardCache.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating leaderboard: $e');
    }
  }

  /// Check if weekly leaderboard needs reset
  Future<void> _checkWeeklyReset() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    
    final lastResetStr = prefs.getString('leaderboard_weekly_reset');
    if (lastResetStr != null) {
      _lastWeeklyReset = DateTime.parse(lastResetStr);
    }

    // Reset on Monday
    if (_lastWeeklyReset == null || 
        now.difference(_lastWeeklyReset!).inDays >= 7 ||
        (now.weekday == 1 && _lastWeeklyReset != null && _lastWeeklyReset!.weekday != 1)) {
      // Reset weekly leaderboards
      await prefs.remove('leaderboard_weekly');
      await prefs.remove('leaderboard_weekly_education');
      await prefs.setString('leaderboard_weekly_reset', now.toIso8601String());
      _lastWeeklyReset = now;
      _leaderboardCache.clear();
    }
  }

  /// Check if monthly leaderboard needs reset
  Future<void> _checkMonthlyReset() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    
    final lastResetStr = prefs.getString('leaderboard_monthly_reset');
    if (lastResetStr != null) {
      _lastMonthlyReset = DateTime.parse(lastResetStr);
    }

    // Reset on 1st of month
    if (_lastMonthlyReset == null || 
        (now.year != _lastMonthlyReset!.year || now.month != _lastMonthlyReset!.month)) {
      // Reset monthly leaderboards
      await prefs.remove('leaderboard_monthly');
      await prefs.remove('leaderboard_monthly_education');
      await prefs.setString('leaderboard_monthly_reset', now.toIso8601String());
      _lastMonthlyReset = now;
      _leaderboardCache.clear();
    }
  }

  /// Generate demo leaderboard for testing
  List<LeaderboardEntry> _generateDemoLeaderboard({
    required int limit,
    required bool isEducationMode,
    String? currentUserId,
  }) {
    final demoEntries = <LeaderboardEntry>[];
    final demoNames = [
      'QuizMaster',
      'BrainBox',
      'TriviaKing',
      'SmartCookie',
      'GeniusMode',
      'MindBender',
      'QuizWhiz',
      'Brainiac',
      'TriviaPro',
      'SmartAce',
    ];

    for (int i = 0; i < limit && i < 10; i++) {
      final isCurrent = currentUserId != null && i == 5; // Mark 6th entry as current user
      demoEntries.add(LeaderboardEntry(
        userId: isCurrent ? currentUserId! : 'demo_user_$i',
        username: isCurrent ? 'You' : demoNames[i % demoNames.length],
        score: 10000 - (i * 500),
        rank: i + 1,
        level: 20 - i,
        accuracy: 0.85 - (i * 0.02),
        gamesPlayed: 100 - (i * 5),
        isCurrentUser: isCurrent,
        isEducationMode: isEducationMode,
      ));
    }

    return demoEntries;
  }

  /// Get user's rank in a leaderboard
  Future<int?> getUserRank({
    required String userId,
    required LeaderboardType type,
    bool isEducationMode = false,
    LeaderboardCategory category = LeaderboardCategory.all,
  }) async {
    final entries = await getLeaderboard(
      type: type,
      category: category,
      isEducationMode: isEducationMode,
      currentUserId: userId,
    );

    final userEntry = entries.firstWhere(
      (e) => e.userId == userId,
      orElse: () => LeaderboardEntry(
        userId: userId,
        username: '',
        score: 0,
        rank: 0,
      ),
    );

    return userEntry.rank > 0 ? userEntry.rank : null;
  }

  /// Clear cache
  void clearCache() {
    _leaderboardCache.clear();
    notifyListeners();
  }
}

