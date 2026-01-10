import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../models/campaign_round.dart';
import '../../services/campaign_service.dart';
import 'campaign_screen.dart';
import 'campaign_game_screen.dart';

class CampaignResultsScreen extends StatefulWidget {
  final CampaignRound round;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int coinsEarned;

  const CampaignResultsScreen({
    super.key,
    required this.round,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.coinsEarned,
  });

  @override
  State<CampaignResultsScreen> createState() => _CampaignResultsScreenState();
}

class _CampaignResultsScreenState extends State<CampaignResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late ConfettiController _confettiController;
  late AnimationController _starsController;
  late Animation<double> _scaleAnimation;
  
  int _displayedStars = 0;
  int _earnedStars = 0;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final maxScore = widget.totalQuestions * (widget.round.difficulty.baseScore + 75);
    _earnedStars = CampaignRound.calculateStars(widget.score, maxScore);

    _scaleController.forward();
    
    if (_earnedStars >= 2) {
      _confettiController.play();
    }

    // Animate stars one by one
    _animateStars();
  }

  void _animateStars() async {
    for (int i = 0; i < _earnedStars; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
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
    _confettiController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final campaignService = context.watch<CampaignService>();
    final nextRound = campaignService.getRound(widget.round.roundNumber + 1);
    final accuracy = (widget.correctAnswers / widget.totalQuestions * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 100,
              minBlastForce: 80,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.3,
              colors: [
                widget.round.difficulty.color,
                AppTheme.primaryNeon,
                AppTheme.accentNeon,
                Colors.amber,
              ],
              createParticlePath: drawStar,
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Round Complete Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.round.difficulty.color.withOpacity(0.3),
                            widget.round.difficulty.color.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.round.difficulty.color,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '${widget.round.title} Complete!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.round.difficulty.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Stars Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return AnimatedScale(
                          scale: i < _displayedStars ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 60,
                              shadows: [
                                Shadow(
                                  color: Colors.amber.withOpacity(0.5),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _earnedStars == 3
                          ? '🎉 Perfect Round! 🎉'
                          : _earnedStars == 2
                              ? '👏 Great Job! 👏'
                              : _earnedStars == 1
                                  ? '👍 Good Effort! 👍'
                                  : '💪 Keep Trying! 💪',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Score',
                          widget.score.toString(),
                          Icons.stars,
                          AppTheme.primaryNeon,
                        ),
                        _buildStatCard(
                          'Correct',
                          '${widget.correctAnswers}/${widget.totalQuestions}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Accuracy',
                          '$accuracy%',
                          Icons.percent,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Coins',
                          '+${widget.coinsEarned}',
                          Icons.monetization_on,
                          Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // Next Round Preview
                    if (nextRound != null && !nextRound.isLocked) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppTheme.primaryNeon.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_forward,
                                  color: AppTheme.primaryNeon,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Next: ${nextRound.title}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: nextRound.difficulty.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
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
                            const SizedBox(height: 12),
                            Text(
                              nextRound.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (nextRound != null && !nextRound.isLocked) {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    CampaignGameScreen(round: nextRound),
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
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          'Next Round',
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
                          elevation: 8,
                          shadowColor: AppTheme.primaryNeon.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Retry this round
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CampaignGameScreen(round: widget.round),
                            ),
                          );
                        },
                        icon: const Icon(Icons.replay),
                        label: const Text(
                          'Retry Round',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.accentNeon),
                          foregroundColor: AppTheme.accentNeon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const CampaignScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Back to Campaign Map',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

