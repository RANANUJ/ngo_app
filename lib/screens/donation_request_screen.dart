import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ngo_registration_service.dart';
import 'payment_donation_screen.dart';

class DonationRequestScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const DonationRequestScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<DonationRequestScreen> createState() => _DonationRequestScreenState();
}

class _DonationRequestScreenState extends State<DonationRequestScreen> {
  static const Color primary = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donation_posts')
            .where('ngoId', isEqualTo: widget.ngoData.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading requests',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];
          
          // Separate into in-progress and completed
          // donation_posts uses 'active' for in-progress and 'completed' for done
          final inProgressDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            return status == 'active' || status == 'pending' || status == 'approved' || status == 'in_progress';
          }).toList();
          
          final completedDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            return status == 'completed' || status == 'closed';
          }).toList();

          // Sort by createdAt
          inProgressDocs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          
          completedDocs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                _buildSummaryCard(inProgressDocs.length, completedDocs.length),
                const SizedBox(height: 24),
                
                // In Progress Section
                _buildSectionHeader('In Progress', inProgressDocs.length, Icons.pending_actions),
                const SizedBox(height: 12),
                if (inProgressDocs.isEmpty)
                  _buildEmptyState('No requests in progress')
                else
                  ...inProgressDocs.map((doc) => _buildRequestCard(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                    isCompleted: false,
                  )),
                
                const SizedBox(height: 24),
                
                // Completed Section
                _buildSectionHeader('Completed', completedDocs.length, Icons.check_circle),
                const SizedBox(height: 12),
                if (completedDocs.isEmpty)
                  _buildEmptyState('No completed requests')
                else
                  ...completedDocs.map((doc) => _buildRequestCard(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                    isCompleted: true,
                  )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(int inProgress, int completed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'In Progress',
              inProgress.toString(),
              primary,
              Icons.pending_actions,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildSummaryItem(
              'Completed',
              completed.toString(),
              Colors.green,
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data, String docId, {required bool isCompleted}) {
    final title = data['title'] ?? 'Donation Post';
    final category = data['category'] ?? 'General';
    final location = data['location'] ?? 'Unknown Location';
    final status = data['status'] ?? 'active';
    final targetAmount = data['targetAmount'] ?? 0;
    final collectedAmount = data['collectedAmount'] ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;
    
    String dateStr = '';
    if (createdAt != null) {
      final date = createdAt.toDate();
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    Color statusColor = primary;
    if (status == 'completed' || status == 'closed') {
      statusColor = Colors.green;
    } else if (status == 'active') {
      statusColor = primary;
    }

    return GestureDetector(
      onTap: () => _showDetailScreen(data, docId, isCompleted),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isCompleted ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.currency_rupee, size: 14, color: Colors.grey.shade500),
                      Text(
                        '₹$collectedAmount / ₹$targetAmount',
                        style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Right side - date and arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailScreen(Map<String, dynamic> data, String docId, bool isCompleted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DonationDetailScreen(
          data: data,
          docId: docId,
          isCompleted: isCompleted,
          ngoData: widget.ngoData,
        ),
      ),
    );
  }

  Future<void> _handleAction(String action, String docId) async {
    try {
      String newStatus = action == 'approve' ? 'approved' : 'completed';
      
      await FirebaseFirestore.instance
          .collection('donation_posts')
          .doc(docId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (action == 'complete') 'completedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approve' ? 'Request approved' : 'Request marked as complete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Detail Screen for Donation Post
class _DonationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isCompleted;
  final NgoRegistrationRequest ngoData;
  
  static const Color primary = Color(0xFF0099B8);

  const _DonationDetailScreen({
    required this.data,
    required this.docId,
    required this.isCompleted,
    required this.ngoData,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donation_posts')
          .doc(docId)
          .snapshots(),
      builder: (context, snapshot) {
        final liveData = snapshot.data?.data() as Map<String, dynamic>? ?? data;
        
        final title = liveData['title'] ?? 'Donation Post';
        final description = liveData['description'] ?? 'No description available';
        final category = liveData['category'] ?? 'General';
        final location = liveData['location'] ?? 'Unknown Location';
        final status = liveData['status'] ?? 'active';
        final targetAmount = (liveData['targetAmount'] ?? 0).toDouble();
        final collectedAmount = (liveData['collectedAmount'] ?? 0).toDouble();
        final urgencyLevel = liveData['urgencyLevel'] ?? 'Normal';
        final donorsCount = liveData['donorsCount'] ?? 0;
        final createdAt = liveData['createdAt'] as Timestamp?;
        final dueDate = liveData['dueDate'] as Timestamp?;
        final images = liveData['images'] as List<dynamic>? ?? [];
        
        final progress = targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
        final isActive = status == 'active';
        
        String dateStr = '';
        if (createdAt != null) {
          final date = createdAt.toDate();
          dateStr = '${date.day}/${date.month}/${date.year}';
        }
        
        String dueDateStr = '';
        if (dueDate != null) {
          final date = dueDate.toDate();
          dueDateStr = '${date.day}/${date.month}/${date.year}';
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Donation Details',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            actions: [
              if (isActive)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: primary),
                  onSelected: (value) => _handleAction(context, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text('Mark Complete'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index) => Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: primary.withOpacity(0.1),
                          child: const Center(child: Icon(Icons.image, size: 50, color: primary)),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: primary.withOpacity(0.1),
                    child: const Center(
                      child: Icon(Icons.volunteer_activism, size: 60, color: primary),
                    ),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge and Category
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive ? primary : Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Completed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (urgencyLevel == 'High' || urgencyLevel == 'Critical')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.priority_high, size: 14, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    urgencyLevel,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Progress Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${collectedAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: primary,
                                      ),
                                    ),
                                    Text(
                                      'of ₹${targetAmount.toStringAsFixed(0)} raised',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${(progress * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '$donorsCount donors',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  progress >= 1.0 ? Colors.green : primary,
                                ),
                                minHeight: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Info Row
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.location_on_outlined, 'Location', location),
                            const Divider(height: 24),
                            _buildInfoRow(Icons.calendar_today, 'Created', dateStr),
                            if (dueDateStr.isNotEmpty) ...[
                              const Divider(height: 24),
                              _buildInfoRow(Icons.event, 'Due Date', dueDateStr),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isActive
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Contribute to Fund',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    try {
      await FirebaseFirestore.instance
          .collection('donation_posts')
          .doc(docId)
          .update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation marked as complete'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDonationDialog(BuildContext context) {
    final amountController = TextEditingController();
    final messageController = TextEditingController();
    int? selectedAmount;

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
                        'Contribute to Fund',
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
                  children: [500, 1000, 2000, 5000, 10000].map((amt) => ChoiceChip(
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
                    labelText: 'Note (Optional)',
                    hintText: 'Add a note for this contribution...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Donate Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _submitDonation(
                      context,
                      selectedAmount ?? int.tryParse(amountController.text) ?? 0,
                      messageController.text,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Contribute Now',
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

  Future<void> _submitDonation(BuildContext context, int amount, String message) async {
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
        'ngoId': ngoData.id,
        'donorId': user?.uid ?? ngoData.id,
        'donorEmail': user?.email ?? ngoData.email,
        'donorName': ngoData.ngoName,
        'donorType': 'ngo',
        'amount': amount,
        'message': message,
        'isAnonymous': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update collected amount in donation post
      await FirebaseFirestore.instance.collection('donation_posts').doc(docId).update({
        'collectedAmount': FieldValue.increment(amount),
        'donorsCount': FieldValue.increment(1),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contribution added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
