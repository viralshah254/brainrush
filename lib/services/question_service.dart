import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionService {
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;
  QuestionService._internal();

  List<Question> _allQuestions = [];
  final Map<String, Set<String>> _userAnsweredQuestions = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Load questions from JSON file
    await _loadQuestionsFromAssets();
    
    // Load user's answered questions
    await _loadUserAnsweredQuestions();
    
    _isInitialized = true;
  }

  Future<void> _loadQuestionsFromAssets() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/questions/questions.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _allQuestions = jsonList.map((json) => Question.fromJson(json)).toList();
      // ignore: avoid_print
      print('Loaded ${_allQuestions.length} questions from assets');
    } catch (e) {
      // ignore: avoid_print
      print('Error loading questions: $e');
      // If file doesn't exist yet, start with empty list
      _allQuestions = [];
    }
  }

  Future<void> _loadUserAnsweredQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? answeredJson = prefs.getString('answered_questions');
      if (answeredJson != null) {
        final Map<String, dynamic> data = json.decode(answeredJson);
        _userAnsweredQuestions.clear();
        data.forEach((category, questionIds) {
          _userAnsweredQuestions[category] = Set<String>.from(questionIds);
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading answered questions: $e');
    }
  }

  Future<void> _saveUserAnsweredQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, List<String>> data = {};
      _userAnsweredQuestions.forEach((category, questionIds) {
        data[category] = questionIds.toList();
      });
      await prefs.setString('answered_questions', json.encode(data));
    } catch (e) {
      // ignore: avoid_print
      print('Error saving answered questions: $e');
    }
  }

  /// Mark a question as answered by the user
  Future<void> markQuestionAsAnswered(String questionId, String category) async {
    if (!_userAnsweredQuestions.containsKey(category)) {
      _userAnsweredQuestions[category] = {};
    }
    _userAnsweredQuestions[category]!.add(questionId);
    await _saveUserAnsweredQuestions();
  }

  /// Get unanswered questions for a category
  List<Question> getUnansweredQuestions(String category, {int limit = 10}) {
    final categoryQuestions = _allQuestions
        .where((q) => q.category == category)
        .toList();

    final answeredIds = _userAnsweredQuestions[category] ?? {};
    
    // Filter out answered questions
    final unanswered = categoryQuestions
        .where((q) => !answeredIds.contains(q.id))
        .toList();

    // If user has answered all questions, reset for this category
    if (unanswered.isEmpty && categoryQuestions.isNotEmpty) {
      _userAnsweredQuestions[category] = {};
      _saveUserAnsweredQuestions();
      return categoryQuestions..shuffle();
    }

    // Shuffle and limit
    unanswered.shuffle();
    return unanswered.take(limit).toList();
  }

  /// Get mixed questions from all categories
  List<Question> getMixedQuestions({int limit = 10}) {
    final categories = ['Math', 'Science', 'History', 'Geography', 'Literature'];
    final List<Question> mixedQuestions = [];
    
    final questionsPerCategory = (limit / categories.length).ceil();
    
    for (final category in categories) {
      final categoryQuestions = getUnansweredQuestions(category, limit: questionsPerCategory);
      mixedQuestions.addAll(categoryQuestions);
    }
    
    mixedQuestions.shuffle();
    return mixedQuestions.take(limit).toList();
  }

  /// Get question bank stats
  Map<String, int> getQuestionStats() {
    final stats = <String, int>{};
    final categories = ['Math', 'Science', 'History', 'Geography', 'Literature'];
    
    for (final category in categories) {
      stats[category] = _allQuestions.where((q) => q.category == category).length;
    }
    
    stats['Total'] = _allQuestions.length;
    return stats;
  }

  /// Get user progress stats
  Map<String, dynamic> getUserProgress() {
    final progress = <String, dynamic>{};
    final categories = ['Math', 'Science', 'History', 'Geography', 'Literature'];
    
    for (final category in categories) {
      final total = _allQuestions.where((q) => q.category == category).length;
      final answered = _userAnsweredQuestions[category]?.length ?? 0;
      progress[category] = {
        'answered': answered,
        'total': total,
        'percentage': total > 0 ? (answered / total * 100).toStringAsFixed(1) : '0.0',
      };
    }
    
    return progress;
  }

  /// Reset user progress for a category
  Future<void> resetProgress(String category) async {
    _userAnsweredQuestions[category] = {};
    await _saveUserAnsweredQuestions();
  }

  /// Reset all progress
  Future<void> resetAllProgress() async {
    _userAnsweredQuestions.clear();
    await _saveUserAnsweredQuestions();
  }

  /// Add new questions (from AI generation or manual entry)
  Future<void> addQuestions(List<Question> questions) async {
    _allQuestions.addAll(questions);
    // In production, this would save to backend/database
    // For now, we'll keep them in memory
    // ignore: avoid_print
    print('Added ${questions.length} new questions. Total: ${_allQuestions.length}');
  }

  /// Check if we need more questions for a category
  bool needsMoreQuestions(String category, {int threshold = 50}) {
    final categoryQuestions = _allQuestions.where((q) => q.category == category).length;
    final answeredCount = _userAnsweredQuestions[category]?.length ?? 0;
    final remaining = categoryQuestions - answeredCount;
    return remaining < threshold;
  }
}

