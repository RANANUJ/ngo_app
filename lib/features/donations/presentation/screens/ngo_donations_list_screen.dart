import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ngo_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ngo_app/features/donations/presentation/controllers/donation_controller.dart';
import 'package:ngo_app/features/donations/domain/models/donation.dart';
import 'donation_detail_screen.dart';

class NgoDonationsListScreen extends StatefulWidget {
  const NgoDonationsListScreen({Key? key}) : super(key: key);

  @override
  State<NgoDonationsListScreen> createState() => _NgoDonationsListScreenState();
}

class _NgoDonationsListScreenState extends State<NgoDonationsListScreen> {
  static const Color primary = Color(0xFF0099B8);
  String _selectedFilter = 'all'; // all, today, week, month
  double _totalDonations = 0;
  int _totalDonors = 0;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final donationController = context.watch<DonationController>();
    final user = authController.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donations Received',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Time')),
              const PopupMenuItem(value: 'today', child: Text('Today')),
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(child: _buildDonationsList(donationController, user.uid)),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.7)],
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Received',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${_totalDonations.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 32),
                const SizedBox(height: 4),
                Text(
                  '$_totalDonors',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Donors',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsList(DonationController controller, String ngoId) {
    return StreamBuilder<List<Donation>>(
      stream: controller.streamNgoReceivedDonations(ngoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var donations = snapshot.data ?? [];

        // Apply filters
        if (_selectedFilter != 'all') {
          DateTime startDate = DateTime.now();
          final now = DateTime.now();
          switch (_selectedFilter) {
            case 'today':
              startDate = DateTime(now.year, now.month, now.day);
              break;
            case 'week':
              startDate = now.subtract(const Duration(days: 7));
              break;
            case 'month':
              startDate = DateTime(now.year, now.month, 1);
              break;
          }
          donations = donations.where((d) => d.createdAt.isAfter(startDate) || d.createdAt.isAtSameMomentAs(startDate)).toList();
        }

        if (donations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No donations received',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Calculate stats in post frame to avoid build phase setState errors
        double total = 0;
        Set<String> uniqueDonors = {};
        for (var doc in donations) {
          total += doc.amount;
          if (doc.donorId != null) {
            uniqueDonors.add(doc.donorId!);
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && (_totalDonations != total || _totalDonors != uniqueDonors.length)) {
            setState(() {
              _totalDonations = total;
              _totalDonors = uniqueDonors.length;
            });
          }
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index];
            return _buildDonationCard(donation);
          },
        );
      },
    );
  }

  Widget _buildDonationCard(Donation donation) {
    final amount = donation.amount;
    final donorName = donation.donorName;
    final isAnonymous = donation.isAnonymous;
    final campaignTitle = donation.campaignTitle;
    final createdAt = donation.createdAt;
    final profileImageUrl = donation.profileImageUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DonationDetailScreen(
                donationId: donation.id,
                donation: donation,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primary.withValues(alpha: 0.1),
                backgroundImage: profileImageUrl != null && !isAnonymous
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl == null || isAnonymous
                    ? Icon(
                        isAnonymous ? Icons.person_off : Icons.person,
                        color: primary,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaignTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
