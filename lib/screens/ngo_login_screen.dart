import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../services/ngo_registration_service.dart';
import '../services/local_storage_service.dart';
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
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _generatedOtp;
  String? _registrationId;
  NgoRegistrationRequest? _ngoData;
  
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
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
      
      // Generate a 6-digit OTP (in production, send via SMS)
      _generatedOtp = (100000 + Random().nextInt(900000)).toString();
      
      // In production, integrate with SMS gateway
      // For demo, we'll show the OTP in a snackbar
      debugPrint('Generated OTP: $_generatedOtp');
      
      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });
      
      _startResendTimer();
      
      // Show OTP for demo purposes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo OTP: $_generatedOtp'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 10),
          ),
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

    setState(() {
      _isVerifying = true;
    });

    // Verify OTP
    if (enteredOtp == _generatedOtp) {
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
    } else {
      setState(() {
        _isVerifying = false;
      });
      _showError('Invalid OTP. Please try again.');
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
                  color: primary.withOpacity(0.1),
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
                _isOtpSent ? 'Verify OTP' : 'Login with Phone',
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
                    : 'Enter the phone number used during registration',
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
              
              const SizedBox(height: 24),
              
              // Send OTP Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
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
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 16,
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
