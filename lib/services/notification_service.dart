import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling push notifications and FCM tokens
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  String? _fcmToken;
  
  // SOS Notification channel for Android (highest priority)
  static const AndroidNotificationChannel _sosChannel = AndroidNotificationChannel(
    'sos_alerts_channel',
    'SOS Alerts',
    description: 'Emergency SOS alerts from volunteers',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // General notification channel
  static const AndroidNotificationChannel _generalChannel = AndroidNotificationChannel(
    'general_channel',
    'General Notifications',
    description: 'General app notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // Donation notification channel
  static const AndroidNotificationChannel _donationsChannel = AndroidNotificationChannel(
    'donations_channel',
    'Donation Notifications',
    description: 'Notifications about donations',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // Event reminder channel
  static const AndroidNotificationChannel _remindersChannel = AndroidNotificationChannel(
    'reminders_channel',
    'Event Reminders',
    description: 'Reminders for upcoming events',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Create notification channels for Android
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.createNotificationChannel(_sosChannel);
      await androidPlugin?.createNotificationChannel(_generalChannel);
      await androidPlugin?.createNotificationChannel(_donationsChannel);
      await androidPlugin?.createNotificationChannel(_remindersChannel);
    }

    // Get FCM token
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token refreshed: $newToken');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated app messages
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _isInitialized = true;
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: false,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
        _handleLocalNotificationTap(response.payload);
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // Navigate to SOS alerts screen - this would need a global navigator key
  }

  void _handleLocalNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        debugPrint('Local notification payload: $data');
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _sosChannel.id,
            _sosChannel.name,
            channelDescription: _sosChannel.description,
            importance: Importance.max,
            priority: Priority.max,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            color: Colors.red,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Show a local SOS alert notification
  Future<void> showSOSNotification({
    required String title,
    required String body,
    required String sosId,
    required String volunteerId,
    required String volunteerName,
    String? emergencyType,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _sosChannel.id,
          _sosChannel.name,
          channelDescription: _sosChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: Colors.red,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          playSound: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ticker: 'SOS EMERGENCY',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: jsonEncode({
        'sosId': sosId,
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'emergencyType': emergencyType,
        'type': 'sos_alert',
      }),
    );
  }

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Update FCM token for an NGO member
  Future<void> updateNGOFcmToken(String ngoId, String memberId) async {
    if (_fcmToken == null) {
      // Try to get the token if not available
      _fcmToken = await _messaging.getToken();
    }
    
    if (_fcmToken == null) {
      debugPrint('FCM token is still null, cannot update');
      return;
    }

    try {
      // Store in a dedicated collection for easier querying by Cloud Functions
      await FirebaseFirestore.instance
          .collection('ngo_fcm_tokens')
          .doc('${ngoId}_$memberId')
          .set({
        'ngoId': ngoId,
        'memberId': memberId,
        'fcmToken': _fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM token saved for NGO: $ngoId');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Update FCM token for a volunteer
  Future<void> updateVolunteerFcmToken(String volunteerId) async {
    if (_fcmToken == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(volunteerId)
          .update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token updated for volunteer: $volunteerId');
    } catch (e) {
      debugPrint('Error updating volunteer FCM token: $e');
    }
  }

  /// Get all NGO FCM tokens for sending notifications
  Future<List<String>> getAllNGOFcmTokens() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ngo_fcm_tokens')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['fcmToken'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (e) {
      debugPrint('Error getting NGO FCM tokens: $e');
      return [];
    }
  }

  /// Subscribe to SOS alerts topic (for NGO members)
  Future<void> subscribeToSOSAlerts() async {
    await _messaging.subscribeToTopic('sos_alerts');
    debugPrint('Subscribed to SOS alerts topic');
  }

  /// Unsubscribe from SOS alerts topic
  Future<void> unsubscribeFromSOSAlerts() async {
    await _messaging.unsubscribeFromTopic('sos_alerts');
    debugPrint('Unsubscribed from SOS alerts topic');
  }

  /// Show a general notification
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _generalChannel.id,
          _generalChannel.name,
          channelDescription: _generalChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF0099B8),
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Show a donation notification
  Future<void> showDonationNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _donationsChannel.id,
          _donationsChannel.name,
          channelDescription: _donationsChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Colors.green,
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Show an event reminder notification
  Future<void> showEventReminderNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _remindersChannel.id,
          _remindersChannel.name,
          channelDescription: _remindersChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Colors.orange,
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Get unread notification count for a user
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      return query.count ?? 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('Marked ${notifications.docs.length} notifications as read');
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleared ${notifications.docs.length} notifications');
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }
}

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.notification?.title}');
  // Handle the background message
}
