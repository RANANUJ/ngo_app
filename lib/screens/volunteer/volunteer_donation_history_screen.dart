import 'package:ngo_app/core/utils/network/network_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';

class VolunteerDonationHistoryScreen extends StatefulWidget {
  const VolunteerDonationHistoryScreen({super.key});

  @override
  State<VolunteerDonationHistoryScreen> createState() => _VolunteerDonationHistoryScreenState();
}

class _VolunteerDonationHistoryScreenState extends State<VolunteerDonationHistoryScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  double _totalDonated = 0;
  int _donationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get all donations by this user
      final donationsSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: user.uid)
          .get();

      // Get emergency donations
      final emergencySnapshot = await FirebaseFirestore.instance
          .collection('emergency_donations_records')
          .where('donorId', isEqualTo: user.uid)
          .get();

      // Get impact donations
      final impactSnapshot = await FirebaseFirestore.instance
          .collection('impact_donations')
          .where('donorId', isEqualTo: user.uid)
          .get();

      double total = 0;
      int count = 0;

      for (var doc in donationsSnapshot.docs) {
        total += (doc.data()['amount'] ?? 0).toDouble();
        count++;
      }
      for (var doc in emergencySnapshot.docs) {
        total += (doc.data()['amount'] ?? 0).toDouble();
        count++;
      }
      for (var doc in impactSnapshot.docs) {
        total += (doc.data()['amount'] ?? 0).toDouble();
        count++;
      }

      if (mounted) {
        setState(() {
          _totalDonated = total;
          _donationCount = count;
        });
      }
    } catch (e) {
      secureLog('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                      colors: [primary, primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total Donated', '₹${_totalDonated.toStringAsFixed(0)}'),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                      _buildStatItem('Donations', '$_donationCount'),
                    ],
                  ),
                ),

                // Donation List
                Expanded(
                  child: _buildDonationList(user.uid),
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
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDonationList(String userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllDonations(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListSkeleton(itemCount: 4, height: 75);
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading donations',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allDonations = snapshot.data ?? [];

        if (allDonations.isEmpty) {
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
            _loadStats();
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allDonations.length,
            itemBuilder: (context, index) {
            final donation = allDonations[index];
            return GestureDetector(
              onTap: () => showDonationDetailDialog(context, donation),
              child: _buildDonationCard(donation),
            );
          },
        ),
      );
    },
  );
}

void showDonationDetailDialog(BuildContext context, Map<String, dynamic> donation) {
  final type = donation['type'] as String;
  final amount = donation['amount'] ?? 0;
  final createdAt = donation['createdAt'] as Timestamp?;
  final isAnonymous = donation['isAnonymous'] ?? false;
  final paymentId = donation['paymentId'] ?? '';
  final ngoName = donation['ngoName'] ?? donation['receiverName'] ?? 'N/A';
  final donorName = donation['donorName'] ?? 'N/A';
  final donorEmail = donation['donorEmail'] ?? '';
  final donorPhone = donation['donorPhone'] ?? '';
  String title;
  switch (type) {
    case 'emergency':
      title = donation['emergencyTitle'] ?? 'Emergency Donation';
      break;
    case 'impact':
      title = donation['impactTitle'] ?? 'Impact Support';
      break;
    default:
      title = donation['requestTitle'] ?? 'Donation';
  }
  String dateStr = 'N/A';
  if (createdAt != null) {
    final date = createdAt.toDate();
    dateStr = '${date.day}/${date.month}/${date.year}';
  }
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
              Row(
                children: [
                  Icon(Icons.receipt_long, color: Color(0xFF0099B8), size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Donation Details',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0099B8)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              detailRow('Title', title),
              detailRow('NGO', ngoName),
              detailRow('Amount', '₹$amount'),
              detailRow('Date', dateStr),
              if (paymentId.isNotEmpty) detailRow('Payment ID', paymentId),
              if (isAnonymous)
                detailRow('Donor', 'Anonymous'),
              if (!isAnonymous) ...[
                detailRow('Donor', donorName),
                if (donorEmail.isNotEmpty) detailRow('Email', donorEmail),
                if (donorPhone.isNotEmpty) detailRow('Phone', donorPhone),
              ],
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0099B8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget detailRow(String label, String value) {
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
            style: TextStyle(color: Colors.black87),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

  Future<List<Map<String, dynamic>>> _getAllDonations(String userId) async {
    List<Map<String, dynamic>> allDonations = [];

    try {
      // Get regular donations
      final donationsSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .get();

      for (var doc in donationsSnapshot.docs) {
        final data = doc.data();
        allDonations.add({
          ...data,
          'type': 'donation_request',
          'docId': doc.id,
        });
      }
    } catch (e) {
      secureLog('Error loading donations: $e');
    }

    try {
      // Get emergency donations
      final emergencySnapshot = await FirebaseFirestore.instance
          .collection('emergency_donations_records')
          .where('donorId', isEqualTo: userId)
          .get();

      for (var doc in emergencySnapshot.docs) {
        final data = doc.data();
        allDonations.add({
          ...data,
          'type': 'emergency',
          'docId': doc.id,
        });
      }
    } catch (e) {
      secureLog('Error loading emergency donations: $e');
    }

    try {
      // Get impact donations
      final impactSnapshot = await FirebaseFirestore.instance
          .collection('impact_donations')
          .where('donorId', isEqualTo: userId)
          .get();

      for (var doc in impactSnapshot.docs) {
        final data = doc.data();
        allDonations.add({
          ...data,
          'type': 'impact',
          'docId': doc.id,
        });
      }
    } catch (e) {
      secureLog('Error loading impact donations: $e');
    }

    // Sort by createdAt
    allDonations.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return allDonations;
  }
 
  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final type = donation['type'] as String;
    final amount = donation['amount'] ?? 0;
    final createdAt = donation['createdAt'] as Timestamp?;
    final isAnonymous = donation['isAnonymous'] ?? false;

    String title;
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'emergency':
        title = donation['emergencyTitle'] ?? 'Emergency Donation';
        icon = Icons.emergency;
        iconColor = Colors.red;
        break;
      case 'impact':
        title = donation['impactTitle'] ?? 'Impact Support';
        icon = Icons.trending_up;
        iconColor = Colors.purple;
        break;
      default:
        title = donation['requestTitle'] ?? 'Donation';
        icon = Icons.volunteer_activism;
        iconColor = Colors.green;
    }

    String dateStr = 'N/A';
    if (createdAt != null) {
      final date = createdAt.toDate();
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          
          // Details
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
          
          // Amount
          Text(
            '₹$amount',
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
