import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/fcm_service.dart';
import '../services/local_notification_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String _fcmToken = 'Checking...';
  bool _notificationsEnabled = false;
  int _pendingNotifications = 0;
  bool _isLoading = true;
  final List<String> _testLog = [];

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _addLog('🔍 Checking notification status...');

    try {
      final fcmService = FCMService();
      final localService = LocalNotificationService();

      // Get FCM token (synchronous)
      final token = fcmService.fcmToken;
      if (token != null && token.length > 20) {
        _fcmToken = '${token.substring(0, 20)}...';
        _addLog('✅ FCM Token available');
      } else if (token != null) {
        _fcmToken = token;
        _addLog('✅ FCM Token: $token');
      } else {
        _fcmToken = 'Not available (iOS Simulator)';
        _addLog('⚠️ FCM not available on iOS Simulator');
      }

      // Check permissions with timeout
      try {
        final enabled = await fcmService.areNotificationsEnabled()
            .timeout(const Duration(seconds: 3));
        _notificationsEnabled = enabled;
        _addLog(enabled ? '✅ Notifications enabled' : '❌ Notifications disabled');
      } catch (e) {
        _addLog('⚠️ Could not check permissions: $e');
        _notificationsEnabled = false;
      }

      // Get pending notifications with timeout
      try {
        final pending = await localService.getPendingNotifications()
            .timeout(const Duration(seconds: 3));
        _pendingNotifications = pending.length;
        _addLog('📅 Scheduled notifications: ${pending.length}');
      } catch (e) {
        _addLog('⚠️ Could not get pending notifications: $e');
        _pendingNotifications = 0;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      _addLog('❌ Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _addLog(String message) {
    setState(() {
      final time = DateTime.now().toString().substring(11, 19);
      _testLog.insert(0, '[$time] $message');
    });
  }

  Future<void> _testImmediateNotification() async {
    _addLog('📱 Testing immediate notification...');
    try {
      await LocalNotificationService().showNotification(
        id: 999,
        title: '🧠 Test Notification',
        body: 'This is a test notification from MindRush!',
      );
      _addLog('✅ Notification sent!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check your notification center!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _scheduleMorning() async {
    _addLog('🌅 Scheduling morning reminder...');
    try {
      await LocalNotificationService().scheduleMorningReminder();
      _addLog('✅ Morning reminder scheduled for 8 AM');
      await _checkStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Morning reminder scheduled for 8 AM tomorrow'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _scheduleDailyChallenge() async {
    _addLog('⚡ Scheduling daily challenge...');
    try {
      await LocalNotificationService().scheduleDailyChallenge();
      _addLog('✅ Daily challenge scheduled for 12:05 AM');
      await _checkStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Daily challenge scheduled for 12:05 AM'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _scheduleLeague() async {
    _addLog('🏆 Scheduling league reminder...');
    try {
      await LocalNotificationService().scheduleLeagueReminder();
      _addLog('✅ League reminder scheduled for 11 AM');
      await _checkStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ League reminder scheduled for 11 AM tomorrow'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _scheduleAll() async {
    _addLog('📅 Scheduling all notifications...');
    try {
      await LocalNotificationService().scheduleAllNotifications();
      _addLog('✅ All notifications scheduled');
      await _checkStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All recurring notifications scheduled!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _cancelAll() async {
    _addLog('🗑️ Cancelling all notifications...');
    try {
      await LocalNotificationService().cancelAllNotifications();
      _addLog('✅ All notifications cancelled');
      await _checkStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All notifications cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    _addLog('🔓 Requesting permissions...');
    try {
      final granted = await FCMService().requestPermissions();
      _addLog(granted ? '✅ Permissions granted' : '❌ Permissions denied');
      await _checkStatus();
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🔔', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Text('Notification Tester'),
          ],
        ),
        backgroundColor: AppTheme.darkCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // iOS Simulator Warning
                  if (Platform.isIOS)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'FCM push notifications require a real iPhone. Local notifications work on Simulator.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 24),

                  // Test Actions
                  _buildSectionTitle('Quick Tests'),
                  _buildActionButton(
                    '📱 Test Immediate Notification',
                    'Send a notification right now',
                    _testImmediateNotification,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    '🔓 Request Permissions',
                    'Request notification permissions',
                    _requestPermissions,
                    Colors.purple,
                  ),
                  const SizedBox(height: 24),

                  // Schedule Notifications
                  _buildSectionTitle('Schedule Recurring Notifications'),
                  _buildActionButton(
                    '🌅 Morning Reminder',
                    'Schedule for 8 AM daily',
                    _scheduleMorning,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    '⚡ Daily Challenge',
                    'Schedule for 12:05 AM daily',
                    _scheduleDailyChallenge,
                    Colors.cyan,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    '🏆 League Reminder',
                    'Schedule for 11 AM daily',
                    _scheduleLeague,
                    Colors.amber,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    '📅 Schedule All',
                    'Schedule all recurring notifications',
                    _scheduleAll,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    '🗑️ Cancel All',
                    'Remove all scheduled notifications',
                    _cancelAll,
                    Colors.red,
                  ),
                  const SizedBox(height: 24),

                  // Test Log
                  _buildSectionTitle('Activity Log'),
                  _buildLogCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusRow('FCM Token', _fcmToken),
          _buildStatusRow(
            'Permissions',
            _notificationsEnabled ? 'Granted ✅' : 'Denied ❌',
          ),
          _buildStatusRow(
            'Scheduled',
            '$_pendingNotifications notification${_pendingNotifications == 1 ? '' : 's'}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

  Widget _buildActionButton(
    String title,
    String subtitle,
    VoidCallback onPressed,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.notifications_active, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
      ),
      child: _testLog.isEmpty
          ? const Center(
              child: Text(
                'No activity yet',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: _testLog.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _testLog[index],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

