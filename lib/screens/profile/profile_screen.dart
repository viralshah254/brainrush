import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final user = userProvider.user;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryNeon.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user.username[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkBg,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: user.isGuest
                                ? Colors.orange.withOpacity(0.2)
                                : AppTheme.primaryNeon.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: user.isGuest
                                  ? Colors.orange
                                  : AppTheme.primaryNeon,
                            ),
                          ),
                          child: Text(
                            user.isGuest ? '👤 Guest User' : '✓ Verified',
                            style: TextStyle(
                              fontSize: 14,
                              color: user.isGuest
                                  ? Colors.orange
                                  : AppTheme.primaryNeon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Grid
                  const Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '💰',
                          user.coins.toString(),
                          'Coins',
                          AppTheme.warningNeon,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '🔥',
                          user.streakCount.toString(),
                          'Streak',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '🎯',
                          '${(user.stats.accuracy * 100).toStringAsFixed(0)}%',
                          'Accuracy',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '⭐',
                          user.stats.totalScore.toString(),
                          'Total Score',
                          AppTheme.primaryNeon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '✅',
                          user.stats.correctAnswers.toString(),
                          'Correct',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '❓',
                          user.stats.questionsAnswered.toString(),
                          'Questions',
                          AppTheme.accentNeon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Achievements Section
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _buildAchievement(
                          '🎓',
                          'Brain Beginner',
                          'Complete your first game',
                          user.stats.questionsAnswered > 0,
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        _buildAchievement(
                          '🏆',
                          'Quiz Master',
                          'Answer 100 questions',
                          user.stats.questionsAnswered >= 100,
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        _buildAchievement(
                          '💯',
                          'Perfect Score',
                          'Get 100% accuracy in a game',
                          user.stats.accuracy == 1.0,
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        _buildAchievement(
                          '💎',
                          'Coin Collector',
                          'Earn 1000 coins',
                          user.coins >= 1000,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Settings Section
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          Icons.notifications,
                          'Notifications',
                          'Manage notifications',
                          () {},
                        ),
                        const Divider(height: 1, color: Colors.white10),
                        _buildSettingItem(
                          Icons.language,
                          'Language',
                          'English',
                          () {},
                        ),
                        const Divider(height: 1, color: Colors.white10),
                        _buildSettingItem(
                          Icons.help,
                          'Help & Support',
                          'Get help',
                          () {},
                        ),
                        const Divider(height: 1, color: Colors.white10),
                        _buildSettingItem(
                          Icons.info,
                          'About',
                          'BrainRush v1.0.0',
                          () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button (for guest users)
                  if (user.isGuest)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to sign up
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sign up coming soon!'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNeon,
                          foregroundColor: AppTheme.darkBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sign Up & Get 100 Coins',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(
    String emoji,
    String title,
    String description,
    bool isUnlocked,
  ) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppTheme.primaryNeon.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: 28,
                color: isUnlocked ? null : Colors.white.withOpacity(0.3),
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
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.white : Colors.white60,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: isUnlocked ? Colors.white60 : Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
        Icon(
          isUnlocked ? Icons.check_circle : Icons.lock,
          color: isUnlocked ? Colors.green : Colors.white30,
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryNeon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white60,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white30,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}

