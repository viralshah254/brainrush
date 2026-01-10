import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../services/room_service.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';
import '../widgets/ad_loading_dialog.dart';
import 'results_screen.dart';
import 'multiplayer/multiplayer_results_screen.dart';

class GameScreen extends StatefulWidget {
  final String category;
  final int questionCount;
  final GameMode mode;
  final String? roomCode;

  const GameScreen({
    super.key,
    required this.category,
    this.questionCount = 5,
    this.mode = GameMode.practice,
    this.roomCode,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  int? _selectedIndex;
  bool _answered = false;
  bool _isCorrect = false;
  int _timeRemaining = 15; // 15 seconds per question
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;

  @override
  void initState() {
    super.initState();
    
    _timerController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _timerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_timerController)
      ..addListener(() {
        setState(() {
          _timeRemaining = (15 * (1 - _timerController.value)).ceil();
        });
      });

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Time's up! Auto-submit wrong answer
        if (!_answered) {
          _handleAnswer(-1); // -1 means timeout
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startGame(
            category: widget.category,
            questionCount: widget.questionCount,
            mode: widget.mode,
          );
      _timerController.forward();
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _handleAnswer(int index) async {
    if (_answered) return;

    // Stop the timer
    _timerController.stop();

    // Calculate time bonus (more time remaining = more bonus)
    final timeBonus = _timeRemaining > 0 ? (_timeRemaining * 5) : 0;

    final gameProvider = context.read<GameProvider>();
    final isCorrect = gameProvider.answerQuestion(index, timeBonus: timeBonus);

    setState(() {
      _selectedIndex = index;
      _isCorrect = isCorrect;
    });

    // If answer is WRONG, show Try Again dialog BEFORE showing correct answer
    if (!isCorrect) {
      final premiumService = context.read<PremiumService>();
      
      if (!premiumService.isPremium) {
        // Show try again dialog
        final shouldTryAgain = await _showTryAgainDialog();
        
        if (shouldTryAgain == true) {
          // User wants to try again - show ad
          final adService = context.read<AdService>();
          
          // Show loading dialog
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AdLoadingDialog(
              message: 'Loading ad...',
            ),
          );

          // Try to load and show ad
          final watched = await adService.showTryAgainAd();
          
          // Close loading dialog
          if (!mounted) return;
          Navigator.of(context).pop();
          
          if (watched) {
            // Reset for another try
            setState(() {
              _selectedIndex = null;
              _answered = false;
              _isCorrect = false;
              _timeRemaining = 15;
            });
            _timerController.forward(from: 0.0);
            return; // Exit early, don't move to next question
          } else {
            // Show error dialog
            if (!mounted) return;
            await showDialog(
              context: context,
              builder: (context) => AdFailedDialog(
                message: 'Unable to load ad at this time.',
                onContinue: () => Navigator.of(context).pop(),
              ),
            );
          }
        }
      }
    }

    // Now mark as answered and show correct answer
    setState(() {
      _answered = true;
    });

    // Wait 2 seconds then move to next question or results
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    {
      if (gameProvider.isGameOver) {
        // Update user stats
        context.read<UserProvider>().updateStats(
              questionsAnswered: gameProvider.totalQuestions,
              correctAnswers: gameProvider.correctAnswers,
              score: gameProvider.score,
            );

        // If multiplayer, update room score and show multiplayer results
        if (widget.mode == GameMode.multiplayer && widget.roomCode != null) {
          final room = await RoomService().getRoom(widget.roomCode!);
          if (room != null) {
            await RoomService().updatePlayerScore(
              widget.roomCode!,
              context.read<UserProvider>().user!.id,
              gameProvider.score,
            );
            
            final updatedRoom = await RoomService().getRoom(widget.roomCode!);
            if (updatedRoom != null && mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiplayerResultsScreen(
                    room: updatedRoom,
                    myScore: gameProvider.score,
                  ),
                ),
              );
              return;
            }
          }
        }

        // Navigate to regular results
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              score: gameProvider.score,
              totalQuestions: gameProvider.totalQuestions,
              correctAnswers: gameProvider.correctAnswers,
              mode: widget.mode,
              category: widget.category,
            ),
          ),
        );
      } else {
        gameProvider.nextQuestion();
        setState(() {
          _selectedIndex = null;
          _answered = false;
          _isCorrect = false;
          _timeRemaining = 15;
        });
        // Reset and start timer for next question
        _timerController.reset();
        _timerController.forward();
      }
    }
  }

  Future<bool?> _showTryAgainDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: AppTheme.primaryNeon.withOpacity(0.5), width: 2),
          ),
          title: Text(
            '❌ Wrong Answer!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.errorNeon,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sentiment_dissatisfied, color: AppTheme.errorNeon, size: 60),
              const SizedBox(height: 20),
              Text(
                'Want to try again? Watch a short ad for another chance!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Skip',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white60),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.replay, color: AppTheme.darkBg),
              label: Text(
                'Try Again (Ad)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.darkBg),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == GameMode.daily ? 'Daily Challenge' : widget.category),
        backgroundColor: AppTheme.darkBg,
      ),
      backgroundColor: AppTheme.darkBg,
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, _) {
          final question = gameProvider.currentQuestion;
          
          if (question == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress and Timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${gameProvider.currentQuestionIndex + 1}/${gameProvider.totalQuestions}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      // Timer
                      AnimatedBuilder(
                        animation: _timerAnimation,
                        builder: (context, child) {
                          final isLowTime = _timeRemaining <= 5;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isLowTime
                                  ? Colors.red.withOpacity(0.2)
                                  : AppTheme.primaryNeon.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isLowTime ? Colors.red : AppTheme.primaryNeon,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  color: isLowTime ? Colors.red : AppTheme.primaryNeon,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_timeRemaining}s',
                                  style: TextStyle(
                                    color: isLowTime ? Colors.red : AppTheme.primaryNeon,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Text(
                        'Score: ${gameProvider.score}',
                        style: const TextStyle(
                          color: AppTheme.primaryNeon,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Timer Progress Bar
                  AnimatedBuilder(
                    animation: _timerAnimation,
                    builder: (context, child) {
                      final isLowTime = _timeRemaining <= 5;
                      return Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: _timerAnimation.value,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isLowTime
                                      ? [Colors.red, Colors.orange]
                                      : [AppTheme.primaryNeon, AppTheme.accentNeon],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLowTime ? Colors.red : AppTheme.primaryNeon)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Progress bar
                  LinearProgressIndicator(
                    value: (gameProvider.currentQuestionIndex + 1) / gameProvider.totalQuestions,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
                  ),
                  const SizedBox(height: 40),

                  // Question
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
                    ),
                    child: Text(
                      question.text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Options
                  Expanded(
                    child: ListView.builder(
                      itemCount: question.options.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedIndex == index;
                        final isCorrectOption = index == question.correctIndex;
                        
                        Color backgroundColor = AppTheme.darkCard;
                        Color borderColor = Colors.white24;
                        
                        if (_answered) {
                          if (isCorrectOption) {
                            backgroundColor = Colors.green.withOpacity(0.2);
                            borderColor = Colors.green;
                          } else if (isSelected) {
                            backgroundColor = Colors.red.withOpacity(0.2);
                            borderColor = Colors.red;
                          }
                        } else if (isSelected) {
                          borderColor = AppTheme.primaryNeon;
                        }

                        return GestureDetector(
                          onTap: () => _handleAnswer(index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: borderColor, width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index), // A, B, C, D
                                      style: TextStyle(
                                        color: borderColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (_answered && isCorrectOption)
                                  const Icon(Icons.check_circle, color: Colors.green),
                                if (_answered && isSelected && !isCorrectOption)
                                  const Icon(Icons.cancel, color: Colors.red),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Explanation (shown after answering)
                  if (_answered)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isCorrect 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isCorrect ? Icons.check_circle : Icons.info,
                                color: _isCorrect ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isCorrect ? 'Correct!' : 'Not quite!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isCorrect ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.explanation,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

