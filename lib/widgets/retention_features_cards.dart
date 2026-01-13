import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../services/retention_service.dart';
import '../screens/daily_quests_screen.dart';
import '../screens/lucky_spin_screen.dart';

class RetentionFeaturesCards extends StatelessWidget {
  const RetentionFeaturesCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily Quests Card
        _buildDailyQuestsCard(context),
        const SizedBox(height: 12),
        
        // Row with Lucky Spin and Free Coins
        Row(
          children: [
            Expanded(child: _buildLuckySpinCard(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildFreeCoinsCard(context)),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDailyQuestsCard(BuildContext context) {
    final retentionService = context.watch<RetentionService>();
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyQuestsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryNeon, AppTheme.secondaryNeon],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🎯', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Quests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${retentionService.completedQuestsCount}/${retentionService.totalQuestsCount} completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (retentionService.allQuestsCompleted)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuckySpinCard(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final canSpin = user?.canSpinLuckyWheel ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LuckySpinScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: canSpin
                  ? [Colors.purple.shade700, Colors.purple.shade500]
                  : [Colors.grey.shade800, Colors.grey.shade700],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canSpin
                  ? Colors.purple.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '🎰',
                style: TextStyle(
                  fontSize: 32,
                  color: canSpin ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lucky Spin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: canSpin ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                canSpin ? 'Available!' : 'Tomorrow',
                style: TextStyle(
                  fontSize: 12,
                  color: canSpin
                      ? Colors.white.withOpacity(0.8)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeCoinsCard(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final canClaim = user?.canClaimFreeCoins ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canClaim
            ? () => _claimFreeCoins(context)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: canClaim
                  ? [Colors.green.shade700, Colors.green.shade500]
                  : [Colors.grey.shade800, Colors.grey.shade700],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canClaim
                  ? Colors.green.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '⏰',
                style: TextStyle(
                  fontSize: 32,
                  color: canClaim ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Free Coins',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: canClaim ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              if (canClaim)
                const Text(
                  '+50 coins',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  _formatTimeRemaining(user?.timeUntilNextFreeCoins),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _claimFreeCoins(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    userProvider.addCoins(50);
    userProvider.claimFreeCoins();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 +50 free coins claimed!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimeRemaining(Duration? duration) {
    if (duration == null || duration == Duration.zero) return 'Ready!';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

