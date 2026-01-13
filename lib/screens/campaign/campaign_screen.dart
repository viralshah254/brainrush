import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/campaign_service.dart';
import '../../models/campaign_round.dart';
import '../../providers/user_provider.dart';
import '../../widgets/out_of_coins_dialog.dart';
import 'campaign_game_screen.dart';

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    // Initialize campaign service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignService>().initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Consumer<CampaignService>(
        builder: (context, campaignService, _) {
          if (campaignService.rounds.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(campaignService),
              _buildStats(campaignService),
              _buildRoundsList(campaignService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(CampaignService service) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.darkBg,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '🎮 Campaign Mode',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryNeon.withOpacity(0.3),
                AppTheme.accentNeon.withOpacity(0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(CampaignService service) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '${service.currentRound}/500',
                'Current Round',
                Icons.flag,
                AppTheme.primaryNeon,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '${service.totalStars}',
                'Total Stars',
                Icons.star,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '${service.completedRounds}',
                'Completed',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoundsList(CampaignService service) {
    final visibleRounds = service.rounds
        .where((r) => r.roundNumber <= service.currentRound + 5)
        .toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final round = visibleRounds[index];
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.05,
                    (index * 0.05) + 0.5,
                    curve: Curves.easeOut,
                  ),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index * 0.05,
                      (index * 0.05) + 0.5,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: _buildRoundCard(round, index),
              ),
            );
          },
          childCount: visibleRounds.length,
        ),
      ),
    );
  }

  Widget _buildRoundCard(CampaignRound round, int index) {
    final isCurrentRound = round.roundNumber == context.read<CampaignService>().currentRound;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          if (round.isLocked) {
            _showLockedDialog(round);
          } else {
            _startRound(round);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: round.isLocked
                ? null
                : LinearGradient(
                    colors: [
                      round.difficulty.color.withOpacity(0.2),
                      round.difficulty.color.withOpacity(0.05),
                    ],
                  ),
            color: round.isLocked ? AppTheme.darkCard.withOpacity(0.5) : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrentRound
                  ? AppTheme.primaryNeon
                  : round.difficulty.color.withOpacity(0.3),
              width: isCurrentRound ? 3 : 2,
            ),
            boxShadow: isCurrentRound
                ? [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Round number
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: round.difficulty.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: round.difficulty.color,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${round.roundNumber}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: round.difficulty.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title and info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                round.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: round.isLocked ? Colors.white38 : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    round.difficulty.icon,
                                    size: 16,
                                    color: round.difficulty.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    round.difficulty.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: round.difficulty.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.quiz,
                                    size: 16,
                                    color: Colors.white60,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${round.questionCount} Q',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Lock or Stars
                        if (round.isLocked)
                          Icon(
                            Icons.lock,
                            color: Colors.white38,
                            size: 28,
                          )
                        else if (round.isCompleted && round.starsEarned != null)
                          Row(
                            children: List.generate(3, (i) {
                              return Icon(
                                i < round.starsEarned!
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              );
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      round.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: round.isLocked ? Colors.white24 : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNeon.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            round.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryNeon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${round.coinsReward}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCurrentRound)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NEXT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBg,
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

  void _showLockedDialog(CampaignRound round) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.white60),
            const SizedBox(width: 12),
            const Text(
              'Locked',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Complete previous rounds to unlock Round ${round.roundNumber}!\n\nStars required: ${round.starsRequired}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startRound(CampaignRound round) {
    final userProvider = context.read<UserProvider>();
    final entryCost = round.difficulty.entryCost;
    
    // Check if user has enough coins
    if (!userProvider.hasEnoughCoins(entryCost)) {
      _showInsufficientCoinsDialog(entryCost);
      return;
    }
    
    // Deduct entry cost
    userProvider.spendCoins(entryCost);
    
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CampaignGameScreen(round: round),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showInsufficientCoinsDialog(int required) {
    // Show the unified out of coins dialog
    showOutOfCoinsDialog(context);
  }
}

