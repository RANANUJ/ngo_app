import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ngo_app/features/donations/presentation/controllers/donation_controller.dart';
import 'package:ngo_app/features/donations/domain/models/donation_request.dart';
import 'package:ngo_app/features/donations/presentation/screens/payment_donation_screen.dart';

class VolunteerDonationRequestScreen extends StatefulWidget {
  const VolunteerDonationRequestScreen({super.key});

  @override
  State<VolunteerDonationRequestScreen> createState() => _VolunteerDonationRequestScreenState();
}

class _VolunteerDonationRequestScreenState extends State<VolunteerDonationRequestScreen> {
  static const Color primary = Color(0xFF0099B8);
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Food', 'Clothing', 'Medical', 'Education', 'Shelter', 'Other'];

  @override
  Widget build(BuildContext context) {
    final donationController = context.watch<DonationController>();

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
          'Donation Requests',
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
          // Category Filter
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: _categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: primary,
                    labelStyle: TextStyle(
                      color: _selectedCategory == cat ? Colors.white : Colors.black,
                      fontWeight: _selectedCategory == cat ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey.shade100,
                  ),
                )).toList(),
              ),
            ),
          ),
          
          // Requests List
          Expanded(
            child: StreamBuilder<List<DonationRequest>>(
              stream: donationController.streamActiveDonationRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading requests',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                var requests = snapshot.data ?? [];
                if (_selectedCategory != 'All') {
                  requests = requests.where((r) => r.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
                }

                // Sort by createdAt descending
                requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.volunteer_activism, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategory == 'All' 
                            ? 'No donation requests available' 
                            : 'No $_selectedCategory requests available',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new requests',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _buildRequestCard(request);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(DonationRequest request) {
    final title = request.title;
    final description = request.description;
    final category = request.category;
    final targetAmount = request.targetAmount;
    final collectedAmount = request.collectedAmount;
    final location = request.location;
    final dueDate = request.dueDate;
    final imageUrl = request.images.isNotEmpty ? request.images.first : null;
    
    final progress = targetAmount > 0 ? collectedAmount / targetAmount : 0.0;
    
    String dueDateStr = 'No deadline';
    if (dueDate != null) {
      dueDateStr = DateFormat('dd/MM/yyyy').format(dueDate);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentDonationScreen(
              campaignId: request.id,
              campaignTitle: title,
              campaignDescription: description,
              goalAmount: targetAmount,
              raisedAmount: collectedAmount,
              donationType: 'donation_request',
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: primary.withValues(alpha: 0.1),
                    child: const Center(child: Icon(Icons.image, size: 40, color: primary)),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.verified, size: 16, color: Colors.blue.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Drive',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (targetAmount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${collectedAmount.toStringAsFixed(0)} raised',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: primary),
                        ),
                        Text(
                          'of ₹${targetAmount.toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(primary),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Due: $dueDateStr',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentDonationScreen(
                              campaignId: request.id,
                              campaignTitle: title,
                              campaignDescription: description,
                              goalAmount: targetAmount,
                              raisedAmount: collectedAmount,
                              donationType: 'donation_request',
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Donate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Colors.orange;
      case 'clothing': return Colors.purple;
      case 'medical': return Colors.red;
      case 'education': return Colors.blue;
      case 'shelter': return Colors.green;
      default: return Colors.grey;
    }
  }
}
