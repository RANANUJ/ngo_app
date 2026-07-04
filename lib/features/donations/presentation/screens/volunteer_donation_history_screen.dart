import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ngo_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ngo_app/features/donations/presentation/controllers/donation_controller.dart';
import 'package:ngo_app/features/donations/domain/models/donation.dart';

class VolunteerDonationHistoryScreen extends StatefulWidget {
  const VolunteerDonationHistoryScreen({super.key});

  @override
  State<VolunteerDonationHistoryScreen> createState() => _VolunteerDonationHistoryScreenState();
}

class _VolunteerDonationHistoryScreenState extends State<VolunteerDonationHistoryScreen> {
  static const Color primary = Color(0xFF0099B8);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final authController = context.read<AuthController>();
    final donationController = context.read<DonationController>();
    if (authController.currentUser != null) {
      await donationController.loadVolunteerDonations(authController.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final donationController = context.watch<DonationController>();
    final user = authController.currentUser;
    final donations = donationController.volunteerDonations;

    double totalDonated = donations.fold(0.0, (sum, d) => sum + d.amount);
    int donationCount = donations.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donation History',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please login to view donation history'))
          : Column(
              children: [
                // Stats Header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total Donated', '₹${totalDonated.toStringAsFixed(0)}'),
                      Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                      _buildStatItem('Donations', '$donationCount'),
                    ],
                  ),
                ),

                // Donation List
                Expanded(
                  child: donationController.isLoading
                      ? const Center(child: CircularProgressIndicator(color: primary))
                      : _buildDonationList(donations),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDonationList(List<Donation> donations) {
    if (donations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No donations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Your donation history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadStats();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: donations.length,
        itemBuilder: (context, index) {
          final donation = donations[index];
          return GestureDetector(
            onTap: () => showDonationDetailDialog(context, donation),
            child: _buildDonationCard(donation),
          );
        },
      ),
    );
  }

  void showDonationDetailDialog(BuildContext context, Donation donation) {
    final type = donation.campaignType;
    final amount = donation.amount;
    final createdAt = donation.createdAt;
    final isAnonymous = donation.isAnonymous;
    final paymentId = donation.paymentId;
    final ngoName = donation.ngoId ?? 'N/A'; // Or fallback if available
    final donorName = donation.donorName;
    final donorEmail = donation.donorEmail;
    final donorPhone = donation.donorPhone;
    final title = donation.campaignTitle;

    String dateStr = DateFormat('dd/MM/yyyy').format(createdAt);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: primary, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Donation Details',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow('Title', title),
                _detailRow('NGO', ngoName),
                _detailRow('Amount', '₹${amount.toStringAsFixed(0)}'),
                _detailRow('Date', dateStr),
                if (paymentId.isNotEmpty) _detailRow('Payment ID', paymentId),
                if (isAnonymous)
                  _detailRow('Donor', 'Anonymous')
                else ...[
                  _detailRow('Donor', donorName),
                  if (donorEmail.isNotEmpty) _detailRow('Email', donorEmail),
                  if (donorPhone.isNotEmpty) _detailRow('Phone', donorPhone),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Donation donation) {
    final type = donation.campaignType;
    final amount = donation.amount;
    final createdAt = donation.createdAt;
    final isAnonymous = donation.isAnonymous;
    final title = donation.campaignTitle;

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'emergency':
        icon = Icons.emergency;
        iconColor = Colors.red;
        break;
      case 'impact':
        icon = Icons.trending_up;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.volunteer_activism;
        iconColor = Colors.green;
    }

    String dateStr = DateFormat('dd/MM/yyyy').format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (isAnonymous) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Anonymous',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}
