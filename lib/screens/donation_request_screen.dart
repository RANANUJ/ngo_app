import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ngo_registration_service.dart';

class DonationRequestScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const DonationRequestScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<DonationRequestScreen> createState() => _DonationRequestScreenState();
}

class _DonationRequestScreenState extends State<DonationRequestScreen> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  late TabController _tabController;
  
  int _totalRequests = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTotalRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTotalRequests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('donation_requests')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .get();
      if (mounted) {
        setState(() => _totalRequests = snapshot.docs.length);
      }
    } catch (e) {
      debugPrint('Error loading total requests: $e');
    }
  }

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
          'Donation Request',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total count
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Total : $_totalRequests',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
          
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Approved'),
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList('approved'),
                _buildRequestList('pending'),
                _buildRequestList('completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donation_requests')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
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

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'approved' ? Icons.check_circle_outline 
                      : status == 'pending' ? Icons.pending_outlined 
                      : Icons.task_alt,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status} requests',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildRequestCard(data, docs[index].id, status);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data, String docId, String status) {
    final title = data['title'] ?? 'Donation Request';
    final donorName = data['donorName'] ?? 'Anonymous';
    final location = data['location'] ?? 'Unknown Location';
    final createdAt = data['createdAt'] as Timestamp?;
    final dueDate = data['dueDate'] as Timestamp?;
    
    String dayOfWeek = 'N/A';
    String dueDateStr = 'N/A';
    
    if (createdAt != null) {
      final date = createdAt.toDate();
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      dayOfWeek = days[date.weekday - 1];
    }
    
    if (dueDate != null) {
      final date = dueDate.toDate();
      dueDateStr = '${date.day} ${_getMonthName(date.month).substring(0, 3)}';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'From: $donorName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Location: $location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      dayOfWeek,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Due date: $dueDateStr',
                      style: const TextStyle(
                        fontSize: 11,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Radio button or action
          const SizedBox(width: 12),
          if (status == 'pending')
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
              onSelected: (value) => _handleAction(value, docId),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Approve'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reject',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Reject'),
                    ],
                  ),
                ),
              ],
            )
          else
            Radio<bool>(
              value: true,
              groupValue: true,
              onChanged: (_) {},
              activeColor: status == 'completed' ? Colors.green : primary,
            ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, String docId) async {
    try {
      String newStatus = action == 'approve' ? 'approved' : 'rejected';
      
      await FirebaseFirestore.instance
          .collection('donation_requests')
          .doc(docId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${action}d successfully'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
        _loadTotalRequests();
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

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
