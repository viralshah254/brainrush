import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_theme.dart';
import '../models/daily_login_reward.dart';

/// Enhanced daily reward dialog with amazing animations
class EnhancedDailyRewardDialog extends StatefulWidget {
  final int loginDay;
  final int coinsEarned;
  final VoidCallback onClaimed;

  const EnhancedDailyRewardDialog({
    super.key,
    required this.loginDay,
    required this.coinsEarned,
    required this.onClaimed,
  });

  @override
  State<EnhancedDailyRewardDialog> createState() => _EnhancedDailyRewardDialogState();
}

class _EnhancedDailyRewardDialogState extends State<EnhancedDailyRewardDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _coinFallController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _coinFallAnimation;
  
  late ConfettiController _confettiController;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    
    // Scale in animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Pulse animation for the reward
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Shimmer effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    
    // Coin fall animation
    _coinFallController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _coinFallAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _coinFallController, curve: Curves.bounceOut),
    );
    
    // Confetti
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _coinFallController.forward();
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _coinFallController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _claim() {
    if (_claimed) return;
    setState(() => _claimed = true);
    
    // Trigger extra confetti
    _confettiController.play();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onClaimed();
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reward = DailyLoginReward.getRewardForDay(widget.loginDay);
    final allRewards = DailyLoginReward.getRewards();
    final isDay7 = widget.loginDay == 7;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.3,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
        
        // Main dialog
        ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDay7
                      ? [
                          const Color(0xFF2D1B69),
                          const Color(0xFF1A0F3E),
                          const Color(0xFF0F0829),
                        ]
                      : [
                          const Color(0xFF1A2433),
                          const Color(0xFF0F1419),
                          const Color(0xFF0A0E14),
                        ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  width: 3,
                  color: isDay7 ? Colors.amber : AppTheme.primaryNeon,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDay7 ? Colors.amber : AppTheme.primaryNeon).withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Shimmer effect
                      AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (rect) {
                              return LinearGradient(
                                begin: Alignment(_shimmerAnimation.value - 0.5, 0),
                                end: Alignment(_shimmerAnimation.value + 0.5, 0),
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.5),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ).createShader(rect);
                            },
                            child: Text(
                              isDay7 ? '🎉 MEGA REWARD! 🎉' : '🎁 Daily Rewards',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isDay7 ? 28 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Day ${widget.loginDay} of 7',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Reward display with coin fall animation
                  AnimatedBuilder(
                    animation: _coinFallAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - _coinFallAnimation.value) * -100),
                        child: Opacity(
                          opacity: _coinFallAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: isDay7
                                    ? [
                                        Colors.amber,
                                        Colors.amber.shade700,
                                        Colors.amber.shade900,
                                      ]
                                    : [
                                        AppTheme.primaryNeon,
                                        AppTheme.primaryNeon.withOpacity(0.7),
                                        AppTheme.primaryNeon.withOpacity(0.4),
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDay7 ? Colors.amber : AppTheme.primaryNeon)
                                      .withOpacity(0.6),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '🪙',
                                    style: TextStyle(
                                      fontSize: isDay7 ? 60 : 48,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '+${widget.coinsEarned}',
                                    style: TextStyle(
                                      fontSize: isDay7 ? 36 : 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Progress tracker
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Your Progress',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final day = index + 1;
                            final isCompleted = day <= widget.loginDay;
                            final isCurrent = day == widget.loginDay;
                            final dayReward = allRewards[index];
                            
                            return Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isCompleted
                                        ? (day == 7
                                            ? LinearGradient(
                                                colors: [Colors.amber, Colors.amber.shade700],
                                              )
                                            : AppTheme.primaryGradient)
                                        : null,
                                    color: isCompleted ? null : Colors.white.withOpacity(0.1),
                                    border: Border.all(
                                      color: isCurrent
                                          ? Colors.white
                                          : (isCompleted
                                              ? Colors.transparent
                                              : Colors.white.withOpacity(0.3)),
                                      width: isCurrent ? 3 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: isCompleted
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : Text(
                                            '$day',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    color: isCompleted ? Colors.white : Colors.white30,
                                    fontSize: 11,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Message
                  Text(
                    isDay7
                        ? '🎉 Amazing! You\'ve completed the full week!'
                        : 'Keep your streak going! Come back tomorrow!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Claim button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _claimed ? null : _claim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDay7 ? Colors.amber : AppTheme.primaryNeon,
                        foregroundColor: isDay7 ? Colors.black : AppTheme.darkBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: (isDay7 ? Colors.amber : AppTheme.primaryNeon)
                            .withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.card_giftcard, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            _claimed ? 'Claimed!' : '✨ Claim Reward!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
        ),
      ],
    );
  }
}





