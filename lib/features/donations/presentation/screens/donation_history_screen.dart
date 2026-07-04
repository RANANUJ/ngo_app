import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'package:ngo_app/features/donations/domain/models/donation.dart';
import 'package:ngo_app/features/donations/presentation/controllers/donation_controller.dart';
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
    final donationController = context.watch<DonationController>();

    return Scaffold(
      appBar: AppBar(
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
                      selectedColor: primary.withValues(alpha: 0.2),
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
            child: StreamBuilder<List<Donation>>(
              stream: donationController.streamMonthlyDonations(ngoId: widget.ngoData.id),
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

                final donations = _filterByDate(snapshot.data ?? []);
                
                if (donations.isEmpty) {
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
                for (var donation in donations) {
                  totalAmount += donation.amount;
                }

                return Column(
                  children: [
                    // Summary card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, primary.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Total Donations', donations.length.toString()),
                          Container(width: 1, height: 40, color: Colors.white30),
                          _buildSummaryItem('Total Amount', '₹${totalAmount.toStringAsFixed(0)}'),
                        ],
                      ),
                    ),
                    
                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: donations.length,
                        itemBuilder: (context, index) {
                          final donation = donations[index];
                          return _buildDonationCard(donation);
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

  List<Donation> _filterByDate(List<Donation> list) {
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

    var filtered = list;
    
    if (startDate != null) {
      filtered = list.where((donation) {
        final createdAt = donation.createdAt;
        return createdAt.isAfter(startDate!) || 
               createdAt.isAtSameMomentAs(startDate);
      }).toList();
    }
    
    // Sort by createdAt descending
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
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

  Widget _buildDonationCard(Donation donation) {
    final donorName = donation.isAnonymous ? 'Anonymous' : (donation.donorName.isNotEmpty ? donation.donorName : 'Anonymous');
    final amount = donation.amount;
    final createdAt = donation.createdAt;
    final profileImageUrl = donation.profileImageUrl;
    final isAnonymous = donation.isAnonymous;
    final campaignTitle = donation.campaignTitle.isNotEmpty ? donation.campaignTitle : 'Unknown Campaign';
    
    // Debug logging
    print('🖼️ Donation Card - Donor: $donorName, ProfileURL: $profileImageUrl, IsAnonymous: $isAnonymous');
    
    final dateStr = DateFormat('dd MMM yyyy').format(createdAt);
    final timeStr = DateFormat('hh:mm a').format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              // Profile Photo or Icon
              CircleAvatar(
                radius: 28,
                backgroundColor: primary.withValues(alpha: 0.1),
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
}
