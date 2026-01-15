import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/user_provider.dart';
import '../../services/ad_service.dart';
import '../../services/premium_service.dart';
import '../../services/question_service.dart';
import '../../services/campaign_service.dart';
import '../../services/expanded_question_bank.dart';
import '../../services/education_question_bank.dart';
import '../../theme/app_theme.dart';
import '../../models/question.dart';
import '../../models/campaign_round.dart';
import '../../widgets/ad_loading_dialog.dart';
import 'campaign_results_screen.dart';

/// Campaign Game Screen - Supports both normal and education campaigns
class CampaignGameScreen extends StatefulWidget {
  final CampaignRound round;
  final bool isEducationMode;
  final String? gradeLevel;

  const CampaignGameScreen({
    super.key,
    required this.round,
    this.isEducationMode = false,
    this.gradeLevel,
  });

  @override
  State<CampaignGameScreen> createState() => _CampaignGameScreenState();
}

class _CampaignGameScreenState extends State<CampaignGameScreen>
    with TickerProviderStateMixin {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedIndex;
  bool _answered = false;
  bool _isCorrect = false;
  int _score = 0;
  int _correctAnswers = 0;
  int _timeRemaining = 15;
  bool _doublePointsActive = false;
  bool _doublePointsUsedThisRound = false; // Track if 2x used this round
  Set<int> _triedWrongOptions = {}; // Track wrong attempts for retry highlighting
  bool _isLoading = true;
  String? _loadingError;

  late AnimationController _timerController;
  late Animation<double> _timerAnimation;
  late AnimationController _questionTransitionController;
  late Animation<Offset> _slideAnimation;

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
      if (status == AnimationStatus.completed && !_answered) {
        _handleAnswer(-1); // Timeout
      }
    });

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  Future<void> _loadQuestions() async {
    try {
      List<Question> questions;
      
      if (widget.isEducationMode && widget.gradeLevel != null) {
        // Use Education Question Bank for education campaign
        debugPrint('📚 Loading education questions for grade: ${widget.gradeLevel}, round: ${widget.round.roundNumber}');
        questions = await EducationQuestionBank.getQuestionsForCampaignRound(
          roundNumber: widget.round.roundNumber,
          gradeLevel: widget.gradeLevel!,
          schoolSystem: _getSchoolSystemFromGrade(widget.gradeLevel!),
        );
        debugPrint('✅ Loaded ${questions.length} education questions');
        
        if (questions.isEmpty) {
          debugPrint('⚠️ No education questions found with filters! Checking question bank...');
          // Try to get any questions for this grade level (any subject, any difficulty)
          final totalCount = await EducationQuestionBank.getTotalQuestionCountForGrade(widget.gradeLevel!);
          debugPrint('📊 Total questions for ${widget.gradeLevel}: $totalCount');
          
          if (totalCount > 0) {
            // Try again without difficulty filter
            debugPrint('🔄 Retrying with broader filters (any difficulty)...');
            questions = await EducationQuestionBank.getQuestions(
              gradeLevel: widget.gradeLevel!,
              subject: widget.round.category,
              difficulty: null, // Try without difficulty filter
              count: 10,
            );
            debugPrint('✅ Retry loaded ${questions.length} questions');
          }
          
          if (questions.isEmpty && totalCount > 0) {
            // Try with any subject
            debugPrint('🔄 Retrying with any subject...');
            questions = await EducationQuestionBank.getQuestions(
              gradeLevel: widget.gradeLevel!,
              subject: 'Math', // Try Math as fallback
              difficulty: null,
              count: 10,
            );
            debugPrint('✅ Retry with Math loaded ${questions.length} questions');
          }
          
          if (questions.isEmpty) {
            throw Exception('No education questions available for grade level: ${widget.gradeLevel}. Total in bank: $totalCount');
          }
        }
      } else {
        // Use Expanded Question Bank for normal campaign
        // Pass the round's category to ensure correct subject matching
        debugPrint('🎮 Loading questions for campaign round ${widget.round.roundNumber}, category: ${widget.round.category}');
        questions = await ExpandedQuestionBank.getQuestionsForRound(
          widget.round.roundNumber,
          category: widget.round.category, // Use the round's actual category
        );
        
        debugPrint('✅ Loaded ${questions.length} questions for campaign round ${widget.round.roundNumber}');
        if (questions.isNotEmpty) {
          debugPrint('📝 First question category: ${questions.first.category}, expected: ${widget.round.category}');
        }
      }

      if (questions.isEmpty) {
        throw Exception('No questions loaded');
      }

      // Remove duplicates by question ID to ensure no repeated questions
      final uniqueQuestions = <String, Question>{};
      for (final question in questions) {
        if (!uniqueQuestions.containsKey(question.id)) {
          uniqueQuestions[question.id] = question;
        }
      }
      final deduplicatedQuestions = uniqueQuestions.values.toList();
      
      // If we have fewer questions after deduplication, log a warning
      if (deduplicatedQuestions.length < questions.length) {
        debugPrint('⚠️ Removed ${questions.length - deduplicatedQuestions.length} duplicate questions');
      }
      
      // Ensure we have at least the required number of questions
      if (deduplicatedQuestions.length < widget.round.questionCount) {
        debugPrint('⚠️ Only ${deduplicatedQuestions.length} unique questions available, need ${widget.round.questionCount}');
      }
      
      // Take only the number of questions needed for this round
      final finalQuestions = deduplicatedQuestions.take(widget.round.questionCount).toList();

      setState(() {
        _questions = finalQuestions;
        _isLoading = false;
        _loadingError = null;
      });

      _questionTransitionController.forward();
      _timerController.forward(from: 0.0);
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading questions: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        _isLoading = false;
        _loadingError = e.toString();
      });
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading questions: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Navigate back after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _questionTransitionController.dispose();
    super.dispose();
  }
  
  /// Extract school system code from grade level
  String _getSchoolSystemFromGrade(String gradeLevel) {
    if (gradeLevel.startsWith('US_')) return 'US';
    if (gradeLevel.startsWith('UK_')) return 'UK';
    return 'GENERAL';
  }

  Future<void> _handleAnswer(int index) async {
    if (_answered) return;
    
    // Don't allow selecting a previously tried wrong answer
    if (_triedWrongOptions.contains(index)) return;

    _timerController.stop();

    final question = _questions[_currentQuestionIndex];
    final selectedOption = index == -1 ? '' : question.options[index];
    final isCorrect = selectedOption == question.correctAnswer;

    setState(() {
      _selectedIndex = index;
      _isCorrect = isCorrect;
    });

    final premiumService = context.read<PremiumService>();
    final adService = context.read<AdService>();

    if (!isCorrect) {
      // Add this wrong option to tried set
      _triedWrongOptions.add(index);
      
      // Deduct coins for wrong answer (5 coins)
      context.read<UserProvider>().deductCoins(5);
      
      if (!premiumService.isPremium) {
        // Show try again dialog (no double points here)
        final shouldTryAgain = await _showWrongAnswerDialog();
        
        if (shouldTryAgain == true) {
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
            // Reset for another try (but keep wrong options highlighted)
            setState(() {
              _selectedIndex = null;
              _answered = false;
              _isCorrect = false;
              _timeRemaining = 15;
            });
            _timerController.forward(from: 0.0);
            return;
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

    // If correct answer, offer double points for NEXT question (once per round)
    if (isCorrect && !_doublePointsUsedThisRound && !premiumService.isPremium) {
      final wantsDoublePoints = await _showDoublePointsDialog();
      if (wantsDoublePoints == true) {
        // Show loading dialog
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AdLoadingDialog(
            message: 'Loading ad for 2X points...',
          ),
        );

        // Try to load and show ad
        final watched = await adService.showTryAgainAd();
        
        // Close loading dialog
        if (!mounted) return;
        Navigator.of(context).pop();

        if (watched) {
          setState(() {
            _doublePointsActive = true;
            _doublePointsUsedThisRound = true; // Mark as used for this round
          });
        } else {
          // Show error dialog
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (context) => AdFailedDialog(
              message: 'Unable to load ad. 2X points not available.',
              onContinue: () => Navigator.of(context).pop(),
            ),
          );
        }
      }
    }

    // NOW mark as answered to show the explanation
    setState(() {
      _answered = true;
    });

    // Calculate score
    if (isCorrect) {
      _correctAnswers++;
      final timeBonus = _timeRemaining > 0 ? (_timeRemaining * 5) : 0;
      final baseScore = widget.round.difficulty.baseScore;
      final totalScore = baseScore + timeBonus;
      _score += _doublePointsActive ? totalScore * 2 : totalScore;
      
      // Reset double points after using it
      if (_doublePointsActive) {
        setState(() {
          _doublePointsActive = false;
        });
      }
    }

    // Mark question as answered
    await context.read<QuestionService>().markQuestionAsAnswered(
      question.id,
      widget.round.category,
    );

    // Show countdown before next question (only if not last question)
    if (_currentQuestionIndex < _questions.length - 1) {
      await _showCountdown();
    } else {
      // Wait 2 seconds before finishing round
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!mounted) {
      return;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      _nextQuestion();
    } else {
      _finishRound();
    }
  }

  Future<bool?> _showWrongAnswerDialog() async {
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

  Future<bool?> _showDoublePointsDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 2),
          ),
          title: Text(
            '✨ Boost Your Points!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 60),
              const SizedBox(height: 20),
              Text(
                'Watch an ad to get 2X points on your NEXT question!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '(Available once per round)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'No Thanks',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white60),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.star, color: AppTheme.darkBg),
              label: Text(
                '2X Points (Ad)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.darkBg),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
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

  Future<void> _showCountdown() async {
    if (!mounted) return;
    
    final countdownNotifier = ValueNotifier<int>(3);
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: ValueListenableBuilder<int>(
            valueListenable: countdownNotifier,
            builder: (context, countdown, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey(countdown),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryNeon.withValues(alpha: 0.9),
                        AppTheme.primaryNeon.withValues(alpha: 0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withValues(alpha: 0.8),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      countdown.toString(),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBg,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(overlayEntry);
    
    // Countdown: 3, 2, 1
    for (int i = 3; i > 0; i--) {
      if (!mounted) break;
      
      countdownNotifier.value = i;
      
      if (i > 1) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    
    // Remove overlay
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && overlayEntry.mounted) {
      overlayEntry.remove();
    }
    countdownNotifier.dispose();
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _selectedIndex = null;
      _answered = false;
      _isCorrect = false;
      _timeRemaining = 15;
      _doublePointsActive = false;
      _triedWrongOptions.clear(); // Clear for new question
    });
    _questionTransitionController.forward(from: 0.0);
    _timerController.forward(from: 0.0);
  }

  void _finishRound() {
    final maxScore = _questions.length * (widget.round.difficulty.baseScore + 75); // Max time bonus
    
    // Calculate stars earned
    final starsEarned = CampaignRound.calculateStars(_score, maxScore);
    
    // Complete the round
    context.read<CampaignService>().completeRound(
      roundNumber: widget.round.roundNumber,
      score: _score,
      maxScore: maxScore,
    );

    // Calculate coins reward based on stars and accuracy
    final accuracy = (_correctAnswers / _questions.length) * 100;
    int coinsEarned;
    
    if (starsEarned == 3) {
      // 3 stars: 100 coins (net +50 after 50 coin entry)
      coinsEarned = 100;
    } else if (starsEarned == 2) {
      // 2 stars: 50 coins (net 0 after 50 coin entry)
      coinsEarned = 50;
    } else if (starsEarned == 1 || accuracy >= 50) {
      // 1 star or 50%+ accuracy: 20 coins (net -30 after 50 coin entry)
      coinsEarned = 20;
    } else {
      // Below 50%: 20 coins (net -30 after 50 coin entry)
      coinsEarned = 20;
    }
    
    context.read<UserProvider>().addCoins(coinsEarned);

    // Navigate to results
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CampaignResultsScreen(
          round: widget.round,
          score: _score,
          correctAnswers: _correctAnswers,
          totalQuestions: _questions.length,
          coinsEarned: coinsEarned,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loadingError != null) ...[
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                Text(
                  'Error Loading Questions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _loadingError!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ] else ...[
                CircularProgressIndicator(color: widget.round.difficulty.color),
                const SizedBox(height: 20),
                Text(
                  widget.isEducationMode 
                      ? 'Loading 🎓 Welcome to ${widget.round.category}...'
                      : 'Loading ${widget.round.title}...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (widget.isEducationMode && widget.gradeLevel != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Grade: ${widget.gradeLevel}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          'Round ${widget.round.roundNumber} • ${_currentQuestionIndex + 1}/${_questions.length}',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.round.difficulty.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.round.difficulty.color),
            ),
            child: Row(
              children: [
                Icon(widget.round.difficulty.icon, size: 16, color: widget.round.difficulty.color),
                const SizedBox(width: 6),
                Text(
                  widget.round.difficulty.displayName,
                  style: TextStyle(
                    color: widget.round.difficulty.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score and multiplier
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: AppTheme.primaryNeon, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Score: $_score',
                          style: const TextStyle(
                            color: AppTheme.primaryNeon,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_doublePointsActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.flash_on, color: Colors.amber, size: 20),
                          SizedBox(width: 4),
                          Text(
                            '2X POINTS',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Timer
              AnimatedBuilder(
                animation: _timerAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: _timerAnimation.value,
                        backgroundColor: AppTheme.darkSurface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _timeRemaining > 5 ? AppTheme.primaryNeon : Colors.redAccent,
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _timeRemaining <= 5 ? Colors.redAccent : AppTheme.primaryNeon,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_timeRemaining s',
                            style: const TextStyle(
                              color: AppTheme.darkBg,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Question
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        question.text,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      // Options
                      ...question.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isTriedWrong = _triedWrongOptions.contains(index);
                        
                        Color? optionColor;
                        bool isDisabled = false;
                        
                        if (_answered) {
                          // Final state - show correct answer
                          if (index == question.correctIndex) {
                            optionColor = Colors.green;
                          } else if (index == _selectedIndex || isTriedWrong) {
                            optionColor = Colors.red;
                          } else {
                            optionColor = Colors.white30;
                          }
                        } else if (isTriedWrong) {
                          // During retry - highlight wrong attempts as disabled
                          optionColor = Colors.red.withOpacity(0.3);
                          isDisabled = true;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Opacity(
                            opacity: isDisabled ? 0.5 : 1.0,
                            child: GestureDetector(
                              onTap: _answered || isDisabled ? null : () => _handleAnswer(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: optionColor ?? AppTheme.darkCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: optionColor ?? AppTheme.primaryNeon.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          decoration: isDisabled ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                    if (isDisabled)
                                      const Icon(Icons.block, color: Colors.red, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 20),
                      // Explanation
                      if (_answered)
                        AnimatedOpacity(
                          opacity: _answered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accentNeon.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Explanation:',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.accentNeon,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  question.explanation,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}

