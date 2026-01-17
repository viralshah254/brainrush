import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../theme/app_theme.dart';
import '../services/social_sharing_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementService _achievementService = AchievementService();
  AchievementCategory _selectedCategory = AchievementCategory.gameplay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    await _achievementService.loadUserAchievements();
    setState(() => _isLoading = false);
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.gameplay:
        return 'Gameplay';
      case AchievementCategory.milestones:
        return 'Milestones';
      case AchievementCategory.streaks:
        return 'Streaks';
      case AchievementCategory.accuracy:
        return 'Accuracy';
      case AchievementCategory.coins:
        return 'Coins';
      case AchievementCategory.campaign:
        return 'Campaign';
      case AchievementCategory.social:
        return 'Social';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_achievementService.unlockedCount}/${_achievementService.totalCount}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Achievements Unlocked',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.primaryGradient,
                            ),
                            child: Center(
                              child: Text(
                                '${_achievementService.completionPercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _achievementService.completionPercentage / 100,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryNeon,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category tabs
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: AchievementCategory.values.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(_getCategoryName(category)),
                          onSelected: (selected) {
                            setState(() => _selectedCategory = category);
                          },
                          selectedColor: AppTheme.primaryNeon,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.darkBg : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: AppTheme.darkCard,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Achievements list
                Expanded(
                  child: _buildAchievementsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildAchievementsList() {
    final achievements = _achievementService
        .getAchievementsByCategory(_selectedCategory);

    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'No achievements in this category',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final userAchievement = _achievementService.getUserAchievement(achievement.id);
        final progress = _achievementService.getProgressPercentage(achievement.id);
        final isUnlocked = userAchievement?.isUnlocked ?? false;
        final rarityColor = _getRarityColor(achievement.rarity);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnlocked
                  ? rarityColor.withOpacity(0.5)
                  : Colors.white10,
              width: isUnlocked ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: isUnlocked ? 1.0 : 0.6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Emoji/Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? rarityColor.withOpacity(0.2)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnlocked ? rarityColor : Colors.white30,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isUnlocked ? achievement.emoji : '🔒',
                        style: TextStyle(
                          fontSize: isUnlocked ? 30 : 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                achievement.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? Colors.white : Colors.white60,
                                ),
                              ),
                            ),
                            if (isUnlocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: rarityColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  achievement.rarity.toString().split('.').last.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: rarityColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 6,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isUnlocked ? rarityColor : Colors.white30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${userAchievement?.currentProgress ?? 0}/${achievement.targetValue}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            if (isUnlocked && (achievement.coinReward > 0 || achievement.xpReward > 0))
                              Row(
                                children: [
                                  if (achievement.coinReward > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Row(
                                        children: [
                                          const Text('🪙', style: TextStyle(fontSize: 12)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${achievement.coinReward}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (achievement.xpReward > 0)
                                    Row(
                                      children: [
                                        const Text('⭐', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${achievement.xpReward}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.primaryNeon,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

