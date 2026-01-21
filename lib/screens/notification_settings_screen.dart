import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/notification_preferences.dart';
import '../services/smart_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final SmartNotificationService _notificationService = SmartNotificationService();
  late NotificationPreferences _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await _notificationService.loadPreferences();
    setState(() => _isLoading = false);
  }

  Future<void> _savePreferences() async {
    await _notificationService.savePreferences(_prefs);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notification preferences saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          title: const Text('Notification Settings'),
          backgroundColor: AppTheme.darkCard,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppTheme.darkCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active, size: 32, color: Colors.white),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'We\'ll only send you what matters, when it matters',
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
            ),
            const SizedBox(height: 24),

            // Notification Types
            _buildSectionTitle('Notification Types'),
            _buildSwitchCard(
              '⚡ Daily Challenge',
              'Get notified when the daily challenge is ready',
              _prefs.enableDailyChallenge,
              (value) => setState(() {
                _prefs = _prefs.copyWith(enableDailyChallenge: value);
              }),
            ),
            _buildSwitchCard(
              '🔥 Streak Reminders',
              'Gentle reminder to maintain your streak',
              _prefs.enableStreakReminders,
              (value) => setState(() {
                _prefs = _prefs.copyWith(enableStreakReminders: value);
              }),
            ),
            _buildSwitchCard(
              '🏆 League Matches',
              'Reminders for league competitions',
              _prefs.enableLeagueReminders,
              (value) => setState(() {
                _prefs = _prefs.copyWith(enableLeagueReminders: value);
              }),
            ),
            _buildSwitchCard(
              '🎯 Achievements',
              'When you unlock something awesome',
              _prefs.enableAchievementNotifications,
              (value) => setState(() {
                _prefs = _prefs.copyWith(enableAchievementNotifications: value);
              }),
            ),
            _buildSwitchCard(
              '👥 Friend Invites',
              'When friends invite you to play',
              _prefs.enableFriendInvites,
              (value) => setState(() {
                _prefs = _prefs.copyWith(enableFriendInvites: value);
              }),
            ),
            const SizedBox(height: 24),

            // Preferred Time
            _buildSectionTitle('Preferred Notification Time'),
            _buildTimePreferenceCard(),
            const SizedBox(height: 24),

            // Quiet Hours
            _buildSectionTitle('Quiet Hours'),
            _buildQuietHoursCard(),
            const SizedBox(height: 24),

            // Daily Limit
            _buildSectionTitle('Daily Limit'),
            _buildDailyLimitCard(),
            const SizedBox(height: 32),

            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We respect your time. Notifications are designed to be helpful, not intrusive.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchCard(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryNeon,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePreferenceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildTimeOption('Morning', 'Around 9 AM', 'morning'),
          const Divider(color: Colors.white12),
          _buildTimeOption('Afternoon', 'Around 2 PM', 'afternoon'),
          const Divider(color: Colors.white12),
          _buildTimeOption('Evening', 'Around 7 PM', 'evening'),
        ],
      ),
    );
  }

  Widget _buildTimeOption(String label, String time, String value) {
    final isSelected = _prefs.preferredTime == value;
    return InkWell(
      onTap: () => setState(() {
        _prefs = _prefs.copyWith(preferredTime: value);
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryNeon : Colors.white54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bedtime, color: AppTheme.primaryNeon, size: 20),
              SizedBox(width: 8),
              Text(
                'No notifications during these hours',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_prefs.quietHoursStart.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white54),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'End',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_prefs.quietHoursEnd.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLimitCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Maximum notifications per day',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_prefs.maxNotificationsPerDay}',
                style: const TextStyle(
                  color: AppTheme.primaryNeon,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _prefs.maxNotificationsPerDay.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppTheme.primaryNeon,
            inactiveColor: Colors.white24,
            onChanged: (value) => setState(() {
              _prefs = _prefs.copyWith(maxNotificationsPerDay: value.toInt());
            }),
          ),
          const Text(
            'Recommended: 3 per day',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}





