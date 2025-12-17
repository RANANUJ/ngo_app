import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/email_service.dart';

class DonationDetailScreen extends StatefulWidget {
  final String donationId;
  final Map<String, dynamic> donationData;

  const DonationDetailScreen({
    Key? key,
    required this.donationId,
    required this.donationData,
  }) : super(key: key);

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  static const Color primary = Color(0xFF0099B8);
  bool _isSendingEmail = false;

  Future<void> _sendThankYouEmail() async {
    final donorEmail = widget.donationData['donorEmail'] ?? '';
    final donorName = widget.donationData['donorName'] ?? 'Donor';
    final amount = (widget.donationData['amount'] ?? 0).toDouble();
    final campaignTitle = widget.donationData['campaignTitle'] ?? 'Unknown Campaign';
    final createdAt = (widget.donationData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final ngoId = widget.donationData['ngoId'] ?? '';

    if (donorEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donor email not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSendingEmail = true;
    });

    try {
      // Get NGO details
      final ngoDetails = await EmailService.getNgoDetails(ngoId);
      final ngoName = ngoDetails?['organizationName'] ?? 'Connect & Contribute';
      final ngoEmail = ngoDetails?['email'] ?? '';

      final success = await EmailService.sendThankYouEmail(
        donorEmail: donorEmail,
        donorName: donorName,
        amount: amount,
        campaignTitle: campaignTitle,
        ngoName: ngoName,
        donationDate: createdAt,
        ngoEmail: ngoEmail,
      );

      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email client opened successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = (widget.donationData['amount'] ?? 0).toDouble();
    final donorName = widget.donationData['donorName'] ?? 'Anonymous';
    final donorEmail = widget.donationData['donorEmail'] ?? '';
    final donorPhone = widget.donationData['donorPhone'] ?? '';
    final donorId = widget.donationData['donorId'] ?? '';
    final isAnonymous = widget.donationData['isAnonymous'] ?? false;
    final campaignTitle = widget.donationData['campaignTitle'] ?? 'Unknown Campaign';
    final campaignType = widget.donationData['campaignType'] ?? '';
    final message = widget.donationData['message'] ?? '';
    final paymentId = widget.donationData['paymentId'] ?? '';
    final orderId = widget.donationData['orderId'] ?? '';
    final createdAt = (widget.donationData['createdAt'] as Timestamp?)?.toDate();
    final profileImageUrl = widget.donationData['profileImageUrl'] as String?;

    // Debug logging
    print('🖼️ Detail Screen - Donor: $donorName, ProfileURL: $profileImageUrl, IsAnonymous: $isAnonymous');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donation Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Amount Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Donation Received',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMMM dd, yyyy • hh:mm a').format(createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Donor Information
            if (!isAnonymous) ...[
              _buildSection(
                context,
                'Donor Information',
                Icons.person,
                [
                  if (profileImageUrl != null && profileImageUrl.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(profileImageUrl),
                          backgroundColor: primary.withOpacity(0.1),
                          onBackgroundImageError: (exception, stackTrace) {
                            print('❌ Error loading profile image in detail: $exception');
                          },
                          child: null,
                        ),
                      ),
                    ),
                  _buildInfoRow(Icons.person_outline, 'Name', donorName),
                  if (donorEmail.isNotEmpty)
                    _buildInfoRow(Icons.email_outlined, 'Email', donorEmail),
                  if (donorPhone.isNotEmpty)
                    _buildInfoRow(Icons.phone_outlined, 'Phone', donorPhone),
                  if (donorId.isNotEmpty)
                    _buildInfoRow(Icons.badge_outlined, 'Donor ID', donorId, copyable: true, context: context),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Campaign Information
            _buildSection(
              context,
              'Campaign Information',
              Icons.campaign,
              [
                _buildInfoRow(Icons.title, 'Campaign', campaignTitle),
                if (campaignType.isNotEmpty)
                  _buildInfoRow(Icons.category, 'Type', _formatCampaignType(campaignType)),
              ],
            ),

            const SizedBox(height: 16),

            // Payment Information
            _buildSection(
              context,
              'Payment Information',
              Icons.payment,
              [
                _buildInfoRow(Icons.credit_card, 'Payment Method', 'Razorpay'),
                _buildInfoRow(Icons.verified, 'Status', 'Success', statusColor: Colors.green),
                if (paymentId.isNotEmpty)
                  _buildInfoRow(Icons.confirmation_number, 'Payment ID', paymentId, copyable: true, context: context),
                if (orderId.isNotEmpty)
                  _buildInfoRow(Icons.receipt_long, 'Order ID', orderId, copyable: true, context: context),
              ],
            ),

            const SizedBox(height: 16),

            // Message
            if (message.isNotEmpty) ...[
              _buildSection(
                context,
                'Donor Message',
                Icons.message,
                [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!isAnonymous && donorEmail.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSendingEmail ? null : _sendThankYouEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: primary.withOpacity(0.6),
                        ),
                        icon: _isSendingEmail
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.mail_outline, color: Colors.white),
                        label: Text(
                          _isSendingEmail ? 'Opening Email...' : 'Send Thank You Email',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool copyable = false, Color? statusColor, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: statusColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (copyable && context != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              color: primary,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatCampaignType(String type) {
    switch (type) {
      case 'campaign':
        return 'Campaign';
      case 'emergency':
        return 'Emergency';
      case 'impact':
        return 'Impact Story';
      case 'donation_request':
        return 'Donation Request';
      default:
        return type;
    }
  }
}
