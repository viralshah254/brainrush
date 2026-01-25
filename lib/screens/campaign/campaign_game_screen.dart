import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/user_provider.dart';
import '../../services/ad_service.dart';
import '../../services/premium_service.dart';
import '../../services/question_service.dart';
import '../../services/campaign_service.dart';
import '../../services/education_campaign_service.dart';
import '../../services/expanded_question_bank.dart';
import '../../services/education_question_bank.dart';
import '../../services/question_tracker_service.dart';
import '../../services/api_service.dart';
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
  bool _showHint = false; // Track if hint is shown
  DateTime? _roundStartTime; // Track when round started for timeSpent calculation
  OverlayEntry? _loadingResultsOverlay; // Loading overlay for results
  bool _extraTimeUsed = false; // Track if extra time ad has been used for current question
  bool _fiftyFiftyUsed = false; // Track if 50/50 lifeline has been used for current question
  Set<int> _hiddenOptions = {}; // Track which options are hidden by 50/50
  bool _showWrongAnswerDialog = false; // Track if wrong answer dialog is showing
  bool _fiveSecondPromptShown = false; // Track if 5-second prompt has been shown for current question
  bool _isWatchingAd = false; // Track if user is currently watching an ad (prevents timeout)

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
          
          // Pause at 5 seconds and prompt for extra time (only if timer is at original 15s duration)
          if (_timeRemaining == 5 && 
              !_answered && 
              !_fiveSecondPromptShown && 
              !_extraTimeUsed &&
              currentDuration == 15) { // Only prompt if we're still on original 15s timer
            _fiveSecondPromptShown = true;
            _timerController.stop();
            _showFiveSecondPrompt();
          }
        });
      });

    _timerController.addStatusListener((status) {
      // Only trigger timeout if timer completed AND question not answered AND not watching ad
      if (status == AnimationStatus.completed && !_answered && !_isWatchingAd) {
        // Double check that timer actually reached 0 (not just paused)
        if (_timeRemaining <= 0) {
          _handleAnswer(-1); // Timeout
        }
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
    
    // Track round start time
    _roundStartTime = DateTime.now();
  }

  Future<void> _loadQuestions() async {
    try {
      List<Question> questions;
      
      if (widget.isEducationMode && widget.gradeLevel != null) {
        // Use Education Question Bank for education campaign
        // IMPORTANT: Use the round's actual category (subject) instead of calculating from round number
        debugPrint('📚 Loading education questions for grade: ${widget.gradeLevel}, round: ${widget.round.roundNumber}, subject: ${widget.round.category}');
        questions = await EducationQuestionBank.getQuestionsForCampaign(
          gradeLevel: widget.gradeLevel!,
          subject: widget.round.category, // Use the round's actual category/subject
          difficulty: _mapCampaignDifficultyToQuestionDifficulty(widget.round.difficulty.name),
          count: widget.round.questionCount,
        );
        debugPrint('✅ Loaded ${questions.length} education questions for subject: ${widget.round.category}');
        
        if (questions.isEmpty) {
          debugPrint('⚠️ No education questions found with filters! Checking question bank...');
          // Try to get any questions for this grade level (any subject, any difficulty)
          final totalCount = await EducationQuestionBank.getTotalQuestionCountForGrade(widget.gradeLevel!);
          debugPrint('📊 Total questions for ${widget.gradeLevel}: $totalCount');
          
          if (totalCount > 0) {
            // Try again without difficulty filter but keep the subject
            debugPrint('🔄 Retrying with broader filters (any difficulty, same subject: ${widget.round.category})...');
            questions = await EducationQuestionBank.getQuestions(
              gradeLevel: widget.gradeLevel!,
              subject: widget.round.category,
              difficulty: null, // Try without difficulty filter
              count: widget.round.questionCount,
            );
            debugPrint('✅ Retry loaded ${questions.length} questions');
            
            // If still not enough, try other subjects for this grade level
            if (questions.length < widget.round.questionCount) {
              debugPrint('🔄 Not enough questions for ${widget.round.category}, trying other subjects...');
              final allSubjects = ['Math', 'Science', 'English', 'History', 'Geography'];
              for (final subject in allSubjects) {
                if (subject == widget.round.category) continue; // Skip the original subject
                
                final subjectQuestions = await EducationQuestionBank.getQuestions(
                  gradeLevel: widget.gradeLevel!,
                  subject: subject,
                  difficulty: null,
                  count: widget.round.questionCount - questions.length,
                );
                
                if (subjectQuestions.isNotEmpty) {
                  debugPrint('✅ Found ${subjectQuestions.length} questions for $subject');
                  questions.addAll(subjectQuestions);
                  
                  // If we have enough now, break
                  if (questions.length >= widget.round.questionCount) {
                    break;
                  }
                }
              }
              
              // Take only what we need
              questions = questions.take(widget.round.questionCount).toList();
              debugPrint('✅ Total loaded after subject fallback: ${questions.length} questions');
            }
          }
          
          if (questions.isEmpty) {
            throw Exception('No education questions available for grade level: ${widget.gradeLevel}. Total in bank: $totalCount');
          }
        }
      } else {
        // Use Expanded Question Bank for normal campaign
        // Pass the round's category to ensure correct subject matching
        debugPrint('🎮 Loading questions for campaign round ${widget.round.roundNumber}, category: ${widget.round.category}, count: ${widget.round.questionCount}');
        questions = await ExpandedQuestionBank.getQuestionsForRound(
          widget.round.roundNumber,
          category: widget.round.category, // Use the round's actual category
          questionCount: widget.round.questionCount, // Use the round's question count (10-15)
        );
        
        debugPrint('✅ Loaded ${questions.length} questions for campaign round ${widget.round.roundNumber}');
        if (questions.isNotEmpty) {
          debugPrint('📝 First question category: ${questions.first.category}, expected: ${widget.round.category}');
        }
      }

      // If we have fewer questions than requested, that's okay - use what we have
      if (questions.isEmpty) {
        throw Exception('No questions loaded');
      }
      
      // Log if we have fewer questions than requested
      if (questions.length < widget.round.questionCount) {
        debugPrint('⚠️ Warning: Only ${questions.length} questions available, requested ${widget.round.questionCount}');
      }

      // Remove duplicates by question ID to ensure no repeated questions
      final uniqueQuestions = <String, Question>{};
      final seenIds = <String>{};
      int duplicateCount = 0;
      
      for (final question in questions) {
        if (seenIds.contains(question.id)) {
          duplicateCount++;
          debugPrint('⚠️ Found duplicate question ID: ${question.id}');
          continue; // Skip duplicate
        }
        seenIds.add(question.id);
        uniqueQuestions[question.id] = question;
      }
      
      final deduplicatedQuestions = uniqueQuestions.values.toList();
      
      // Mark questions as used immediately to prevent reuse
      if (deduplicatedQuestions.isNotEmpty) {
        final tracker = QuestionTrackerService();
        await tracker.initialize();
        final questionIds = deduplicatedQuestions.map((q) => q.id).toList();
        tracker.markQuestionsAsUsed(questionIds);
        debugPrint('✅ Marked ${questionIds.length} questions as used for round ${widget.round.roundNumber}');
      }
      
      // If we have fewer questions after deduplication, log a warning
      if (deduplicatedQuestions.length < questions.length) {
        debugPrint('❌ WARNING: Removed $duplicateCount duplicate questions from round ${widget.round.roundNumber}');
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
    _removeLoadingResultsOverlay();
    _timerController.dispose();
    _questionTransitionController.dispose();
    super.dispose();
  }
  
  /// Map campaign difficulty to question difficulty
  String _mapCampaignDifficultyToQuestionDifficulty(String campaignDifficulty) {
    // Campaign enum uses "superHard", questions use "very_hard"
    // Convert enum name to question bank format
    if (campaignDifficulty == 'superHard' || campaignDifficulty == 'super_hard') {
      return 'very_hard';
    }
    return campaignDifficulty; // easy, medium, hard stay the same
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
        setState(() {
          _showWrongAnswerDialog = true;
        });
        final shouldTryAgain = await _showWrongAnswerDialogMethod();
        setState(() {
          _showWrongAnswerDialog = false;
        });
        
        if (shouldTryAgain == true) {
          // Show loading dialog
          if (!mounted) return;
          bool dialogShown = false;
          
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const AdLoadingDialog(
                message: 'Loading ad...',
              ),
            );
            dialogShown = true;

            // Try to load and show ad with timeout
            final watched = await Future.any([
              adService.showTryAgainAd(),
              Future.delayed(const Duration(seconds: 15), () => false), // 15 second timeout
            ]);
            
            // Always close loading dialog
            if (mounted && dialogShown) {
              Navigator.of(context).pop();
              dialogShown = false;
            }

            if (watched) {
              // Reset for another try (but keep wrong options highlighted)
              setState(() {
                _selectedIndex = null;
                _answered = false;
                _isCorrect = false;
                _timeRemaining = 15;
              _extraTimeUsed = false; // Reset extra time for retry
              _fiftyFiftyUsed = false; // Reset 50/50 for retry
              _hiddenOptions.clear(); // Clear hidden options
              _fiveSecondPromptShown = false; // Reset 5-second prompt for retry
              _isWatchingAd = false; // Reset ad watching flag
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
          } catch (e) {
            debugPrint('❌ Error in try again ad: $e');
            // Ensure dialog is dismissed even on error
            if (mounted && dialogShown) {
              Navigator.of(context).pop();
            }
            if (mounted) {
              await showDialog(
                context: context,
                builder: (context) => AdFailedDialog(
                  message: 'Error loading ad. Please try again.',
                  onContinue: () => Navigator.of(context).pop(),
                ),
              );
            }
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
      
      if (!mounted) return;
      _nextQuestion();
    } else {
      // Show loading overlay while preparing results
      if (mounted) {
        _showLoadingResultsOverlay();
      }
      // Wait briefly to show loading message
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      // Finish round and navigate to results
      await _finishRound();
    }
  }

  Future<bool?> _showWrongAnswerDialogMethod() async {
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

  void _showLoadingResultsOverlay() {
    if (!mounted) return;
    
    // Remove any existing overlay first
    _removeLoadingResultsOverlay();
    
    _loadingResultsOverlay = OverlayEntry(
      opaque: false, // Allow navigation to work through overlay
      maintainState: false, // Don't maintain state when removed
      builder: (context) => IgnorePointer(
        ignoring: true, // Completely ignore pointer events
        child: Material(
          color: Colors.black.withValues(alpha: 0.85),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated loading spinner
                Container(
                  width: 80,
                  height: 80,
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
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.darkBg,
                      strokeWidth: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Loading message with icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: AppTheme.primaryNeon,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading Results...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: AppTheme.primaryNeon.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Calculating your score and unlocking next round',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    if (mounted) {
      Overlay.of(context).insert(_loadingResultsOverlay!);
    }
  }

  void _removeLoadingResultsOverlay() {
    if (_loadingResultsOverlay != null) {
      try {
        if (_loadingResultsOverlay!.mounted) {
          _loadingResultsOverlay!.remove();
          debugPrint('✅ Loading overlay removed');
        } else {
          debugPrint('⚠️ Loading overlay not mounted, already removed');
        }
      } catch (e) {
        // Overlay might already be removed
        debugPrint('⚠️ Error removing loading overlay: $e');
      }
      _loadingResultsOverlay = null;
    } else {
      debugPrint('⚠️ No loading overlay to remove');
    }
  }

  Future<void> _handleExtraTime() async {
    if (_extraTimeUsed || _answered) return; // Already used or question answered
    
    final premiumService = context.read<PremiumService>();
    if (premiumService.isPremium) {
      // Premium users get extra time without ads
      _addExtraTime();
      return;
    }
    
    // Pause the timer before showing ad
    _timerController.stop();
    
    // Mark that we're watching an ad (prevents timeout)
    setState(() {
      _isWatchingAd = true;
    });
    
    final adService = context.read<AdService>();
    
    // Show loading dialog
    if (!mounted) return;
    bool dialogShown = false;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AdLoadingDialog(
          message: 'Loading ad...',
        ),
      );
      dialogShown = true;

      // Try to show ad with timeout to prevent hanging
      final adShown = await Future.any([
        adService.showTryAgainAd(),
        Future.delayed(const Duration(seconds: 15), () => false), // 15 second timeout
      ]);
      
      // Always dismiss loading dialog
      if (mounted && dialogShown) {
        Navigator.of(context).pop();
        dialogShown = false;
      }
      
      // Mark that ad watching is complete
      setState(() {
        _isWatchingAd = false;
      });
      
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
      } else {
        // Resume timer if ad failed
        if (mounted && !_answered) {
          _timerController.forward();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load ad. Please try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in extra time ad: $e');
      // Mark that ad watching is complete
      setState(() {
        _isWatchingAd = false;
      });
      // Ensure dialog is dismissed even on error
      if (mounted && dialogShown) {
        Navigator.of(context).pop();
      }
      // Resume timer on error
      if (mounted && !_answered) {
        _timerController.forward();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading ad. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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

  Future<void> _handleFiftyFifty() async {
    if (_fiftyFiftyUsed || _answered) return; // Already used or question answered
    
    final premiumService = context.read<PremiumService>();
    if (premiumService.isPremium) {
      // Premium users get 50/50 without ads
      _applyFiftyFifty();
      return;
    }
    
    // Pause the timer before showing ad
    _timerController.stop();
    
    // Mark that we're watching an ad (prevents timeout)
    setState(() {
      _isWatchingAd = true;
    });
    
    final adService = context.read<AdService>();
    
    // Show loading dialog
    if (!mounted) return;
    bool dialogShown = false;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AdLoadingDialog(
          message: 'Loading ad...',
        ),
      );
      dialogShown = true;

      // Try to show ad with timeout to prevent hanging
      final adShown = await Future.any([
        adService.showTryAgainAd(),
        Future.delayed(const Duration(seconds: 15), () => false), // 15 second timeout
      ]);
      
      // Always dismiss loading dialog
      if (mounted && dialogShown) {
        Navigator.of(context).pop();
        dialogShown = false;
      }
      
      // Mark that ad watching is complete
      setState(() {
        _isWatchingAd = false;
      });
      
      if (adShown) {
        // Ad watched successfully - apply 50/50
        _applyFiftyFifty();
        
        // Resume timer after reward granted - continue from where it was paused
        if (mounted && !_answered) {
          _timerController.forward();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ 2 wrong answers removed!'),
              backgroundColor: Colors.purple,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Resume timer if ad failed - continue from where it was paused
        if (mounted && !_answered) {
          _timerController.forward();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load ad. Please try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in 50/50 ad: $e');
      // Mark that ad watching is complete
      setState(() {
        _isWatchingAd = false;
      });
      // Ensure dialog is dismissed even on error
      if (mounted && dialogShown) {
        Navigator.of(context).pop();
      }
      // Resume timer on error - continue from where it was paused
      if (mounted && !_answered) {
        _timerController.forward();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading ad. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _applyFiftyFifty() {
    if (_currentQuestionIndex >= _questions.length) return;
    final question = _questions[_currentQuestionIndex];

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

  Future<void> _showFiveSecondPrompt() async {
    if (!mounted || _answered) return;

    final premiumService = context.read<PremiumService>();
    if (premiumService.isPremium) {
      // Premium users get extra time automatically
      _addExtraTime();
      return;
    }

    final shouldAddTime = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 2),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_off, color: Colors.amber, size: 32),
              const SizedBox(width: 12),
              Text(
                'Time Running Out!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Text(
                  'Only 5 seconds left!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Watch a short ad to get +30 seconds and continue!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                // Resume timer
                if (mounted && !_answered) {
                  _timerController.forward();
                }
              },
              child: Text(
                'No Thanks',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white60,
                    ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.add_alarm, color: AppTheme.darkBg),
              label: Text(
                '+30s (Ad)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.darkBg,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldAddTime == true) {
      // Timer is already paused from the 5-second check
      // Mark that we're watching an ad (prevents timeout)
      setState(() {
        _isWatchingAd = true;
      });
      
      // Show loading dialog
      if (!mounted) return;
      bool dialogShown = false;
      
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AdLoadingDialog(
            message: 'Loading ad...',
          ),
        );
        dialogShown = true;

        final adService = context.read<AdService>();
        final adShown = await Future.any([
          adService.showTryAgainAd(),
          Future.delayed(const Duration(seconds: 15), () => false), // 15 second timeout
        ]);

        // Always dismiss loading dialog
        if (mounted && dialogShown) {
          Navigator.of(context).pop();
          dialogShown = false;
        }

        // Mark that ad watching is complete
        setState(() {
          _isWatchingAd = false;
        });

        if (adShown) {
          // Ad watched successfully - add extra time
          // Timer is at 5 seconds, adding 30 makes it 35 seconds total
          _addExtraTime();
          // Timer will resume automatically in _addExtraTime() via forward()
          // It will count down from 35 seconds
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ +30 seconds added! Timer continues from 35 seconds.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Resume timer if ad failed
          if (mounted && !_answered) {
            _timerController.forward();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to load ad. Timer resumed.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error in 5-second prompt ad: $e');
        // Mark that ad watching is complete
        setState(() {
          _isWatchingAd = false;
        });
        // Ensure dialog is dismissed even on error
        if (mounted && dialogShown) {
          Navigator.of(context).pop();
        }
        // Resume timer on error
        if (mounted && !_answered) {
          _timerController.forward();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error loading ad. Timer resumed.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Resume timer if user declined
      if (mounted && !_answered) {
        _timerController.forward();
      }
    }
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
      _extraTimeUsed = false; // Reset extra time for next question
      _fiftyFiftyUsed = false; // Reset 50/50 for next question
      _hiddenOptions.clear(); // Clear hidden options
      _fiveSecondPromptShown = false; // Reset 5-second prompt for next question
      _isWatchingAd = false; // Reset ad watching flag
    });
    _questionTransitionController.forward(from: 0.0);
    _timerController.forward(from: 0.0);
  }

  Future<void> _finishRound() async {
    final maxScore = _questions.length * (widget.round.difficulty.baseScore + 75); // Max time bonus
    
    // Calculate stars earned
    final starsEarned = CampaignRound.calculateStars(_score, maxScore);
    
    // Calculate time spent in seconds
    final timeSpent = _roundStartTime != null
        ? DateTime.now().difference(_roundStartTime!).inSeconds
        : 0;
    
    // Convert roundNumber to roundId (string)
    final roundId = widget.round.roundNumber.toString();
    
    // Complete the round locally first - this unlocks the next round immediately
    // Access the service BEFORE any navigation to ensure context is valid
    if (widget.isEducationMode && widget.gradeLevel != null) {
      // EducationCampaignService is provided at CampaignScreen level
      // Since CampaignGameScreen is pushed from CampaignScreen, it should have access
      try {
        final educationService = context.read<EducationCampaignService>();
        educationService.completeRound(
          roundNumber: widget.round.roundNumber,
          score: _score,
          maxScore: maxScore,
        );
        debugPrint('✅ Round completed in EducationCampaignService');
      } catch (e) {
        debugPrint('⚠️ Could not access EducationCampaignService: $e');
        // Try Provider.of as fallback
        try {
          final educationService = Provider.of<EducationCampaignService>(
            context,
            listen: false,
          );
          educationService.completeRound(
            roundNumber: widget.round.roundNumber,
            score: _score,
            maxScore: maxScore,
          );
          debugPrint('✅ Round completed in EducationCampaignService (via Provider.of)');
        } catch (e2) {
          debugPrint('⚠️ Could not access EducationCampaignService with Provider.of: $e2');
          debugPrint('⚠️ Round completion will be handled by backend');
        }
      }
    } else {
      // CampaignService is provided at app level, should always be available
      try {
        final campaignService = context.read<CampaignService>();
        campaignService.completeRound(
          roundNumber: widget.round.roundNumber,
          score: _score,
          maxScore: maxScore,
        );
        debugPrint('✅ Round completed in CampaignService');
      } catch (e) {
        debugPrint('⚠️ Could not access CampaignService: $e');
        // Try Provider.of as fallback
        try {
          final campaignService = Provider.of<CampaignService>(
            context,
            listen: false,
          );
          campaignService.completeRound(
            roundNumber: widget.round.roundNumber,
            score: _score,
            maxScore: maxScore,
          );
          debugPrint('✅ Round completed in CampaignService (via Provider.of)');
        } catch (e2) {
          debugPrint('⚠️ Could not access CampaignService with Provider.of: $e2');
          debugPrint('⚠️ Round completion will be handled by backend');
        }
      }
    }
    
    // Send scores to backend in background (non-blocking)
    // This ensures results screen opens immediately
    _sendRoundCompletionToBackend(roundId, timeSpent).catchError((e) {
      debugPrint('⚠️ Background save failed: $e');
    });

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

    // Navigate to results immediately - don't wait for backend
    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, cannot navigate');
      return;
    }
    
    // Remove overlay first - do this synchronously
    _removeLoadingResultsOverlay();
    
    // Small delay to ensure overlay removal is processed
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (!mounted) {
      debugPrint('⚠️ Widget not mounted after removing overlay');
      return;
    }
    
    debugPrint('🚀 Navigating to results screen (education: ${widget.isEducationMode}, grade: ${widget.gradeLevel})...');
    debugPrint('📊 Score: $_score, Correct: $_correctAnswers/${_questions.length}, Coins: $coinsEarned');
    
    try {
      // If education mode, we need to provide EducationCampaignService to CampaignResultsScreen
      if (widget.isEducationMode && widget.gradeLevel != null) {
        // Get the service from context (it should be available from CampaignGameScreen)
        EducationCampaignService? educationService;
        try {
          educationService = context.read<EducationCampaignService>();
        } catch (e) {
          debugPrint('⚠️ Could not read EducationCampaignService from context: $e');
          // Try Provider.of as fallback
          try {
            educationService = Provider.of<EducationCampaignService>(
              context,
              listen: false,
            );
          } catch (e2) {
            debugPrint('❌ Could not access EducationCampaignService: $e2');
          }
        }
        
        if (educationService != null) {
          // Wrap with provider
          final serviceToPass = educationService; // Non-null assertion since we checked
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider<EducationCampaignService>.value(
                value: serviceToPass,
                child: CampaignResultsScreen(
                  round: widget.round,
                  score: _score,
                  correctAnswers: _correctAnswers,
                  totalQuestions: _questions.length,
                  coinsEarned: coinsEarned,
                  isEducationMode: widget.isEducationMode,
                  gradeLevel: widget.gradeLevel,
                ),
              ),
            ),
          );
        } else {
          // Fallback: navigate without provider (will show error but won't crash)
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CampaignResultsScreen(
                round: widget.round,
                score: _score,
                correctAnswers: _correctAnswers,
                totalQuestions: _questions.length,
                coinsEarned: coinsEarned,
                isEducationMode: widget.isEducationMode,
                gradeLevel: widget.gradeLevel,
              ),
            ),
          );
        }
      } else {
        // Normal campaign mode - navigate directly
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CampaignResultsScreen(
              round: widget.round,
              score: _score,
              correctAnswers: _correctAnswers,
              totalQuestions: _questions.length,
              coinsEarned: coinsEarned,
              isEducationMode: widget.isEducationMode,
              gradeLevel: widget.gradeLevel,
            ),
          ),
        );
      }
      debugPrint('✅ Navigation to results screen completed');
    } catch (e, stackTrace) {
      debugPrint('❌ Error navigating to results: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // Fallback navigation - try with root navigator
      if (mounted) {
        try {
          // If education mode, try to get service and wrap
          if (widget.isEducationMode && widget.gradeLevel != null) {
            try {
              final fallbackService = context.read<EducationCampaignService>();
              await Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<EducationCampaignService>.value(
                    value: fallbackService,
                    child: CampaignResultsScreen(
                      round: widget.round,
                      score: _score,
                      correctAnswers: _correctAnswers,
                      totalQuestions: _questions.length,
                      coinsEarned: coinsEarned,
                      isEducationMode: widget.isEducationMode,
                      gradeLevel: widget.gradeLevel,
                    ),
                  ),
                ),
              );
            } catch (e3) {
              // Service not available, navigate without provider
              await Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => CampaignResultsScreen(
                    round: widget.round,
                    score: _score,
                    correctAnswers: _correctAnswers,
                    totalQuestions: _questions.length,
                    coinsEarned: coinsEarned,
                    isEducationMode: widget.isEducationMode,
                    gradeLevel: widget.gradeLevel,
                  ),
                ),
              );
            }
          } else {
            await Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CampaignResultsScreen(
                  round: widget.round,
                  score: _score,
                  correctAnswers: _correctAnswers,
                  totalQuestions: _questions.length,
                  coinsEarned: coinsEarned,
                  isEducationMode: widget.isEducationMode,
                  gradeLevel: widget.gradeLevel,
                ),
              ),
            );
          }
          debugPrint('✅ Fallback navigation with root navigator completed');
        } catch (e2) {
          debugPrint('❌ Fallback navigation also failed: $e2');
          // Last resort - try without await
          if (mounted) {
            if (widget.isEducationMode && widget.gradeLevel != null) {
              try {
                final lastResortService = context.read<EducationCampaignService>();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider<EducationCampaignService>.value(
                      value: lastResortService,
                      child: CampaignResultsScreen(
                        round: widget.round,
                        score: _score,
                        correctAnswers: _correctAnswers,
                        totalQuestions: _questions.length,
                        coinsEarned: coinsEarned,
                        isEducationMode: widget.isEducationMode,
                        gradeLevel: widget.gradeLevel,
                      ),
                    ),
                  ),
                );
              } catch (e4) {
                // Final fallback without provider
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => CampaignResultsScreen(
                      round: widget.round,
                      score: _score,
                      correctAnswers: _correctAnswers,
                      totalQuestions: _questions.length,
                      coinsEarned: coinsEarned,
                      isEducationMode: widget.isEducationMode,
                      gradeLevel: widget.gradeLevel,
                    ),
                  ),
                );
              }
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => CampaignResultsScreen(
                    round: widget.round,
                    score: _score,
                    correctAnswers: _correctAnswers,
                    totalQuestions: _questions.length,
                    coinsEarned: coinsEarned,
                    isEducationMode: widget.isEducationMode,
                    gradeLevel: widget.gradeLevel,
                  ),
                ),
              );
            }
          }
        }
      }
    }
  }
  
  /// Send round completion to backend in background (non-blocking)
  Future<void> _sendRoundCompletionToBackend(String roundId, int timeSpent) async {
    try {
      debugPrint('📤 Sending campaign round completion to backend (background)...');
      debugPrint('   Round ID: $roundId');
      debugPrint('   Score: $_score');
      debugPrint('   Correct Answers: $_correctAnswers');
      debugPrint('   Total Questions: ${_questions.length}');
      debugPrint('   Time Spent: ${timeSpent}s');
      
      final api = ApiService();
      await api.campaign.completeRound(
        roundId: roundId,
        score: _score,
        correctAnswers: _correctAnswers,
        totalQuestions: _questions.length,
        timeSpent: timeSpent,
      );
      
      debugPrint('✅ Campaign round completion saved to backend');
    } catch (e) {
      debugPrint('⚠️ Failed to save campaign round completion to backend: $e');
      // Silently fail - local completion is what matters
    }
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
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      // Question text with hint button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              question.text,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Hint button (keep hint button in question area)
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
                      const SizedBox(height: 30),
                      // Options
                      ...question.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isTriedWrong = _triedWrongOptions.contains(index);
                        
                        // Hide options removed by 50/50 (unless answered)
                        if (!_answered && _hiddenOptions.contains(index)) {
                          return const SizedBox.shrink();
                        }
                        
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
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
                                        if (_answered && index == question.correctIndex)
                                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                        if (_answered && index == _selectedIndex && index != question.correctIndex)
                                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                                      ],
                                    ),
                                    // Show whyWrong explanation when answered
                                    if (_answered && question.whyWrong != null && question.getWhyWrong(index) != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          question.getWhyWrong(index)!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: index == question.correctIndex
                                                ? Colors.green.withOpacity(0.9)
                                                : Colors.red.withOpacity(0.9),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
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
                                Row(
                                  children: [
                                    Icon(
                                      _isCorrect ? Icons.check_circle : Icons.info,
                                      color: _isCorrect ? Colors.green : Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isCorrect ? 'Correct!' : 'Not quite!',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: _isCorrect ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Use bestExplanation (prefers deepExplanation, falls back to shortExplanation or legacy explanation)
                                Text(
                                  question.bestExplanation,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                        ),
                    ],
                  ),
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
  ]),
        ),
      ),
      bottomNavigationBar: _buildLifelinesBar(),
    );
  }

  Widget _buildLifelinesBar() {
    if (_answered) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBg,
            AppTheme.darkBg.withOpacity(0.95),
            AppTheme.darkBg,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Extra Time Lifeline
            _buildLifelineButton(
              icon: Icons.add_alarm,
              label: '+30s',
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB347), Color(0xFFFF6B35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              isUsed: _extraTimeUsed,
              onTap: _handleExtraTime,
              tooltip: 'Get 30 extra seconds',
            ),
            // 50/50 Lifeline
            _buildLifelineButton(
              icon: Icons.cancel_outlined,
              label: '50:50',
              gradient: const LinearGradient(
                colors: [Color(0xFF9D4EDD), Color(0xFF7209B7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              isUsed: _fiftyFiftyUsed,
              onTap: _handleFiftyFifty,
              tooltip: 'Remove 2 wrong answers',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifelineButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required bool isUsed,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Tooltip(
          message: tooltip,
          child: GestureDetector(
            onTap: isUsed ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 60,
              decoration: BoxDecoration(
                gradient: isUsed
                    ? LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.3),
                          Colors.grey.withOpacity(0.2),
                        ],
                      )
                    : gradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUsed
                      ? Colors.grey.withOpacity(0.5)
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: isUsed
                    ? []
                    : [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isUsed ? Colors.grey : Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isUsed ? Colors.grey : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isUsed) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_circle,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

