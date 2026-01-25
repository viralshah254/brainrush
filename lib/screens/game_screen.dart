import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../services/room_service.dart';
import '../services/league_service.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';
import '../widgets/ad_loading_dialog.dart';
import 'results_screen.dart';
import 'multiplayer/multiplayer_results_screen.dart';
import 'leagues/league_results_screen.dart';

class GameScreen extends StatefulWidget {
  final String category;
  final int questionCount;
  final GameMode mode;
  final String? roomCode;
  final String? leagueId; // For league mode

  const GameScreen({
    super.key,
    required this.category,
    this.questionCount = 5,
    this.mode = GameMode.practice,
    this.roomCode,
    this.leagueId,
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
  bool _extraTimeUsed = false; // Track if extra time ad has been used for current question
  bool _showHint = false; // Track if hint is shown
  bool _fiftyFiftyUsed = false; // Track if 50/50 lifeline has been used for current question
  Set<int> _hiddenOptions = {}; // Track which options are hidden by 50/50
  bool _showWrongAnswerDialog = false; // Track if wrong answer dialog is showing

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
          // Calculate time remaining based on current timer duration and value
          // Timer animation: value goes from 0.0 (start) to 1.0 (end)
          // When value = 0.0: animation just started (full time remaining)
          // When value = 1.0: animation completed (no time remaining)
          // Formula: timeRemaining = duration * (1 - value)
          // When value = 0.0: timeRemaining = duration * (1 - 0) = duration (full time) ✓
          // When value = 1.0: timeRemaining = duration * (1 - 1) = 0 (no time) ✓
          final currentDuration = _timerController.duration?.inSeconds;
          if (currentDuration != null) {
            _timeRemaining = (currentDuration * (1 - _timerController.value)).ceil();
          }
          // If duration is null, keep the current _timeRemaining value (don't reset to 15)
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
              _extraTimeUsed = false; // Reset extra time for retry
              _fiftyFiftyUsed = false; // Reset 50/50 for retry
              _hiddenOptions.clear(); // Clear hidden options
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

    // Move to next question first to update the index
    gameProvider.nextQuestion();
    
    // Now check if game is over (after incrementing)
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

      // If league, update league score and show league results
      if (widget.mode == GameMode.league && widget.leagueId != null) {
        final leagueService = LeagueService();
        final user = context.read<UserProvider>().user;
        if (user != null) {
          // Update player score in league
          await leagueService.updatePlayerScore(
            widget.leagueId!,
            user.id,
            gameProvider.score,
          );
          
          // Get updated league data
          final league = await leagueService.getLeagueById(widget.leagueId!);
          if (league != null && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LeagueResultsScreen(
                  league: league,
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
      // Reset state for next question
      setState(() {
        _selectedIndex = null;
        _answered = false;
        _isCorrect = false;
        _timeRemaining = 15;
        _extraTimeUsed = false; // Reset extra time for next question
        _fiftyFiftyUsed = false; // Reset 50/50 for next question
        _hiddenOptions.clear(); // Clear hidden options
      });
      // Reset and start timer for next question
      _timerController.reset();
      _timerController.forward();
    }
  }

  Future<void> _handleExtraTime() async {
    if (_extraTimeUsed) return; // Already used for this question
    
    final premiumService = context.read<PremiumService>();
    if (premiumService.isPremium) {
      // Premium users get extra time without ads
      _addExtraTime();
      return;
    }
    
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

    // Try to show ad
    final adShown = await adService.showTryAgainAd();
    
    if (!mounted) return;
    
    // Dismiss loading dialog
    Navigator.of(context).pop();
    
    if (adShown) {
      // Ad watched successfully - add extra time
      _addExtraTime();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ +30 seconds added!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleFiftyFifty() async {
    if (_fiftyFiftyUsed || _answered) return; // Already used or question answered
    
    final premiumService = context.read<PremiumService>();
    if (premiumService.isPremium) {
      // Premium users get 50/50 without ads
      _applyFiftyFifty();
      return;
    }
    
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

    // Try to show ad
    final adShown = await adService.showTryAgainAd();
    
    if (!mounted) return;
    
    // Dismiss loading dialog
    Navigator.of(context).pop();
    
    if (adShown) {
      // Ad watched successfully - apply 50/50
      _applyFiftyFifty();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ 2 wrong answers removed!'),
            backgroundColor: Colors.purple,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _applyFiftyFifty() {
    final gameProvider = context.read<GameProvider>();
    final question = gameProvider.currentQuestion;
    if (question == null) return;

    // Get wrong answer indices (all except correct one)
    final wrongIndices = <int>[];
    for (int i = 0; i < question.options.length; i++) {
      if (i != question.correctIndex) {
        wrongIndices.add(i);
      }
    }

    // Randomly select 2 wrong answers to hide
    wrongIndices.shuffle();
    final toHide = wrongIndices.take(2).toSet();

    setState(() {
      _fiftyFiftyUsed = true;
      _hiddenOptions = toHide;
    });
  }
  
  void _addExtraTime() {
    if (_answered) return; // Don't add time if question already answered
    
    // Stop the timer first to prevent listener from interfering
    _timerController.stop();
    
    setState(() {
      _extraTimeUsed = true;
      
      // Get current time remaining - use the displayed value
      final currentTimeRemaining = _timeRemaining;
      final newTimeRemaining = currentTimeRemaining + 30;
      
      debugPrint('⏰ Adding extra time: $currentTimeRemaining + 30 = $newTimeRemaining seconds');
      
      // IMPORTANT: Set duration FIRST, then reset value
      // Extend the timer duration to accommodate the new time
      _timerController.duration = Duration(seconds: newTimeRemaining);
      
      // Reset the animation controller to start from the beginning (value = 0.0)
      // Timer formula: timeRemaining = duration * (1 - value)
      // When value = 0.0: timeRemaining = duration * (1 - 0) = duration (full time) ✓
      // When value = 1.0: timeRemaining = duration * (1 - 1) = 0 (no time) ✓
      _timerController.reset(); // This sets value to 0.0 and status to dismissed
      
      // Update the displayed time immediately (before listener recalculates)
      _timeRemaining = newTimeRemaining;
      
      debugPrint('⏰ Timer updated: duration=${_timerController.duration?.inSeconds}s, value=${_timerController.value}, timeRemaining=$newTimeRemaining');
    });
    
    // Resume timer - it will count down from newTimeRemaining to 0
    // The listener will update _timeRemaining as it counts down
    _timerController.forward();
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
                      Row(
                        children: [
                          // Extra Time Button (available before time runs out)
                          if (!_answered && !_extraTimeUsed && _timeRemaining > 0)
                            GestureDetector(
                              onTap: _handleExtraTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.amber, Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.add_alarm,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '+30s',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
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
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Score
                  Text(
                    'Score: ${gameProvider.score}',
                    style: const TextStyle(
                      color: AppTheme.primaryNeon,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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

                  // Question and Options with blur overlay
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            // Question
                            Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
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
                            // Lifelines row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 50/50 Button
                                if (!_answered && !_fiftyFiftyUsed)
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.purple, width: 1.5),
                                      ),
                                      child: const Text(
                                        '50:50',
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    onPressed: _handleFiftyFifty,
                                    tooltip: 'Remove 2 wrong answers (Watch Ad)',
                                  ),
                                // Hint button
                                if (!_answered && question.hint != null && question.hint!.isNotEmpty)
                                  IconButton(
                                    icon: Icon(
                                      _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
                                      color: AppTheme.accentNeon,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showHint = !_showHint;
                                      });
                                    },
                                    tooltip: 'Show hint',
                                  ),
                              ],
                            ),
                          ],
                        ),
                        // Learning Objective (if available)
                        if (question.learningObjective != null && question.learningObjective!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentNeon.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.school, size: 16, color: AppTheme.accentNeon),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      question.learningObjective!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.accentNeon.withOpacity(0.9),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Hint display
                        if (_showHint && question.hint != null && question.hint!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.accentNeon.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.accentNeon.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb, size: 20, color: AppTheme.accentNeon),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      question.hint!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.accentNeon,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                            // Options
                            Expanded(
                              child: ListView.builder(
                      itemCount: question.options.length,
                      itemBuilder: (context, index) {
                        // Hide options removed by 50/50 (unless answered)
                        if (!_answered && _hiddenOptions.contains(index)) {
                          return const SizedBox.shrink();
                        }

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                // Show whyWrong explanation when answered
                                if (_answered && question.whyWrong != null && question.getWhyWrong(index) != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 56),
                                    child: Text(
                                      question.getWhyWrong(index)!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isCorrectOption 
                                            ? Colors.green.withOpacity(0.9)
                                            : Colors.red.withOpacity(0.9),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                              ),
                            ),
                          ],
                        ),
                        // Blur overlay when wrong answer dialog is showing
                        if (_showWrongAnswerDialog)
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                      ],
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
                        border: Border.all(
                          color: (_isCorrect ? Colors.green : Colors.orange).withOpacity(0.3),
                        ),
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
                          const SizedBox(height: 12),
                          // Use bestExplanation (prefers deepExplanation, falls back to shortExplanation or legacy explanation)
                          Text(
                            question.bestExplanation,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          // Show question type if available
                          if (question.questionType != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNeon.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Type: ${question.questionType}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryNeon,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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

