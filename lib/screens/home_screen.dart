import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/mode_provider.dart';
import '../theme/app_theme.dart';
import '../models/app_mode.dart';
import '../models/daily_login_reward.dart';
import '../services/education_subscription_service.dart';
import '../services/retention_service.dart';
import '../widgets/retention_features_cards.dart';
import '../widgets/daily_login_reward_dialog.dart';
import 'game_screen.dart';
import 'leagues/leagues_screen.dart';
import 'friends/play_with_friends_screen.dart';
import 'campaign/campaign_screen.dart';
import 'education/education_settings_screen.dart';
import 'coin_store_screen.dart';
import 'notification_settings_screen.dart';
import '../providers/game_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _countdown = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _updateCountdown();
    // Update countdown every second
    Future.delayed(const Duration(seconds: 1), _updateCountdown);
    
    // Check for daily login reward and comeback bonus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyLoginReward();
      _initializeSmartNotifications();
    });
  }
  
  /// Initialize smart notifications on app launch
  Future<void> _initializeSmartNotifications() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.initializeSmartNotifications();
  }
  
  void _checkDailyLoginReward() {
    final userProvider = context.read<UserProvider>();
    final retentionService = context.read<RetentionService>();
    final user = userProvider.user;
    
    if (user == null) return;
    
    // Check if user should receive login reward
    final daysAway = userProvider.checkDailyLogin();
    
    if (!user.hasClaimedDailyLoginReward && daysAway >= 0) {
      // Show comeback bonus if applicable
      if (daysAway >= 2) {
        final comebackBonus = retentionService.getComebackBonus(daysAway);
        if (comebackBonus > 0) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            userProvider.addCoins(comebackBonus);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 Welcome back! +$comebackBonus comeback bonus!'),
                backgroundColor: Colors.amber,
                duration: const Duration(seconds: 3),
              ),
            );
          });
        }
      }
      
      // Show daily login reward
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        final reward = DailyLoginReward.getRewardForDay(user.consecutiveLoginDays);
        showDailyLoginRewardDialog(
          context,
          loginDay: user.consecutiveLoginDays,
          coinsEarned: reward.coins,
          onClaimed: () {
            userProvider.addCoins(reward.coins);
            userProvider.claimDailyLoginReward();
          },
        );
      });
    }
    
    // Refresh quests for new day
    retentionService.checkQuestRefresh();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateCountdown() {
    if (!mounted) return;
    
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final difference = tomorrow.difference(now);
    
    setState(() {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);
      _countdown = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
    
    // Continue updating
    Future.delayed(const Duration(seconds: 1), _updateCountdown);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Row(
          children: [
            // MindRush logo
            ClipOval(
              child: Image.asset(
                'assets/images/mindrush_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text('MindRush'),
          ],
        ),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Notification Settings Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Text('🔔', style: TextStyle(fontSize: 18)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          // Coin Store Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Text('💰', style: TextStyle(fontSize: 18)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CoinStoreScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Consumer<ModeProvider>(
            builder: (context, modeProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildModeToggle(context),
                  const SizedBox(height: 24),
                  
                  // Retention features (daily quests, lucky spin, free coins)
                  const RetentionFeaturesCards(),
                  
                  // Content changes based on mode
                  if (modeProvider.isEducationMode)
                    ..._buildEducationModeCards(context)
                  else
                    ..._buildGeneralModeCards(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        if (user == null) return const SizedBox.shrink();

        return Column(
          children: [
            // Enhanced stats row with better coins design
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedCoinsCard(user.coins),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('🔥', user.streakCount.toString(), 'Streak'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '🎯',
                    '${(user.stats.accuracy * 100).toStringAsFixed(0)}%',
                    'Accuracy',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedCoinsCard(int coins) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade700,
            Colors.amber.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              const Text(
                '💰',
                style: TextStyle(fontSize: 28),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            coins.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const Text(
            'Coins',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNeon,
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

  Widget _buildModeToggle(BuildContext context) {
    return Consumer<ModeProvider>(
      builder: (context, modeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  context,
                  'General',
                  Icons.psychology,
                  modeProvider.currentMode == AppMode.general,
                  () => modeProvider.switchMode(AppMode.general),
                ),
              ),
              Expanded(
                child: _buildModeButton(
                  context,
                  'Education',
                  Icons.school,
                  modeProvider.currentMode == AppMode.education,
                  () => _handleEducationModeSwitch(context, modeProvider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryNeon : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.darkBg : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.darkBg : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEducationModeSwitch(
    BuildContext context,
    ModeProvider modeProvider,
  ) async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    // Check if user has education profile setup
    if (user?.gradeLevel == null || user?.age == null) {
      // Show setup prompt
      final shouldSetup = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: const Text(
            '🎓 Education Mode',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Set up your education profile to get grade-appropriate questions and exam prep!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
              ),
              child: const Text(
                'Set Up',
                style: TextStyle(color: AppTheme.darkBg),
              ),
            ),
          ],
        ),
      );

      if (shouldSetup == true && context.mounted) {
        // Navigate to education settings
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const EducationSettingsScreen(),
          ),
        );

        if (result == true || context.mounted) {
          // Settings saved, switch mode
          await modeProvider.switchMode(AppMode.education);
        }
      }
    } else {
      // Profile already set up, just switch
      await modeProvider.switchMode(AppMode.education);
    }
  }

  Widget _buildAnimatedCampaignCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_animationController.value * 0.015),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CampaignScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.purple.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.shade400.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🎮', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Campaign Mode',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Multiple rounds • Epic journey • Earn stars',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animationController.value * -2),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyChallengeCard(BuildContext context) {
    // Check if daily challenge is completed
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final now = DateTime.now();
    final lastChallenge = user?.lastDailyChallenge ?? DateTime(2000);
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(lastChallenge.year, lastChallenge.month, lastChallenge.day);
    final isCompleted = today == lastDay;

    // If completed, show compact notification banner
    if (isCompleted) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_animationController.value * 0.01),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade800.withOpacity(0.6),
                    Colors.purple.shade700.withOpacity(0.6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.shade400.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Daily Challenge Complete!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Next in: $_countdown',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Show active daily challenge with animation
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animationController.value * -5),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GameScreen(
                    category: 'Mixed',
                    questionCount: 10,
                    mode: GameMode.daily,
                  ),
                ),
              );
            },
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.warningNeon, AppTheme.secondaryNeon],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warningNeon.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '⚡',
                        style: TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Challenge',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '10 questions • ⏱️ 15s each • Double points!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Start Now →',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.white, size: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildGeneralModeCards(BuildContext context) {
    return [
      _buildDailyChallengeCard(context),
      const SizedBox(height: 16),
      _buildAnimatedCampaignCard(context),
      const SizedBox(height: 16),
      _buildModeCard(
        context,
        title: 'Practice Mode',
        subtitle: 'Unlimited play • Learn at your pace',
        emoji: '📚',
        color: AppTheme.primaryNeon,
        onTap: () => _showCategoryDialog(context),
      ),
      const SizedBox(height: 16),
      _buildModeCard(
        context,
        title: 'Play With Friends',
        subtitle: '2-5 players • Just for fun',
        emoji: '👥',
        color: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PlayWithFriendsScreen(),
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      _buildModeCard(
        context,
        title: 'Global League',
        subtitle: 'Ranked • 10 rounds • Worldwide',
        emoji: '🏆',
        color: Colors.amber,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LeaguesScreen(),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildEducationModeCards(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final subscriptionService = context.watch<EducationSubscriptionService>();
    
    // Get user's exam focus
    final examFocus = user?.examFocus ?? 'NONE';
    final hasSat = examFocus == 'SAT' || subscriptionService.hasSatSubscription;
    final hasGmat = examFocus == 'GMAT' || subscriptionService.hasGmatSubscription;
    final gradeDisplay = user?.gradeLevel != null 
        ? GradeLevel.fromCode(user!.gradeLevel!)?.displayName ?? 'College Level'
        : 'College Level';
    
    // Check if user is post-high-school age
    final age = user?.age ?? 0;
    final isBeyondHighSchool = age >= 19;
    
    List<Widget> cards = [];
    
    // Daily Challenge - Education Version
    cards.add(_buildDailyEducationCard(context, gradeDisplay));
    cards.add(const SizedBox(height: 16));
    
    // Subject Practice (only for high school age)
    if (!isBeyondHighSchool) {
      cards.add(_buildModeCard(
        context,
        title: 'Subject Practice',
        subtitle: 'Practice by subject • $gradeDisplay level',
        emoji: '📝',
        color: AppTheme.primaryNeon,
        onTap: () => _showEducationSubjectDialog(context),
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // SAT Prep (if user has SAT)
    if (hasSat) {
      cards.add(_buildModeCard(
        context,
        title: 'SAT Prep',
        subtitle: 'College admission prep • Practice tests',
        emoji: '🎓',
        color: Colors.blue,
        onTap: () => _showEducationSubjectDialog(context, isSat: true),
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // GMAT Prep (if user has GMAT)
    if (hasGmat) {
      cards.add(_buildModeCard(
        context,
        title: 'GMAT Prep',
        subtitle: 'MBA admission prep • Practice tests',
        emoji: '💼',
        color: Colors.orange,
        onTap: () => _showEducationSubjectDialog(context, isGmat: true),
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // Study With Friends - Education Version
    cards.add(_buildModeCard(
      context,
      title: 'Study With Friends',
      subtitle: 'Test each other • Choose subjects together',
      emoji: '👥',
      color: Colors.green,
      onTap: () => _showEducationFriendsDialog(context),
    ));
    cards.add(const SizedBox(height: 16));
    
    // Grade League (only for high school age)
    if (!isBeyondHighSchool) {
      cards.add(_buildModeCard(
        context,
        title: 'Grade League',
        subtitle: 'Compete with $gradeDisplay students',
        emoji: '🏆',
        color: Colors.amber,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LeaguesScreen(),
            ),
          );
        },
      ));
    }
    
    return cards;
  }
  
  void _showEducationFriendsDialog(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    final subscriptionService = context.read<EducationSubscriptionService>();
    
    // Get available study modes
    final examFocus = user?.examFocus ?? 'NONE';
    final hasSat = examFocus == 'SAT' || subscriptionService.hasSatSubscription;
    final hasGmat = examFocus == 'GMAT' || subscriptionService.hasGmatSubscription;
    final age = user?.age ?? 0;
    final isBeyondHighSchool = age >= 19;
    
    List<Map<String, dynamic>> studyModes = [];
    
    // School subjects (for high school age)
    if (!isBeyondHighSchool) {
      studyModes.add({
        'title': 'School Subjects',
        'subtitle': 'Math, Science, English, etc.',
        'emoji': '📚',
        'color': AppTheme.primaryNeon,
        'onTap': () {
          Navigator.pop(context);
          _showEducationSubjectDialog(context, isFriendsMode: true);
        },
      });
    }
    
    // SAT prep
    if (hasSat) {
      studyModes.add({
        'title': 'SAT Practice',
        'subtitle': 'Math & Reading/Writing',
        'emoji': '🎓',
        'color': Colors.blue,
        'onTap': () {
          Navigator.pop(context);
          _showEducationSubjectDialog(context, isSat: true, isFriendsMode: true);
        },
      });
    }
    
    // GMAT prep
    if (hasGmat) {
      studyModes.add({
        'title': 'GMAT Practice',
        'subtitle': 'Quantitative & Verbal',
        'emoji': '💼',
        'color': Colors.orange,
        'onTap': () {
          Navigator.pop(context);
          _showEducationSubjectDialog(context, isGmat: true, isFriendsMode: true);
        },
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: const Text(
            '👥 Study With Friends',
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose what to practice together:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...studyModes.map((mode) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => mode['onTap'](),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (mode['color'] as Color).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            mode['emoji'] as String,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mode['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mode['subtitle'] as String,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: mode['color'] as Color,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyEducationCard(BuildContext context, String gradeLevel) {
    final isCompleted = false; // TODO: Check actual completion

    return GestureDetector(
      onTap: isCompleted ? null : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GameScreen(
              category: 'Mixed',
              questionCount: 10,
              mode: GameMode.daily,
            ),
          ),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: isCompleted
              ? LinearGradient(
                  colors: [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? Colors.grey : AppTheme.primaryNeon,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.school,
                size: 140,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '📚',
                        style: TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCompleted ? 'Daily Challenge Complete!' : 'Daily Class Challenge',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '$gradeLevel • 10 questions',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, color: Color(0xFF6366F1), size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Start Challenge',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

  void _showEducationSubjectDialog(BuildContext context, {bool isSat = false, bool isGmat = false, bool isFriendsMode = false}) {
    String title = 'Choose Subject';
    List<Map<String, String>> subjects = [];
    
    if (isSat) {
      title = isFriendsMode ? 'SAT Study Together' : 'SAT Subjects';
      subjects = [
        {'name': 'All Subjects', 'emoji': '🎲'},
        {'name': 'Math', 'emoji': '🔢'},
        {'name': 'Reading & Writing', 'emoji': '📖'},
      ];
    } else if (isGmat) {
      title = isFriendsMode ? 'GMAT Study Together' : 'GMAT Subjects';
      subjects = [
        {'name': 'All Subjects', 'emoji': '🎲'},
        {'name': 'Quantitative', 'emoji': '🔢'},
        {'name': 'Verbal', 'emoji': '📖'},
        {'name': 'Analytical Writing', 'emoji': '✍️'},
      ];
    } else {
      title = isFriendsMode ? 'Study Together' : 'Choose Subject';
      subjects = [
        {'name': 'All Subjects', 'emoji': '🎲'},
        {'name': 'Math', 'emoji': '🔢'},
        {'name': 'Science', 'emoji': '🔬'},
        {'name': 'English', 'emoji': '📖'},
        {'name': 'History', 'emoji': '📚'},
        {'name': 'Geography', 'emoji': '🌍'},
      ];
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: subjects.map((subject) => ListTile(
            leading: Text(subject['emoji']!, style: const TextStyle(fontSize: 24)),
            title: Text(
              subject['name']!,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: AppTheme.primaryNeon, size: 16),
            onTap: () {
              Navigator.pop(dialogContext);
              if (isFriendsMode) {
                // Navigate to Play With Friends screen with subject pre-selected
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlayWithFriendsScreen(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      category: subject['name']!,
                      questionCount: 10,
                      mode: GameMode.practice,
                    ),
                  ),
                );
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context) {
    final categories = ['Mixed', 'Math', 'Science', 'History', 'Geography', 'Literature'];
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Choose a Category',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories
              .map((category) => ListTile(
                    title: Text(
                      category,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: AppTheme.primaryNeon, size: 16),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            category: category,
                            questionCount: 10,
                            mode: GameMode.practice,
                          ),
                        ),
                      );
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
