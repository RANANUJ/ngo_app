import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/ngo_registration_service.dart';
import 'donation_detail_screen.dart';

class DonationHistoryScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const DonationHistoryScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  static const Color primary = Color(0xFF0099B8);
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'This Week', 'This Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? primary : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      checkmarkColor: primary,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Donations list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primary));
                }

                if (snapshot.hasError) {
                  debugPrint('Donation history error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading donations',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                // Filter by date in memory
                final docs = _filterByDate(snapshot.data?.docs ?? []);
                
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No donation history',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completed donations will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate totals
                double totalAmount = 0;
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalAmount += (data['amount'] ?? 0).toDouble();
                }

                return Column(
                  children: [
                    // Summary card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Total Donations', docs.length.toString()),
                          Container(width: 1, height: 40, color: Colors.white30),
                          _buildSummaryItem('Total Amount', '₹${totalAmount.toStringAsFixed(0)}'),
                        ],
                      ),
                    ),
                    
                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildDonationCard(doc.id, data);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    // Simple query without composite index requirement
    // Filter in memory to avoid index issues
    return FirebaseFirestore.instance
        .collection('donations')
        .where('ngoId', isEqualTo: widget.ngoData.id)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterByDate(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    DateTime? startDate;
    
    switch (_selectedFilter) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = null;
    }

    var filtered = docs;
    
    if (startDate != null) {
      filtered = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt == null) return false;
        return createdAt.toDate().isAfter(startDate!) || 
               createdAt.toDate().isAtSameMomentAs(startDate);
      }).toList();
    }
    
    // Sort by createdAt descending
    filtered.sort((a, b) {
      final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
      final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });
    
    return filtered;
  }

  Widget _buildSummaryItem(String label, String value) {
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
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDonationCard(String donationId, Map<String, dynamic> data) {
    final donorName = data['donorName'] ?? 'Anonymous';
    final amount = (data['amount'] ?? 0).toDouble();
    final createdAt = data['createdAt'] as Timestamp?;
    final profileImageUrl = data['profileImageUrl'] as String?;
    final isAnonymous = data['isAnonymous'] ?? false;
    final campaignTitle = data['campaignTitle'] ?? 'Unknown Campaign';
    
    // Debug logging
    print('🖼️ Donation Card - Donor: $donorName, ProfileURL: $profileImageUrl, IsAnonymous: $isAnonymous');
    
    String dateStr = 'N/A';
    String timeStr = '';
    if (createdAt != null) {
      final date = createdAt.toDate();
      dateStr = DateFormat('dd MMM yyyy').format(date);
      timeStr = DateFormat('hh:mm a').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              // Profile Photo or Icon
              CircleAvatar(
                radius: 28,
                backgroundColor: primary.withOpacity(0.1),
                backgroundImage: profileImageUrl != null && 
                                  profileImageUrl.isNotEmpty && 
                                  !isAnonymous
                    ? NetworkImage(profileImageUrl)
                    : null,
                onBackgroundImageError: profileImageUrl != null && 
                                         profileImageUrl.isNotEmpty && 
                                         !isAnonymous
                    ? (exception, stackTrace) {
                        print('❌ Error loading profile image: $exception');
                      }
                    : null,
                child: profileImageUrl == null || 
                       profileImageUrl.isEmpty || 
                       isAnonymous
                    ? Icon(
                        isAnonymous ? Icons.person_off : Icons.person,
                        color: primary,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaignTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time, size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Amount and Arrow
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
