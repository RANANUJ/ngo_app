import 'package:flutter/material.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_verification_service.dart';
import 'package:ngo_app/screens/volunteer/volunteer_dashboard_screen.dart';

class VerificationResultScreen extends StatelessWidget {
  final VerificationResult result;

  const VerificationResultScreen({Key? key, required this.result}) : super(key: key);

  static const Color primary = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Verification Status',
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
          children: [
            // Status Icon
            _buildStatusIcon(),
            const SizedBox(height: 24),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _getStatusColor()),
              ),
              child: Text(
                result.statusBadge,
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              result.message ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 32),

            // Trust Score Card
            _buildTrustScoreCard(),
            const SizedBox(height: 24),

            // Verification Checks
            _buildVerificationChecks(),
            const SizedBox(height: 24),

            // Rejection Reason (if any)
            if (result.rejectionReason != null) ...[
              _buildRejectionReasonCard(),
              const SizedBox(height: 24),
            ],

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (result.isVerified) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const VolunteerDashboardScreen()),
                      (route) => false,
                    );
                  } else if (result.status == VerificationLevel.manualReview) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const VolunteerDashboardScreen()),
                      (route) => false,
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  result.isVerified || result.status == VerificationLevel.manualReview
                      ? 'Go to Dashboard'
                      : 'Go Back & Fix Issues',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            if (result.status == VerificationLevel.manualReview) ...[
              const SizedBox(height: 12),
              Text(
                'Our team will review your application within 24-48 hours',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (result.status) {
      case VerificationLevel.verified:
      case VerificationLevel.autoVerified:
        icon = Icons.check_circle;
        bgColor = Colors.green.shade50;
        iconColor = Colors.green;
        break;
      case VerificationLevel.manualReview:
        icon = Icons.hourglass_top;
        bgColor = Colors.orange.shade50;
        iconColor = Colors.orange;
        break;
      case VerificationLevel.rejected:
        icon = Icons.cancel;
        bgColor = Colors.red.shade50;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.pending;
        bgColor = Colors.grey.shade100;
        iconColor = Colors.grey;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 60, color: iconColor),
    );
  }

  Color _getStatusColor() {
    switch (result.status) {
      case VerificationLevel.verified:
      case VerificationLevel.autoVerified:
        return Colors.green;
      case VerificationLevel.manualReview:
        return Colors.orange;
      case VerificationLevel.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTrustScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Trust Score',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.trustScore}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: result.trustScore / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getTrustBadge(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTrustBadge() {
    if (result.trustScore >= 90) return '🏆 Platinum Verified';
    if (result.trustScore >= 75) return '🥇 Gold Verified';
    if (result.trustScore >= 50) return '🥈 Silver Verified';
    if (result.trustScore >= 25) return '🥉 Bronze Verified';
    return '⏳ Pending Verification';
  }

  Widget _buildVerificationChecks() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.checklist, color: primary),
                const SizedBox(width: 8),
                Text(
                  'Verification Checks (${result.passedChecks}/${result.totalChecks})',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...result.checks.map((check) => _buildCheckItem(check)),
        ],
      ),
    );
  }

  Widget _buildCheckItem(VerificationCheck check) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: check.passed ? Colors.green.shade50 : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              check.passed ? Icons.check : Icons.close,
              size: 16,
              color: check.passed ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.checkName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (check.failureReason != null)
                  Text(
                    check.failureReason!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReasonCard() {
    return Container(
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
              Icon(Icons.warning_amber, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Rejection Reasons',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.rejectionReason!,
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
