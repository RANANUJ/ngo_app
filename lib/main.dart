import 'package:ngo_app/core/utils/network/network_utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:ngo_app/screens/auth/splash_screen.dart';
import 'package:ngo_app/core/utils/seeding/seed_government_schemes.dart';
import 'package:ngo_app/core/services/notification_service.dart';
import 'package:ngo_app/core/services/cache_service.dart';
import 'package:ngo_app/core/services/language_service.dart';
import 'package:ngo_app/core/services/crashlytics_service.dart';
import 'package:ngo_app/core/services/remote_config_service.dart';
import 'package:ngo_app/core/services/analytics_service.dart';
import 'l10n/app_localizations.dart';


// Flutter local notifications plugin instance for background use
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler - must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  secureLog('Background message: ${message.notification?.title}');
  
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
    
    secureLog('Background notification shown: ${notification.title}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Crashlytics
  await CrashlyticsService().initialize();
  
  // Initialize Firebase Remote Config
  await RemoteConfigService().initialize();
  
  // Initialize Analytics Service (handles all analytics setup)
  await AnalyticsService().initialize();
  
  // Log app open event
  await AnalyticsService().logAppOpen();
  
  // Set initial screen
  await AnalyticsService().logScreenView('splash_screen', screenClass: 'SplashScreen');
  
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

  // Create analytics observer from AnalyticsService
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: AnalyticsService().analytics);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageService(),
      child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            locale: languageService.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('hi'), // Hindi
            ],
            theme: ThemeData(
              useMaterial3: true,
            ),
            navigatorObservers: <NavigatorObserver>[observer],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
