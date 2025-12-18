import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_type_screen.dart';
import 'ngo/ngo_verification_status_screen.dart';
import 'ngo/ngo_home_screen.dart';
import 'volunteer/volunteer_dashboard_screen.dart';
import '../services/local_storage_service.dart';
import '../services/ngo_registration_service.dart';
import '../services/cache_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color primary = Color(0xFF0099B8);
  final LocalStorageService _localStorageService = LocalStorageService();
  final NgoRegistrationService _registrationService = NgoRegistrationService();
  
  String _loadingStatus = 'Initializing...';
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure widget is fully built before navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });
  }

  Future<void> _initializeAndNavigate() async {
    // Step 1: Initialize cache service
    _updateStatus('Loading cache...', 0.1);
    await CacheService().initialize();
    
    // Step 2: Preload asset images
    _updateStatus('Loading images...', 0.2);
    if (mounted) {
      await CacheService().preloadAssetImages(context);
    }
    
    // Step 3: Start preloading data in background (don't wait for it)
    _updateStatus('Fetching data...', 0.4);
    DataPreloader().preloadAllData(); // Fire and forget
    
    // Step 4: Check authentication (parallel with data loading)
    _updateStatus('Checking session...', 0.6);
    await _checkRegistrationAndNavigate();
  }

  void _updateStatus(String status, double progress) {
    if (mounted) {
      setState(() {
        _loadingStatus = status;
        _loadingProgress = progress;
      });
    }
  }

  Future<void> _checkRegistrationAndNavigate() async {
    // Minimum splash display time
    await Future.delayed(const Duration(milliseconds: 1500));
    
    _updateStatus('Almost ready...', 0.8);
    
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
            Text(
              'Connect & Contribute',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 40),
            // Loading progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _loadingProgress,
                      backgroundColor: Theme.of(context).dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadingStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
