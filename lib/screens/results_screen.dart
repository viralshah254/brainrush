import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../services/retention_service.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';
import '../models/daily_quest.dart';
import '../widgets/out_of_coins_dialog.dart';
import '../widgets/ad_loading_dialog.dart';
import '../models/daily_reward.dart';

class ResultsScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final GameMode mode;
  final String category;

  const ResultsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    this.mode = GameMode.practice,
    this.category = 'Mixed',
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late ConfettiController _confettiController;
  late Animation<double> _scaleAnimation;
  late List<Animation<Offset>> _cardAnimations;
  bool _pointsDoubled = false;
  bool _coinsAlreadyAwarded = false;
  String? _gameSessionId;
  late AnimationController _coinAnimationController;
  late Animation<double> _coinScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Generate unique game session ID
    _gameSessionId = '${DateTime.now().millisecondsSinceEpoch}_${widget.score}_${widget.correctAnswers}';
    
    // Check if points were already doubled for this session
    _checkIfPointsAlreadyDoubled();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _coinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    _coinScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3).chain(
        CurveTween(curve: Curves.easeOut),
      ), weight: 0.5),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0).chain(
        CurveTween(curve: Curves.easeIn),
      ), weight: 0.5),
    ]).animate(_coinAnimationController);

    // Create staggered animations for stat cards (4 cards)
    _cardAnimations = List.generate(
      6,
      (index) => Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            index * 0.1,
            0.4 + (index * 0.1),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    // Start animations
    _scaleController.forward();
    _slideController.forward();

    // Show confetti if perfect score
    final isPerfect = widget.correctAnswers == widget.totalQuestions;
    if (isPerfect) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _confettiController.play();
      });
    }

    // Update user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUserData();
    });
  }

  Future<void> _updateUserData() async {
    if (_coinsAlreadyAwarded) return; // Prevent double awarding
    
    final userProvider = context.read<UserProvider>();
    final retentionService = context.read<RetentionService>();
    final coinsEarned = _calculateCoinsEarned();

    // Add coins
    userProvider.addCoins(coinsEarned);
    _coinsAlreadyAwarded = true;

    // Update streak if daily challenge
    if (widget.mode == GameMode.daily && widget.correctAnswers > 0) {
      userProvider.incrementStreak();
      
      // Add daily reward
      final todayReward = DailyReward.getTodaysReward();
      switch (todayReward.type) {
        case RewardType.coins:
          userProvider.addCoins(todayReward.amount);
          break;
        case RewardType.lives:
          // TODO: Implement lives system
          break;
        case RewardType.hints:
          // TODO: Implement hints system
          break;
        case RewardType.doubleXP:
        case RewardType.adFree:
          // TODO: Implement buffs system
          break;
      }
      
      // Update daily challenge quest
      final bonus1 = await retentionService.updateQuestProgress(QuestType.playDaily);
      if (bonus1 > 0) {
        userProvider.addCoins(bonus1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 All quests complete! +$bonus1 bonus coins!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
    
    // Update quest progress for all game modes
    final bonus2 = await retentionService.updateQuestProgress(QuestType.playGames);
    
    int bonus = 0;
    // Update correct answers quest
    if (widget.correctAnswers > 0) {
      bonus = await retentionService.updateQuestProgress(
        QuestType.correctAnswers,
        increment: widget.correctAnswers,
      );
    }
    
    // Update mode-specific quests
    if (widget.mode == GameMode.league) {
      final bonus3 = await retentionService.updateQuestProgress(QuestType.playLeague);
      if (bonus3 > bonus) bonus = bonus3;
    } else if (widget.mode == GameMode.multiplayer) {
      final bonus3 = await retentionService.updateQuestProgress(QuestType.playWithFriends);
      if (bonus3 > bonus) bonus = bonus3;
    }
    
    // Award the highest bonus (should be the same if all quests completed)
    final totalBonus = bonus2 > bonus ? bonus2 : bonus;
    if (totalBonus > 0 && mounted) {
      userProvider.addCoins(totalBonus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 All quests complete! +$totalBonus bonus coins!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    // Record game played for smart notifications
    userProvider.recordGamePlayed();
  }

  int _calculateCoinsEarned() {
    int baseCoins = _calculateBaseCoins();
    
    // Apply double points multiplier if ad was watched
    if (_pointsDoubled) {
      baseCoins *= 2;
    }
    
    return baseCoins;
  }
  
  Future<void> _doublePointsByWatchingAd() async {
    if (_pointsDoubled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Points already doubled for this game!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final premiumService = context.read<PremiumService>();
    if (premiumService.isPremium) {
      // Premium users get double points without ad
      await _applyDoublePoints();
      return;
    }
    
    final adService = context.read<AdService>();
    
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AdLoadingDialog(message: 'Loading ad...'),
    );
    
    // Show ad
    final watched = await adService.showRoundCompleteAd();
    
    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog
    
    if (watched) {
      await _applyDoublePoints();
      _showGoHomePrompt();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load ad. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _applyDoublePoints() async {
    if (_pointsDoubled) return;
    
    // Save to SharedPreferences
    await _savePointsDoubled();
    
    setState(() {
      _pointsDoubled = true;
    });
    
    // Award extra coins
    final userProvider = context.read<UserProvider>();
    final baseCoins = _calculateBaseCoins();
    final extraCoins = baseCoins; // Double = add same amount again
    
    // Animate coin addition
    _coinAnimationController.forward(from: 0);
    
    // Add coins with animation
    userProvider.addCoins(extraCoins);
    
    // Play confetti
    _confettiController.play();
    
    if (!mounted) return;
    
    // Show success dialog with animation
    _showDoublePointsSuccessDialog(extraCoins);
  }

  int _calculateBaseCoins() {
    int baseCoins = widget.score ~/ 10; // 10 points = 1 coin
    if (widget.mode == GameMode.daily) {
      baseCoins *= 2; // Double for daily
    } else if (widget.mode == GameMode.league) {
      baseCoins = (baseCoins * 1.5).round(); // 1.5x for league
    }
    return baseCoins;
  }

  void _showDoublePointsSuccessDialog(int extraCoins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.amber.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _coinScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _coinScaleAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade700, Colors.amber.shade400],
                        ),
                      ),
                      child: const Icon(
                        Icons.monetization_on,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                '🎉 Points Doubled!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '+$extraCoins coins added!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${context.read<UserProvider>().user?.coins ?? 0} coins',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: AppTheme.darkBg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoHomePrompt() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryNeon.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.home,
                  size: 48,
                  color: AppTheme.primaryNeon,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Great job!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Head back home to continue playing?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Stay Here'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNeon,
                          foregroundColor: AppTheme.darkBg,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Go Home'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _checkIfPointsAlreadyDoubled() async {
    if (_gameSessionId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final doubledSessionId = prefs.getString('last_doubled_points_session');
    
    if (doubledSessionId == _gameSessionId) {
      setState(() {
        _pointsDoubled = true;
      });
    }
  }

  Future<void> _savePointsDoubled() async {
    if (_gameSessionId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_doubled_points_session', _gameSessionId!);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _coinAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final accuracy = (widget.correctAnswers / widget.totalQuestions * 100).toStringAsFixed(1);
    final isPerfect = widget.correctAnswers == widget.totalQuestions;
    final coinsEarned = _calculateCoinsEarned();
    final performanceRating = _getPerformanceRating(double.parse(accuracy));

    // Check if user ran out of coins AFTER game ended
    // Only show popup if they're at 0 coins
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userProvider.isOutOfCoins && !userProvider.shouldShowOutOfCoinsDialog) {
        userProvider.triggerOutOfCoinsDialog();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && userProvider.shouldShowOutOfCoinsDialog) {
            userProvider.resetOutOfCoinsFlag();
            showOutOfCoinsDialog(context);
          }
        });
      } else if (userProvider.shouldShowOutOfCoinsDialog) {
        userProvider.resetOutOfCoinsFlag();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // Confetti for perfect score
          if (isPerfect)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2,
                maxBlastForce: 100,
                minBlastForce: 80,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.3,
                colors: const [
                  AppTheme.primaryNeon,
                  AppTheme.secondaryNeon,
                  AppTheme.accentNeon,
                  Colors.amber,
                ],
              ),
            ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with trophy/star (compact)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Icon(
                          isPerfect ? Icons.emoji_events : Icons.star,
                          size: 60,
                          color: isPerfect ? Colors.amber : AppTheme.primaryNeon,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPerfect ? '🎉 Perfect Score! 🎉' : performanceRating,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getModeTitle(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getModeColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _getModeColor()),
                          ),
                          child: Text(
                            widget.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getModeColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Call to Action Buttons (AT THE TOP)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Double Points Button (only show if not already doubled)
                      if (!_pointsDoubled)
                        SlideTransition(
                          position: _cardAnimations[0],
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.amber.shade700, Colors.amber.shade400],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _doublePointsByWatchingAd,
                              icon: const Text('📺', style: TextStyle(fontSize: 18)),
                              label: const Text(
                                '2X Points - Watch Ad',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: AppTheme.darkBg,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      Row(
                        children: [
                          Expanded(
                            child: SlideTransition(
                              position: _cardAnimations[1],
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  },
                                  icon: const Icon(Icons.home, size: 20),
                                  label: const Text(
                                    'Home',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryNeon,
                                    foregroundColor: AppTheme.darkBg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SlideTransition(
                              position: _cardAnimations[2],
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.replay, size: 20),
                                  label: const Text(
                                    'Play Again',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.primaryNeon, width: 2),
                                    foregroundColor: AppTheme.primaryNeon,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Scrollable stats section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Stats Grid (3x2) - Compact
                        SlideTransition(
                          position: _cardAnimations[3],
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Final Score',
                                  widget.score.toString(),
                                  Icons.stars,
                                  AppTheme.primaryNeon,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AnimatedBuilder(
                                  animation: _coinScaleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pointsDoubled ? _coinScaleAnimation.value : 1.0,
                                      child: _buildStatCard(
                                        'Coins Earned',
                                        '+$coinsEarned',
                                        Icons.monetization_on,
                                        Colors.amber,
                                        isDoubled: _pointsDoubled,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SlideTransition(
                          position: _cardAnimations[4],
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Correct',
                                  '${widget.correctAnswers}/${widget.totalQuestions}',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Accuracy',
                                  '$accuracy%',
                                  Icons.percent,
                                  _getAccuracyColor(double.parse(accuracy)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SlideTransition(
                          position: _cardAnimations[5],
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Wrong',
                                  '${widget.totalQuestions - widget.correctAnswers}',
                                  Icons.cancel,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Performance',
                                  _getPerformanceEmoji(double.parse(accuracy)),
                                  Icons.emoji_events,
                                  _getModeColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Daily Reward (if daily challenge) - Compact
                        if (widget.mode == GameMode.daily)
                          _buildDailyRewardCard(),
                        if (widget.mode == GameMode.daily)
                          const SizedBox(height: 16),

                        // Achievements/Messages (compact)
                        if (isPerfect || double.parse(accuracy) >= 80)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.celebration, color: Colors.green, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isPerfect
                                        ? '🎊 Flawless Victory!'
                                        : '⭐ Excellent work!',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getModeTitle() {
    switch (widget.mode) {
      case GameMode.daily:
        return '⚡ Daily Challenge Complete';
      case GameMode.practice:
        return '📚 Practice Session Complete';
      case GameMode.league:
        return '🏆 League Match Complete';
      case GameMode.multiplayer:
        return '👥 Multiplayer Game Complete';
      default:
        return 'Challenge Complete';
    }
  }

  Color _getModeColor() {
    switch (widget.mode) {
      case GameMode.daily:
        return AppTheme.warningNeon;
      case GameMode.practice:
        return AppTheme.accentNeon;
      case GameMode.league:
        return Colors.purple;
      case GameMode.multiplayer:
        return AppTheme.successNeon;
      default:
        return AppTheme.primaryNeon;
    }
  }

  String _getModeMultiplier() {
    switch (widget.mode) {
      case GameMode.daily:
        return '2x (Daily Challenge)';
      case GameMode.league:
        return '1.5x (League Match)';
      default:
        return '1x (Standard)';
    }
  }

  String _getPerformanceRating(double accuracy) {
    if (accuracy == 100) return 'Perfect!';
    if (accuracy >= 90) return 'Excellent!';
    if (accuracy >= 80) return 'Great Job!';
    if (accuracy >= 70) return 'Good Work!';
    if (accuracy >= 60) return 'Nice Try!';
    return 'Keep Practicing!';
  }

  String _getPerformanceEmoji(double accuracy) {
    if (accuracy == 100) return '🏆';
    if (accuracy >= 90) return '⭐';
    if (accuracy >= 80) return '💪';
    if (accuracy >= 70) return '👍';
    if (accuracy >= 60) return '📈';
    return '💡';
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 90) return Colors.green;
    if (accuracy >= 70) return Colors.blue;
    if (accuracy >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyRewardCard() {
    final todayReward = DailyReward.getTodaysReward();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[todayReward.dayOfWeek - 1];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.3),
            Colors.pink.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.5), width: 2),
      ),
      child: Row(
        children: [
          Text(
            todayReward.emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Reward!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dayName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  todayReward.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isDoubled = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
        if (isDoubled)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '2X',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
