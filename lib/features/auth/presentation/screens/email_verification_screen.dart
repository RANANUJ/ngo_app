import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngo_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ngo_app/screens/volunteer/volunteer_dashboard_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  bool _isEmailVerified = false;
  bool _canResendEmail = true;
  Timer? _verificationTimer;
  Timer? _cooldownTimer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    // Start checking for email verification
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startEmailVerificationCheck() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final authController = context.read<AuthController>();
      final verified = await authController.checkEmailVerified();
      
      if (verified) {
        timer.cancel();
        if (mounted) {
          setState(() => _isEmailVerified = true);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to dashboard after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const VolunteerDashboardScreen()),
                (route) => false,
              );
            }
          });
        }
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60;
    });

    final authController = context.read<AuthController>();
    final result = await authController.resendEmailVerification();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }

    // Start cooldown timer and cancel any existing cooldown timer first
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        if (mounted) {
          setState(() => _resendCooldown--);
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() => _canResendEmail = true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 50,
                  color: primary,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Verify your email',
                style: TextStyle(
                  color: primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'We have sent a verification link to:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),

              // Email
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please check your inbox and click the verification link.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 28),
                        Expanded(
                          child: Text(
                            'Also check your spam folder if you don\'t see it.',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Checking status indicator
              if (!_isEmailVerified) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for verification...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              // Resend button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _canResendEmail ? _resendVerificationEmail : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: _canResendEmail ? primary : Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _canResendEmail
                        ? 'Resend Verification Email'
                        : 'Resend in $_resendCooldown seconds',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Change email option
              TextButton(
                onPressed: () async {
                  final authController = context.read<AuthController>();
                  await authController.signOut();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Wrong email? Go back and change',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
