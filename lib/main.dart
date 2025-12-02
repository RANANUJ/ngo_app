import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'utils/seed_government_schemes.dart';
import 'services/notification_service.dart';
import 'services/cache_service.dart';

// IMPORTANT: Add your platform config files from the Firebase console:
// - Android: place `google-services.json` into `android/app/`
// - iOS: place `GoogleService-Info.plist` into `ios/Runner/`
// Also follow the Firebase Flutter setup docs to add the Gradle plugin and
// iOS bundle configuration. See README notes below after running pub get.

// Flutter local notifications plugin instance for background use
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler - must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message: ${message.notification?.title}');
  
  // Show local notification when app is in background/terminated
  await _showBackgroundNotification(message);
}

// Show notification when app is in background
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  
  final notification = message.notification;
  final data = message.data;
  
  if (notification != null) {
    // Determine the notification channel based on type
    String channelId = 'general_channel';
    String channelName = 'General Notifications';
    Color notificationColor = const Color(0xFF0099B8);
    Importance importance = Importance.high;
    Priority priority = Priority.high;
    
    final type = data['type']?.toString().toLowerCase() ?? '';
    
    if (type.contains('sos') || type.contains('emergency')) {
      channelId = 'sos_alerts_channel';
      channelName = 'SOS Alerts';
      notificationColor = const Color(0xFFE53935);
      importance = Importance.max;
      priority = Priority.max;
    } else if (type.contains('donation')) {
      channelId = 'donations_channel';
      channelName = 'Donation Notifications';
      notificationColor = const Color(0xFF4CAF50);
    } else if (type.contains('reminder') || type.contains('event')) {
      channelId = 'reminders_channel';
      channelName = 'Event Reminders';
      notificationColor = const Color(0xFFFF9800);
    }
    
    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: importance,
          priority: priority,
          icon: '@mipmap/ic_launcher',
          color: notificationColor,
          enableVibration: true,
          playSound: true,
          showWhen: true,
          autoCancel: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    
    debugPrint('Background notification shown: ${notification.title}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize cache service early
  await CacheService().initialize();
  
  // Initialize Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize notification service
  await NotificationService().initialize();
  
  // Seed government schemes in background (don't wait)
  GovernmentSchemeSeeder.seedSchemes();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Enable image caching globally
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
