import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/campaign_round.dart';
import '../models/app_mode.dart';

/// Education Campaign Service
/// Creates campaign rounds specific to a user's grade level and school system
/// Rotates through subjects (Math, Science, English, History, Geography)
/// Progresses through difficulty levels as rounds advance
class EducationCampaignService extends ChangeNotifier {
  static final Map<String, EducationCampaignService> _instances = {};
  
  // Create instance per grade level (to support multiple users/grade levels)
  factory EducationCampaignService({required String gradeLevel}) {
    if (!_instances.containsKey(gradeLevel)) {
      _instances[gradeLevel] = EducationCampaignService._internal(gradeLevel);
    }
    return _instances[gradeLevel]!;
  }
  
  EducationCampaignService._internal(this._gradeLevel);
  
  final String _gradeLevel; // e.g., 'US_GRADE_6', 'UK_YEAR_7', 'GRADE_8'
  
  List<CampaignRound> _rounds = [];
  int _currentRound = 1;
  int _totalStars = 0;
  
  List<CampaignRound> get rounds => _rounds;
  int get currentRound => _currentRound;
  int get totalStars => _totalStars;
  int get completedRounds => _rounds.where((r) => r.isCompleted).length;
  String get gradeLevel => _gradeLevel;
  
  // Education subjects
  static const List<String> educationSubjects = [
    'Math',
    'Science',
    'English',
    'History',
    'Geography',
  ];
  
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
    
    // Generate 500 rounds rotating through education subjects
    for (int i = 1; i <= 500; i++) {
      final difficulty = _getDifficultyForRound(i);
      // Rotate through subjects
      final subjectIndex = (i - 1) % educationSubjects.length;
      final category = educationSubjects[subjectIndex];
      final questionCount = 10; // Fixed 10 questions per round
      
      _rounds.add(CampaignRound(
        roundNumber: i,
        title: _getRoundTitle(i, difficulty, category),
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
    // Mixed difficulty progression: Easy -> Hard -> Medium -> Easy -> Hard -> Medium...
    // Pattern repeats every 6 rounds: Easy, Hard, Medium, Easy, Hard, Medium
    // This creates a varied experience with easy questions in between harder ones
    
    // First 50 rounds: Mix of Easy, Medium, Hard (no super hard)
    if (round <= 50) {
      final patternIndex = (round - 1) % 6;
      if (patternIndex == 0 || patternIndex == 3) return RoundDifficulty.easy;
      if (patternIndex == 1 || patternIndex == 4) return RoundDifficulty.hard;
      return RoundDifficulty.medium; // patternIndex == 2 or 5
    }
    
    // Rounds 51-150: Mix Easy, Medium, Hard with occasional Super Hard
    if (round <= 150) {
      final patternIndex = (round - 1) % 8;
      if (patternIndex == 0 || patternIndex == 4) return RoundDifficulty.easy;
      if (patternIndex == 1 || patternIndex == 5) return RoundDifficulty.hard;
      if (patternIndex == 2 || patternIndex == 6) return RoundDifficulty.medium;
      return RoundDifficulty.superHard; // patternIndex == 3 or 7
    }
    
    // Rounds 151-300: More Super Hard, but still mixed
    if (round <= 300) {
      final patternIndex = (round - 1) % 10;
      if (patternIndex == 0 || patternIndex == 5) return RoundDifficulty.easy;
      if (patternIndex == 1 || patternIndex == 6) return RoundDifficulty.hard;
      if (patternIndex == 2 || patternIndex == 7) return RoundDifficulty.medium;
      return RoundDifficulty.superHard; // patternIndex == 3, 4, 8, or 9
    }
    
    // Rounds 301-500: Mostly Hard and Super Hard, with Easy breaks
    final patternIndex = (round - 1) % 12;
    if (patternIndex == 0 || patternIndex == 6) return RoundDifficulty.easy;
    if (patternIndex == 1 || patternIndex == 2 || patternIndex == 7 || patternIndex == 8) {
      return RoundDifficulty.hard;
    }
    if (patternIndex == 3 || patternIndex == 9) return RoundDifficulty.medium;
    return RoundDifficulty.superHard; // patternIndex == 4, 5, 10, or 11
  }
  
  String _getRoundTitle(int round, RoundDifficulty difficulty, String subject) {
    if (round == 1) return '🎓 Welcome to $subject';
    if (round == 10) return '🏆 $subject Milestone';
    if (round == 50) return '🔥 $subject Master';
    if (round == 100) return '💯 $subject Expert';
    if (round == 250) return '⚡ $subject Champion';
    if (round == 500) return '👑 $subject Legend';
    
    // Special rounds every 25
    if (round % 25 == 0) return '🌟 $subject Checkpoint $round';
    
    return '$subject Round $round';
  }
  
  String _getRoundDescription(int round, String category) {
    final gradeDisplay = _getGradeDisplayName();
    
    if (round <= 10) {
      return 'Master $category basics for $gradeDisplay';
    } else if (round <= 50) {
      return 'Building $category skills for $gradeDisplay';
    } else if (round <= 150) {
      return 'Advanced $category challenges for $gradeDisplay';
    } else if (round <= 300) {
      return 'Expert $category mastery for $gradeDisplay';
    } else {
      return 'Legendary $category questions for $gradeDisplay';
    }
  }
  
  String _getGradeDisplayName() {
    final gradeLevel = GradeLevel.fromCode(_gradeLevel);
    return gradeLevel?.displayName ?? 'your grade';
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
    
    // Update total stars
    if (round.starsEarned == null || stars > round.starsEarned!) {
      _totalStars = _rounds.fold(0, (sum, r) => sum + (r.starsEarned ?? 0));
    }
    
    // Unlock next round
    if (index + 1 < _rounds.length) {
      _rounds[index + 1] = _rounds[index + 1].copyWith(isLocked: false);
    }
    
    // Update current round
    if (roundNumber >= _currentRound) {
      _currentRound = roundNumber + 1;
    }
    
    await _saveProgress();
    notifyListeners();
  }
  
  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'education_campaign_$_gradeLevel';
      
      final progressJson = prefs.getString(key);
      if (progressJson == null) {
        _currentRound = 1;
        _totalStars = 0;
        return;
      }
      
      final progress = json.decode(progressJson) as Map<String, dynamic>;
      _currentRound = progress['currentRound'] as int? ?? 1;
      _totalStars = progress['totalStars'] as int? ?? 0;
      
      // Load rounds data
      final roundsJson = prefs.getString('${key}_rounds');
      if (roundsJson != null) {
        final roundsList = json.decode(roundsJson) as List<dynamic>;
        _rounds = roundsList.map((r) => CampaignRound.fromJson(r as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('❌ Error loading education campaign progress: $e');
      _currentRound = 1;
      _totalStars = 0;
    }
  }
  
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'education_campaign_$_gradeLevel';
      
      // Save progress
      await prefs.setString(key, json.encode({
        'currentRound': _currentRound,
        'totalStars': _totalStars,
        'gradeLevel': _gradeLevel,
      }));
      
      // Save rounds
      final roundsJson = json.encode(_rounds.map((r) => r.toJson()).toList());
      await prefs.setString('${key}_rounds', roundsJson);
      
      debugPrint('💾 Saved education campaign progress for $_gradeLevel');
    } catch (e) {
      debugPrint('❌ Error saving education campaign progress: $e');
    }
  }
  
  void reset() {
    _rounds.clear();
    _currentRound = 1;
    _totalStars = 0;
    _generateRounds();
    _saveProgress();
    notifyListeners();
  }
}

