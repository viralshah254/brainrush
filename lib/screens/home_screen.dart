import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/mode_provider.dart';
import '../theme/app_theme.dart';
import '../models/app_mode.dart';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildModeToggle(context),
              const SizedBox(height: 24),
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
            ],
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

  void _showCategoryDialog(BuildContext context) {
    final categories = ['Math', 'Science', 'History', 'Geography', 'Literature'];
    
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
                            questionCount: 5,
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
