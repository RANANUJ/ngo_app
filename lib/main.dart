import 'package:ngo_app/core/utils/network/network_utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:ngo_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:ngo_app/core/utils/seeding/seed_government_schemes.dart';
import 'package:ngo_app/core/services/notification_service.dart';
import 'package:ngo_app/core/services/cache_service.dart';
import 'package:ngo_app/core/services/language_service.dart';
import 'package:ngo_app/core/services/crashlytics_service.dart';
import 'package:ngo_app/core/services/remote_config_service.dart';
import 'package:ngo_app/core/services/analytics_service.dart';
import 'package:ngo_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ngo_app/features/emergency/domain/repositories/sos_repository.dart';
import 'package:ngo_app/features/emergency/data/repositories/firebase_sos_repository.dart';
import 'package:ngo_app/features/emergency/presentation/controllers/sos_controller.dart';
import 'package:ngo_app/features/donations/domain/repositories/donation_repository.dart';
import 'package:ngo_app/features/donations/data/repositories/firebase_donation_repository.dart';
import 'package:ngo_app/features/donations/presentation/controllers/donation_controller.dart';
import 'package:ngo_app/features/campaigns/domain/repositories/campaign_repository.dart';
import 'package:ngo_app/features/campaigns/data/repositories/firebase_campaign_repository.dart';
import 'package:ngo_app/features/campaigns/presentation/controllers/campaign_controller.dart';
import 'package:ngo_app/features/opportunities/domain/repositories/opportunity_repository.dart';
import 'package:ngo_app/features/opportunities/data/repositories/firebase_opportunity_repository.dart';
import 'package:ngo_app/features/opportunities/presentation/controllers/opportunity_controller.dart';
import 'package:ngo_app/features/resources/domain/repositories/resource_repository.dart';
import 'package:ngo_app/features/resources/data/repositories/firebase_resource_repository.dart';
import 'package:ngo_app/features/resources/presentation/controllers/resource_controller.dart';
import 'package:ngo_app/features/tasks/domain/repositories/task_repository.dart';
import 'package:ngo_app/features/tasks/data/repositories/firebase_task_repository.dart';
import 'package:ngo_app/features/tasks/presentation/controllers/task_controller.dart';
import 'package:ngo_app/features/community/domain/repositories/community_repository.dart';
import 'package:ngo_app/features/community/data/repositories/firebase_community_repository.dart';
import 'package:ngo_app/features/community/presentation/controllers/community_controller.dart';
import 'package:ngo_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:ngo_app/features/profile/data/repositories/firebase_profile_repository.dart';
import 'package:ngo_app/features/profile/presentation/controllers/profile_controller.dart';
import 'l10n/app_localizations.dart';
import 'package:ngo_app/core/utils/route_observer.dart';

 
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        Provider<SosRepository>(create: (_) => FirebaseSosRepository()),
        ChangeNotifierProvider(create: (context) => SosController(context.read<SosRepository>())),
        Provider<DonationRepository>(create: (_) => FirebaseDonationRepository()),
        ChangeNotifierProvider(create: (context) => DonationController(context.read<DonationRepository>())),
        Provider<CampaignRepository>(create: (_) => FirebaseCampaignRepository()),
        ChangeNotifierProvider(create: (context) => CampaignController(context.read<CampaignRepository>())),
        Provider<OpportunityRepository>(create: (_) => FirebaseOpportunityRepository()),
        ChangeNotifierProvider(create: (context) => OpportunityController(context.read<OpportunityRepository>())),
        Provider<ResourceRepository>(create: (_) => FirebaseResourceRepository()),
        ChangeNotifierProvider(create: (context) => ResourceController(context.read<ResourceRepository>())),
        Provider<TaskRepository>(create: (_) => FirebaseTaskRepository()),
        ChangeNotifierProvider(create: (context) => TaskController(context.read<TaskRepository>())),
        Provider<CommunityRepository>(create: (_) => FirebaseCommunityRepository()),
        ChangeNotifierProvider(create: (context) => CommunityController(context.read<CommunityRepository>())),
        Provider<ProfileRepository>(create: (_) => FirebaseProfileRepository()),
        ChangeNotifierProvider(create: (context) => ProfileController(context.read<ProfileRepository>())),
      ],
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
            navigatorObservers: <NavigatorObserver>[observer, routeObserver],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
