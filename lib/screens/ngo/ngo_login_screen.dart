import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'package:ngo_app/features/storage/data/services/local_storage_service.dart';
import 'ngo_home_screen.dart';

class NgoLoginScreen extends StatefulWidget {
  const NgoLoginScreen({Key? key}) : super(key: key);

  @override
  State<NgoLoginScreen> createState() => _NgoLoginScreenState();
}

class _NgoLoginScreenState extends State<NgoLoginScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _usePasswordLogin = false; // Toggle between OTP and password login
  bool _obscurePassword = true;
  String? _verificationId;
  int? _resendToken;
  String? _registrationId;
  NgoRegistrationRequest? _ngoData;
  
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid 10-digit phone number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if this phone number exists in approved registrations
      final registrationService = NgoRegistrationService();
      final registration = await registrationService.findApprovedRegistrationByPhone(phone);
      
      if (registration == null) {
        _showError('No approved NGO found with this phone number. Please register first or wait for approval.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _ngoData = registration;
      _registrationId = registration.id;
      
      // Use Firebase Phone Authentication to send real OTP
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only) - automatically sign in
          setState(() {
            _isVerifying = true;
          });
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'SMS quota exceeded. Please try again later';
          } else {
            errorMessage = e.message ?? 'Verification failed';
          }
          _showError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isOtpSent = true;
            _isLoading = false;
          });
          _startResendTimer();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent successfully! Please check your SMS'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error: $e');
    }
  }

  Future<void> _loginWithPassword() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    
    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid 10-digit phone number');
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final registrationService = NgoRegistrationService();
      final registration = await registrationService.verifyLoginWithPassword(phone, password);
      
      if (registration == null) {
        _showError('Invalid phone number or password. Please check your credentials.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _ngoData = registration;
      _registrationId = registration.id;
      
      // Save login state
      final localStorageService = LocalStorageService();
      await localStorageService.saveNgoLogin(_registrationId!, _ngoData!.ngoName);
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${_ngoData!.ngoName}!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to NGO Home Screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => NgoHomeScreen(ngoData: _ngoData!),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error: $e');
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();
    
    if (enteredOtp.isEmpty || enteredOtp.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    if (_verificationId == null) {
      _showError('Verification failed. Please request a new OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Create credential with verification ID and OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: enteredOtp,
      );
      
      await _signInWithCredential(credential);
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      
      String errorMessage = 'Invalid OTP. Please try again.';
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-verification-code') {
          errorMessage = 'Invalid OTP. Please check and try again.';
        } else if (e.code == 'session-expired') {
          errorMessage = 'OTP expired. Please request a new one.';
        }
      }
      _showError(errorMessage);
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
      
      // Save login state
      final localStorageService = LocalStorageService();
      await localStorageService.saveNgoLogin(_registrationId!, _ngoData!.ngoName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${_ngoData!.ngoName}!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to NGO Home Screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => NgoHomeScreen(ngoData: _ngoData!),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isVerifying = false;
      });
      
      String errorMessage = 'Authentication failed';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid OTP. Please check and try again.';
      } else if (e.code == 'session-expired') {
        errorMessage = 'OTP expired. Please request a new one.';
      } else {
        errorMessage = e.message ?? 'Authentication failed';
      }
      _showError(errorMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NGO Login',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Header Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business,
                  size: 50,
                  color: primary,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Center(
              child: Text(
                _isOtpSent ? 'Verify OTP' : (_usePasswordLogin ? 'Login with Password' : 'Login with Phone'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Center(
              child: Text(
                _isOtpSent 
                    ? 'Enter the 6-digit OTP sent to your phone'
                    : (_usePasswordLogin 
                        ? 'Enter your phone number and password'
                        : 'Enter the phone number used during registration'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 40),
            
            if (!_isOtpSent) ...[
              // Phone Number Input
              Text(
                'Phone Number',
                style: TextStyle(
                  color: primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter 10-digit phone number',
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+91',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                ),
              ),
              
              // Password field (shown when password login is selected)
              if (_usePasswordLogin) ...[
                const SizedBox(height: 16),
                Text(
                  'Password',
                  style: TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Login Button (Send OTP or Login with Password)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_usePasswordLogin ? _loginWithPassword : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _usePasswordLogin ? 'Login' : 'Send OTP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Toggle between OTP and Password login
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _usePasswordLogin = !_usePasswordLogin;
                      _passwordController.clear();
                    });
                  },
                  child: Text(
                    _usePasswordLogin 
                        ? 'Login with OTP instead' 
                        : 'Login with Password instead',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // OTP Input
              Text(
                'Enter OTP',
                style: TextStyle(
                  color: primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Resend OTP
              Center(
                child: _resendTimer > 0
                    ? Text(
                        'Resend OTP in $_resendTimer seconds',
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    : TextButton(
                        onPressed: _sendOtp,
                        child: Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify & Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Change Number
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isOtpSent = false;
                      _otpController.clear();
                    });
                  },
                  child: Text(
                    'Change Phone Number',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            
            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Only approved NGOs can login. If your registration is pending, please wait for admin approval.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
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
