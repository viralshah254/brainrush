import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/campaign_round.dart';

class CampaignService extends ChangeNotifier {
  static final CampaignService _instance = CampaignService._internal();
  factory CampaignService() => _instance;
  CampaignService._internal();

  List<CampaignRound> _rounds = [];
  int _currentRound = 1;
  int _totalStars = 0;

  List<CampaignRound> get rounds => _rounds;
  int get currentRound => _currentRound;
  int get totalStars => _totalStars;
  int get completedRounds => _rounds.where((r) => r.isCompleted).length;

  Future<void> initialize() async {
    await _loadProgress();
    if (_rounds.isEmpty) {
      _generateRounds();
      await _saveProgress();
    }
    notifyListeners();
  }

  void _generateRounds() {
    _rounds.clear();
    
    // Define subjects with rotation pattern
    final subjects = [
      'General Knowledge',
      'Science',
      'Math',
      'History',
      'Geography',
      'Literature',
      'Technology',
      'Sports',
      'Entertainment',
      'Nature',
    ];
    
    // Generate 300+ rounds (30+ chapters of 10 rounds each)
    final totalRounds = 300;
    final roundsPerChapter = 10;
    
    for (int i = 1; i <= totalRounds; i++) {
      final chapterNumber = ((i - 1) ~/ roundsPerChapter) + 1;
      final roundInChapter = ((i - 1) % roundsPerChapter) + 1;
      
      // Get random difficulty for this chapter (ensures mix within each chapter)
      final difficulty = _getDifficultyForRoundInChapter(i, chapterNumber, roundInChapter);
      
      // Rotate through subjects, ensuring variety
      final category = subjects[(i - 1) % subjects.length];
      
        // Random question count between 10-15
        final questionCount = _getRandomQuestionCount(i);
        
        // Only round 1 is unlocked initially, rest unlock sequentially
        final isLocked = i > 1; // Only round 1 is unlocked initially
        
        _rounds.add(CampaignRound(
          roundNumber: i,
          title: _getRoundTitle(i, difficulty, chapterNumber),
          description: _getRoundDescription(i, category, chapterNumber),
          difficulty: difficulty,
          questionCount: questionCount,
          category: category,
          coinsReward: _getCoinsReward(difficulty),
          starsRequired: _getStarsRequired(i),
          isLocked: isLocked,
          isCompleted: false,
        ));
    }
  }

  int _getRandomQuestionCount(int roundNumber) {
    // Use round number as seed for consistent randomness
    // This ensures the same round always has the same question count
    final seed = roundNumber * 7919; // Prime number for better distribution
    final random = (seed % 6) + 10; // 10-15 questions
    return random;
  }

  RoundDifficulty _getDifficultyForRoundInChapter(int roundNumber, int chapterNumber, int roundInChapter) {
    // Each chapter (10 rounds) should have a random mix of difficulties
    // Use chapter number as seed to ensure consistency
    final chapterSeed = chapterNumber * 9973; // Prime for better distribution
    
    // Create a list of difficulties for this chapter
    // Each chapter should have a mix: 2-3 easy, 2-3 medium, 2-3 hard, 1-2 superHard
    final difficulties = <RoundDifficulty>[];
    
    // Add 2-3 easy rounds
    final easyCount = 2 + (chapterSeed % 2); // 2 or 3
    for (int i = 0; i < easyCount; i++) {
      difficulties.add(RoundDifficulty.easy);
    }
    
    // Add 2-3 medium rounds
    final mediumCount = 2 + ((chapterSeed ~/ 10) % 2); // 2 or 3
    for (int i = 0; i < mediumCount; i++) {
      difficulties.add(RoundDifficulty.medium);
    }
    
    // Add 2-3 hard rounds
    final hardCount = 2 + ((chapterSeed ~/ 100) % 2); // 2 or 3
    for (int i = 0; i < hardCount; i++) {
      difficulties.add(RoundDifficulty.hard);
    }
    
    // Add 1-2 superHard rounds (fill remaining slots to total 10)
    final remaining = 10 - difficulties.length;
    for (int i = 0; i < remaining; i++) {
      difficulties.add(RoundDifficulty.superHard);
    }
    
    // Shuffle the difficulties for this chapter using consistent seed-based shuffling
    _shuffleWithSeed(difficulties, chapterSeed);
    
    // Return the difficulty for this specific round in the chapter
    return difficulties[(roundInChapter - 1) % difficulties.length];
  }

