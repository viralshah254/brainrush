import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Service to track questions used in rounds and sessions
/// Prevents question repetition within rounds and across sessions
class QuestionTrackerService {
  static final QuestionTrackerService _instance = QuestionTrackerService._internal();
  factory QuestionTrackerService() => _instance;
  QuestionTrackerService._internal();

  // Questions used in current session (in-memory, cleared on app restart)
  final Set<String> _sessionUsedQuestionIds = {};
  
  // Questions used across all sessions (persisted)
  final Set<String> _persistentUsedQuestionIds = {};
  
  bool _isInitialized = false;

  /// Initialize and load persistent used questions
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final usedJson = prefs.getString('used_question_ids');
      if (usedJson != null) {
        final List<dynamic> usedList = json.decode(usedJson);
        _persistentUsedQuestionIds.addAll(usedList.map((id) => id.toString()));
        debugPrint('📋 Loaded ${_persistentUsedQuestionIds.length} previously used question IDs');
      }
    } catch (e) {
      debugPrint('❌ Error loading used questions: $e');
    }
    
    _isInitialized = true;
  }

  /// Save persistent used questions
  Future<void> _savePersistentUsedQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('used_question_ids', json.encode(_persistentUsedQuestionIds.toList()));
    } catch (e) {
      debugPrint('❌ Error saving used questions: $e');
    }
  }

  /// Mark questions as used (for current round/session)
  void markQuestionsAsUsed(List<String> questionIds) {
    final newCount = questionIds.length;
    final beforeSession = _sessionUsedQuestionIds.length;
    final beforePersistent = _persistentUsedQuestionIds.length;
    
    _sessionUsedQuestionIds.addAll(questionIds);
    _persistentUsedQuestionIds.addAll(questionIds);
    
    final afterSession = _sessionUsedQuestionIds.length;
    final afterPersistent = _persistentUsedQuestionIds.length;
    
    _savePersistentUsedQuestions();
    
    debugPrint('📝 Marked ${questionIds.length} questions as used');
    debugPrint('   Session: $beforeSession → $afterSession (${afterSession - beforeSession} new)');
    debugPrint('   Persistent: $beforePersistent → $afterPersistent (${afterPersistent - beforePersistent} new)');
    debugPrint('   Sample IDs: ${questionIds.take(3).join(", ")}${questionIds.length > 3 ? "..." : ""}');
  }

  /// Mark a single question as used
  void markQuestionAsUsed(String questionId) {
    _sessionUsedQuestionIds.add(questionId);
    _persistentUsedQuestionIds.add(questionId);
    _savePersistentUsedQuestions();
  }

  /// Check if a question has been used
  bool isQuestionUsed(String questionId) {
    return _sessionUsedQuestionIds.contains(questionId) || 
           _persistentUsedQuestionIds.contains(questionId);
  }

  /// Filter out used questions from a list
  List<T> filterUsedQuestions<T>(List<T> questions, String Function(T) getId) {
    final beforeCount = questions.length;
    final filtered = questions.where((q) => !isQuestionUsed(getId(q))).toList();
    final afterCount = filtered.length;
    
    if (beforeCount != afterCount) {
      debugPrint('🔍 Filtered questions: $beforeCount → $afterCount (removed ${beforeCount - afterCount} used questions)');
    }
    
    return filtered;
  }

  /// Get questions that haven't been used
  List<T> getUnusedQuestions<T>(List<T> questions, String Function(T) getId) {
    return filterUsedQuestions(questions, getId);
  }

  /// Clear session used questions (but keep persistent ones)
  void clearSessionUsedQuestions() {
    _sessionUsedQuestionIds.clear();
    debugPrint('🔄 Cleared session used questions');
  }

  /// Reset all tracking (clear both session and persistent)
  Future<void> resetAll() async {
    _sessionUsedQuestionIds.clear();
    _persistentUsedQuestionIds.clear();
    await _savePersistentUsedQuestions();
    debugPrint('🔄 Reset all question tracking');
  }

  /// Get count of used questions
  int getUsedQuestionCount() {
    return _persistentUsedQuestionIds.length;
  }

  /// Get count of session-used questions
  int getSessionUsedQuestionCount() {
    return _sessionUsedQuestionIds.length;
  }
}

