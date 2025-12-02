import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_type_screen.dart';
import 'ngo/ngo_verification_status_screen.dart';
import 'ngo/ngo_home_screen.dart';
import 'volunteer/volunteer_dashboard_screen.dart';
import '../services/local_storage_service.dart';
import '../services/ngo_registration_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color primary = Color(0xFF0099B8);
  final LocalStorageService _localStorageService = LocalStorageService();
  final NgoRegistrationService _registrationService = NgoRegistrationService();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure widget is fully built before navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRegistrationAndNavigate();
    });
  }

  Future<void> _checkRegistrationAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // Check if a volunteer/individual user is logged in with Firebase Auth
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.emailVerified) {
      // Check if this is NOT an NGO user (no NGO login state)
      final isNgoLoggedIn = await _localStorageService.isNgoLoggedIn();
      if (!isNgoLoggedIn) {
        // This is a volunteer/individual user
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VolunteerDashboardScreen()),
          );
        }
        return;
      }
    }

    // Check if NGO is already logged in
    final isLoggedIn = await _localStorageService.isNgoLoggedIn();
    if (isLoggedIn) {
      final ngoId = await _localStorageService.getLoggedInNgoId();
      if (ngoId != null) {
        // Get NGO data and navigate to home
        final ngoData = await _registrationService.findRegistrationById(ngoId);
        if (ngoData != null && ngoData.status == RegistrationStatus.approved) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NgoHomeScreen(ngoData: ngoData),
              ),
            );
          }
          return;
        } else {
          // Clear invalid login state
          await _localStorageService.clearNgoLogin();
        }
      }
    }

    // Check if there's a pending registration
    final pendingRegistrationId = await _localStorageService.getPendingRegistrationId();
    final registrationStatus = await _localStorageService.getRegistrationStatus();

    print('SplashScreen: Checking registration - ID: $pendingRegistrationId, Status: $registrationStatus');

    if (pendingRegistrationId != null && 
        pendingRegistrationId.isNotEmpty && 
        registrationStatus == 'pending') {
      // User has a pending registration, show verification status screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NgoVerificationStatusScreen(
              registrationId: pendingRegistrationId,
            ),
          ),
        );
      }
    } else {
      // No pending registration, show user type screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserTypeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // NGO Logo from assets
            Image.asset(
              'assets/image.png',
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8E6C9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volunteer_activism, size: 50, color: Colors.teal),
                );
              },
            ),
            const SizedBox(height: 8),
            
            const SizedBox(height: 40),
            // Connect & Contribute text
            const Text(
              'Connect & Contribute',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
