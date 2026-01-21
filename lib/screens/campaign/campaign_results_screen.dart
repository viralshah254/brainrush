import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../models/campaign_round.dart';
import '../../models/daily_quest.dart';
import '../../services/campaign_service.dart';
import '../../services/education_campaign_service.dart';
import '../../services/ad_service.dart';
import '../../services/premium_service.dart';
import '../../services/retention_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/ad_loading_dialog.dart';
import '../../widgets/out_of_coins_dialog.dart';
import 'campaign_screen.dart';
import 'campaign_game_screen.dart';

class CampaignResultsScreen extends StatefulWidget {
  final CampaignRound round;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int coinsEarned;
  final bool isEducationMode;
  final String? gradeLevel;

  const CampaignResultsScreen({
    super.key,
    required this.round,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.coinsEarned,
    this.isEducationMode = false,
    this.gradeLevel,
  });

  @override
  State<CampaignResultsScreen> createState() => _CampaignResultsScreenState();
}

class _CampaignResultsScreenState extends State<CampaignResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late ConfettiController _confettiController;
  late ConfettiController _leftFireworksController;
  late ConfettiController _rightFireworksController;
  late AnimationController _pulseController;
  late AnimationController _starsController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late List<Animation<Offset>> _cardAnimations;
  
  int _displayedStars = 0;
  int _earnedStars = 0;
  bool _coinsDoubled = false;
  static const int _entryCost = 50; // All rounds cost 50 coins to enter

  @override
  void initState() {
    super.initState();
    
    // Check if coins were already doubled for this round
    _checkIfCoinsAlreadyDoubled();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Multiple confetti controllers for fireworks effect
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _leftFireworksController = ConfettiController(duration: const Duration(seconds: 3));
    _rightFireworksController = ConfettiController(duration: const Duration(seconds: 3));
    
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final maxScore = widget.totalQuestions * (widget.round.difficulty.baseScore + 75);
    _earnedStars = CampaignRound.calculateStars(widget.score, maxScore);

    // Create staggered animations for stat cards
    _cardAnimations = List.generate(
      4,
      (index) {
        final start = index * 0.15;
        final end = (0.6 + (index * 0.15)).clamp(0.0, 1.0); // Clamp to prevent > 1.0
        return Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: Interval(
              start,
              end,
              curve: Curves.easeOutCubic,
            ),
          ),
        );
      },
    );

    _scaleController.forward();
    _slideController.forward();
    
    // Fireworks based on performance
    if (_earnedStars >= 2) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _confettiController.play();
        _leftFireworksController.play();
        _rightFireworksController.play();
      });
    }

    // Animate stars one by one
    _animateStars();
    
    // Update quest progress and auto-award bonus if all quests completed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final retentionService = context.read<RetentionService>();
      final userProvider = context.read<UserProvider>();
      
      final bonus1 = await retentionService.updateQuestProgress(QuestType.completeCampaign);
      final bonus2 = await retentionService.updateQuestProgress(QuestType.playGames);
      
      int bonus = 0;
      if (widget.correctAnswers > 0) {
        bonus = await retentionService.updateQuestProgress(
          QuestType.correctAnswers,
          increment: widget.correctAnswers,
        );
      }
      
      // Award the highest bonus (should be the same if all quests completed)
      final totalBonus = bonus1 > bonus2 ? bonus1 : (bonus2 > bonus ? bonus2 : bonus);
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
    });
  }

  void _animateStars() async {
    for (int i = 0; i < _earnedStars; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _displayedStars = i + 1;
        });
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    _leftFireworksController.dispose();
    _rightFireworksController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  Path drawStar(Size size) {
    double outerRadius = size.width / 2;
    double innerRadius = size.width / 4;
    Path path = Path();
    for (int i = 0; i < 5; i++) {
      double angle = (i * 2 * pi / 5) - (pi / 2);
      path.lineTo(outerRadius * cos(angle), outerRadius * sin(angle));
      angle += (pi / 5);
      path.lineTo(innerRadius * cos(angle), innerRadius * sin(angle));
    }
    path.close();
    return path;
  }

  Path drawCircle(Size size) {
    return Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final accuracy = (widget.correctAnswers / widget.totalQuestions * 100).toStringAsFixed(1);
    
    // Get next round based on mode
    CampaignRound? nextRound;
    if (widget.isEducationMode && widget.gradeLevel != null) {
      final educationService = context.watch<EducationCampaignService>();
      try {
        nextRound = educationService.rounds.firstWhere(
          (r) => r.roundNumber == widget.round.roundNumber + 1,
        );
        // Check if the round is not locked
        if (nextRound.isLocked) {
          nextRound = null;
        }
      } catch (e) {
        // Round doesn't exist
        nextRound = null;
      }
    } else {
      final campaignService = context.watch<CampaignService>();
      nextRound = campaignService.getRound(widget.round.roundNumber + 1);
    }

    // Check if user ran out of coins AFTER game ended
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
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  widget.round.difficulty.color.withValues(alpha: 0.1),
                  AppTheme.darkBg,
                  AppTheme.darkBg,
                ],
              ),
            ),
          ),

          // Fireworks - Center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 120,
              minBlastForce: 100,
              emissionFrequency: 0.03,
              numberOfParticles: 80,
              gravity: 0.2,
              colors: [
                widget.round.difficulty.color,
                AppTheme.primaryNeon,
                AppTheme.accentNeon,
                Colors.amber,
                Colors.pink,
                Colors.cyan,
              ],
              createParticlePath: drawStar,
            ),
          ),

          // Fireworks - Left
          Align(
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: const Offset(50, 100),
              child: ConfettiWidget(
                confettiController: _leftFireworksController,
                blastDirection: pi / 2.5,
                maxBlastForce: 100,
                minBlastForce: 80,
                emissionFrequency: 0.04,
                numberOfParticles: 50,
                gravity: 0.25,
                colors: [
                  Colors.orange,
                  Colors.red,
                  Colors.yellow,
                  AppTheme.primaryNeon,
                ],
                createParticlePath: drawCircle,
              ),
            ),
          ),

          // Fireworks - Right
          Align(
            alignment: Alignment.topRight,
            child: Transform.translate(
              offset: const Offset(-50, 100),
              child: ConfettiWidget(
                confettiController: _rightFireworksController,
                blastDirection: pi / 3.5,
                maxBlastForce: 100,
                minBlastForce: 80,
                emissionFrequency: 0.04,
                numberOfParticles: 50,
                gravity: 0.25,
                colors: [
                  Colors.purple,
                  Colors.blue,
                  Colors.cyan,
                  AppTheme.accentNeon,
                ],
                createParticlePath: drawCircle,
              ),
            ),
          ),

          SafeArea(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                children: [
                  // Top Section: Round Complete Badge (Enhanced)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.round.difficulty.color,
                                  widget.round.difficulty.color.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.round.difficulty.color,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.round.difficulty.color.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.round.title} Complete!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Call-to-Action Buttons Section (Enhanced)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      children: [
                        // Next Round Button (Primary CTA - Enhanced)
                        if (nextRound != null && !nextRound.isLocked)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryNeon.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          CampaignGameScreen(
                                        round: nextRound!,
                                        isEducationMode: widget.isEducationMode,
                                        gradeLevel: widget.gradeLevel,
                                      ),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(1.0, 0.0),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(milliseconds: 500),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow, size: 22),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Next: ',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      nextRound.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: nextRound.difficulty.color.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: nextRound.difficulty.color,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        nextRound.difficulty.displayName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: nextRound.difficulty.color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryNeon,
                                  foregroundColor: AppTheme.darkBg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        
                        // Double Coins Button (Enhanced)
                        if (!_coinsDoubled) ...[
                          const SizedBox(height: 8),
                          _buildDoubleCoinsButton(context),
                        ],
                        
                        // Secondary Actions Row (Enhanced)
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.replay,
                                label: 'Retry',
                                color: AppTheme.accentNeon,
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CampaignGameScreen(
                                        round: widget.round,
                                        isEducationMode: widget.isEducationMode,
                                        gradeLevel: widget.gradeLevel,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.map,
                                label: 'Map',
                                color: Colors.white70,
                                onPressed: () {
                                  if (widget.isEducationMode && widget.gradeLevel != null) {
                                    // Navigate to education map and scroll to next round
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CampaignScreen(
                                          isEducationMode: true,
                                          gradeLevel: widget.gradeLevel,
                                          shouldScrollToNextRound: true,
                                        ),
                                      ),
                                      (route) => false,
                                    );
                                  } else {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CampaignScreen(
                                          shouldScrollToNextRound: true,
                                        ),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.home,
                                label: 'Home',
                                color: AppTheme.primaryNeon,
                                onPressed: () {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Stats Section (Enhanced with animations)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Stars and Message (Enhanced)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (i) {
                              return AnimatedScale(
                                scale: i < _displayedStars ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.elasticOut,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: i < _displayedStars
                                          ? [
                                              BoxShadow(
                                                color: Colors.amber.withValues(alpha: 0.6),
                                                blurRadius: 20,
                                                spreadRadius: 3,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _earnedStars == 3
                                ? '🎉 Perfect Round! 🎉'
                                : _earnedStars == 2
                                    ? '👏 Great Job! 👏'
                                    : _earnedStars == 1
                                        ? '👍 Good Effort! 👍'
                                        : '💪 Keep Trying! 💪',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: widget.round.difficulty.color.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Animated Stats Grid - Using Column with Row to avoid GridView issues
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: SlideTransition(
                                      position: _cardAnimations[0],
                                      child: _buildStatCard(
                                        'Score',
                                        widget.score.toString(),
                                        Icons.stars,
                                        AppTheme.primaryNeon,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SlideTransition(
                                      position: _cardAnimations[1],
                                      child: _buildStatCard(
                                        'Correct',
                                        '${widget.correctAnswers}/${widget.totalQuestions}',
                                        Icons.check_circle,
                                        Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: SlideTransition(
                                      position: _cardAnimations[2],
                                      child: _buildStatCard(
                                        'Accuracy',
                                        '$accuracy%',
                                        Icons.percent,
                                        Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SlideTransition(
                                      position: _cardAnimations[3],
                                      child:                               _buildStatCard(
                                'Coins',
                                _getCoinsDisplayText(),
                                Icons.monetization_on,
                                Colors.amber,
                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }

  String _getCoinsDisplayText() {
    final netCoins = widget.coinsEarned - _entryCost;
    if (netCoins > 0) {
      return '+${widget.coinsEarned}\n(net +$netCoins)';
    } else if (netCoins == 0) {
      return '+${widget.coinsEarned}\n(break even)';
    } else {
      return '+${widget.coinsEarned}\n(net $netCoins)';
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard,
            AppTheme.darkCard.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: SizedBox(
        height: 44,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: color),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: color.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildDoubleCoinsButton(BuildContext context) {
    final premiumService = context.watch<PremiumService>();
    
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () => _handleDoubleCoins(context),
            icon: Icon(
              premiumService.isPremium ? Icons.star : Icons.play_circle_filled,
              color: Colors.amber.shade600,
              size: 20,
            ),
            label: Text(
              premiumService.isPremium
                  ? 'Claim 2X Coins (${widget.coinsEarned * 2})'
                  : 'Watch Ad for 2X (${widget.coinsEarned * 2})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkIfCoinsAlreadyDoubled() async {
    final prefs = await SharedPreferences.getInstance();
    final doubledRoundKey = 'campaign_doubled_coins_round_${widget.round.roundNumber}';
    final isDoubled = prefs.getBool(doubledRoundKey) ?? false;
    
    if (isDoubled) {
      setState(() {
        _coinsDoubled = true;
      });
    }
  }

  Future<void> _saveCoinsDoubled() async {
    final prefs = await SharedPreferences.getInstance();
    final doubledRoundKey = 'campaign_doubled_coins_round_${widget.round.roundNumber}';
    await prefs.setBool(doubledRoundKey, true);
  }

  Future<void> _handleDoubleCoins(BuildContext context) async {
    // Check if already doubled
    if (_coinsDoubled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coins already doubled for this round!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final premiumService = context.read<PremiumService>();
    final userProvider = context.read<UserProvider>();
    
    if (premiumService.isPremium) {
      userProvider.addCoins(widget.coinsEarned);
      await _saveCoinsDoubled(); // Persist the state
      setState(() {
        _coinsDoubled = true;
      });
      
      // Trigger fireworks
      _confettiController.play();
      _leftFireworksController.play();
      _rightFireworksController.play();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ +${widget.coinsEarned} bonus coins! Total: ${widget.coinsEarned * 2}'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    
    final adService = context.read<AdService>();
    
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AdLoadingDialog(
        message: 'Loading ad...',
      ),
    );

    final watched = await adService.showRoundCompleteAd();
    
    if (!mounted) return;
    Navigator.of(context).pop();
    
    if (watched) {
      userProvider.addCoins(widget.coinsEarned);
      await _saveCoinsDoubled(); // Persist the state
      setState(() {
        _coinsDoubled = true;
      });
      
      // Trigger fireworks
      _confettiController.play();
      _leftFireworksController.play();
      _rightFireworksController.play();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Coins doubled! +${widget.coinsEarned} bonus coins!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load ad. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
