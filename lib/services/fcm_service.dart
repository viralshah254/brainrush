import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message: ${message.messageId}');
  debugPrint('📩 Title: ${message.notification?.title}');
  debugPrint('📩 Body: ${message.notification?.body}');
  debugPrint('📩 Data: ${message.data}');
}

/// Firebase Cloud Messaging Service
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize FCM
  Future<void> initialize() async {
    try {
      // Request permissions
      await _requestPermissions();

      // Get FCM token (will be null on iOS Simulator)
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        debugPrint('🔑 FCM Token: $_fcmToken');
      } else {
        debugPrint('⚠️ FCM Token not available (iOS Simulator)');
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle messages when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check for initial message (app opened from terminated state)
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleInitialMessage(initialMessage);
      }

      debugPrint('✅ FCM Service initialized');
    } catch (e) {
      debugPrint('❌ FCM initialization error: $e');
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      return false;
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message: ${message.messageId}');
    debugPrint('🔔 Title: ${message.notification?.title}');
    debugPrint('🔔 Body: ${message.notification?.body}');
    debugPrint('🔔 Data: ${message.data}');
  }

  /// Handle message when app opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🚀 App opened from background: ${message.messageId}');
    debugPrint('🚀 Data: ${message.data}');
  }

  /// Handle initial message when app opened from terminated state
  void _handleInitialMessage(RemoteMessage message) {
    debugPrint('🚀 App opened from terminated state: ${message.messageId}');
    debugPrint('🚀 Data: ${message.data}');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('❌ Error checking notification status: $e');
      return false;
    }
  }

  /// Manually request permissions
  Future<bool> requestPermissions() async {
    return await _requestPermissions();
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }
}
