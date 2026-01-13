import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/league.dart';
import '../../providers/user_provider.dart';
import '../../widgets/out_of_coins_dialog.dart';

class LeagueResultsScreen extends StatefulWidget {
  final League league;
  final int myScore;

  const LeagueResultsScreen({
    super.key,
    required this.league,
    required this.myScore,
  });

  @override
  State<LeagueResultsScreen> createState() => _LeagueResultsScreenState();
}

class _LeagueResultsScreenState extends State<LeagueResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late List<Animation<Offset>> _slideAnimations;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create staggered slide animations for each player
    final rankedPlayers = _getRankedPlayers();
    _slideAnimations = List.generate(
      rankedPlayers.length.clamp(0, 10), // Show animation for top 10
      (index) => Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            index * 0.1,
            0.5 + (index * 0.1),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    // Award prizes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prize = _myPrize;
      if (prize > 0) {
        context.read<UserProvider>().addCoins(prize);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏆 You won $prize coins!'),
            backgroundColor: Colors.amber,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Show results after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showResults = true);
          _slideController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  /// Get ranked players sorted by score
  List<LeagueParticipant> _getRankedPlayers() {
    final players = List<LeagueParticipant>.from(widget.league.participants);
    players.sort((a, b) => b.score.compareTo(a.score));
    return players;
  }

  /// Calculate prize distribution for top 50 players
  /// Distribution: 1st: 20%, 2nd: 15%, 3rd: 10%, 4th-10th: 5% each, 11th-50th: remaining split
  Map<String, int> get _prizeDistribution {
    final prizePot = widget.league.prizePot;
    final rankedPlayers = _getRankedPlayers();
    final distribution = <String, int>{};

    if (rankedPlayers.isEmpty || prizePot == 0) return distribution;

    int remainingPot = prizePot;

    // 1st place: 20%
    if (rankedPlayers.isNotEmpty) {
      final prize = (prizePot * 0.20).round();
      distribution[rankedPlayers[0].userId] = prize;
      remainingPot -= prize;
    }

    // 2nd place: 15%
    if (rankedPlayers.length >= 2) {
      final prize = (prizePot * 0.15).round();
      distribution[rankedPlayers[1].userId] = prize;
      remainingPot -= prize;
    }

    // 3rd place: 10%
    if (rankedPlayers.length >= 3) {
      final prize = (prizePot * 0.10).round();
      distribution[rankedPlayers[2].userId] = prize;
      remainingPot -= prize;
    }

    // 4th-10th place: 5% each
    for (int i = 3; i < rankedPlayers.length.clamp(0, 10); i++) {
      final prize = (prizePot * 0.05).round();
      distribution[rankedPlayers[i].userId] = prize;
      remainingPot -= prize;
    }

    // 11th-50th place: split remaining pot
    final top50Count = rankedPlayers.length.clamp(0, 50);
    if (top50Count > 10) {
      final prizePerPlayer = (remainingPot / (top50Count - 10)).round();
      for (int i = 10; i < top50Count; i++) {
        distribution[rankedPlayers[i].userId] = prizePerPlayer;
      }
    }

    return distribution;
  }

  int get _myPrize {
    final user = context.read<UserProvider>().user;
    if (user == null) return 0;
    return _prizeDistribution[user.id] ?? 0;
  }

  int get _myRank {
    final user = context.read<UserProvider>().user;
    if (user == null) return -1;
    final rankedPlayers = _getRankedPlayers();
    return rankedPlayers.indexWhere((p) => p.userId == user.id) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final rankedPlayers = _getRankedPlayers();
    final myRank = _myRank;
    final myPrize = _myPrize;

    // Check if user ran out of coins AFTER game ended
    // Only show popup if they're at 0 coins (didn't win a prize)
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    '🏆 League Results',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.league.name,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // My Stats Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: myRank <= 3
                            ? [Colors.amber.shade700, Colors.amber.shade400]
                            : [AppTheme.darkCard, AppTheme.darkCard.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: myRank <= 3
                            ? Colors.amber
                            : AppTheme.primaryNeon.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: myRank <= 3
                          ? [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Rank', '#$myRank'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatColumn('Score', '${widget.myScore}'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatColumn(
                          'Prize',
                          myPrize > 0 ? '+$myPrize' : '-',
                          color: myPrize > 0 ? Colors.green : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Prize Pool Info
            if (_showResults)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryNeon.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: AppTheme.primaryNeon,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Total Prize Pool: ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.league.prizePot} coins',
                        style: const TextStyle(
                          color: AppTheme.primaryNeon,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Rankings List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Final Rankings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${rankedPlayers.length} players)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: rankedPlayers.length,
                        itemBuilder: (context, index) {
                          final player = rankedPlayers[index];
                          final rank = index + 1;
                          final prize = _prizeDistribution[player.userId] ?? 0;
                          final isMe = player.userId ==
                              context.read<UserProvider>().user?.id;

                          // Use slide animation for top 10
                          if (index < 10 && index < _slideAnimations.length) {
                            return SlideTransition(
                              position: _slideAnimations[index],
                              child: _buildPlayerCard(
                                  player, rank, prize, isMe),
                            );
                          }

                          return _buildPlayerCard(player, rank, prize, isMe);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Go back to leagues screen
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNeon,
                        foregroundColor: AppTheme.darkBg,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back to Leagues',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildStatColumn(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(
    LeagueParticipant player,
    int rank,
    int prize,
    bool isMe,
  ) {
    Color? rankColor;
    String? rankEmoji;

    if (rank == 1) {
      rankColor = Colors.amber;
      rankEmoji = '🥇';
    } else if (rank == 2) {
      rankColor = Colors.grey.shade400;
      rankEmoji = '🥈';
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankEmoji = '🥉';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primaryNeon.withOpacity(0.2) : AppTheme.darkBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppTheme.primaryNeon
              : (rankColor ?? Colors.white.withOpacity(0.1)),
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: rankColor ?? Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rankEmoji ?? '#$rank',
                style: TextStyle(
                  fontSize: rankEmoji != null ? 24 : 18,
                  fontWeight: FontWeight.bold,
                  color: rankColor != null ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNeon,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBg,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Score: ${player.score}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Prize
          if (prize > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on,
                      color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+$prize',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

