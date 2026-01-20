import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import 'question_tracker_service.dart';

/// Education Question Bank
/// Supports questions organized by:
/// - School System: US, UK, General
/// - Grade Level: Grade 5-12 (US), Year 5-12 (UK), Grade 5-12 (General)
/// - Subject: Math, Science, English, History, Geography
/// - Target: 500 questions per subject per grade per system
class EducationQuestionBank {
  static final Random _random = Random();
  static List<Question>? _cachedQuestions;
  static bool _isInitialized = false;
  
  // Education subjects
  static const List<String> educationSubjects = [
    'Math',
    'Science',
    'English',
    'History',
    'Geography',
  ];
  
  /// Initialize and load education questions from JSON
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('📚 EducationQuestionBank already initialized with ${_cachedQuestions?.length ?? 0} questions');
      if (_cachedQuestions != null && _cachedQuestions!.isNotEmpty) {
        // Debug: Show distribution of grade levels
        final gradeCounts = <String, int>{};
        for (final q in _cachedQuestions!.take(1000)) {
          if (q.gradeLevel != null) {
            gradeCounts[q.gradeLevel!] = (gradeCounts[q.gradeLevel!] ?? 0) + 1;
          }
        }
        debugPrint('📊 Sample grade level distribution: ${gradeCounts.entries.take(5).map((e) => '${e.key}: ${e.value}').join(", ")}');
      }
      return;
    }
    
    try {
      debugPrint('📚 Loading education questions from assets/questions/education_questions.json...');
      
      // First, verify the asset exists
      try {
        final manifestContent = await rootBundle.loadString('AssetManifest.json');
        final manifest = json.decode(manifestContent) as Map<String, dynamic>;
        final assetExists = manifest.containsKey('assets/questions/education_questions.json');
        debugPrint('📋 Asset manifest check: education_questions.json exists = $assetExists');
        if (!assetExists) {
          debugPrint('⚠️ Asset not found in manifest! Run: flutter clean && flutter pub get && flutter run');
        }
      } catch (e) {
        debugPrint('⚠️ Could not check asset manifest: $e');
      }
      
      final stopwatch = Stopwatch()..start();
      
      // Load from JSON file
      final String jsonString = await rootBundle.loadString('assets/questions/education_questions.json');
      debugPrint('📚 JSON string loaded (${jsonString.length} characters) in ${stopwatch.elapsedMilliseconds}ms');
      
      stopwatch.reset();
      final List<dynamic> jsonList = json.decode(jsonString);
      debugPrint('📚 JSON decoded (${jsonList.length} items) in ${stopwatch.elapsedMilliseconds}ms');
      
      stopwatch.reset();
      
      // Parse questions with error handling
      final parsedQuestions = <Question>[];
      int parseErrors = 0;
      for (int i = 0; i < jsonList.length; i++) {
        try {
          final question = Question.fromJson(jsonList[i] as Map<String, dynamic>);
          parsedQuestions.add(question);
        } catch (e) {
          parseErrors++;
          if (parseErrors <= 5) {
            debugPrint('⚠️ Error parsing question at index $i: $e');
          }
        }
      }
      
      _cachedQuestions = parsedQuestions;
      debugPrint('📚 Questions parsed (${_cachedQuestions!.length} questions, $parseErrors errors) in ${stopwatch.elapsedMilliseconds}ms');
      
      _isInitialized = true;
      debugPrint('✅ Loaded ${_cachedQuestions!.length} education questions from JSON');
      
      // Debug: Show distribution of grade levels (sample first to avoid performance issues)
      if (_cachedQuestions!.isNotEmpty) {
        final gradeCounts = <String, int>{};
        // Check first 10000 questions for distribution
        final sampleSize = _cachedQuestions!.length > 10000 ? 10000 : _cachedQuestions!.length;
        for (int i = 0; i < sampleSize; i++) {
          final q = _cachedQuestions![i];
          if (q.gradeLevel != null) {
            gradeCounts[q.gradeLevel!] = (gradeCounts[q.gradeLevel!] ?? 0) + 1;
          }
        }
        debugPrint('📊 Grade level distribution (sample of $sampleSize): ${gradeCounts.entries.map((e) => '${e.key}: ${e.value}').join(", ")}');
        
        // Specifically check for UK_YEAR_9 in the full list
        final ukYear9Count = _cachedQuestions!.where((q) => q.gradeLevel == 'UK_YEAR_9').length;
        debugPrint('📊 UK_YEAR_9 questions found: $ukYear9Count');
        
        // Also check a few sample questions to verify structure
        if (_cachedQuestions!.isNotEmpty) {
          final sample = _cachedQuestions!.first;
          debugPrint('📊 Sample question: id=${sample.id}, gradeLevel=${sample.gradeLevel}, category=${sample.category}, mode=${sample.mode}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading education_questions.json: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Check if it's a file not found error
      if (e.toString().contains('Unable to load asset') || e.toString().contains('not found')) {
        debugPrint('⚠️ Education questions file not found in assets');
      } else {
        debugPrint('⚠️ Error parsing education questions JSON - might be too large or corrupted');
      }
      
      // Don't set _isInitialized to true if we failed - allow retry
      _cachedQuestions = [];
      _isInitialized = false; // Allow retry on next call
      
      // Re-throw to let caller know initialization failed
      rethrow;
    }
  }
  
  /// Get questions for a specific grade, subject, and school system
  static Future<List<Question>> getQuestions({
    required String gradeLevel, // e.g., 'US_GRADE_6', 'UK_YEAR_7', 'GRADE_8'
    required String subject, // 'Math', 'Science', 'English', 'History', 'Geography'
    String? difficulty, // 'easy', 'medium', 'hard', 'very_hard' (optional filter)
    int count = 10,
  }) async {
    try {
      await initialize();
    } catch (e) {
      debugPrint('❌ Failed to initialize EducationQuestionBank: $e');
      return [];
    }
    
    if (_cachedQuestions == null || _cachedQuestions!.isEmpty) {
      debugPrint('⚠️ No education questions available after initialization');
      debugPrint('⚠️ _cachedQuestions is null: ${_cachedQuestions == null}');
      debugPrint('⚠️ _isInitialized: $_isInitialized');
      return [];
    }
    
    debugPrint('🔍 Filtering questions for grade: $gradeLevel, subject: $subject, difficulty: $difficulty');
    debugPrint('📊 Total cached questions: ${_cachedQuestions!.length}');
    
    // Debug: Check how many questions match just the grade level
    final gradeOnlyCount = _cachedQuestions!.where((q) => q.gradeLevel == gradeLevel).length;
    debugPrint('📊 Questions for grade $gradeLevel (any subject): $gradeOnlyCount');
    
    // Filter questions by grade level, subject, and optional difficulty
    var filteredQuestions = _cachedQuestions!.where((q) {
      // Match grade level (exact match)
      final gradeMatch = q.gradeLevel == gradeLevel;
      
      // Match subject (category)
      final subjectMatch = q.category == subject;
      
      // Match mode (should be EDUCATION_SCHOOL)
      final modeMatch = q.mode == 'EDUCATION_SCHOOL' || q.mode == null;
      
      // Match difficulty if specified (case-insensitive, trimmed)
      final difficultyMatch = difficulty == null || 
          q.difficulty.toLowerCase().trim() == difficulty.toLowerCase().trim();
      
      return gradeMatch && subjectMatch && modeMatch && difficultyMatch;
    }).toList();
    
    debugPrint('📊 Found ${filteredQuestions.length} questions matching all criteria (grade: $gradeLevel, subject: $subject, difficulty: $difficulty)');
    
    // If not enough questions, try without difficulty filter
    if (filteredQuestions.length < count && difficulty != null) {
      debugPrint('⚠️ Not enough questions with difficulty filter, trying without difficulty...');
      filteredQuestions = _cachedQuestions!.where((q) {
        return q.gradeLevel == gradeLevel && 
               q.category == subject && 
               (q.mode == 'EDUCATION_SCHOOL' || q.mode == null);
      }).toList();
      debugPrint('📊 Found ${filteredQuestions.length} questions without difficulty filter');
    }
    
    // If still not enough, try without subject filter
    if (filteredQuestions.length < count) {
      debugPrint('⚠️ Still not enough questions, trying any subject for this grade...');
      filteredQuestions = _cachedQuestions!.where((q) {
        return q.gradeLevel == gradeLevel && 
               (q.mode == 'EDUCATION_SCHOOL' || q.mode == null);
      }).toList();
      debugPrint('📊 Found ${filteredQuestions.length} questions for grade $gradeLevel (any subject)');
    }
    
    // Initialize question tracker and filter out used questions
    final tracker = QuestionTrackerService();
    await tracker.initialize();
    filteredQuestions = tracker.filterUsedQuestions(filteredQuestions, (q) => q.id);
    
    // Shuffle and return requested count
    filteredQuestions.shuffle(_random);
    
    // Ensure no duplicates by ID
    final uniqueQuestions = <String, Question>{};
    for (final q in filteredQuestions) {
      if (!uniqueQuestions.containsKey(q.id)) {
        uniqueQuestions[q.id] = q;
      }
    }
    final result = uniqueQuestions.values.take(count).toList();
    
    // Mark as used
    if (result.isNotEmpty) {
      tracker.markQuestionsAsUsed(result.map((q) => q.id).toList());
    }
    
    debugPrint('✅ Returning ${result.length} unique questions');
    return result;
  }
  
  /// Get questions for education campaign round
  /// Campaign rounds rotate through subjects and progress through grades
  /// IMPORTANT: Never falls back to different subjects - must match the round's subject
  static Future<List<Question>> getQuestionsForCampaignRound({
    required int roundNumber,
    required String gradeLevel,
    required String schoolSystem, // 'US', 'UK', 'GENERAL'
    int questionCount = 10,
  }) async {
    try {
      await initialize();
    } catch (e) {
      debugPrint('❌ Failed to initialize EducationQuestionBank in getQuestionsForCampaignRound: $e');
      return [];
    }
    
    if (_cachedQuestions == null || _cachedQuestions!.isEmpty) {
      debugPrint('⚠️ No cached questions available for campaign round');
      return [];
    }
    
    // Rotate through subjects
    final subjectIndex = (roundNumber - 1) % educationSubjects.length;
    final subject = educationSubjects[subjectIndex];
    
    // Determine difficulty based on round number
    final difficulty = _getDifficultyForRound(roundNumber);
    
    // Map campaign difficulty to question difficulty
    final mappedDifficulty = _mapCampaignDifficultyToQuestionDifficulty(difficulty);
    
    debugPrint('🎯 Campaign round $roundNumber: grade=$gradeLevel, subject=$subject, difficulty=$mappedDifficulty');
    
    // For campaign rounds, we MUST match the subject - no fallback to other subjects
    return getQuestionsForCampaign(
      gradeLevel: gradeLevel,
      subject: subject,
      difficulty: mappedDifficulty,
      count: questionCount,
    );
  }
  
  /// Get questions for campaign with strict subject matching (no subject fallback)
  static Future<List<Question>> getQuestionsForCampaign({
    required String gradeLevel,
    required String subject,
    String? difficulty,
    int count = 10,
  }) async {
    try {
      await initialize();
    } catch (e) {
      debugPrint('❌ Failed to initialize EducationQuestionBank in getQuestionsForCampaign: $e');
      return [];
    }
    
    if (_cachedQuestions == null || _cachedQuestions!.isEmpty) {
      debugPrint('⚠️ No cached questions available');
      return [];
    }
    
    // Filter questions by grade level, subject, and optional difficulty
    // IMPORTANT: Subject must match exactly - no fallback
    var filteredQuestions = _cachedQuestions!.where((q) {
      // Match grade level (exact match)
      final gradeMatch = q.gradeLevel == gradeLevel;
      
      // Match subject (category) - MUST match exactly for campaign rounds
      final subjectMatch = q.category == subject;
      
      // Match mode (should be EDUCATION_SCHOOL)
      final modeMatch = q.mode == 'EDUCATION_SCHOOL' || q.mode == null;
      
      // Match difficulty if specified (case-insensitive, trimmed)
      final difficultyMatch = difficulty == null || 
          q.difficulty.toLowerCase().trim() == difficulty.toLowerCase().trim();
      
      return gradeMatch && subjectMatch && modeMatch && difficultyMatch;
    }).toList();
    
    debugPrint('📊 Found ${filteredQuestions.length} questions matching all criteria (grade: $gradeLevel, subject: $subject, difficulty: $difficulty)');
    
    // If not enough questions, try without difficulty filter (but keep subject filter)
    if (filteredQuestions.length < count && difficulty != null) {
      debugPrint('⚠️ Not enough questions with difficulty filter, trying without difficulty (keeping subject: $subject)...');
      filteredQuestions = _cachedQuestions!.where((q) {
        return q.gradeLevel == gradeLevel && 
               q.category == subject && // Keep subject filter!
               (q.mode == 'EDUCATION_SCHOOL' || q.mode == null);
      }).toList();
      debugPrint('📊 Found ${filteredQuestions.length} questions without difficulty filter (subject: $subject)');
    }
    
    // DO NOT fall back to other subjects for campaign rounds
    // If we still don't have enough, return what we have (or empty if none)
    if (filteredQuestions.isEmpty) {
      debugPrint('⚠️ No questions found for grade=$gradeLevel, subject=$subject, difficulty=$difficulty');
      debugPrint('⚠️ Campaign round requires exact subject match - cannot use other subjects');
    }
    
    // Initialize question tracker and filter out used questions
    final tracker = QuestionTrackerService();
    await tracker.initialize();
    filteredQuestions = tracker.filterUsedQuestions(filteredQuestions, (q) => q.id);
    
    // Shuffle and return requested count
    filteredQuestions.shuffle(_random);
    return filteredQuestions.take(count).toList();
  }
  
  /// Map campaign difficulty string to question bank difficulty
  static String _mapCampaignDifficultyToQuestionDifficulty(String campaignDifficulty) {
    // Campaign uses "super_hard", questions use "very_hard"
    if (campaignDifficulty == 'super_hard') {
      return 'very_hard';
    }
    return campaignDifficulty; // easy, medium, hard stay the same
  }
  
  /// Get difficulty for campaign round
  /// Matches the mixed difficulty progression from EducationCampaignService
  static String _getDifficultyForRound(int roundNumber) {
    // Mixed difficulty progression: Easy -> Hard -> Medium -> Easy -> Hard -> Medium...
    // Pattern repeats every 6 rounds: Easy, Hard, Medium, Easy, Hard, Medium
    
    // First 50 rounds: Mix of Easy, Medium, Hard (no super hard)
    if (roundNumber <= 50) {
      final patternIndex = (roundNumber - 1) % 6;
      if (patternIndex == 0 || patternIndex == 3) return 'easy';
      if (patternIndex == 1 || patternIndex == 4) return 'hard';
      return 'medium'; // patternIndex == 2 or 5
    }
    
    // Rounds 51-150: Mix Easy, Medium, Hard with occasional Super Hard
    if (roundNumber <= 150) {
      final patternIndex = (roundNumber - 1) % 8;
      if (patternIndex == 0 || patternIndex == 4) return 'easy';
      if (patternIndex == 1 || patternIndex == 5) return 'hard';
      if (patternIndex == 2 || patternIndex == 6) return 'medium';
      return 'super_hard'; // patternIndex == 3 or 7 (will be mapped to very_hard)
    }
    
    // Rounds 151-300: More Super Hard, but still mixed
    if (roundNumber <= 300) {
      final patternIndex = (roundNumber - 1) % 10;
      if (patternIndex == 0 || patternIndex == 5) return 'easy';
      if (patternIndex == 1 || patternIndex == 6) return 'hard';
      if (patternIndex == 2 || patternIndex == 7) return 'medium';
      return 'super_hard'; // patternIndex == 3, 4, 8, or 9
    }
    
    // Rounds 301-500: Mostly Hard and Super Hard, with Easy breaks
    final patternIndex = (roundNumber - 1) % 12;
    if (patternIndex == 0 || patternIndex == 6) return 'easy';
    if (patternIndex == 1 || patternIndex == 2 || patternIndex == 7 || patternIndex == 8) {
      return 'hard';
    }
    if (patternIndex == 3 || patternIndex == 9) return 'medium';
    return 'super_hard'; // patternIndex == 4, 5, 10, or 11
  }
  
  /// Get questions for daily education challenge
  /// Uses day-based seed for consistency
  static Future<List<Question>> getDailyEducationChallengeQuestions({
    required String gradeLevel,
    int count = 10,
  }) async {
    await initialize();
    
    if (_cachedQuestions == null || _cachedQuestions!.isEmpty) {
      return [];
    }
    
    // Get day number for seed
    final prefs = await SharedPreferences.getInstance();
    final dayNumber = prefs.getInt('daily_challenge_day') ?? DateTime.now().day;
    
    // Filter questions for this grade level
    final gradeQuestions = _cachedQuestions!.where((q) {
      return q.gradeLevel == gradeLevel && 
             (q.mode == 'EDUCATION_SCHOOL' || q.mode == null) &&
             educationSubjects.contains(q.category);
    }).toList();
    
    if (gradeQuestions.isEmpty) {
      return [];
    }
    
    // Use day number as seed for consistent daily selection
    final dayRandom = Random(dayNumber);
    final shuffledQuestions = List<Question>.from(gradeQuestions);
    shuffledQuestions.shuffle(dayRandom);
    
    // Select balanced mix of subjects and difficulties
    final selectedQuestions = <Question>[];
    final usedIndices = <int>{};
    
    final difficultyTargets = [
      'easy', 'easy', 'medium', 'medium', 'medium', 'hard', 'hard', 'very_hard', 'medium', 'hard',
    ];
    
    for (var i = 0; i < count && selectedQuestions.length < count; i++) {
      final targetDifficulty = i < difficultyTargets.length 
          ? difficultyTargets[i] 
          : ['easy', 'medium', 'hard', 'very_hard'][dayRandom.nextInt(4)];
      
      // Try to find a question with target difficulty
      var found = false;
      for (var j = 0; j < shuffledQuestions.length && !found; j++) {
        if (!usedIndices.contains(j) && shuffledQuestions[j].difficulty == targetDifficulty) {
          selectedQuestions.add(shuffledQuestions[j]);
          usedIndices.add(j);
          found = true;
        }
      }
      
      // If not found, take any available question
      if (!found) {
        for (var j = 0; j < shuffledQuestions.length; j++) {
          if (!usedIndices.contains(j)) {
            selectedQuestions.add(shuffledQuestions[j]);
            usedIndices.add(j);
            break;
          }
        }
      }
    }
    
    return selectedQuestions.take(count).toList();
  }
  
  /// Get question count for a specific grade/subject combination
  static Future<int> getQuestionCount({
    required String gradeLevel,
    required String subject,
  }) async {
    await initialize();
    
    if (_cachedQuestions == null) return 0;
    
    return _cachedQuestions!.where((q) {
      return q.gradeLevel == gradeLevel && 
             q.category == subject &&
             (q.mode == 'EDUCATION_SCHOOL' || q.mode == null);
    }).length;
  }
  
  /// Get total question count for a grade level
  static Future<int> getTotalQuestionCountForGrade(String gradeLevel) async {
    await initialize();
    
    if (_cachedQuestions == null || _cachedQuestions!.isEmpty) {
      debugPrint('⚠️ No cached questions available for count check');
      debugPrint('⚠️ _isInitialized: $_isInitialized');
      debugPrint('⚠️ _cachedQuestions is null: ${_cachedQuestions == null}');
      return 0;
    }
    
    debugPrint('🔍 Searching for grade level: $gradeLevel');
    debugPrint('📊 Total cached questions: ${_cachedQuestions!.length}');
    
    // Check first few questions to see what grade levels we have
    final sampleGrades = _cachedQuestions!.take(100).map((q) => q.gradeLevel).where((g) => g != null).toSet().toList();
    debugPrint('📊 Sample grade levels in first 100 questions: ${sampleGrades.take(10).join(", ")}');
    
    // Try to find questions matching this grade level
    var matchingQuestions = <Question>[];
    for (final q in _cachedQuestions!) {
      if (q.gradeLevel == gradeLevel) {
        matchingQuestions.add(q);
      }
    }
    
    final count = matchingQuestions.length;
    debugPrint('📊 Found $count questions for $gradeLevel');
    
    // If still 0, check if there are any questions with similar grade levels
    if (count == 0) {
      final allGradeLevels = _cachedQuestions!.map((q) => q.gradeLevel).where((g) => g != null).toSet().toList();
      debugPrint('📊 All unique grade levels in cache: ${allGradeLevels.take(20).join(", ")}');
      
      // Check if the grade level exists but maybe with different casing or format
      final similarGrades = allGradeLevels.where((g) => g!.toLowerCase().contains(gradeLevel.toLowerCase().replaceAll('_', ''))).toList();
      if (similarGrades.isNotEmpty) {
        debugPrint('⚠️ Found similar grade levels: ${similarGrades.join(", ")}');
      }
    }
    
    return count;
  }
  
  /// Get question count by subject for a grade
  static Future<Map<String, int>> getQuestionCountBySubject(String gradeLevel) async {
    await initialize();
    
    final counts = <String, int>{};
    
    for (final subject in educationSubjects) {
      counts[subject] = await getQuestionCount(
        gradeLevel: gradeLevel,
        subject: subject,
      );
    }
    
    return counts;
  }
}

