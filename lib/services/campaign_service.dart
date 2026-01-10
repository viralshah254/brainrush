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
    
    final categories = ['Math', 'Science', 'History', 'Geography', 'Literature', 'Mixed'];
    
    // Generate 500 rounds
    for (int i = 1; i <= 500; i++) {
      final difficulty = _getDifficultyForRound(i);
      final category = categories[i % categories.length];
      final questionCount = 10 + (i % 6); // 10-15 questions
      
      _rounds.add(CampaignRound(
        roundNumber: i,
        title: _getRoundTitle(i, difficulty),
        description: _getRoundDescription(i, category),
        difficulty: difficulty,
        questionCount: questionCount,
        category: category,
        coinsReward: _getCoinsReward(difficulty),
        starsRequired: _getStarsRequired(i),
        isLocked: i > 1, // First round unlocked
        isCompleted: false,
      ));
    }
  }

  RoundDifficulty _getDifficultyForRound(int round) {
    if (round <= 50) return RoundDifficulty.easy;
    if (round <= 150) return RoundDifficulty.medium;
    if (round <= 350) return RoundDifficulty.hard;
    return RoundDifficulty.superHard;
  }

  String _getRoundTitle(int round, RoundDifficulty difficulty) {
    if (round == 1) return '🎮 Welcome Challenge';
    if (round == 10) return '🏆 First Milestone';
    if (round == 50) return '🔥 Half Century';
    if (round == 100) return '💯 Century Club';
    if (round == 250) return '⚡ Quarter Master';
    if (round == 500) return '👑 Ultimate Champion';
    
    // Special rounds every 25
    if (round % 25 == 0) return '🌟 Checkpoint $round';
    
    return 'Round $round';
  }

  String _getRoundDescription(int round, String category) {
    if (round <= 10) {
      return 'Master the basics of $category';
    } else if (round <= 50) {
      return 'Building momentum in $category';
    } else if (round <= 150) {
      return 'Expert level $category challenges';
    } else if (round <= 350) {
      return 'Ultimate $category mastery';
    } else {
      return 'Legendary $category questions';
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

    // Unlock next round
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

