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
    // If instance exists but is disposed, create a new one
    if (_instances.containsKey(gradeLevel) && _instances[gradeLevel]!._isDisposed) {
      _instances.remove(gradeLevel);
    }
    
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
  
  bool _isDisposed = false;
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
  
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
  
  Future<void> initialize() async {
    if (_isDisposed) return; // Don't initialize if already disposed
    
    await _loadProgress();
    if (_isDisposed) return; // Check again after async operation
    
    if (_rounds.isEmpty) {
      _generateRounds();
      await _saveProgress();
      if (_isDisposed) return; // Check again after async operation
    }
    
    _safeNotifyListeners();
  }
  
  void _generateRounds() {
    _rounds.clear();
    
    // Generate 300+ rounds (30+ chapters of 10 rounds each)
    final totalRounds = 300;
    final roundsPerChapter = 10;
    
    for (int i = 1; i <= totalRounds; i++) {
      final chapterNumber = ((i - 1) ~/ roundsPerChapter) + 1;
      final roundInChapter = ((i - 1) % roundsPerChapter) + 1;
      
      // Get random difficulty for this chapter (ensures mix within each chapter)
      final difficulty = _getDifficultyForRoundInChapter(i, chapterNumber, roundInChapter);
      
      // Rotate through subjects
      final subjectIndex = (i - 1) % educationSubjects.length;
      final category = educationSubjects[subjectIndex];
      
      // Random question count between 10-15
      final questionCount = _getRandomQuestionCount(i);
      
      // Only round 1 is unlocked initially, rest unlock sequentially
      final isLocked = i > 1; // Only round 1 is unlocked initially
      
      _rounds.add(CampaignRound(
        roundNumber: i,
        title: _getRoundTitle(i, difficulty, category, chapterNumber),
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
  
  String _getRoundTitle(int round, RoundDifficulty difficulty, String subject, int chapterNumber) {
    if (round == 1) return '🎓 Welcome to $subject';
    
    // Chapter milestones
    if (round % 10 == 1 && round > 1) {
      return '📖 Chapter $chapterNumber - $subject';
    }
    
    // Special chapter completions
    if (round % 10 == 0) {
      return '🏆 Chapter $chapterNumber Complete';
    }
    
    // Special milestones
    if (round == 50) return '🔥 $subject Master';
    if (round == 100) return '💯 $subject Expert';
    if (round == 200) return '⚡ $subject Champion';
    if (round == 300) return '👑 $subject Legend';
    
    // Special rounds every 25
    if (round % 25 == 0) return '🌟 $subject Checkpoint $round';
    
    return '$subject Round $round';
  }

  String _getRoundDescription(int round, String category, int chapterNumber) {
    final gradeDisplay = _getGradeDisplayName();
    
    if (round <= 10) {
      return 'Chapter 1: Master $category basics for $gradeDisplay';
    } else if (round <= 50) {
      return 'Chapter $chapterNumber: Building $category skills for $gradeDisplay';
    } else if (round <= 150) {
      return 'Chapter $chapterNumber: Advanced $category challenges for $gradeDisplay';
    } else if (round <= 250) {
      return 'Chapter $chapterNumber: Expert $category mastery for $gradeDisplay';
    } else {
      return 'Chapter $chapterNumber: Legendary $category questions for $gradeDisplay';
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
    
    // Unlock rounds sequentially: Round N+1 unlocks only when Round N is completed
    // Always unlock just the next round
    if (index + 1 < _rounds.length) {
      _rounds[index + 1] = _rounds[index + 1].copyWith(isLocked: false);
    }
    
    // Update current round
    if (roundNumber >= _currentRound) {
      _currentRound = roundNumber + 1;
    }
    
    await _saveProgress();
    _safeNotifyListeners();
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
    _safeNotifyListeners();
  }
}

