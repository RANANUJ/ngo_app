import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../payment_donation_screen.dart';

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
            child: StreamBuilder<QuerySnapshot>(
              stream: _getRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primary));
                }

                if (snapshot.hasError) {
                  debugPrint('Error: ${snapshot.error}');
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

                // Filter by category in memory to avoid composite index requirement
                var docs = snapshot.data?.docs ?? [];
                if (_selectedCategory != 'All') {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['category'] == _selectedCategory;
                  }).toList();
                }
                
                // Sort by createdAt
                docs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism, size: 80, color: Colors.grey.shade300),
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
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildRequestCard(data, doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getRequestsStream() {
    // Query donation_posts with active status for volunteers to see and donate
    return FirebaseFirestore.instance
        .collection('donation_posts')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  Widget _buildRequestCard(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? 'Donation Request';
    final description = data['description'] ?? '';
    final ngoName = data['ngoName'] ?? 'NGO';
    final category = data['category'] ?? 'Other';
    final targetAmount = data['targetAmount'] ?? 0;
    final collectedAmount = data['collectedAmount'] ?? 0;
    final location = data['location'] ?? 'Unknown Location';
    final dueDate = data['dueDate'] as Timestamp?;
    final imageUrl = data['imageUrl'] as String?;
    
    final progress = targetAmount > 0 ? collectedAmount / targetAmount : 0.0;
    
    String dueDateStr = 'No deadline';
    if (dueDate != null) {
      final date = dueDate.toDate();
      dueDateStr = '${date.day}/${date.month}/${date.year}';
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
              campaignId: docId,
              campaignTitle: data['title'] ?? 'Donation Request',
              campaignDescription: data['description'],
              goalAmount: data['targetAmount'],
              raisedAmount: data['collectedAmount'],
              donationType: 'donation_request',
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
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
                    color: primary.withOpacity(0.1),
                    child: const Center(child: Icon(Icons.image, size: 40, color: primary)),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge & NGO Name
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
                        ngoName,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Location
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
                  
                  // Progress Bar
                  if (targetAmount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹$collectedAmount raised',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: primary),
                        ),
                        Text(
                          'of ₹$targetAmount',
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
                  
                  // Due Date & Donate Button
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
                              campaignId: docId,
                              campaignTitle: data['title'] ?? 'Donation Request',
                              campaignDescription: data['description'],
                              goalAmount: data['targetAmount'],
                              raisedAmount: data['collectedAmount'],
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

  void _showDonationDialog(Map<String, dynamic> data, String docId) {
    final amountController = TextEditingController();
    final messageController = TextEditingController();
    int? selectedAmount;
    bool isAnonymous = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Make a Donation',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'For: ${data['title']}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // Quick Amount Selection
                const Text('Select Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [100, 500, 1000, 2000, 5000].map((amt) => ChoiceChip(
                    label: Text('₹$amt'),
                    selected: selectedAmount == amt,
                    onSelected: (s) => setModalState(() {
                      selectedAmount = s ? amt : null;
                      if (s) amountController.clear();
                    }),
                    selectedColor: primary,
                    labelStyle: TextStyle(
                      color: selectedAmount == amt ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),

                // Custom Amount
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Or enter custom amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  onChanged: (_) => setModalState(() => selectedAmount = null),
                ),
                const SizedBox(height: 16),

                // Message
                TextField(
                  controller: messageController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Message (Optional)',
                    hintText: 'Write a message for the NGO...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Anonymous Checkbox
                CheckboxListTile(
                  value: isAnonymous,
                  onChanged: (v) => setModalState(() => isAnonymous = v ?? false),
                  title: const Text('Donate anonymously'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),

                // Donate Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _submitDonation(
                      docId,
                      data,
                      selectedAmount ?? int.tryParse(amountController.text) ?? 0,
                      messageController.text,
                      isAnonymous,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Donate Now',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitDonation(
    String docId,
    Map<String, dynamic> requestData,
    int amount,
    String message,
    bool isAnonymous,
  ) async {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.pop(context); // Close bottom sheet

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Add donation record
      await FirebaseFirestore.instance.collection('donations').add({
        'requestId': docId,
        'ngoId': requestData['ngoId'],
        'donorId': user?.uid,
        'donorEmail': isAnonymous ? 'Anonymous' : user?.email,
        'donorName': isAnonymous ? 'Anonymous' : (user?.displayName ?? 'Volunteer'),
        'amount': amount,
        'message': message,
        'isAnonymous': isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update collected amount in donation post
      await FirebaseFirestore.instance.collection('donation_posts').doc(docId).update({
        'collectedAmount': FieldValue.increment(amount),
        'donorsCount': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your donation!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
