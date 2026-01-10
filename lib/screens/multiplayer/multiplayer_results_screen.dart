import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../models/room.dart';

class MultiplayerResultsScreen extends StatefulWidget {
  final Room room;
  final int myScore;

  const MultiplayerResultsScreen({
    super.key,
    required this.room,
    required this.myScore,
  });

  @override
  State<MultiplayerResultsScreen> createState() =>
      _MultiplayerResultsScreenState();
}

class _MultiplayerResultsScreenState extends State<MultiplayerResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _slideController;
  late List<Animation<Offset>> _slideAnimations;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create staggered slide animations for each player
    _slideAnimations = List.generate(
      widget.room.players.length,
      (index) => Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            index * 0.1,
            0.5 + (index * 0.1),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    // Start animations after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.forward();
        _slideController.forward();
        setState(() => _showResults = true);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  List<RoomPlayer> get _rankedPlayers {
    final players = List<RoomPlayer>.from(widget.room.players);
    players.sort((a, b) => b.score.compareTo(a.score));
    return players;
  }

  @override
  Widget build(BuildContext context) {
    final rankedPlayers = _rankedPlayers;
    final myRank =
        rankedPlayers.indexWhere((p) => p.score == widget.myScore) + 1;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // Confetti animation
          ...List.generate(50, (index) {
            return AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                final progress = _confettiController.value;
                final x = (index % 10) * (MediaQuery.of(context).size.width / 10);
                final y = -50 +
                    (progress * MediaQuery.of(context).size.height * 1.2) +
                    (math.sin(progress * 4 * math.pi + index) * 50);

                return Positioned(
                  left: x,
                  top: y,
                  child: Transform.rotate(
                    angle: progress * 4 * math.pi + index,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: [
                          AppTheme.primaryNeon,
                          AppTheme.secondaryNeon,
                          AppTheme.accentNeon,
                          Colors.amber,
                        ][index % 4],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header
                  AnimatedOpacity(
                    opacity: _showResults ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    child: Column(
                      children: [
                        Icon(
                          myRank == 1
                              ? Icons.emoji_events
                              : Icons.military_tech,
                          size: 80,
                          color: _getRankColor(myRank),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          myRank == 1 ? 'Victory!' : 'Great Job!',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          myRank == 1
                              ? '🎉 You ranked #1! 🎉'
                              : 'You ranked #$myRank',
                          style: TextStyle(
                            fontSize: 20,
                            color: _getRankColor(myRank),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Leaderboard
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.leaderboard,
                                  color: AppTheme.primaryNeon,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Final Rankings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.white10),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: rankedPlayers.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final player = rankedPlayers[index];
                                final rank = index + 1;
                                final isMe = player.score == widget.myScore;

                                return SlideTransition(
                                  position: _slideAnimations[index],
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? AppTheme.primaryNeon.withOpacity(0.1)
                                          : AppTheme.darkBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isMe
                                            ? AppTheme.primaryNeon
                                            : _getRankColor(rank)
                                                .withOpacity(0.3),
                                        width: isMe ? 3 : 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Rank badge
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: _getRankColor(rank)
                                                .withOpacity(0.2),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _getRankColor(rank),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              rank <= 3
                                                  ? ['🥇', '🥈', '🥉'][rank - 1]
                                                  : '#$rank',
                                              style: TextStyle(
                                                fontSize: rank <= 3 ? 24 : 16,
                                                fontWeight: FontWeight.bold,
                                                color: _getRankColor(rank),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Avatar
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.primaryGradient,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              player.username[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.darkBg,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Name
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    player.username,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: isMe
                                                          ? AppTheme.primaryNeon
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                  if (isMe) ...[
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      '(You)',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppTheme.primaryNeon,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${player.score} points',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white60,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Medal or badge
                                        if (rank <= 3)
                                          Text(
                                            ['👑', '⭐', '💎'][rank - 1],
                                            style: const TextStyle(fontSize: 24),
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
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryNeon),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Home',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.primaryNeon,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                              // Navigate to create new room
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryNeon,
                              foregroundColor: AppTheme.darkBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Play Again',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade300;
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.primaryNeon;
    }
  }
}

