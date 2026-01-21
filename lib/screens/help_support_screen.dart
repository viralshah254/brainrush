import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline,
                  size: 40,
                  color: AppTheme.primaryNeon,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'We\'re Here to Help!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Have a question or need assistance? We\'re just an email away.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Contact Email Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryNeon.withOpacity(0.2),
                    AppTheme.successNeon.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryNeon.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.email,
                    size: 48,
                    color: AppTheme.primaryNeon,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Email Us',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'help@dvtechventures.com',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.primaryNeon,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final emailUri = Uri(
                        scheme: 'mailto',
                        path: 'help@dvtechventures.com',
                        query: 'subject=MindRush Support Request',
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to open email app'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNeon,
                      foregroundColor: AppTheme.darkBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // FAQ Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            _buildFAQItem(
              question: 'How do I play MindRush?',
              answer: 'MindRush is a quiz game where you answer questions across various categories. Choose a game mode (Campaign, Practice, Daily Challenge, or Play with Friends) and start answering questions to earn points and coins!',
            ),
            const SizedBox(height: 12),
            
            _buildFAQItem(
              question: 'How do I earn coins?',
              answer: 'You can earn coins by playing games, completing daily challenges, watching ads, spinning the lucky wheel, and completing daily quests. Coins are used to enter campaign rounds and multiplayer games.',
            ),
            const SizedBox(height: 12),
            
            _buildFAQItem(
              question: 'What are streaks?',
              answer: 'Streaks track how many consecutive days you\'ve played. Maintain your streak by playing at least once every day to earn bonus rewards!',
            ),
            const SizedBox(height: 12),
            
            _buildFAQItem(
              question: 'How do I add friends?',
              answer: 'Go to the Friends tab and tap "Find Friends". You can search for users by username or find contacts from your phone who also play MindRush.',
            ),
            const SizedBox(height: 12),
            
            _buildFAQItem(
              question: 'What is Education Mode?',
              answer: 'Education Mode provides grade-specific questions tailored to your school system and grade level. Perfect for students who want to learn while having fun!',
            ),
            const SizedBox(height: 12),
            
            _buildFAQItem(
              question: 'How do leaderboards work?',
              answer: 'Leaderboards rank players based on their scores. You can compete globally, weekly, monthly, or by category. Climb the ranks to become the top player!',
            ),
            const SizedBox(height: 32),

            // Additional Help Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryNeon,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Need More Help?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If you can\'t find the answer you\'re looking for, please don\'t hesitate to reach out to us. Our support team is ready to assist you with any questions or issues you may have.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Response Time: We typically respond within 24-48 hours.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryNeon,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
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
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}




