import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/mode_provider.dart';
import '../theme/app_theme.dart';
import '../models/app_mode.dart';
import '../services/education_subscription_service.dart';
import 'game_screen.dart';
import 'leagues/leagues_screen.dart';
import 'friends/play_with_friends_screen.dart';
import 'campaign/campaign_screen.dart';
import 'education/education_settings_screen.dart';
import '../providers/game_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Brainz Rush'),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        automaticallyImplyLeading: false,
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBg,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Keep that brain fresh! 🧠',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('💰', user.coins.toString(), 'Coins'),
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

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
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
    );
  }

  Widget _buildDailyChallengeCard(BuildContext context) {
    // Check if daily challenge is completed
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    // Simple completion check (in production, use proper storage)
    final isCompleted = false; // TODO: Check actual completion status

    return GestureDetector(
      onTap: isCompleted
          ? null
          : () {
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
                  colors: [Colors.grey.shade800, Colors.grey.shade700],
                )
              : const LinearGradient(
                  colors: [AppTheme.warningNeon, AppTheme.secondaryNeon],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? Colors.black26
                  : AppTheme.warningNeon.withOpacity(0.3),
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
                        isCompleted
                            ? 'Completed! Come back tomorrow'
                            : '10 questions • ⏱️ 15s each • Double points!',
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
    );
  }

  List<Widget> _buildGeneralModeCards(BuildContext context) {
    return [
      _buildDailyChallengeCard(context),
      const SizedBox(height: 16),
      _buildModeCard(
        context,
        title: 'Campaign Mode',
        subtitle: '500 rounds • Epic journey • Earn stars',
        emoji: '🎮',
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CampaignScreen(),
            ),
          );
        },
      ),
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
