import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';

class TryAgainDialog extends StatelessWidget {
  final VoidCallback onTryAgain;
  final VoidCallback onSkip;

  const TryAgainDialog({
    super.key,
    required this.onTryAgain,
    required this.onSkip,
  });

  static Future<bool?> show(
    BuildContext context, {
    required VoidCallback onTryAgain,
    required VoidCallback onSkip,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TryAgainDialog(
        onTryAgain: onTryAgain,
        onSkip: onSkip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = PremiumService().isPremium;

    return Dialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Incorrect Answer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              isPremium
                  ? 'Would you like to try again?'
                  : 'Watch a short ad to try again or skip to see the answer',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Try Again Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (isPremium) {
                    // Premium users can try again without ads
                    Navigator.pop(context, true);
                    onTryAgain();
                  } else {
                    // Show ad for free users
                    final adShown = await AdService().showTryAgainAd();
                    if (adShown && context.mounted) {
                      Navigator.pop(context, true);
                      onTryAgain();
                    } else if (context.mounted) {
                      // Ad not ready, allow try anyway
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ad not available. Try again for free!'),
                        ),
                      );
                      Navigator.pop(context, true);
                      onTryAgain();
                    }
                  }
                },
                icon: Icon(
                  isPremium ? Icons.replay : Icons.play_circle_filled,
                  size: 24,
                ),
                label: Text(
                  isPremium ? 'Try Again' : 'Watch Ad & Try Again',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNeon,
                  foregroundColor: AppTheme.darkBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Skip Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context, false);
                  onSkip();
                },
                icon: const Icon(Icons.skip_next, size: 24),
                label: const Text(
                  'Skip & See Answer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30, width: 2),
                  foregroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

