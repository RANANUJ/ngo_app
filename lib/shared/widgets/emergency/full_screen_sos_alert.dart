import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen SOS Alert overlay widget
/// Shows a dramatic red alert screen similar to native Android SOSAlertActivity
class FullScreenSOSAlert extends StatefulWidget {
  final String volunteerName;
  final String emergencyType;
  final String address;
  final String? sosId;
  final String? volunteerId;
  final String? volunteerPhone;
  final VoidCallback? onViewDetails;
  final VoidCallback? onDismiss;

  const FullScreenSOSAlert({
    Key? key,
    required this.volunteerName,
    required this.emergencyType,
    required this.address,
    this.sosId,
    this.volunteerId,
    this.volunteerPhone,
    this.onViewDetails,
    this.onDismiss,
  }) : super(key: key);

  /// Show the full-screen SOS alert as an overlay
  static Future<void> show(
    BuildContext context, {
    required String volunteerName,
    required String emergencyType,
    required String address,
    String? sosId,
    String? volunteerId,
    String? volunteerPhone,
    VoidCallback? onViewDetails,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (context) => FullScreenSOSAlert(
        volunteerName: volunteerName,
        emergencyType: emergencyType,
        address: address,
        sosId: sosId,
        volunteerId: volunteerId,
        volunteerPhone: volunteerPhone,
        onViewDetails: onViewDetails,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<FullScreenSOSAlert> createState() => _FullScreenSOSAlertState();
}

class _FullScreenSOSAlertState extends State<FullScreenSOSAlert>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the warning icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shake animation for the entire screen
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _shakeAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Start vibration pattern
    _startVibration();

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _startVibration() {
    // Initial vibration
    HapticFeedback.heavyImpact();

    // Repeat vibration
    _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _stopVibration();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFCC0000),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  
                  // Warning Icon with pulse animation
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Alert Title
                  const Text(
                    '🚨 SOS ALERT',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Volunteer Name
                  Text(
                    '${widget.volunteerName} needs help!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Emergency Type
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.emergencyType,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Address
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.address,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // View Details Button
                  SizedBox(
                    width: 280,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        _stopVibration();
                        Navigator.pop(context);
                        widget.onViewDetails?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFCC0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'VIEW DETAILS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dismiss Button
                  SizedBox(
                    width: 280,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        _stopVibration();
                        Navigator.pop(context);
                        widget.onDismiss?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'DISMISS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
