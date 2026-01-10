import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'leagues/leagues_screen.dart';
import 'friends/play_with_friends_screen.dart';
import '../providers/game_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
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
