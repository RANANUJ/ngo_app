import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'utils/seed_government_schemes.dart';

// IMPORTANT: Add your platform config files from the Firebase console:
// - Android: place `google-services.json` into `android/app/`
// - iOS: place `GoogleService-Info.plist` into `ios/Runner/`
// Also follow the Firebase Flutter setup docs to add the Gradle plugin and
// iOS bundle configuration. See README notes below after running pub get.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Seed government schemes (will reseed if less than 10 schemes exist)
  await GovernmentSchemeSeeder.seedSchemes();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
