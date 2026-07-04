import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'package:ngo_app/features/donations/domain/models/donation_request.dart';
import 'package:ngo_app/features/donations/presentation/controllers/donation_controller.dart';
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
    final donationController = context.watch<DonationController>();

    return Scaffold(
      appBar: AppBar(
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
      body: StreamBuilder<List<DonationRequest>>(
        stream: donationController.streamNgoDonationRequests(widget.ngoData.id),
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

          final allRequests = snapshot.data ?? [];
          
          // Separate into in-progress and completed
          final inProgressRequests = allRequests.where((req) {
            final status = req.status;
            return status == 'active' || status == 'pending' || status == 'approved' || status == 'in_progress';
          }).toList();
          
          final completedRequests = allRequests.where((req) {
            final status = req.status;
            return status == 'completed' || status == 'closed';
          }).toList();

          // Sort by createdAt descending
          inProgressRequests.sort((a, b) {
            final aTime = a.createdAt;
            final bTime = b.createdAt;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          
          completedRequests.sort((a, b) {
            final aTime = a.createdAt;
            final bTime = b.createdAt;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                _buildSummaryCard(inProgressRequests.length, completedRequests.length),
                const SizedBox(height: 24),
                
                // In Progress Section
                _buildSectionHeader('In Progress', inProgressRequests.length, Icons.pending_actions),
                const SizedBox(height: 12),
                if (inProgressRequests.isEmpty)
                  _buildEmptyState('No requests in progress')
                else
                  ...inProgressRequests.map((req) => _buildRequestCard(
                    req,
                    isCompleted: false,
                  )),
                
                const SizedBox(height: 24),
                
                // Completed Section
                _buildSectionHeader('Completed', completedRequests.length, Icons.check_circle),
                const SizedBox(height: 12),
                if (completedRequests.isEmpty)
                  _buildEmptyState('No completed requests')
                else
                  ...completedRequests.map((req) => _buildRequestCard(
                    req,
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
            color: Colors.grey.withValues(alpha: 0.08),
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
            color: primary.withValues(alpha: 0.1),
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

  Widget _buildRequestCard(DonationRequest req, {required bool isCompleted}) {
    final title = req.title.isNotEmpty ? req.title : 'Donation Post';
    final category = req.category.isNotEmpty ? req.category : 'General';
    final location = req.location.isNotEmpty ? req.location : 'Unknown Location';
    final status = req.status;
    final targetAmount = req.targetAmount;
    final collectedAmount = req.collectedAmount;
    final createdAt = req.createdAt;
    
    String dateStr = '';
    if (createdAt != null) {
      dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }

    Color statusColor = primary;
    if (status == 'completed' || status == 'closed') {
      statusColor = Colors.green;
    } else if (status == 'active') {
      statusColor = primary;
    }

    return GestureDetector(
      onTap: () => _showDetailScreen(req, isCompleted),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isCompleted ? Border.all(color: Colors.green.withValues(alpha: 0.3)) : null,
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

  void _showDetailScreen(DonationRequest req, bool isCompleted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DonationDetailScreen(
          req: req,
          isCompleted: isCompleted,
          ngoData: widget.ngoData,
        ),
      ),
    );
  }
}

// Detail Screen for Donation Post
class _DonationDetailScreen extends StatelessWidget {
  final DonationRequest req;
  final bool isCompleted;
  final NgoRegistrationRequest ngoData;
  
  static const Color primary = Color(0xFF0099B8);

  const _DonationDetailScreen({
    required this.req,
    required this.isCompleted,
    required this.ngoData,
  });

  @override
  Widget build(BuildContext context) {
    final donationController = context.watch<DonationController>();

    return StreamBuilder<List<DonationRequest>>(
      stream: donationController.streamNgoDonationRequests(ngoData.id),
      builder: (context, snapshot) {
        final currentReq = snapshot.data?.firstWhere((r) => r.id == req.id, orElse: () => req) ?? req;
        
        final title = currentReq.title.isNotEmpty ? currentReq.title : 'Donation Post';
        final description = currentReq.description.isNotEmpty ? currentReq.description : 'No description available';
        final category = currentReq.category.isNotEmpty ? currentReq.category : 'General';
        final location = currentReq.location.isNotEmpty ? currentReq.location : 'Unknown Location';
        final status = currentReq.status;
        final targetAmount = currentReq.targetAmount.toDouble();
        final collectedAmount = currentReq.collectedAmount.toDouble();
        final urgencyLevel = currentReq.urgencyLevel.isNotEmpty ? currentReq.urgencyLevel : 'Normal';
        final donorsCount = currentReq.donorsCount;
        final createdAt = currentReq.createdAt;
        final dueDate = currentReq.dueDate;
        final images = currentReq.images;
        
        final progress = targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
        final isActive = status == 'active';
        
        String dateStr = '';
        if (createdAt != null) {
          dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
        }
        
        String dueDateStr = '';
        if (dueDate != null) {
          dueDateStr = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
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
                          color: primary.withValues(alpha: 0.1),
                          child: const Center(child: Icon(Icons.image, size: 50, color: primary)),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: primary.withValues(alpha: 0.1),
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
                                color: Colors.red.withValues(alpha: 0.1),
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
                              color: Colors.grey.withValues(alpha: 0.1),
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
                        color: Colors.grey.withValues(alpha: 0.2),
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
                            campaignId: req.id,
                            campaignTitle: req.title.isNotEmpty ? req.title : 'Donation Request',
                            campaignDescription: req.description,
                            goalAmount: req.targetAmount,
                            raisedAmount: req.collectedAmount,
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
      final donationController = context.read<DonationController>();
      await donationController.markRequestComplete(req.id);
      
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
}
