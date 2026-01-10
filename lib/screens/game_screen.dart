import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../services/room_service.dart';
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

class _GameScreenState extends State<GameScreen> {
  int? _selectedIndex;
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startGame(
            category: widget.category,
            questionCount: widget.questionCount,
            mode: widget.mode,
          );
    });
  }

  void _handleAnswer(int index) {
    if (_answered) return;

    setState(() {
      _selectedIndex = index;
      _answered = true;
      _isCorrect = context.read<GameProvider>().answerQuestion(index);
    });

    // Wait 2 seconds then move to next question or results
    Future.delayed(const Duration(seconds: 2), () async {
      final gameProvider = context.read<GameProvider>();
      
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
            ),
          ),
        );
      } else {
        gameProvider.nextQuestion();
        setState(() {
          _selectedIndex = null;
          _answered = false;
          _isCorrect = false;
        });
      }
    });
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
                  // Progress
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

