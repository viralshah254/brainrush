import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../models/question.dart';
import '../../models/room.dart';
import '../../services/room_service.dart';
import '../../services/question_service.dart';
import '../../services/expanded_question_bank.dart';
import '../../services/education_question_bank.dart';
import '../../providers/user_provider.dart';
import 'multiplayer_results_screen.dart';

/// Multiplayer game screen with 3 rounds, 10 questions per round
/// Each round gets different questions from the question bank
class MultiplayerGameScreen extends StatefulWidget {
  final Room room;
  final String? roomCode;

  const MultiplayerGameScreen({
    super.key,
    required this.room,
    this.roomCode,
  });

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen>
    with TickerProviderStateMixin {
  final QuestionService _questionService = QuestionService();
  final Random _random = Random();
  
  // Round management
  int _currentRound = 1;
  final int _totalRounds = 3;
  final int _questionsPerRound = 10;
  
  // Current round questions
  List<Question> _currentRoundQuestions = [];
  int _currentQuestionIndex = 0;
  Set<String> _usedQuestionIds = {}; // Track questions used across all rounds
  
  // Game state
  int? _selectedIndex;
  bool _answered = false;
  bool _isCorrect = false; // Track if current answer is correct
  int _timeRemaining = 15;
  int _score = 0;
  int _correctAnswers = 0;
  int _roundScore = 0;
  int _roundCorrectAnswers = 0;
  
  // Animations
  late AnimationController _timerController;
  late AnimationController _countdownController;
  late AnimationController _questionTransitionController;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = true;
  bool _showCountdown = false;
  String _countdownText = '3';

  @override
  void initState() {
    super.initState();
    
    _initializeAnimations();
    _loadRoundQuestions();
  }

  void _initializeAnimations() {
    _timerController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _timerController.addListener(() {
      setState(() {
        _timeRemaining = (15 * (1 - _timerController.value)).ceil();
      });
    });

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_answered) {
        _handleAnswer(-1); // Timeout
      }
    });

    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _questionTransitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionTransitionController,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Load questions for current round (ensuring no duplicates from previous rounds)
  Future<void> _loadRoundQuestions() async {
    setState(() {
      _isLoading = true;
      _currentQuestionIndex = 0;
      _roundScore = 0;
      _roundCorrectAnswers = 0;
    });

    try {
      // Get difficulty string
      final difficultyStr = _getDifficultyString();
      
      List<Question> allQuestions;
      
      // Use EducationQuestionBank if in education mode with grade level
      if (widget.room.isEducationMode && widget.room.gradeLevel != null) {
        // Map difficulty for education questions
        final mappedDifficulty = _mapDifficultyToQuestionBank(difficultyStr);
        
        // Load grade-specific questions from EducationQuestionBank
        allQuestions = await EducationQuestionBank.getQuestions(
          gradeLevel: widget.room.gradeLevel!,
          subject: widget.room.topic,
          difficulty: mappedDifficulty != 'random' ? mappedDifficulty : null,
          count: 100, // Get more than needed to filter out used ones
        );
      } else {
        // Use ExpandedQuestionBank for general mode
        final mappedDifficulty = _mapDifficultyToQuestionBank(difficultyStr);
        
        allQuestions = await ExpandedQuestionBank.getQuestionsBySubjectAndDifficulty(
          widget.room.topic,
          mappedDifficulty,
          count: 100, // Get more than needed to filter out used ones
        );
      }

      // Filter out questions already used in previous rounds
      final availableQuestions = allQuestions
          .where((q) => !_usedQuestionIds.contains(q.id))
          .toList();

      // Get mapped difficulty for filtering (if not random)
      final mappedDifficulty = _mapDifficultyToQuestionBank(difficultyStr);

      // If random difficulty, shuffle and pick random from all available
      if (widget.room.difficulty == GameDifficulty.random) {
        availableQuestions.shuffle(_random);
        _currentRoundQuestions = availableQuestions.take(_questionsPerRound).toList();
      } else {
        // Filter by difficulty - ensure exact match for education mode
        // In education mode, we want precise difficulty matching
        List<Question> difficultyQuestions;
        
        if (widget.room.isEducationMode) {
          // For education mode, strictly filter by difficulty
          // Normalize difficulty comparison (case-insensitive)
          difficultyQuestions = availableQuestions
              .where((q) => q.difficulty.toLowerCase().trim() == mappedDifficulty.toLowerCase().trim())
              .toList();
          
          debugPrint('🎯 Education mode: Found ${difficultyQuestions.length} questions with difficulty "$mappedDifficulty"');
          
          // If not enough questions of exact difficulty, try adjacent difficulties
          if (difficultyQuestions.length < _questionsPerRound) {
            debugPrint('⚠️ Not enough $mappedDifficulty questions, trying adjacent difficulties...');
            
            // Get adjacent difficulty levels
            List<String> adjacentDifficulties = [];
            switch (mappedDifficulty) {
              case 'easy':
                adjacentDifficulties = ['medium'];
                break;
              case 'medium':
                adjacentDifficulties = ['easy', 'hard'];
                break;
              case 'hard':
                adjacentDifficulties = ['medium', 'very_hard'];
                break;
              case 'very_hard':
                adjacentDifficulties = ['hard'];
                break;
            }
            
            // Add questions from adjacent difficulties
            for (final adjDiff in adjacentDifficulties) {
              if (difficultyQuestions.length >= _questionsPerRound) break;
              
              final adjQuestions = availableQuestions
                  .where((q) => 
                      q.difficulty.toLowerCase().trim() == adjDiff &&
                      !difficultyQuestions.any((dq) => dq.id == q.id))
                  .toList();
              
              difficultyQuestions.addAll(adjQuestions);
              debugPrint('  Added ${adjQuestions.length} questions from "$adjDiff" difficulty');
            }
          }
        } else {
          // For general mode, use existing logic
          difficultyQuestions = availableQuestions
              .where((q) => q.difficulty.toLowerCase() == mappedDifficulty)
              .toList();
          
          if (difficultyQuestions.length < _questionsPerRound) {
            // Not enough questions of this difficulty, mix with others
            final otherQuestions = availableQuestions
                .where((q) => q.difficulty.toLowerCase() != mappedDifficulty)
                .toList();
            difficultyQuestions.addAll(otherQuestions);
          }
        }
        
        // Shuffle and take the required number
        difficultyQuestions.shuffle(_random);
        _currentRoundQuestions = difficultyQuestions.take(_questionsPerRound).toList();
        
        debugPrint('✅ Selected ${_currentRoundQuestions.length} questions for round');
        if (_currentRoundQuestions.isNotEmpty) {
          final actualDifficulties = _currentRoundQuestions
              .map((q) => q.difficulty)
              .toSet()
              .toList();
          debugPrint('📊 Actual difficulties in round: ${actualDifficulties.join(", ")}');
        }
      }

      // Mark these questions as used
      for (final question in _currentRoundQuestions) {
        _usedQuestionIds.add(question.id);
      }

      // Track in QuestionService to prevent showing in other game modes
      for (final question in _currentRoundQuestions) {
        _questionService.markQuestionAsAnswered(question.id, widget.room.topic);
      }

      setState(() {
        _isLoading = false;
      });

      // Show countdown before starting round
      _showRoundCountdown();
    } catch (e) {
      debugPrint('❌ Error loading round questions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDifficultyString() {
    switch (widget.room.difficulty) {
      case GameDifficulty.easy:
        return 'easy';
      case GameDifficulty.medium:
        return 'medium';
      case GameDifficulty.hard:
        return 'hard';
      case GameDifficulty.extraHard:
        return 'very_hard'; // Map extra hard to very_hard
      case GameDifficulty.random:
        return 'random';
    }
  }

  String _mapDifficultyToQuestionBank(String difficulty) {
    // Map our difficulty names to question bank difficulty names
    // This ensures UI difficulty levels match the question bank format
    final normalized = difficulty.toLowerCase().trim();
    
    switch (normalized) {
      case 'easy':
        return 'easy';
      case 'medium':
        return 'medium';
      case 'hard':
        return 'hard';
      case 'extra hard':
      case 'extrahard':
      case 'very_hard':
      case 'very hard':
        return 'very_hard'; // Map all variations to very_hard
      case 'random':
        return 'random';
      default:
        debugPrint('⚠️ Unknown difficulty: "$difficulty", defaulting to medium');
        return 'medium'; // Default fallback
    }
  }

  /// Show countdown before round starts
  void _showRoundCountdown() {
    setState(() {
      _showCountdown = true;
      _countdownText = '3';
    });

    _countdownController.forward(from: 0.0);
    
    // Countdown: 3, 2, 1
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _countdownText = '2');
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _countdownText = '1');
    });
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _showCountdown = false;
        });
        _questionTransitionController.forward();
        _timerController.forward();
      }
    });
  }

  Future<void> _handleAnswer(int index) async {
    if (_answered) return;

    _timerController.stop();

    final timeBonus = _timeRemaining > 0 ? (_timeRemaining * 5) : 0;
    final currentQuestion = _currentRoundQuestions[_currentQuestionIndex];
    final isCorrect = index == currentQuestion.correctIndex;

    setState(() {
      _selectedIndex = index;
      _isCorrect = isCorrect;
      _answered = true;
    });

    if (isCorrect) {
      final questionScore = 100 + timeBonus;
      _roundScore += questionScore;
      _roundCorrectAnswers++;
      _score += questionScore;
      _correctAnswers++;
    }

    // Wait 2 seconds then move to next question or round
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    _currentQuestionIndex++;

    if (_currentQuestionIndex >= _currentRoundQuestions.length) {
      // Round complete
      await _handleRoundComplete();
    } else {
      // Next question in same round
      setState(() {
        _selectedIndex = null;
        _answered = false;
        _isCorrect = false;
        _timeRemaining = 15;
      });
      _questionTransitionController.forward(from: 0.0);
      _timerController.forward(from: 0.0);
    }
  }

  Future<void> _handleRoundComplete() async {
    // Update room score for this round
    if (widget.roomCode != null) {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.user;
      if (user != null) {
        await RoomService().updatePlayerScore(
          widget.roomCode!,
          user.id,
          _roundScore,
        );
      }
    }

    if (_currentRound < _totalRounds) {
      // Move to next round
      setState(() {
        _currentRound++;
        _currentQuestionIndex = 0;
        _selectedIndex = null;
        _answered = false;
        _isCorrect = false;
        _timeRemaining = 15;
        _roundScore = 0;
        _roundCorrectAnswers = 0;
      });
      
      // Load next round questions
      await _loadRoundQuestions();
    } else {
      // All rounds complete - show results
      await _showFinalResults();
    }
  }

  Future<void> _showFinalResults() async {
    // Update final score
    if (widget.roomCode != null) {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.user;
      if (user != null) {
        await RoomService().updatePlayerScore(
          widget.roomCode!,
          user.id,
          _score,
        );
      }
    }

    // Update user stats
    context.read<UserProvider>().updateStats(
      questionsAnswered: _totalRounds * _questionsPerRound,
      correctAnswers: _correctAnswers,
      score: _score,
    );

    // Get updated room
    final room = await RoomService().getRoom(widget.roomCode ?? '');
    if (room != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MultiplayerResultsScreen(
            room: room,
            myScore: _score,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _countdownController.dispose();
    _questionTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_showCountdown) {
      return Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Round $_currentRound',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _countdownController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_countdownController.value * 0.5),
                    child: Text(
                      _countdownText,
                      style: TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNeon,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuestionIndex >= _currentRoundQuestions.length) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = _currentRoundQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _currentRoundQuestions.length;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header with round info
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Round $_currentRound/$_totalRounds',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Question ${_currentQuestionIndex + 1}/$_questionsPerRound',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _timeRemaining <= 5
                          ? Colors.red.withOpacity(0.2)
                          : AppTheme.primaryNeon.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _timeRemaining <= 5
                            ? Colors.red
                            : AppTheme.primaryNeon,
                      ),
                    ),
                    child: Text(
                      '$_timeRemaining',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _timeRemaining <= 5
                            ? Colors.red
                            : AppTheme.primaryNeon,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryNeon,
                  ),
                ),
              ),
            ),

            // Question and options
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question text
                      Expanded(
                        child: Center(
                          child: Text(
                            question.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Options
                      ...question.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isSelected = _selectedIndex == index;
                        final isCorrectOption = index == question.correctIndex;
                        final wasSelectedWrong = isSelected && !_isCorrect;

                        Color? backgroundColor;
                        Color? borderColor;
                        Color? textColor = Colors.white;

                        if (_answered) {
                          if (isCorrectOption) {
                            backgroundColor = Colors.green.withOpacity(0.2);
                            borderColor = Colors.green;
                          } else if (wasSelectedWrong) {
                            backgroundColor = Colors.red.withOpacity(0.2);
                            borderColor = Colors.red;
                          }
                        } else if (isSelected) {
                          backgroundColor = AppTheme.primaryNeon.withOpacity(0.2);
                          borderColor = AppTheme.primaryNeon;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: _answered ? null : () => _handleAnswer(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: backgroundColor ?? AppTheme.darkCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor ?? Colors.white10,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: borderColor?.withOpacity(0.2) ??
                                          Colors.white10,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index), // A, B, C, D
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: borderColor ?? Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: textColor,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (_answered && isCorrectOption)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                  if (_answered && wasSelectedWrong)
                                    const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Round score
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                border: Border(
                  top: BorderSide(color: Colors.white10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Score', '$_roundScore'),
                  Container(width: 1, height: 30, color: Colors.white10),
                  _buildStatItem('Correct', '$_roundCorrectAnswers/$_questionsPerRound'),
                  Container(width: 1, height: 30, color: Colors.white10),
                  _buildStatItem('Total', '$_score'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNeon,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

