import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../services/question_bank.dart';
import '../services/expanded_question_bank.dart';

enum GameMode { practice, daily, league, multiplayer }

/// Game Provider - Manages game state and question loading
class GameProvider extends ChangeNotifier {
  final QuestionBank _questionBank = QuestionBank();
  
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  GameMode _mode = GameMode.practice;
  String _category = 'Math';
  bool _isLoading = false;
  
  // Getters
  List<Question> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get correctAnswers => _correctAnswers;
  
  /// Loading state indicator - true when questions are being loaded
  bool get isLoading {
    return _isLoading;
  }
  Question? get currentQuestion => 
      _currentQuestionIndex < _questions.length 
          ? _questions[_currentQuestionIndex] 
          : null;
  bool get isGameOver => _currentQuestionIndex >= _questions.length;
  int get totalQuestions => _questions.length;
  GameMode get mode => _mode;

  Future<void> startGame({
    required String category,
    required int questionCount,
    GameMode mode = GameMode.practice,
  }) async {
    _category = category;
    _mode = mode;
    _isLoading = true;
    notifyListeners();
    
    try {
      if (mode == GameMode.daily) {
        // Use ExpandedQuestionBank for daily challenge with day-based seed
        _questions = await ExpandedQuestionBank.getDailyChallengeQuestions(count: questionCount);
      } else {
        // Use regular QuestionBank for other modes
        _questions = await _questionBank.getQuestions(
          category: category,
          count: questionCount,
        );
      }
      
      // Ensure no duplicates in final list
      _questions = _removeDuplicates(_questions);
      
      debugPrint('✅ Loaded ${_questions.length} unique questions for ${mode.toString()} mode');
    } catch (e) {
      debugPrint('❌ Error loading questions: $e');
      // Fallback to regular question bank
      _questions = await _questionBank.getQuestions(
        category: category,
        count: questionCount,
      );
      _questions = _removeDuplicates(_questions);
    } finally {
      _isLoading = false;
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      notifyListeners();
    }
  }

  Future<void> startMixedGame({
    required List<String> categories,
    required int questionCount,
    GameMode mode = GameMode.practice,
  }) async {
    _mode = mode;
    _isLoading = true;
    notifyListeners();
    
    try {
      if (mode == GameMode.daily) {
        // Use ExpandedQuestionBank for daily challenge
        _questions = await ExpandedQuestionBank.getDailyChallengeQuestions(count: questionCount);
      } else {
        // Use regular QuestionBank for other modes
        _questions = await _questionBank.getMixedQuestions(
          categories: categories,
          count: questionCount,
        );
      }
      
      // Ensure no duplicates in final list
      _questions = _removeDuplicates(_questions);
      
      debugPrint('✅ Loaded ${_questions.length} unique questions for mixed ${mode.toString()} mode');
    } catch (e) {
      debugPrint('❌ Error loading mixed questions: $e');
      // Fallback to regular question bank
      _questions = await _questionBank.getMixedQuestions(
        categories: categories,
        count: questionCount,
      );
      _questions = _removeDuplicates(_questions);
    } finally {
      _isLoading = false;
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      notifyListeners();
    }
  }

  bool answerQuestion(int selectedIndex, {int timeBonus = 0}) {
    if (currentQuestion == null) return false;

    final isCorrect = selectedIndex == currentQuestion!.correctIndex;
    
    if (isCorrect) {
      _correctAnswers++;
      // Base score based on mode
      int points = 100;
      if (_mode == GameMode.daily) {
        points = 200;
      } else if (_mode == GameMode.league) {
        points = 150;
      }
      
      // Add time bonus (fast answers get more points)
      _score += points + timeBonus;
    }

    return isCorrect;
  }

  void nextQuestion() {
    if (!isGameOver) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void reset() {
    _questions = [];
    _currentQuestionIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    notifyListeners();
  }

  /// Remove duplicate questions by ID
  List<Question> _removeDuplicates(List<Question> questions) {
    final seen = <String>{};
    final unique = <Question>[];
    
    for (final question in questions) {
      if (!seen.contains(question.id)) {
        seen.add(question.id);
        unique.add(question);
      }
    }
    
    if (unique.length != questions.length) {
      debugPrint('⚠️ Removed ${questions.length - unique.length} duplicate questions');
    }
    
    return unique;
  }

  double get accuracy => _questions.isEmpty 
      ? 0.0 
      : _correctAnswers / _questions.length;
}

