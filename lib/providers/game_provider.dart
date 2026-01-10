import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../services/question_bank.dart';

enum GameMode { practice, daily, league, multiplayer }

class GameProvider extends ChangeNotifier {
  final QuestionBank _questionBank = QuestionBank();
  
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  GameMode _mode = GameMode.practice;
  String _category = 'Math';
  
  // Getters
  List<Question> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get correctAnswers => _correctAnswers;
  Question? get currentQuestion => 
      _currentQuestionIndex < _questions.length 
          ? _questions[_currentQuestionIndex] 
          : null;
  bool get isGameOver => _currentQuestionIndex >= _questions.length;
  int get totalQuestions => _questions.length;
  GameMode get mode => _mode;

  void startGame({
    required String category,
    required int questionCount,
    GameMode mode = GameMode.practice,
  }) {
    _category = category;
    _mode = mode;
    _questions = _questionBank.getQuestions(
      category: category,
      count: questionCount,
    );
    _currentQuestionIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    notifyListeners();
  }

  void startMixedGame({
    required List<String> categories,
    required int questionCount,
    GameMode mode = GameMode.practice,
  }) {
    _mode = mode;
    _questions = _questionBank.getMixedQuestions(
      categories: categories,
      count: questionCount,
    );
    _currentQuestionIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    notifyListeners();
  }

  bool answerQuestion(int selectedIndex) {
    if (currentQuestion == null) return false;

    final isCorrect = selectedIndex == currentQuestion!.correctIndex;
    
    if (isCorrect) {
      _correctAnswers++;
      // Score based on mode
      final points = _mode == GameMode.daily ? 200 : 100;
      _score += points;
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

  double get accuracy => _questions.isEmpty 
      ? 0.0 
      : _correctAnswers / _questions.length;
}

