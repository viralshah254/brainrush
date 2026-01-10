import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/app_mode.dart';
import '../../services/education_subscription_service.dart';

class EducationPaywallScreen extends StatelessWidget {
  final ExamFocus examFocus;

  const EducationPaywallScreen({
    super.key,
    required this.examFocus,
  });

  @override
  Widget build(BuildContext context) {
    final subscriptionService = context.watch<EducationSubscriptionService>();
    
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCard,
        title: Text(
          '${examFocus.displayName} Unlock',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryNeon.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    examFocus == ExamFocus.sat ? Icons.school : Icons.business_center,
                    size: 80,
                    color: AppTheme.primaryNeon,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    examFocus.displayName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    examFocus == ExamFocus.sat
                        ? 'Master the SAT with targeted practice'
                        : 'Ace your GMAT with expert-level questions',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Features List
            _buildFeatureItem(
              context,
              Icons.quiz,
              'Full Question Bank',
              '1000+ ${examFocus.code} practice questions',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.timer,
              'Timed Section Drills',
              'Simulate real exam conditions',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.analytics,
              'Performance Analytics',
              'Track progress by topic',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.lightbulb,
              'Detailed Explanations',
              'Understand every answer',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.block,
              'Ad-Free Experience',
              'Focus on learning',
            ),
            
            const SizedBox(height: 32),
            
            // Pricing
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryNeon.withOpacity(0.2),
                    AppTheme.primaryNeon.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppTheme.primaryNeon.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    examFocus == ExamFocus.sat
                        ? EducationSubscriptionService.satPrice
                        : EducationSubscriptionService.gmatPrice,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppTheme.primaryNeon,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cancel anytime • Full access',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Subscribe Button
            ElevatedButton(
              onPressed: () => _handleSubscribe(context, subscriptionService),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                foregroundColor: AppTheme.darkBg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start ${examFocus.displayName} Prep',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.darkBg,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Restore Button
            TextButton(
              onPressed: () => _handleRestore(context, subscriptionService),
              child: Text(
                'Restore Purchase',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.primaryNeon,
                    ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Terms
            Text(
              'By subscribing, you agree to our Terms of Service and Privacy Policy',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryNeon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryNeon,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubscribe(
    BuildContext context,
    EducationSubscriptionService service,
  ) async {
    // Track analytics
    // ignore: avoid_print
    print('📊 Analytics: subscribe_tap - ${examFocus.code}');
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryNeon,
        ),
      ),
    );
    
    // Purchase
    bool success = false;
    if (examFocus == ExamFocus.sat) {
      success = await service.purchaseSatSubscription();
    } else if (examFocus == ExamFocus.gmat) {
      success = await service.purchaseGmatSubscription();
    }
    
    // Close loading
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    // Show result
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${examFocus.displayName} unlocked! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleRestore(
    BuildContext context,
    EducationSubscriptionService service,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryNeon,
        ),
      ),
    );
    
    // Restore
    await service.restorePurchases();
    
    // Close loading
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    // Check if user has subscription now
    if (context.mounted) {
      final hasAccess = service.canAccessExamMode(examFocus);
      if (hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase restored! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchase found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

