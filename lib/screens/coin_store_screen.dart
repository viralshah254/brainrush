import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';
import '../widgets/ad_loading_dialog.dart';

class CoinStoreScreen extends StatelessWidget {
  const CoinStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/mindrush_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Coin Store'),
          ],
        ),
        backgroundColor: AppTheme.darkBg,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final coins = userProvider.user?.coins ?? 0;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current Balance
                _buildBalanceCard(coins),
                const SizedBox(height: 24),
                
                // Free Coins Section
                _buildSectionTitle('🎁 Free Coins'),
                const SizedBox(height: 12),
                _buildAdRewardCard(context, userProvider),
                const SizedBox(height: 32),
                
                // Purchase Coins Section
                _buildSectionTitle('💰 Buy Coins'),
                const SizedBox(height: 12),
                _buildCoinPackage(
                  context,
                  coins: 500,
                  price: '\$0.99',
                  bonus: 'Starter Pack',
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                ),
                const SizedBox(height: 12),
                _buildCoinPackage(
                  context,
                  coins: 1200,
                  price: '\$1.99',
                  bonus: '+200 Bonus!',
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade700, Colors.purple.shade500],
                  ),
                ),
                const SizedBox(height: 12),
                _buildCoinPackage(
                  context,
                  coins: 3000,
                  price: '\$3.99',
                  bonus: '+500 Bonus!',
                  popular: true,
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade500],
                  ),
                ),
                const SizedBox(height: 12),
                _buildCoinPackage(
                  context,
                  coins: 6500,
                  price: '\$6.99',
                  bonus: '+1500 Bonus!',
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade700, Colors.pink.shade500],
                  ),
                ),
                const SizedBox(height: 12),
                _buildCoinPackage(
                  context,
                  coins: 15000,
                  price: '\$14.99',
                  bonus: '+5000 Bonus!',
                  bestValue: true,
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade700, Colors.amber.shade500],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Info
                _buildInfoCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(int coins) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Balance',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💰', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text(
                coins.toString(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Coins',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdRewardCard(BuildContext context, UserProvider userProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _watchAdForCoins(context, userProvider),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('📺', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Watch Ad for Coins',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Earn 50 coins per ad',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinPackage(
    BuildContext context, {
    required int coins,
    required String price,
    required String bonus,
    required Gradient gradient,
    bool popular = false,
    bool bestValue = false,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: popular || bestValue
                  ? Colors.amber
                  : Colors.white24,
              width: popular || bestValue ? 3 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _purchaseCoins(context, coins, price),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('💰', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$coins Coins',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bonus,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (popular)
          Positioned(
            top: -8,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '⭐ POPULAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        if (bestValue)
          Positioned(
            top: -8,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🔥 BEST VALUE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryNeon, size: 20),
              SizedBox(width: 8),
              Text(
                'How to Use Coins',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('• Play with Friends: 50 coins per game'),
          _buildInfoItem('• Campaign Mode: Costs coins to enter levels'),
          _buildInfoItem('• Global League: Entry fee required'),
          _buildInfoItem('• Win coins by completing challenges'),
          _buildInfoItem('• Watch ads to earn free coins'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
    );
  }

  Future<void> _watchAdForCoins(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    final premiumService = context.read<PremiumService>();
    
    if (premiumService.isPremium) {
      // Premium users get coins without ads
      userProvider.addCoins(50);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Premium reward: +50 coins!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    
    final adService = context.read<AdService>();
    
    // Show loading dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AdLoadingDialog(
        message: 'Loading ad...',
      ),
    );

    // Try to show ad
    final watched = await adService.showTryAgainAd();
    
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close loading dialog
    
    if (watched) {
      // Award coins
      userProvider.addCoins(50);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💰 +50 coins earned!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load ad. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _purchaseCoins(
    BuildContext context,
    int coins,
    String price,
  ) async {
    // TODO: Implement in-app purchase
    // For now, show coming soon dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '💳 Purchase Coins',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Purchase $coins coins for $price?\n\n(In-app purchases coming soon)',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Award coins for testing
              context.read<UserProvider>().addCoins(coins);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ $coins coins added! (Test mode)'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
            ),
            child: const Text('Buy (Test)'),
          ),
        ],
      ),
    );
  }
}

