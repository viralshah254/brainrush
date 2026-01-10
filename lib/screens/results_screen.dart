import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
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

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

  void _updateUserData() {
    final userProvider = context.read<UserProvider>();
    final coinsEarned = _calculateCoinsEarned();

    // Add coins
    userProvider.addCoins(coinsEarned);

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
    }
  }

  int _calculateCoinsEarned() {
    int baseCoins = widget.score ~/ 10; // 10 points = 1 coin
    if (widget.mode == GameMode.daily) {
      baseCoins *= 2; // Double for daily
    } else if (widget.mode == GameMode.league) {
      baseCoins = (baseCoins * 1.5).round(); // 1.5x for league
    }
    return baseCoins;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = (widget.correctAnswers / widget.totalQuestions * 100).toStringAsFixed(1);
    final isPerfect = widget.correctAnswers == widget.totalQuestions;
    final coinsEarned = _calculateCoinsEarned();
    final performanceRating = _getPerformanceRating(double.parse(accuracy));

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Header with trophy/star
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Icon(
                          isPerfect ? Icons.emoji_events : Icons.star,
                          size: 100,
                          color: isPerfect ? Colors.amber : AppTheme.primaryNeon,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isPerfect ? '🎉 Perfect Score! 🎉' : performanceRating,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getModeTitle(),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getModeColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getModeColor()),
                          ),
                          child: Text(
                            widget.category,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getModeColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Grid (3x2)
                  SlideTransition(
                    position: _cardAnimations[0],
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
                          child: _buildStatCard(
                            'Coins Earned',
                            '+$coinsEarned',
                            Icons.monetization_on,
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SlideTransition(
                    position: _cardAnimations[1],
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
                    position: _cardAnimations[2],
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
                  const SizedBox(height: 24),
                  
                  // Daily Reward (if daily challenge)
                  if (widget.mode == GameMode.daily)
                    SlideTransition(
                      position: _cardAnimations[3],
                      child: _buildDailyRewardCard(),
                    ),
                  if (widget.mode == GameMode.daily)
                    const SizedBox(height: 24),

                  // Performance Summary
                  SlideTransition(
                    position: _cardAnimations[widget.mode == GameMode.daily ? 4 : 3],
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getModeColor().withOpacity(0.2),
                            _getModeColor().withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getModeColor().withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.analytics,
                                color: _getModeColor(),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Performance Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow('Points per Question', '${(widget.score / widget.totalQuestions).toStringAsFixed(1)} pts'),
                          const Divider(height: 20, color: Colors.white10),
                          _buildSummaryRow('Success Rate', '$accuracy%'),
                          const Divider(height: 20, color: Colors.white10),
                          _buildSummaryRow('Mode Multiplier', _getModeMultiplier()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Achievements/Messages
                  if (isPerfect || double.parse(accuracy) >= 80)
                    SlideTransition(
                      position: _cardAnimations[4],
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.celebration, color: Colors.green, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isPerfect
                                    ? '🎊 Flawless Victory! You answered everything correctly!'
                                    : '⭐ Excellent work! You\'re on fire!',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Buttons
                  SlideTransition(
                    position: _cardAnimations[5],
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            icon: const Icon(Icons.home),
                            label: const Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: 18,
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
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // This will go back to category selection
                            },
                            icon: const Icon(Icons.replay),
                            label: const Text(
                              'Play Again',
                              style: TextStyle(
                                fontSize: 18,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                todayReward.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Reward!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dayName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.darkBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              todayReward.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
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
    );
  }
}
