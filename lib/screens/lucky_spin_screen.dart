import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../services/retention_service.dart';

class LuckySpinScreen extends StatefulWidget {
  const LuckySpinScreen({super.key});

  @override
  State<LuckySpinScreen> createState() => _LuckySpinScreenState();
}

class _LuckySpinScreenState extends State<LuckySpinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  bool _isSpinning = false;
  int? _winAmount;

  final List<LuckySpinSegment> _segments = [
    LuckySpinSegment(coins: 50, color: Colors.blue, emoji: '💰'),
    LuckySpinSegment(coins: 100, color: Colors.green, emoji: '💸'),
    LuckySpinSegment(coins: 50, color: Colors.purple, emoji: '💰'),
    LuckySpinSegment(coins: 200, color: Colors.orange, emoji: '🎁'),
    LuckySpinSegment(coins: 50, color: Colors.pink, emoji: '💰'),
    LuckySpinSegment(coins: 500, color: Colors.red, emoji: '🏆'),
    LuckySpinSegment(coins: 100, color: Colors.teal, emoji: '💸'),
    LuckySpinSegment(coins: 1000, color: Colors.amber, emoji: '👑'),
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _spinAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOut),
    );

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _winAmount != null) {
        _showWinDialog();
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;

    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    if (user == null || !user.canSpinLuckyWheel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Come back tomorrow for another spin!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _winAmount = null;
    });

    // Get win amount from retention service (this determines probability)
    final retentionService = context.read<RetentionService>();
    final targetCoinAmount = retentionService.spinLuckyWheel();

    // Find all segments that match the target coin amount
    final matchingSegments = <int>[];
    for (int i = 0; i < _segments.length; i++) {
      if (_segments[i].coins == targetCoinAmount) {
        matchingSegments.add(i);
      }
    }

    // Randomly select one of the matching segments
    final random = math.Random();
    final targetSegmentIndex = matchingSegments[random.nextInt(matchingSegments.length)];
    
    // Get the actual win amount from the selected segment (this ensures correct payout)
    _winAmount = _segments[targetSegmentIndex].coins;

    // Calculate target rotation (multiple full spins + landing position)
    // The wheel is drawn with segments starting at -90° (top)
    // The pointer is at the top, so we need the target segment's center to align with the pointer
    final segmentAngle = (2 * math.pi) / _segments.length;
    
    // Calculate the angle of the target segment's center
    // Segment 0 starts at -90° (-π/2), so its center is at -90° + segmentAngle/2
    // Segment N's center is at: -90° + (N * segmentAngle) + (segmentAngle / 2)
    final segmentCenterAngle = (targetSegmentIndex * segmentAngle) - (math.pi / 2) + (segmentAngle / 2);
    
    // To bring this segment center to the top (where pointer is), we need to rotate
    // the wheel so the segment center moves from its current position to 0° (top)
    // Since rotation is clockwise (positive), we rotate by: 0 - segmentCenterAngle
    // But we want positive rotation, so: 2π - segmentCenterAngle (or -segmentCenterAngle wrapped)
    final targetAngle = (2 * math.pi) - segmentCenterAngle;
    
    // Add multiple full rotations for excitement (5 full spins)
    final fullRotations = 5;
    final totalRotation = (fullRotations * 2 * math.pi) + targetAngle;

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: totalRotation,
    ).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOut),
    );

    _spinController.reset();
    _spinController.forward();

    // Update last spin date
    userProvider.setUser(user.copyWith(lastLuckySpinDate: DateTime.now()));
    userProvider.saveUserData(); // Persist the date
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.darkCard, AppTheme.darkCard.withOpacity(0.95)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _winAmount! >= 500 ? '🎊 JACKPOT! 🎊' : '🎉 You Won!',
                  style: TextStyle(
                    fontSize: _winAmount! >= 500 ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: _winAmount! >= 500 ? Colors.amber : Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade700, Colors.amber.shade400],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _segments.firstWhere((s) => s.coins == _winAmount).emoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                        Text(
                          '+$_winAmount',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<UserProvider>().addCoins(_winAmount!);
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: AppTheme.darkBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Claim!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    setState(() {
      _isSpinning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final canSpin = user?.canSpinLuckyWheel ?? false;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('🎰 Lucky Spin'),
        backgroundColor: AppTheme.darkBg,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Spin the Wheel!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canSpin ? 'Try your luck today!' : 'Come back tomorrow!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 48),

            // Wheel
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Spinning wheel
                    AnimatedBuilder(
                      animation: _spinAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _spinAnimation.value,
                          child: CustomPaint(
                            size: const Size(300, 300),
                            painter: WheelPainter(segments: _segments),
                          ),
                        );
                      },
                    ),

                    // Center button
                    GestureDetector(
                      onTap: _spin,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: canSpin
                                ? [AppTheme.primaryNeon, AppTheme.secondaryNeon]
                                : [Colors.grey.shade700, Colors.grey.shade600],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: canSpin
                                  ? AppTheme.primaryNeon.withOpacity(0.5)
                                  : Colors.transparent,
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'SPIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Pointer at top
                    Positioned(
                      top: 0,
                      child: Icon(
                        Icons.arrow_drop_down,
                        size: 48,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Possible Prizes:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _segments.toSet().map((segment) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: segment.color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: segment.color),
                        ),
                        child: Text(
                          '${segment.emoji} ${segment.coins}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '⏰ Free spin available once per day!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LuckySpinSegment {
  final int coins;
  final Color color;
  final String emoji;

  LuckySpinSegment({
    required this.coins,
    required this.color,
    required this.emoji,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LuckySpinSegment &&
          runtimeType == other.runtimeType &&
          coins == other.coins;

  @override
  int get hashCode => coins.hashCode;
}

class WheelPainter extends CustomPainter {
  final List<LuckySpinSegment> segments;

  WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - (math.pi / 2);
      
      final paint = Paint()
        ..color = segments[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Text
      final textAngle = startAngle + (segmentAngle / 2);
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${segments[i].emoji}\n',
              style: const TextStyle(fontSize: 20),
            ),
            TextSpan(
              text: '${segments[i].coins}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Outer border
    final outerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, outerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

