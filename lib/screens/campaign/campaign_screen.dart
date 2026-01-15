import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/campaign_service.dart';
import '../../services/education_campaign_service.dart';
import '../../models/campaign_round.dart';
import '../../models/app_mode.dart';
import '../../providers/user_provider.dart';
import '../../widgets/out_of_coins_dialog.dart';
import 'campaign_game_screen.dart';

class CampaignScreen extends StatefulWidget {
  final bool isEducationMode;
  final String? gradeLevel;
  
  const CampaignScreen({
    super.key,
    this.isEducationMode = false,
    this.gradeLevel,
  });

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  bool _hasScrolledToLatest = false;

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
      if (widget.isEducationMode && widget.gradeLevel != null) {
        // Education campaign service will be initialized by the Provider
        // Access it via context after the widget tree is built
      } else {
        // Use general campaign service
        context.read<CampaignService>().initialize();
      }
    });
  }

  void _scrollToLatestRound({required bool isEducation}) {
    if (!mounted) return;
    
    // Wait for scroll controller to be attached
    if (!_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToLatestRound(isEducation: isEducation);
      });
      return;
    }
    
    try {
      int currentRound;
      List<CampaignRound> allRounds;
      
      if (isEducation && widget.gradeLevel != null) {
        final educationService = context.read<EducationCampaignService>();
        currentRound = educationService.currentRound;
        allRounds = educationService.rounds;
      } else {
        final campaignService = context.read<CampaignService>();
        currentRound = campaignService.currentRound;
        allRounds = campaignService.rounds;
      }
      
      if (allRounds.isEmpty) return;
      
      // Calculate which set of 10 rounds to show
      final currentSet = ((currentRound - 1) ~/ 10) + 1;
      final startRound = ((currentSet - 1) * 10) + 1;
      final endRound = currentSet * 10;
      
      // Find the latest unlocked round in the current set
      int targetRoundNumber = currentRound.clamp(startRound, endRound);
      for (final round in allRounds) {
        if (round.roundNumber >= startRound && round.roundNumber <= endRound) {
          if (round.roundNumber > currentRound && round.isLocked) {
            // Found first locked round, scroll to the round before it (latest unlocked)
            targetRoundNumber = round.roundNumber - 1;
            break;
          } else if (round.roundNumber >= currentRound && !round.isLocked) {
            targetRoundNumber = round.roundNumber;
          }
        }
      }
      
      // Find the index of the target round in visible rounds (current set of 10)
      final visibleRounds = allRounds
          .where((r) => r.roundNumber >= startRound && r.roundNumber <= endRound)
          .toList();
      
      final targetIndex = visibleRounds.indexWhere((r) => r.roundNumber == targetRoundNumber);
      
      if (targetIndex == -1 || targetIndex == 0) {
        // If target is first round or not found, scroll to top
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        return;
      }
      
      // Calculate scroll position more accurately
      // App bar expanded height: 120
      // Stats section: ~100 (padding + content)
      // Each round card: ~200 (estimated based on content including padding)
      // Card spacing: 16
      const double appBarHeight = 120.0;
      const double statsHeight = 100.0;
      const double cardHeight = 200.0;
      const double cardSpacing = 16.0;
      
      final scrollPosition = appBarHeight + statsHeight + (targetIndex * (cardHeight + cardSpacing)) - 50; // -50 to show a bit above
      
      // Ensure we don't scroll beyond max scroll extent
      final maxScroll = _scrollController.position.maxScrollExtent;
      final finalPosition = scrollPosition.clamp(0.0, maxScroll);
      
      // Scroll to position with animation
      _scrollController.animateTo(
        finalPosition,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      // Silently fail if there's an error
      debugPrint('Error scrolling to latest round: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEducationMode && widget.gradeLevel != null) {
      // Education campaign mode - provide EducationCampaignService at screen level
      return ChangeNotifierProvider<EducationCampaignService>(
        create: (_) {
          final service = EducationCampaignService(gradeLevel: widget.gradeLevel!);
          // Initialize the service asynchronously
          service.initialize().then((_) {
            // Scroll to latest round after rounds are loaded (only once)
            if (!_hasScrolledToLatest) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _hasScrolledToLatest = true;
                    _scrollToLatestRound(isEducation: true);
                  }
                });
              });
            }
          });
          return service;
        },
        child: Scaffold(
          backgroundColor: AppTheme.darkBg,
          body: Consumer<EducationCampaignService>(
            builder: (context, campaignService, _) {
              if (campaignService.rounds.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildEducationAppBar(campaignService),
                  _buildEducationStats(campaignService),
                  _buildEducationRoundsList(campaignService),
                ],
              );
            },
          ),
        ),
      );
    }
    
    // Normal campaign mode
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Consumer<CampaignService>(
        builder: (context, campaignService, _) {
          if (campaignService.rounds.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Scroll to latest round when rounds are available (only once)
          if (!_hasScrolledToLatest && campaignService.rounds.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && campaignService.rounds.isNotEmpty) {
                  _hasScrolledToLatest = true;
                  _scrollToLatestRound(isEducation: false);
                }
              });
            });
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
    // Show only 10 rounds at a time
    // Calculate which set of 10 rounds to show based on current round
    final currentSet = ((service.currentRound - 1) ~/ 10) + 1; // Which set of 10 (1, 2, 3, etc.)
    final startRound = ((currentSet - 1) * 10) + 1;
    final endRound = currentSet * 10;
    
    final visibleRounds = service.rounds
        .where((r) => r.roundNumber >= startRound && r.roundNumber <= endRound)
        .toList();
    
    // Check if we need to show unlock message
    final isLastSet = endRound >= 500;
    final showUnlockMessage = service.currentRound > endRound - 1 && !isLastSet;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Show unlock message after rounds if needed
            if (index == visibleRounds.length && showUnlockMessage) {
              return _buildUnlockMessage(endRound + 1, endRound + 10);
            }
            
            if (index >= visibleRounds.length) return const SizedBox.shrink();
            
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
          childCount: visibleRounds.length + (showUnlockMessage ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildRoundCard(CampaignRound round, int index) {
    final campaignService = context.read<CampaignService>();
    final isCurrentRound = round.roundNumber == campaignService.currentRound;

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

  Widget _buildUnlockMessage(int startRound, int endRound) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryNeon.withValues(alpha: 0.2),
            AppTheme.accentNeon.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryNeon.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: AppTheme.primaryNeon,
          ),
          const SizedBox(height: 16),
          const Text(
            '🔒 Unlock More Rounds!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Complete Round ${endRound - 9} to unlock Rounds $startRound-$endRound',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Keep playing to unlock all rounds!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            CampaignGameScreen(
          round: round,
          isEducationMode: widget.isEducationMode,
          gradeLevel: widget.gradeLevel,
        ),
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
  
  // Education-specific UI methods
  Widget _buildEducationAppBar(EducationCampaignService service) {
    final gradeLevel = GradeLevel.fromCode(widget.gradeLevel ?? '');
    final gradeDisplay = gradeLevel?.displayName ?? 'your grade';
    
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.darkBg,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          '🎓 Education Campaign\n$gradeDisplay',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.indigo.withOpacity(0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEducationStats(EducationCampaignService service) {
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
                Colors.blue,
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

  Widget _buildEducationRoundsList(EducationCampaignService service) {
    // Show only 10 rounds at a time
    // Calculate which set of 10 rounds to show based on current round
    final currentSet = ((service.currentRound - 1) ~/ 10) + 1; // Which set of 10 (1, 2, 3, etc.)
    final startRound = ((currentSet - 1) * 10) + 1;
    final endRound = currentSet * 10;
    
    final visibleRounds = service.rounds
        .where((r) => r.roundNumber >= startRound && r.roundNumber <= endRound)
        .toList();
    
    // Check if we need to show unlock message
    final isLastSet = endRound >= service.rounds.length;
    final showUnlockMessage = service.currentRound > endRound - 1 && !isLastSet;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Show unlock message after rounds if needed
            if (index == visibleRounds.length && showUnlockMessage) {
              return _buildUnlockMessage(endRound + 1, endRound + 10);
            }
            
            if (index >= visibleRounds.length) return const SizedBox.shrink();
            
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
                child: _buildEducationRoundCard(round, index, service),
              ),
            );
          },
          childCount: visibleRounds.length + (showUnlockMessage ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildEducationRoundCard(CampaignRound round, int index, EducationCampaignService service) {
    final isCurrentRound = round.roundNumber == service.currentRound;

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
              color: round.isLocked
                  ? Colors.grey.withOpacity(0.3)
                  : round.difficulty.color.withOpacity(0.5),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          round.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: round.isLocked ? Colors.grey : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          round.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: round.isLocked
                                ? Colors.grey
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (round.isLocked)
                    const Icon(Icons.lock, color: Colors.grey, size: 24)
                  else if (round.isCompleted)
                    Row(
                      children: List.generate(
                        round.starsEarned ?? 0,
                        (_) => const Icon(Icons.star, color: Colors.amber, size: 20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: round.difficulty.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      round.difficulty.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: round.difficulty.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${round.questionCount} questions',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                  const Spacer(),
                  if (isCurrentRound)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

