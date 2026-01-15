import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/retention_service.dart';
import '../providers/user_provider.dart';
import '../models/daily_quest.dart';
import '../providers/game_provider.dart';
import 'campaign/campaign_screen.dart';
import 'game_screen.dart';

class DailyQuestsScreen extends StatelessWidget {
  const DailyQuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final retentionService = context.watch<RetentionService>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('🎯 Daily Quests'),
        backgroundColor: AppTheme.darkBg,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryNeon.withOpacity(0.2),
                    AppTheme.secondaryNeon.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryNeon.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Missions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete quests to earn coins!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${retentionService.completedQuestsCount}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBg,
                          ),
                        ),
                        Text(
                          '/${retentionService.totalQuestsCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkBg.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quests list
            Expanded(
              child: retentionService.dailyQuests.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: retentionService.dailyQuests.length,
                      itemBuilder: (context, index) {
                        final quest = retentionService.dailyQuests[index];
                        return _QuestCard(
                          quest: quest,
                          onTap: () => _handleQuestTap(context, quest),
                          onClaim: () async {
                            final coins = await retentionService.claimQuestReward(quest.id);
                            if (coins > 0) {
                              userProvider.addCoins(coins);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 +$coins coins earned!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
            ),

            // All quests completed bonus
            if (retentionService.allQuestsCompleted)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade700, Colors.amber.shade400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          '🏆',
                          style: TextStyle(fontSize: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'All Quests Complete!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkBg,
                                ),
                              ),
                              Text(
                                retentionService.allQuestsBonusClaimed
                                    ? 'Amazing work! Come back tomorrow for new quests.'
                                    : 'Claim your bonus reward!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.darkBg.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!retentionService.allQuestsBonusClaimed) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final bonus = await retentionService.claimAllQuestsBonus();
                            if (bonus > 0) {
                              userProvider.addCoins(bonus);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 +$bonus bonus coins earned!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkBg,
                            foregroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Claim +500 Bonus Coins',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleQuestTap(BuildContext context, DailyQuest quest) {
    switch (quest.type) {
      case QuestType.playGames:
        // Navigate to home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case QuestType.playDaily:
        // Navigate to daily challenge
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GameScreen(
              category: 'Mixed',
              questionCount: 10,
              mode: GameMode.daily,
            ),
          ),
        );
        break;
      case QuestType.completeCampaign:
        // Navigate to campaign screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CampaignScreen(),
          ),
        );
        break;
      case QuestType.playWithFriends:
        // Hidden - do nothing
        break;
      default:
        // Navigate to home screen for other quests
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
    }
  }
}

class _QuestCard extends StatelessWidget {
  final DailyQuest quest;
  final VoidCallback? onTap;
  final VoidCallback onClaim;

  const _QuestCard({
    required this.quest,
    this.onTap,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quest.isCompleted
                ? Colors.green.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Text(
                  quest.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quest.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (quest.isCompleted)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryNeon),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: AppTheme.primaryNeon,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${quest.coinReward}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNeon,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${quest.currentValue}/${quest.targetValue}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: quest.progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      quest.isCompleted ? Colors.green : AppTheme.primaryNeon,
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

