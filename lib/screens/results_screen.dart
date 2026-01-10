import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int correctAnswers;

  const ResultsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = (correctAnswers / totalQuestions * 100).toStringAsFixed(1);
    final isPerfect = correctAnswers == totalQuestions;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy or star icon
              Icon(
                isPerfect ? Icons.emoji_events : Icons.star,
                size: 100,
                color: isPerfect ? Colors.amber : AppTheme.primaryNeon,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                isPerfect ? 'Perfect!' : 'Great Job!',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Challenge Complete',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Score',
                      score.toString(),
                      Icons.stars,
                      AppTheme.primaryNeon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Correct',
                      '$correctAnswers/$totalQuestions',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Accuracy',
                      '$accuracy%',
                      Icons.percent,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Coins Earned',
                      '+${score ~/ 10}',
                      Icons.monetization_on,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Buttons
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNeon,
                    foregroundColor: AppTheme.darkBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryNeon),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.primaryNeon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
}
