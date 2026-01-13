import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/daily_login_reward.dart';

class DailyLoginRewardDialog extends StatefulWidget {
  final int loginDay;
  final int coinsEarned;
  final VoidCallback onClaimed;

  const DailyLoginRewardDialog({
    super.key,
    required this.loginDay,
    required this.coinsEarned,
    required this.onClaimed,
  });

  @override
  State<DailyLoginRewardDialog> createState() => _DailyLoginRewardDialogState();
}

class _DailyLoginRewardDialogState extends State<DailyLoginRewardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reward = DailyLoginReward.getRewardForDay(widget.loginDay);
    final allRewards = DailyLoginReward.getRewards();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: reward.isSpecial
                      ? [
                          const Color(0xFF1a1625),
                          const Color(0xFF2d1b3d),
                          const Color(0xFF1a1625),
                        ]
                      : [
                          const Color(0xFF0f1419),
                          const Color(0xFF1a1f2e),
                          const Color(0xFF0f1419),
                        ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: reward.isSpecial
                      ? Colors.amber.withOpacity(0.6)
                      : AppTheme.primaryNeon.withOpacity(0.4),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: reward.isSpecial
                        ? Colors.amber.withOpacity(0.3)
                        : AppTheme.primaryNeon.withOpacity(0.3),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          reward.isSpecial ? '🎊' : '🎁',
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward.isSpecial ? 'SPECIAL BONUS!' : 'Daily Rewards',
                              style: TextStyle(
                                fontSize: reward.isSpecial ? 22 : 24,
                                fontWeight: FontWeight.bold,
                                color: reward.isSpecial ? Colors.amber : Colors.white,
                              ),
                            ),
                            Text(
                              'Day ${widget.loginDay} of 7',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Coin reward display with enhanced design
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                reward.isSpecial
                                    ? Colors.amber.withOpacity(0.3)
                                    : AppTheme.primaryNeon.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Main coin circle
                        Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: reward.isSpecial
                                    ? [
                                        Colors.amber.shade700,
                                        Colors.amber.shade400,
                                        Colors.amber.shade300,
                                      ]
                                    : [
                                        AppTheme.primaryNeon,
                                        AppTheme.secondaryNeon,
                                        AppTheme.accentNeon,
                                      ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: reward.isSpecial
                                      ? Colors.amber.withOpacity(0.6)
                                      : AppTheme.primaryNeon.withOpacity(0.6),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    reward.emoji,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '+${widget.coinsEarned}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
                    const SizedBox(height: 32),

                    // Weekly progress with better design
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Your Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: allRewards.map((r) {
                                final isPast = r.day < widget.loginDay;
                                final isCurrent = r.day == widget.loginDay;
                                final isDaySpecial = r.isSpecial;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: isDaySpecial ? 38 : 34,
                                        height: isDaySpecial ? 38 : 34,
                                        decoration: BoxDecoration(
                                          gradient: isPast || isCurrent
                                              ? (isDaySpecial
                                                  ? LinearGradient(
                                                      colors: [Colors.amber.shade700, Colors.amber.shade400],
                                                    )
                                                  : LinearGradient(
                                                      colors: [AppTheme.primaryNeon, AppTheme.secondaryNeon],
                                                    ))
                                              : null,
                                          color: isPast || isCurrent ? null : Colors.grey.shade800,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isCurrent
                                                ? Colors.white
                                                : (isDaySpecial && !isPast && !isCurrent
                                                    ? Colors.amber.withOpacity(0.3)
                                                    : Colors.transparent),
                                            width: isCurrent ? 3 : 1,
                                          ),
                                          boxShadow: isCurrent
                                              ? [
                                                  BoxShadow(
                                                    color: (isDaySpecial ? Colors.amber : AppTheme.primaryNeon)
                                                        .withOpacity(0.5),
                                                    blurRadius: 12,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: isPast || isCurrent
                                              ? Icon(
                                                  isDaySpecial ? Icons.star : Icons.check,
                                                  color: Colors.white,
                                                  size: isDaySpecial ? 22 : 18,
                                                )
                                              : Text(
                                                  r.day.toString(),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r.day.toString(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isCurrent ? Colors.white : Colors.white54,
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.loginDay == 7
                                  ? '🎉 Amazing! You completed the week!'
                                  : 'Keep your streak going! Come back tomorrow!',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Claim button with gradient
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: reward.isSpecial
                              ? [Colors.amber.shade700, Colors.amber.shade400]
                              : [AppTheme.primaryNeon, AppTheme.secondaryNeon],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (reward.isSpecial ? Colors.amber : AppTheme.primaryNeon)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onClaimed();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '✨',
                              style: TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              reward.isSpecial ? 'Claim Bonus!' : 'Claim Reward!',
                              style: const TextStyle(
                                fontSize: 20,
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
          );
        },
      ),
    );
  }
}

void showDailyLoginRewardDialog(
  BuildContext context, {
  required int loginDay,
  required int coinsEarned,
  required VoidCallback onClaimed,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => DailyLoginRewardDialog(
      loginDay: loginDay,
      coinsEarned: coinsEarned,
      onClaimed: onClaimed,
    ),
  );
}

