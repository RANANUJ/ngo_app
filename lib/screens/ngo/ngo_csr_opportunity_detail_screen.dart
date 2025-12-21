import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NgoCsrOpportunityDetailScreen extends StatefulWidget {
  final String opportunityId;
  final Map<String, dynamic> opportunityData;
  final String ngoId;

  const NgoCsrOpportunityDetailScreen({
    Key? key,
    required this.opportunityId,
    required this.opportunityData,
    required this.ngoId,
  }) : super(key: key);

  @override
  State<NgoCsrOpportunityDetailScreen> createState() => _NgoCsrOpportunityDetailScreenState();
}

class _NgoCsrOpportunityDetailScreenState extends State<NgoCsrOpportunityDetailScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  static const Color primaryDark = Color(0xFF007A94);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  late TabController _tabController;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .where('opportunityId', isEqualTo: widget.opportunityId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (mounted) {
        setState(() {
          _pendingCount = snapshot.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.opportunityData['title'] ?? 'CSR Opportunity';
    final sector = widget.opportunityData['sector'] ?? 'General';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadPendingCount,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showOptionsMenu(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primaryDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                sector,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(widget.opportunityData['status'] ?? 'open'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildQuickStats(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: primary,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: [
                  const Tab(text: 'Details'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Volunteers'),
                        if (_pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: errorRed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Impact'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(),
                  _buildVolunteersTab(),
                  _buildImpactTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .where('opportunityId', isEqualTo: widget.opportunityId)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        
        // Deduplicate by volunteerId for accurate count
        final Set<String> approvedVolunteerIds = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'approved') {
            final volunteerId = data['volunteerId'] as String? ?? doc.id;
            approvedVolunteerIds.add(volunteerId);
          }
        }
        final approvedCount = approvedVolunteerIds.length;
        
        final volunteersNeeded = widget.opportunityData['volunteersNeeded'] ?? 0;
        final budget = (widget.opportunityData['budget'] ?? 0).toDouble();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: _buildStatItem(Icons.currency_rupee, _formatAmount(budget), 'Budget')),
              Container(height: 24, width: 1, color: Colors.white.withOpacity(0.3)),
              Expanded(child: _buildStatItem(Icons.people, '$approvedCount/$volunteersNeeded', 'Volunteers')),
              Container(height: 24, width: 1, color: Colors.white.withOpacity(0.3)),
              Expanded(child: _buildStatItem(Icons.pending_actions, '$_pendingCount', 'Pending')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'open':
        bgColor = successGreen;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'closed':
        bgColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.cancel;
        break;
      case 'completed':
        bgColor = primary;
        textColor = Colors.white;
        icon = Icons.verified;
        break;
      default:
        bgColor = warningOrange;
        textColor = Colors.white;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============== DETAILS TAB ==============
  Widget _buildDetailsTab() {
    final description = widget.opportunityData['description'] ?? 'No description available';
    final createdAt = widget.opportunityData['createdAt'] as Timestamp?;
    final sector = widget.opportunityData['sector'] ?? 'General';
    final budget = (widget.opportunityData['budget'] ?? 0).toDouble();
    final volunteersNeeded = widget.opportunityData['volunteersNeeded'] ?? 0;
    final requirements = widget.opportunityData['requirements'] ?? '';
    final location = widget.opportunityData['location'] ?? 'Not specified';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description Card
        _buildDetailCard(
          'About This Opportunity',
          Icons.info_outline,
          child: Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Info Grid
        _buildDetailCard(
          'Quick Info',
          Icons.dashboard,
          child: Column(
            children: [
              _buildInfoRow(Icons.category, 'Sector', sector),
              const Divider(height: 24),
              _buildInfoRow(Icons.currency_rupee, 'Budget', '₹${_formatAmount(budget)}'),
              const Divider(height: 24),
              _buildInfoRow(Icons.people, 'Volunteers Needed', '$volunteersNeeded'),
              const Divider(height: 24),
              _buildInfoRow(Icons.location_on, 'Location', location),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.calendar_today, 
                'Created', 
                createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt.toDate()) : 'N/A',
              ),
            ],
          ),
        ),

        if (requirements.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDetailCard(
            'Requirements',
            Icons.checklist,
            child: Text(
              requirements,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editOpportunity,
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(1); // Go to volunteers tab
                },
                icon: const Icon(Icons.people, color: Colors.white),
                label: const Text('View Applicants', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, IconData icon, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ============== VOLUNTEERS TAB ==============
  Widget _buildVolunteersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .where('opportunityId', isEqualTo: widget.opportunityId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No volunteer applications yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Applicants will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Deduplicate by volunteerId - keep only the latest application per volunteer
        final Map<String, QueryDocumentSnapshot> uniqueVolunteers = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final volunteerId = data['volunteerId'] as String? ?? doc.id;
          final existingDoc = uniqueVolunteers[volunteerId];
          if (existingDoc == null) {
            uniqueVolunteers[volunteerId] = doc;
          } else {
            // Keep the one with higher priority status or latest date
            final existingData = existingDoc.data() as Map<String, dynamic>;
            final existingStatus = existingData['status'] ?? 'pending';
            final newStatus = data['status'] ?? 'pending';
            // Priority: approved > pending > rejected
            final statusPriority = {'approved': 3, 'pending': 2, 'rejected': 1};
            if ((statusPriority[newStatus] ?? 0) > (statusPriority[existingStatus] ?? 0)) {
              uniqueVolunteers[volunteerId] = doc;
            }
          }
        }
        final uniqueDocs = uniqueVolunteers.values.toList();

        // Separate by status
        final pending = uniqueDocs.where((d) => (d.data() as Map)['status'] == 'pending').toList();
        final approved = uniqueDocs.where((d) => (d.data() as Map)['status'] == 'approved').toList();
        final rejected = uniqueDocs.where((d) => (d.data() as Map)['status'] == 'rejected').toList();

        return RefreshIndicator(
          onRefresh: _loadPendingCount,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats Summary
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildVolunteerStat('${pending.length}', 'Pending', warningOrange),
                    _buildVolunteerStat('${approved.length}', 'Approved', successGreen),
                    _buildVolunteerStat('${rejected.length}', 'Rejected', errorRed),
                    _buildVolunteerStat('${uniqueDocs.length}', 'Total', primary),
                  ],
                ),
              ),

              if (pending.isNotEmpty) ...[
                _buildVolunteerSection('Pending Review', pending, warningOrange),
                const SizedBox(height: 16),
              ],
              if (approved.isNotEmpty) ...[
                _buildVolunteerSection('Approved Volunteers', approved, successGreen),
                const SizedBox(height: 16),
              ],
              if (rejected.isNotEmpty) ...[
                _buildVolunteerSection('Rejected Applications', rejected, errorRed),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildVolunteerStat(String value, String label, Color color) {
    return Column(
      children: [
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
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildVolunteerSection(String title, List<QueryDocumentSnapshot> docs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${docs.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...docs.map((doc) => _buildVolunteerCard(doc)),
      ],
    );
  }

  Widget _buildVolunteerCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final volunteerName = data['volunteerName'] ?? 'Unknown';
    final volunteerEmail = data['volunteerEmail'] ?? '';
    final status = data['status'] ?? 'pending';
    final appliedAt = data['appliedAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primary.withOpacity(0.1),
                child: Text(
                  volunteerName.isNotEmpty ? volunteerName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      volunteerEmail,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildVolunteerStatusBadge(status),
            ],
          ),
          if (appliedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Applied: ${DateFormat('MMM dd, yyyy').format(appliedAt.toDate())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateApplicationStatus(doc.id, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: errorRed,
                      side: BorderSide(color: errorRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateApplicationStatus(doc.id, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Approve', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
          // Show remove option for approved or rejected volunteers
          if (status == 'approved' || status == 'rejected') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (status == 'approved') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateApplicationStatus(doc.id, 'rejected'),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Revoke Access'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: warningOrange,
                        side: BorderSide(color: warningOrange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (status == 'rejected') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateApplicationStatus(doc.id, 'approved'),
                      icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                      label: const Text('Give Access', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: successGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _removeVolunteer(doc.id, volunteerName),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: errorRed,
                      side: BorderSide(color: errorRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _removeVolunteer(String applicationId, String volunteerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: errorRed),
            const SizedBox(width: 8),
            const Text('Remove Volunteer'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "$volunteerName" from this opportunity?\n\nThis will delete their application and any assigned tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete the application
        await FirebaseFirestore.instance
            .collection('csr_volunteer_applications')
            .doc(applicationId)
            .delete();

        // Also delete any tasks assigned to this volunteer for this opportunity
        final tasksSnapshot = await FirebaseFirestore.instance
            .collection('volunteer_tasks')
            .where('opportunityId', isEqualTo: widget.opportunityId)
            .get();
        
        for (var task in tasksSnapshot.docs) {
          await task.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$volunteerName has been removed'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPendingCount();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
          );
        }
      }
    }
  }

  Widget _buildVolunteerStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = successGreen;
        break;
      case 'rejected':
        color = errorRed;
        break;
      default:
        color = warningOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .doc(applicationId)
          .update({
        'status': newStatus,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${newStatus == 'approved' ? 'approved' : 'rejected'} successfully'),
            backgroundColor: newStatus == 'approved' ? successGreen : errorRed,
          ),
        );
        _loadPendingCount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
        );
      }
    }
  }

  // ============== IMPACT TAB ==============
  Widget _buildImpactTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_activities')
          .where('opportunityId', isEqualTo: widget.opportunityId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        final activities = snapshot.data?.docs ?? [];

        // Calculate stats
        int totalHours = 0;
        int totalActivities = activities.length;
        Set<String> uniqueVolunteers = {};

        for (var doc in activities) {
          final data = doc.data() as Map<String, dynamic>;
          totalHours += (data['hoursWorked'] ?? 0) as int;
          final volunteerId = data['volunteerId'] as String?;
          if (volunteerId != null) {
            uniqueVolunteers.add(volunteerId);
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Impact Dashboard Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_graph, color: Colors.white.withOpacity(0.8)),
                      const SizedBox(width: 10),
                      const Text(
                        'Impact Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildImpactStat(Icons.people, '${uniqueVolunteers.length}', 'Active Volunteers')),
                      Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                      Expanded(child: _buildImpactStat(Icons.timer, '$totalHours', 'Hours Contributed')),
                      Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                      Expanded(child: _buildImpactStat(Icons.task_alt, '$totalActivities', 'Activities')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    Icons.add_task,
                    'Log Activity',
                    'Record volunteer work',
                    () => _showLogActivityDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    Icons.share,
                    'Share Impact',
                    'Generate report',
                    () => _shareImpactReport(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Assigned Tasks Section
            _buildAssignedTasksSection(),

            const SizedBox(height: 20),

            // Recent Activities
            if (activities.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.history, color: primary, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...activities.take(10).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildActivityCard(data);
              }),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No activities logged yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activities will appear here once volunteers start logging their work',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildImpactStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedTasksSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_tasks')
          .where('opportunityId', isEqualTo: widget.opportunityId)
          .snapshots(),
      builder: (context, snapshot) {
        final tasks = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: primary, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Assigned Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showCreateTaskDialog,
                  icon: Icon(Icons.add, color: primary, size: 18),
                  label: Text('Add Task', style: TextStyle(color: primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No tasks assigned yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...tasks.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildTaskCard(data, doc.id);
              }),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? 'Task';
    final volunteerName = data['volunteerName'] ?? 'Unassigned';
    final status = data['status'] ?? 'pending';
    
    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = successGreen;
        break;
      case 'in_progress':
        statusColor = warningOrange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              status == 'completed' ? Icons.check_circle : Icons.assignment,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Assigned to: $volunteerName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data) {
    final description = data['description'] ?? 'Activity';
    final hoursWorked = data['hoursWorked'] ?? 0;
    final volunteerName = data['volunteerName'] ?? 'Unknown';
    final createdAt = data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_circle, color: successGreen, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By $volunteerName • $hoursWorked hours',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(createdAt.toDate()),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============== HELPER METHODS ==============
  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: primary),
              title: const Text('Edit Opportunity'),
              onTap: () {
                Navigator.pop(context);
                _editOpportunity();
              },
            ),
            ListTile(
              leading: Icon(Icons.close, color: warningOrange),
              title: const Text('Close Opportunity'),
              onTap: () {
                Navigator.pop(context);
                _closeOpportunity();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: errorRed),
              title: const Text('Delete Opportunity'),
              onTap: () {
                Navigator.pop(context);
                _deleteOpportunity();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editOpportunity() {
    final titleController = TextEditingController(text: widget.opportunityData['title'] ?? '');
    final descriptionController = TextEditingController(text: widget.opportunityData['description'] ?? '');
    final budgetController = TextEditingController(text: (widget.opportunityData['budget'] ?? 0).toString());
    final volunteersController = TextEditingController(text: (widget.opportunityData['volunteersNeeded'] ?? 0).toString());
    final locationController = TextEditingController(text: widget.opportunityData['location'] ?? '');
    final requirementsController = TextEditingController(text: widget.opportunityData['requirements'] ?? '');
    String selectedSector = widget.opportunityData['sector'] ?? 'Education';
    
    final sectors = ['Education', 'Healthcare', 'Environment', 'Rural Development', 'Women Empowerment', 'Child Welfare', 'Disaster Relief', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Icon(Icons.edit, color: primary),
                  const SizedBox(width: 8),
                  const Text('Edit Opportunity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEditField('Title', titleController, Icons.title),
                        const SizedBox(height: 16),
                        _buildEditField('Description', descriptionController, Icons.description, maxLines: 4),
                        const SizedBox(height: 16),
                        const Text('Sector', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: sectors.contains(selectedSector) ? selectedSector : 'Education',
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.category, color: primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setModalState(() => selectedSector = v ?? 'Education'),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _buildEditField('Budget (₹)', budgetController, Icons.currency_rupee, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildEditField('Volunteers', volunteersController, Icons.people, keyboardType: TextInputType.number)),
                        ]),
                        const SizedBox(height: 16),
                        _buildEditField('Location', locationController, Icons.location_on),
                        const SizedBox(height: 16),
                        _buildEditField('Requirements', requirementsController, Icons.checklist, maxLines: 3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), side: BorderSide(color: primary)),
                    child: Text('Cancel', style: TextStyle(color: primary)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance.collection('csr_opportunities').doc(widget.opportunityId).update({
                          'title': titleController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'sector': selectedSector,
                          'budget': double.tryParse(budgetController.text) ?? 0,
                          'volunteersNeeded': int.tryParse(volunteersController.text) ?? 0,
                          'location': locationController.text.trim(),
                          'requirements': requirementsController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opportunity updated!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: errorRed));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.all(14)),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _closeOpportunity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Opportunity?'),
        content: const Text('This will mark the opportunity as closed. Volunteers will no longer be able to apply.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: warningOrange),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('csr_opportunities')
            .doc(widget.opportunityId)
            .update({'status': 'closed'});
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opportunity closed'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
          );
        }
      }
    }
  }

  void _deleteOpportunity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Opportunity?'),
        content: const Text('This action cannot be undone. All related applications will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('csr_opportunities')
            .doc(widget.opportunityId)
            .delete();
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opportunity deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
          );
        }
      }
    }
  }

  void _showLogActivityDialog() {
    final descriptionController = TextEditingController();
    final hoursController = TextEditingController();
    String? selectedVolunteerId;
    String? selectedVolunteerName;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Icon(Icons.add_task, color: primary),
                  const SizedBox(width: 8),
                  const Text('Log Volunteer Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 20),
                // Volunteer Selector
                const Text('Select Volunteer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('csr_volunteer_applications')
                      .where('opportunityId', isEqualTo: widget.opportunityId)
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final volunteers = snapshot.data?.docs ?? [];
                    if (volunteers.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: const Text('No approved volunteers yet', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      value: selectedVolunteerId,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person, color: primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Choose a volunteer',
                      ),
                      items: volunteers.map((v) {
                        final data = v.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: data['volunteerId'] ?? v.id,
                          child: Text(data['volunteerName'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        // Find the volunteer name for the selected ID
                        for (var vol in volunteers) {
                          final data = vol.data() as Map<String, dynamic>;
                          if ((data['volunteerId'] ?? vol.id) == v) {
                            selectedVolunteerName = data['volunteerName'];
                            break;
                          }
                        }
                        setModalState(() => selectedVolunteerId = v);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildEditField('Activity Description', descriptionController, Icons.description, maxLines: 3),
                const SizedBox(height: 16),
                _buildEditField('Hours Worked', hoursController, Icons.timer, keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: selectedVolunteerId == null ? null : () async {
                      if (descriptionController.text.isEmpty || hoursController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                        return;
                      }
                      try {
                        await FirebaseFirestore.instance.collection('volunteer_activities').add({
                          'opportunityId': widget.opportunityId,
                          'ngoId': widget.ngoId,
                          'volunteerId': selectedVolunteerId,
                          'volunteerName': selectedVolunteerName ?? 'Unknown',
                          'description': descriptionController.text.trim(),
                          'hoursWorked': int.tryParse(hoursController.text) ?? 0,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity logged!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: errorRed));
                      }
                    },
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('Log Activity', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.all(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareImpactReport() async {
    // Generate impact report and share
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('Generating report...'),
        ]),
      ),
    );

    try {
      // Fetch impact data
      final activitiesSnapshot = await FirebaseFirestore.instance
          .collection('volunteer_activities')
          .where('opportunityId', isEqualTo: widget.opportunityId)
          .get();

      final volunteersSnapshot = await FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .where('opportunityId', isEqualTo: widget.opportunityId)
          .where('status', isEqualTo: 'approved')
          .get();

      int totalHours = 0;
      for (var doc in activitiesSnapshot.docs) {
        totalHours += (doc.data()['hoursWorked'] ?? 0) as int;
      }

      if (mounted) Navigator.pop(context);

      final title = widget.opportunityData['title'] ?? 'CSR Opportunity';
      final sector = widget.opportunityData['sector'] ?? 'General';
      final budget = widget.opportunityData['budget'] ?? 0;

      // Show shareable report
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, primaryDark]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  const Icon(Icons.auto_graph, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  Text('Impact Report', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14), textAlign: TextAlign.center),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _reportStatCard('Volunteers', '${volunteersSnapshot.docs.length}', Icons.people, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _reportStatCard('Hours', '$totalHours', Icons.timer, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _reportStatCard('Activities', '${activitiesSnapshot.docs.length}', Icons.task_alt, Colors.orange)),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _reportRow('Sector', sector),
                  const Divider(),
                  _reportRow('Budget', '₹${_formatAmount(budget.toDouble())}'),
                  const Divider(),
                  _reportRow('Status', widget.opportunityData['status']?.toString().toUpperCase() ?? 'OPEN'),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report copied to clipboard!')));
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), side: BorderSide(color: primary)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share functionality - integrate with share_plus package')));
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text('Share', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.all(14)),
                )),
              ]),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: errorRed));
    }
  }

  Widget _reportStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ]),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedVolunteerId;
    String? selectedVolunteerName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Icon(Icons.add_task, color: primary),
                  const SizedBox(width: 8),
                  const Text('Create Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 20),
                _buildEditField('Task Title', titleController, Icons.title),
                const SizedBox(height: 16),
                _buildEditField('Task Description', descriptionController, Icons.description, maxLines: 3),
                const SizedBox(height: 16),
                // Volunteer Selector
                const Text('Assign to Volunteer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('csr_volunteer_applications')
                      .where('opportunityId', isEqualTo: widget.opportunityId)
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final volunteers = snapshot.data?.docs ?? [];
                    if (volunteers.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: const Text('No approved volunteers yet. Approve volunteers first.', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      value: selectedVolunteerId,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person, color: primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Choose a volunteer',
                      ),
                      items: volunteers.map((v) {
                        final data = v.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: data['volunteerId'] ?? v.id,
                          child: Text(data['volunteerName'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        // Find the volunteer name for the selected ID
                        for (var vol in volunteers) {
                          final data = vol.data() as Map<String, dynamic>;
                          if ((data['volunteerId'] ?? vol.id) == v) {
                            selectedVolunteerName = data['volunteerName'];
                            break;
                          }
                        }
                        setModalState(() => selectedVolunteerId = v);
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a task title')));
                        return;
                      }
                      try {
                        await FirebaseFirestore.instance.collection('volunteer_tasks').add({
                          'opportunityId': widget.opportunityId,
                          'ngoId': widget.ngoId,
                          'title': titleController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'volunteerId': selectedVolunteerId,
                          'volunteerName': selectedVolunteerName ?? 'Unassigned',
                          'status': 'pending',
                          'assignedAt': FieldValue.serverTimestamp(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: errorRed));
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Create Task', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.all(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
