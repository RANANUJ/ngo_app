import 'package:flutter/material.dart';
import '../services/ngo_registration_service.dart';
import '../services/local_storage_service.dart';
import 'dashboard_screen.dart';
import 'user_type_screen.dart';

class NgoVerificationStatusScreen extends StatefulWidget {
  final String registrationId;

  const NgoVerificationStatusScreen({
    Key? key,
    required this.registrationId,
  }) : super(key: key);

  @override
  State<NgoVerificationStatusScreen> createState() => _NgoVerificationStatusScreenState();
}

class _NgoVerificationStatusScreenState extends State<NgoVerificationStatusScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  final NgoRegistrationService _registrationService = NgoRegistrationService();
  final LocalStorageService _localStorageService = LocalStorageService();
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  RegistrationStatus? _lastNotifiedStatus;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for pending state
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _showStatusNotification(String title, String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(message),
            ],
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<NgoRegistrationRequest?>(
        stream: _registrationService.getStatusStream(widget.registrationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primary),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  const Text('Error loading registration status'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final registration = snapshot.data!;
          
          // Show notification when status changes (only once per status)
          if (_lastNotifiedStatus != registration.status && 
              _lastNotifiedStatus != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (registration.status == RegistrationStatus.approved) {
                _showStatusNotification(
                  'Congratulations!',
                  'Your NGO registration has been approved!',
                  Colors.green,
                );
              } else if (registration.status == RegistrationStatus.rejected) {
                _showStatusNotification(
                  'Registration Rejected',
                  registration.rejectionReason ?? 'Your registration was not approved.',
                  Colors.red,
                );
              }
            });
          }
          _lastNotifiedStatus = registration.status;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildStatusIcon(registration),
                        const SizedBox(height: 32),
                        _buildStatusTitle(registration),
                        const SizedBox(height: 16),
                        _buildStatusDescription(registration),
                        const SizedBox(height: 40),
                        _buildRegistrationDetails(registration),
                        const SizedBox(height: 24),
                        if (registration.status == RegistrationStatus.rejected)
                          _buildRejectionReason(registration),
                      ],
                    ),
                  ),
                ),
                _buildBottomButton(registration),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(NgoRegistrationRequest registration) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (registration.status) {
      case RegistrationStatus.approved:
        icon = Icons.check_circle;
        color = Colors.green;
        bgColor = Colors.green.shade50;
        break;
      case RegistrationStatus.rejected:
        icon = Icons.cancel;
        color = Colors.red;
        bgColor = Colors.red.shade50;
        break;
      default:
        icon = Icons.hourglass_top;
        color = Colors.orange;
        bgColor = Colors.orange.shade50;
    }

    Widget iconWidget = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 60,
        color: color,
      ),
    );

    // Add pulse animation for pending state
    if (registration.status == RegistrationStatus.pending) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: iconWidget,
      );
    }

    return iconWidget;
  }

  Widget _buildStatusTitle(NgoRegistrationRequest registration) {
    String title;
    Color color;

    switch (registration.status) {
      case RegistrationStatus.approved:
        title = 'Registration Approved!';
        color = Colors.green;
        break;
      case RegistrationStatus.rejected:
        title = 'Registration Rejected';
        color = Colors.red;
        break;
      default:
        title = 'Waiting for Admin Approval';
        color = Colors.orange;
    }

    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatusDescription(NgoRegistrationRequest registration) {
    String description;

    switch (registration.status) {
      case RegistrationStatus.approved:
        description = 'Your NGO "${registration.ngoName}" has been verified and approved. You can now access all features of the platform.';
        break;
      case RegistrationStatus.rejected:
        description = 'Unfortunately, your registration for "${registration.ngoName}" was not approved. Please review the reason below and submit a new application if needed.';
        break;
      default:
        description = 'Your registration is being reviewed by our admin team. This usually takes 24-48 hours. You will be notified once a decision is made.';
    }

    return Text(
      description,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRegistrationDetails(NgoRegistrationRequest registration) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registration Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('NGO Name', registration.ngoName),
          _buildDetailRow('Registration No', registration.registrationNo),
          _buildDetailRow('Type', registration.ngoType),
          _buildDetailRow('Category', registration.category),
          _buildDetailRow('Contact Person', registration.contactPersonName),
          _buildDetailRow('Email', registration.email),
          _buildDetailRow('Submitted On', _formatDateTime(registration.submittedAt)),
          if (registration.reviewedAt != null)
            _buildDetailRow('Reviewed On', _formatDateTime(registration.reviewedAt!)),
          const SizedBox(height: 12),
          _buildDocumentStatus(registration),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatus(NgoRegistrationRequest registration) {
    final docPercentage = registration.documentCompletionPercentage;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documents Uploaded',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$docPercentage%',
              style: TextStyle(
                color: docPercentage == 100 ? Colors.green : Colors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: docPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              docPercentage == 100 ? Colors.green : Colors.orange,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildRejectionReason(NgoRegistrationRequest registration) {
    if (registration.rejectionReason == null || registration.rejectionReason!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Reason for Rejection',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            registration.rejectionReason!,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(NgoRegistrationRequest registration) {
    if (registration.status == RegistrationStatus.pending) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Status updates automatically when admin reviews your application',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (registration.status == RegistrationStatus.approved) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              // Clear local storage as registration is approved
              await _localStorageService.markAsApproved();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Go to Dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    // Rejected - allow to go back and try again
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            // Clear local storage to allow new registration
            await _localStorageService.clearRegistrationData();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const UserTypeScreen()),
                (route) => false,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Submit New Application',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
