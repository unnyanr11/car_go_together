import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Initialize notification services
  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onSelectNotification,
      );

      // Configure FCM for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Get the token
      String? token = await _messaging.getToken();
      if (token != null) {
        _saveToken(token); // Now only called if token is not null
      } else {
        // Optional: Handle the case where the token couldn't be retrieved
        print("Failed to get FCM token.");
      }

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen(_saveToken);
    }
  }

  // Save FCM token to Firestore for the current user
  Future<void> _saveToken(String token) async {
    // This would typically be tied to the current user ID
    // For now, let's just log it or store in a generic place
    print('FCM Token: $token');
  }

  // Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'safarmilao_channel',
      'SafarMilao Notifications',
      channelDescription: 'SafarMilao app notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Handle notification tap
  void _onSelectNotification(NotificationResponse response) {
    // Parse the payload and navigate to the appropriate screen
    print('Notification tapped with payload: ${response.payload}');
    // Navigator.pushNamed(context, '/notification_details', arguments: response.payload);
  }

  // Subscribe to a topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Send a notification to a specific user
  Future<void> sendNotificationToUser(
    String userId,
    String title,
    String body,
  ) async {
    try {
      // This would typically be done via a Cloud Function or backend API
      // For now, we'll log it
      print('Sending notification to user $userId: $title - $body');
    } catch (e) {
      throw Exception('Failed to send notification: ${e.toString()}');
    }
  }
}
