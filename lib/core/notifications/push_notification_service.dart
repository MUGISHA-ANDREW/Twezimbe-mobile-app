import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart';

class PushNotificationService {
  const PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;
  static const String _tokenKeyPrefix = 'fcm_token_for_user_';

  static Future<void> initialize() async {
    if (_isInitialized || kIsWeb) {
      return;
    }

    // Request permission on iOS
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print(
        'Push notification permission status: ${settings.authorizationStatus}',
      );
    }

    // Get token
    final token = await _messaging.getToken();
    if (kDebugMode) {
      print('FCM Token: $token');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }

    _isInitialized = true;
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Show local notification for foreground messages
    LocalNotificationService.showNotification(
      title: notification.title ?? 'Twezimbe',
      body: notification.body ?? '',
      payload: message.data.toString(),
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateToNotification(message);
  }

  static void _handleInitialMessage(RemoteMessage message) {
    _navigateToNotification(message);
  }

  static void _navigateToNotification(RemoteMessage message) {
    // Handle navigation based on notification data
    final data = message.data;
    final type = data['type'] ?? '';

    if (kDebugMode) {
      print('Notification type: $type');
      print('Notification data: $data');
    }

    NotificationHandler.setPendingNotification(message);
  }

  static Future<void> saveTokenLocally(String userId) async {
    final token = await _messaging.getToken();
    if (token == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_tokenKeyPrefix$userId', token);
      await prefs.setString(
        '$_tokenKeyPrefix${userId}_platform',
        defaultTargetPlatform.name,
      );
      await prefs.setString(
        '$_tokenKeyPrefix${userId}_updatedAt',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
}

// Helper class to handle notification taps
class NotificationHandler {
  static String? _pendingNotificationType;
  static Map<String, dynamic>? _pendingNotificationData;

  static void setPendingNotification(RemoteMessage message) {
    _pendingNotificationType = message.data['type'];
    _pendingNotificationData = message.data;
  }

  static String? get pendingNotificationType => _pendingNotificationType;
  static Map<String, dynamic>? get pendingNotificationData =>
      _pendingNotificationData;

  static void clearPendingNotification() {
    _pendingNotificationType = null;
    _pendingNotificationData = null;
  }
}