  void _shuffleWithSeed(List<RoundDifficulty> list, int seed) {
    // Simple seeded shuffle algorithm (Fisher-Yates with seed)
    var random = seed;
    for (int i = list.length - 1; i > 0; i--) {
      random = (random * 1103515245 + 12345) & 0x7fffffff; // Linear congruential generator
      final j = random % (i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  String _getRoundTitle(int round, RoundDifficulty difficulty, int chapterNumber) {
    if (round == 1) return '🎮 Welcome Challenge';
    
    // Chapter milestones
    if (round % 10 == 1 && round > 1) {
      return '📖 Chapter $chapterNumber - Round ${((round - 1) % 10) + 1}';
    }
    
    // Special chapter completions
    if (round % 10 == 0) {
      return '🏆 Chapter $chapterNumber Complete';
    }
    
    // Special milestones
    if (round == 50) return '🔥 Half Century';
    if (round == 100) return '💯 Century Club';
    if (round == 200) return '⚡ Double Century';
    if (round == 300) return '👑 Ultimate Champion';
    
    // Special rounds every 25
    if (round % 25 == 0) return '🌟 Checkpoint $round';
    
    return 'Round $round';
  }

  String _getRoundDescription(int round, String category, int chapterNumber) {
    if (round <= 10) {
      return 'Chapter 1: Master the basics of $category';
    } else if (round <= 50) {
      return 'Chapter $chapterNumber: Building momentum in $category';
    } else if (round <= 150) {
      return 'Chapter $chapterNumber: Expert level $category challenges';
    } else if (round <= 250) {
      return 'Chapter $chapterNumber: Ultimate $category mastery';
    } else {
      return 'Chapter $chapterNumber: Legendary $category questions';
    }
  }

  int _getCoinsReward(RoundDifficulty difficulty) {
    switch (difficulty) {
      case RoundDifficulty.easy:
        return 50;
      case RoundDifficulty.medium:
        return 100;
      case RoundDifficulty.hard:
        return 200;
      case RoundDifficulty.superHard:
        return 500;
    }
  }

  int _getStarsRequired(int round) {
    if (round == 1) return 0;
    if (round <= 10) return (round - 1) * 1; // Need 1 star per round
    if (round <= 50) return (round - 1) * 2;
    if (round <= 150) return round * 2;
    return round * 3;
  }

  Future<void> completeRound({
    required int roundNumber,
    required int score,
    required int maxScore,
  }) async {
    final index = _rounds.indexWhere((r) => r.roundNumber == roundNumber);
    if (index == -1) return;

    final stars = CampaignRound.calculateStars(score, maxScore);
    final round = _rounds[index];

    // Update round
    _rounds[index] = round.copyWith(
      isCompleted: true,
      bestScore: round.bestScore == null || score > round.bestScore! ? score : round.bestScore,
      starsEarned: round.starsEarned == null || stars > round.starsEarned! ? stars : round.starsEarned,
    );

    // Unlock rounds sequentially: Round N+1 unlocks only when Round N is completed
    // Always unlock just the next round
    if (index + 1 < _rounds.length) {
      _rounds[index + 1] = _rounds[index + 1].copyWith(isLocked: false);
    }

    // Update current round
    _currentRound = roundNumber + 1;

    // Recalculate total stars
    _totalStars = _rounds
        .where((r) => r.starsEarned != null)
        .fold(0, (sum, r) => sum + r.starsEarned!);

    await _saveProgress();
    notifyListeners();
  }

  CampaignRound? getRound(int roundNumber) {
    return _rounds.firstWhere(
      (r) => r.roundNumber == roundNumber,
      orElse: () => _rounds.first,
    );
  }

  List<CampaignRound> getVisibleRounds() {
    // Show current, completed, and next 3 unlocked rounds
    final current = _currentRound;
    return _rounds.where((r) {
      return r.roundNumber <= current + 3 && !r.isLocked;
    }).toList();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roundsJson = prefs.getString('campaign_rounds');
      if (roundsJson != null) {
        final List<dynamic> decoded = json.decode(roundsJson);
        _rounds = decoded.map((r) => CampaignRound.fromJson(r)).toList();
        
        // Ensure rounds are properly locked based on sequential completion
        // Round 1 is always unlocked
        // Round N+1 unlocks only when Round N is completed
        for (int i = 0; i < _rounds.length; i++) {
          final round = _rounds[i];
          final roundNumber = round.roundNumber;
          
          // Round 1 is always unlocked
          if (roundNumber == 1) {
            if (round.isLocked) {
              _rounds[i] = round.copyWith(isLocked: false);
            }
          } else {
            // For rounds beyond 1, check if the previous round is completed
            final previousRoundNumber = roundNumber - 1;
            final previousRound = _rounds.firstWhere(
              (r) => r.roundNumber == previousRoundNumber,
              orElse: () => _rounds.first,
            );
            
            // Unlock this round only if the previous round is completed
            final shouldBeUnlocked = previousRound.isCompleted;
            if (round.isLocked != !shouldBeUnlocked) {
              _rounds[i] = round.copyWith(isLocked: !shouldBeUnlocked);
            }
          }
        }
      }
      _currentRound = prefs.getInt('current_round') ?? 1;
      _totalStars = prefs.getInt('total_stars') ?? 0;
    } catch (e) {
      // ignore: avoid_print
      print('Error loading campaign progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roundsJson = json.encode(_rounds.map((r) => r.toJson()).toList());
      await prefs.setString('campaign_rounds', roundsJson);
      await prefs.setInt('current_round', _currentRound);
      await prefs.setInt('total_stars', _totalStars);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving campaign progress: $e');
    }
  }

  Future<void> resetProgress() async {
    _rounds.clear();
    _currentRound = 1;
    _totalStars = 0;
    _generateRounds();
    await _saveProgress();
    notifyListeners();
  }
}

