import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../widgets/full_screen_sos_alert.dart';

/// Global navigator key for showing dialogs from services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Method channel for native SOS alert
const MethodChannel _sosChannel = MethodChannel('com.example.ngo_app/sos_alert');

/// Show native full-screen SOS alert (works from background)
Future<void> showNativeSOSAlert(Map<String, dynamic> data) async {
  try {
    await _sosChannel.invokeMethod('showSOSAlert', data);
  } catch (e) {
    debugPrint('Error showing native SOS alert: $e');
  }
}

/// Service for handling push notifications and FCM tokens
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _emergencyPlayer = AudioPlayer();
  
  bool _isInitialized = false;
  String? _fcmToken;
  bool _isPlayingEmergencySound = false;
  
  // SOS Notification channel for Android (highest priority)
  static const AndroidNotificationChannel _sosChannel = AndroidNotificationChannel(
    'sos_alerts_channel',
    'SOS Alerts',
    description: 'Emergency SOS alerts from volunteers',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    sound: RawResourceAndroidNotificationSound('emergency_alert'),
    enableLights: true,
    ledColor: Color(0xFFE53935),
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
    debugPrint('Message data: ${message.data}');
    
    final data = message.data;
    final type = data['type']?.toString().toLowerCase() ?? '';
    
    debugPrint('Notification type: $type');
    
    // Check if this is an SOS alert
    if (type == 'sos_alert') {
      debugPrint('🚨 SOS ALERT DETECTED - Triggering emergency sound and vibration!');
      // Play emergency sound and vibrate
      _playEmergencyAlertSound();
      // Show full-screen SOS alert
      _showFullScreenSOSAlert(data);
    } else {
      _showLocalNotification(message);
    }
  }
  
  /// Show full-screen SOS alert when app is in foreground
  void _showFullScreenSOSAlert(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('Navigator context not available for full-screen alert');
      return;
    }
    
    FullScreenSOSAlert.show(
      context,
      volunteerName: data['volunteerName'] ?? 'Unknown',
      emergencyType: data['emergencyType'] ?? 'Emergency',
      address: data['address'] ?? 'Unknown location',
      sosId: data['sosId'],
      volunteerId: data['volunteerId'],
      volunteerPhone: data['volunteerPhone'],
      onViewDetails: () {
        debugPrint('View details tapped for SOS: ${data['sosId']}');
        // Navigate to SOS details - handled by the caller
      },
      onDismiss: () {
        debugPrint('SOS alert dismissed');
      },
    );
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

  /// Play emergency alert sound for 10 seconds with vibration
  Future<void> _playEmergencyAlertSound() async {
    debugPrint('🔊 _playEmergencyAlertSound called');
    
    if (_isPlayingEmergencySound) {
      debugPrint('⚠️ Emergency sound already playing, skipping');
      return;
    }
    
    try {
      _isPlayingEmergencySound = true;
      debugPrint('✅ Starting emergency alert sound and vibration');
      
      // Start continuous vibration pattern for 10 seconds
      _startEmergencyVibration();
      
      // Play emergency sound (looping for 10 seconds)
      // Using system alarm sound as fallback
      await _emergencyPlayer.setReleaseMode(ReleaseMode.loop);
      await _emergencyPlayer.setVolume(1.0);
      
      // Try to play custom emergency sound, fallback to system sound
      try {
        // Use system notification sound with max volume
        debugPrint('🎵 Attempting to play emergency_alert.mp3');
        await _emergencyPlayer.play(AssetSource('emergency_alert.mp3'));
        debugPrint('✅ Emergency sound playing');
      } catch (e) {
        debugPrint('❌ Custom sound not found, using system sound: $e');
        // Play default notification sound repeatedly
        await SystemSound.play(SystemSoundType.alert);
      }
      
      // Stop after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        debugPrint('⏰ 10 seconds elapsed, stopping emergency sound');
        _stopEmergencyAlertSound();
      });
    } catch (e) {
      debugPrint('❌ Error playing emergency sound: $e');
      _isPlayingEmergencySound = false;
    }
  }
  
  /// Start emergency vibration pattern
  Future<void> _startEmergencyVibration() async {
    debugPrint('📳 _startEmergencyVibration called');
    
    try {
      // Check if device has vibration capability
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      debugPrint('Device has vibrator: $hasVibrator');
      
      if (!hasVibrator) {
        debugPrint('⚠️ Device has no vibrator, skipping vibration');
        return;
      }
      
      debugPrint('✅ Starting vibration pattern (13 cycles of 500ms ON, 200ms OFF)');
      
      // Vibrate in emergency pattern for 10 seconds
      // Pattern: [wait, vibrate, wait, vibrate, ...]
      // 500ms vibrate, 200ms pause, repeat
      for (int i = 0; i < 13; i++) {
        if (!_isPlayingEmergencySound) {
          debugPrint('⏹️ Vibration stopped early at cycle $i');
          break;
        }
        await Vibration.vibrate(duration: 500, amplitude: 255);
        await Future.delayed(const Duration(milliseconds: 200));
      }
      debugPrint('✅ Vibration pattern completed');
    } catch (e) {
      debugPrint('❌ Error vibrating: $e');
    }
  }
  
  /// Stop emergency alert sound and vibration
  Future<void> _stopEmergencyAlertSound() async {
    try {
      _isPlayingEmergencySound = false;
      await _emergencyPlayer.stop();
      await Vibration.cancel();
    } catch (e) {
      debugPrint('Error stopping emergency sound: $e');
    }
  }
  
  /// Public method to manually stop emergency sound
  Future<void> stopEmergencySound() async {
    await _stopEmergencyAlertSound();
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
    // Play emergency sound and vibrate
    await _playEmergencyAlertSound();
    
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
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500, 200, 500, 200, 500]),
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('emergency_alert'),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ticker: 'SOS EMERGENCY',
          ongoing: false,
          autoCancel: false,
          timeoutAfter: 10000,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'emergency_alert.aiff',
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
    try {
      // Always get a fresh token on login/signup
      debugPrint('🟢 Getting fresh FCM token for NGO: $ngoId');
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken == null) {
        debugPrint('❌ FCM token is null, cannot register for notifications');
        return;
      }
      
      debugPrint('🟢 FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');

      // Store in a dedicated collection for easier querying by Cloud Functions
      await FirebaseFirestore.instance
          .collection('ngo_fcm_tokens')
          .doc('${ngoId}_$memberId')
          .set({
        'ngoId': ngoId,
        'memberId': memberId,
        'fcmToken': _fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
      }, SetOptions(merge: true));

      debugPrint('✅ FCM token registered successfully for NGO: $ngoId');
    } catch (e) {
      debugPrint('❌ Error registering FCM token for NGO: $e');
    }
  }

  /// Update FCM token for a volunteer
  Future<void> updateVolunteerFcmToken(String volunteerId) async {
    try {
      // Always get a fresh token on login/signup
      debugPrint('🟢 Getting fresh FCM token for volunteer: $volunteerId');
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken == null) {
        debugPrint('❌ FCM token is null, cannot register for notifications');
        return;
      }
      
      debugPrint('🟢 FCM Token obtained: \${_fcmToken!.substring(0, 20)}...');

      await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(volunteerId)
          .update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });
      debugPrint('✅ FCM token registered successfully for volunteer: $volunteerId');
    } catch (e) {
      debugPrint('❌ Error registering FCM token for volunteer: $e');
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

  /// Remove FCM token for NGO member on logout
  Future<void> removeNGOFcmToken(String ngoId, String memberId) async {
    try {
      debugPrint('🔴 Starting FCM token removal for NGO: $ngoId');
      
      // First, get the current token to verify what we're deleting
      final currentToken = _fcmToken ?? await _messaging.getToken();
      debugPrint('🔴 Current FCM token: $currentToken');
      
      // Delete FCM token from Firestore using the specific document ID
      final docRef = FirebaseFirestore.instance
          .collection('ngo_fcm_tokens')
          .doc('${ngoId}_$memberId');
      
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        await docRef.delete();
        debugPrint('🔴 Deleted FCM token document: ${ngoId}_$memberId');
      } else {
        debugPrint('🔴 FCM token document not found: ${ngoId}_$memberId');
      }
      
      // Also delete any other documents with this ngoId and current token
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ngo_fcm_tokens')
          .where('ngoId', isEqualTo: ngoId)
          .where('fcmToken', isEqualTo: currentToken)
          .get();
      
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
        debugPrint('🔴 Deleted additional FCM token document: ${doc.id}');
      }
      
      // Delete the device token from FCM
      if (currentToken != null) {
        await _messaging.deleteToken();
        debugPrint('🔴 Deleted FCM device token');
      }
      
      // Clear local token
      _fcmToken = null;

      debugPrint('✅ FCM token removal completed for NGO: $ngoId');
    } catch (e) {
      debugPrint('❌ Error removing NGO FCM token: $e');
      rethrow;
    }
  }

  /// Remove FCM token for volunteer on logout
  Future<void> removeVolunteerFcmToken(String volunteerId) async {
    try {
      debugPrint('🔴 Starting FCM token removal for volunteer: $volunteerId');
      
      // Get the current token
      final currentToken = _fcmToken ?? await _messaging.getToken();
      debugPrint('🔴 Current FCM token: $currentToken');
      
      // Remove FCM token from volunteer document
      await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(volunteerId)
          .update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
      debugPrint('🔴 Removed FCM token from volunteer document');

      // Delete the device token from FCM
      if (currentToken != null) {
        await _messaging.deleteToken();
        debugPrint('🔴 Deleted FCM device token');
      }
      
      // Clear local token
      _fcmToken = null;

      debugPrint('✅ FCM token removal completed for volunteer: $volunteerId');
    } catch (e) {
      debugPrint('❌ Error removing volunteer FCM token: $e');
      rethrow;
    }
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
    String? largeIconUrl,  // Donor profile image URL (for future enhancement)
  }) async {
    // Use BigTextStyle for richer notification
    final styleInformation = BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: 'Connect & Contribute',
      htmlFormatBigText: true,
      htmlFormatContentTitle: true,
    );
    
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
          styleInformation: styleInformation,
          ticker: title,
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
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
  debugPrint('Background message received: ${message.data}');
  
  final data = message.data;
  final type = data['type']?.toString().toLowerCase() ?? '';
  
  // Check if this is an SOS alert that needs full-screen display
  if (type == 'sos_alert' && data['fullScreenIntent'] == 'true') {
    debugPrint('SOS Alert in background - showing full-screen notification');
    
    // Initialize local notifications for background
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await localNotifications.initialize(initSettings);
    
    // Create notification channel
    final androidPlugin = localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    const AndroidNotificationChannel sosChannel = AndroidNotificationChannel(
      'sos_alert_channel',
      'SOS Emergency Alerts',
      description: 'Critical SOS emergency alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    
    await androidPlugin?.createNotificationChannel(sosChannel);
    
    final volunteerName = data['volunteerName'] ?? 'Unknown';
    final emergencyType = data['emergencyType'] ?? 'Emergency';
    final address = data['address'] ?? 'Unknown location';
    
    // Show high-priority notification with full-screen intent
    await localNotifications.show(
      999, // Fixed ID for SOS alerts
      '🚨 EMERGENCY SOS ALERT',
      '$volunteerName needs help! $emergencyType at $address',
      NotificationDetails(
        android: AndroidNotificationDetails(
          sosChannel.id,
          sosChannel.name,
          channelDescription: sosChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFE53935),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500, 500]),
          playSound: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ticker: 'SOS EMERGENCY',
          ongoing: true,
          autoCancel: false,
          timeoutAfter: 300000, // 5 minutes
          actions: [
            const AndroidNotificationAction(
              'view_details',
              'VIEW DETAILS',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'dismiss',
              'DISMISS',
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: jsonEncode(data),
    );
  }
}
