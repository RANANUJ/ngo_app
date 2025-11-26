import 'package:flutter/material.dart';
import 'user_type_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color primary = Color(0xFF0099B8);

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure widget is fully built before navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToHome();
    });
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserTypeScreen()),
      );
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
