import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
          Expanded(child: _buildDonationsList()),
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
          colors: [primary, primary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
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
              color: Colors.white.withOpacity(0.2),
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

  Widget _buildDonationsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    Query query = FirebaseFirestore.instance
        .collection('ngos')
        .doc(user.uid)
        .collection('received_donations')
        .orderBy('createdAt', descending: true);

    // Apply filters
    if (_selectedFilter != 'all') {
      DateTime startDate = DateTime.now();
      switch (_selectedFilter) {
        case 'today':
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'week':
          startDate = startDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(startDate.year, startDate.month, 1);
          break;
      }
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final donations = snapshot.data?.docs ?? [];

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

        // Calculate stats
        double total = 0;
        Set<String> uniqueDonors = {};
        for (var doc in donations) {
          final data = doc.data() as Map<String, dynamic>;
          total += (data['amount'] ?? 0).toDouble();
          if (data['donorId'] != null) {
            uniqueDonors.add(data['donorId']);
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
            final data = donations[index].data() as Map<String, dynamic>;
            final donationId = donations[index].id;
            return _buildDonationCard(data, donationId);
          },
        );
      },
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> data, String donationId) {
    final amount = (data['amount'] ?? 0).toDouble();
    final donorName = data['donorName'] ?? 'Anonymous';
    final isAnonymous = data['isAnonymous'] ?? false;
    final campaignTitle = data['campaignTitle'] ?? 'Unknown Campaign';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final profileImageUrl = data['profileImageUrl'] as String?;

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
                donationId: donationId,
                donationData: data,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 30,
                backgroundColor: primary.withOpacity(0.1),
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
              
              // Donor Info
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
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Amount
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
