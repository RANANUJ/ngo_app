import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'package:ngo_app/screens/campaigns/opportunity_detail_screen.dart';

class CsrIntegrationScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const CsrIntegrationScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<CsrIntegrationScreen> createState() => _CsrIntegrationScreenState();
}

class _CsrIntegrationScreenState extends State<CsrIntegrationScreen> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  static const Color primaryDark = Color(0xFF007A94);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  
  late TabController _tabController;
  
  // Real-time stats
  double _totalCsrAmount = 0;
  int _projectsCount = 0;
  int _pendingApplications = 0;
  int _activeOpportunities = 0;
  int _totalVolunteersEngaged = 0;

  // Impact tracking stats
  int _totalImpactHours = 0;
  int _completedProjects = 0;
  int _beneficiariesReached = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      // Load partners count and total amount
      final partnershipsSnapshot = await FirebaseFirestore.instance
          .collection('csr_partnerships')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .get();
      
      double totalAmount = 0;
      int activePartners = 0;
      for (var doc in partnershipsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'active') {
          totalAmount += (data['amount'] ?? 0).toDouble();
          activePartners++;
        }
      }

      // Load volunteer applications count (pending) for NGO's opportunities
      final applicationsSnapshot = await FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .get();
      
      int pending = 0;
      int totalVolunteers = 0;
      for (var doc in applicationsSnapshot.docs) {
        final data = doc.data();
        if (data['opportunityCreatedBy'] == widget.ngoData.id) {
          if (data['status'] == 'pending') pending++;
          if (data['status'] == 'approved') totalVolunteers++;
        }
      }

      // Load NGO's CSR applications (projects)
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('csr_applications')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .get();

      // Load NGO's active opportunities
      final opportunitiesSnapshot = await FirebaseFirestore.instance
          .collection('csr_opportunities')
          .where('createdBy', isEqualTo: widget.ngoData.id)
          .where('status', isEqualTo: 'open')
          .get();

      // Load impact data - activities logged
      final activitiesSnapshot = await FirebaseFirestore.instance
          .collection('volunteer_activities')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .get();
      
      int totalHours = 0;
      for (var doc in activitiesSnapshot.docs) {
        final data = doc.data();
        totalHours += (data['hoursWorked'] ?? 0) as int;
      }

      if (mounted) {
        setState(() {
          _totalCsrAmount = totalAmount;
          _projectsCount = projectsSnapshot.docs.length;
          _pendingApplications = pending;
          _activeOpportunities = opportunitiesSnapshot.docs.length;
          _totalVolunteersEngaged = totalVolunteers;
          _totalImpactHours = totalHours;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
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
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: [
                  const Tab(text: 'Opportunities'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Volunteers'),
                        if (_pendingApplications > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: errorRed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_pendingApplications',
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
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOpportunitiesTab(),
                  _buildVolunteerApplicationsTab(),
                  _buildImpactTrackingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOpportunityDialog,
        backgroundColor: primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
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
          onPressed: _loadStats,
          tooltip: 'Refresh Stats',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: _showCsrInfoBottomSheet,
          tooltip: 'CSR Info',
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
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.handshake, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CSR Integration Hub',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.ngoData.ngoName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Stats Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildStatItem(Icons.campaign, '$_activeOpportunities', 'Active Opps')),
                        _buildVerticalDivider(),
                        Expanded(child: _buildStatItem(Icons.currency_rupee, _formatAmount(_totalCsrAmount), 'CSR Funds')),
                        _buildVerticalDivider(),
                        Expanded(child: _buildStatItem(Icons.people_alt, '$_totalVolunteersEngaged', 'Volunteers')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  void _showCsrInfoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline, color: primary, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'About CSR Integration',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              Icons.lightbulb_outline,
              'Create Opportunities',
              'Post CSR opportunities to attract corporate partners and volunteers for your causes.',
            ),
            _buildInfoItem(
              Icons.people_outline,
              'Manage Volunteers',
              'Review and approve volunteer applications for your CSR projects.',
            ),
            _buildInfoItem(
              Icons.handshake_outlined,
              'Partner with Corporates',
              'Build lasting partnerships with companies for sustainable funding.',
            ),
            _buildInfoItem(
              Icons.analytics_outlined,
              'Track Impact',
              'Monitor your CSR activities and measure social impact.',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  Widget _buildOpportunitiesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_opportunities')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        final allDocs = snapshot.data?.docs ?? [];
        // Separate own and other opportunities
        final myOpportunities = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['createdBy'] == widget.ngoData.id;
        }).toList();
        
        final otherOpportunities = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['createdBy'] != widget.ngoData.id && data['status'] == 'open';
        }).toList();

        if (myOpportunities.isEmpty && otherOpportunities.isEmpty) {
          return _buildEmptyState(
            Icons.campaign_outlined,
            'No CSR Opportunities Yet',
            'Create your first CSR opportunity to connect with corporate partners and volunteers.',
            showCreateButton: true,
          );
        }

        return RefreshIndicator(
          onRefresh: _loadStats,
          color: primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // My Opportunities Section
              if (myOpportunities.isNotEmpty) ...[
                _buildSectionHeader('Your Opportunities', Icons.star, myOpportunities.length),
                const SizedBox(height: 12),
                ...myOpportunities.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildMyOpportunityCard(data, doc.id);
                }),
                const SizedBox(height: 24),
              ],
              
              // Other Opportunities Section
              if (otherOpportunities.isNotEmpty) ...[
                _buildSectionHeader('Available Opportunities', Icons.explore, otherOpportunities.length),
                const SizedBox(height: 12),
                ...otherOpportunities.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildOpportunityCard(data, doc.id);
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // Enhanced card for user's own opportunities with lifecycle tracking
  Widget _buildMyOpportunityCard(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? 'CSR Opportunity';
    final description = data['description'] ?? '';
    final sector = data['sector'] ?? 'General';
    final budget = (data['budget'] ?? 0).toDouble();
    final volunteersNeeded = data['volunteersNeeded'] ?? 0;
    final status = data['status'] ?? 'open';
    final createdAt = data['createdAt'] as Timestamp?;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .where('opportunityId', isEqualTo: docId)
          .snapshots(),
      builder: (context, applicantSnapshot) {
        final allApplicants = applicantSnapshot.data?.docs ?? [];
        final pendingCount = allApplicants.where((d) => (d.data() as Map)['status'] == 'pending').length;
        final approvedCount = allApplicants.where((d) => (d.data() as Map)['status'] == 'approved').length;
        
        // Determine lifecycle stage
        int lifecycleStage = 0; // 0: Open, 1: Has Applicants, 2: In Progress, 3: Completed
        if (status == 'completed') {
          lifecycleStage = 3;
        } else if (approvedCount > 0) {
          lifecycleStage = 2;
        } else if (allApplicants.isNotEmpty) {
          lifecycleStage = 1;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getSectorColor(sector).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sector,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getSectorColor(sector),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: successGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 12, color: successGreen),
                              const SizedBox(width: 4),
                              Text(
                                'YOUR POST',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: successGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Lifecycle Progress Tracker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline, size: 16, color: primary),
                        const SizedBox(width: 8),
                        Text(
                          'Opportunity Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildLifecycleStep(0, lifecycleStage, 'Posted', Icons.campaign),
                        _buildLifecycleConnector(lifecycleStage >= 1),
                        _buildLifecycleStep(1, lifecycleStage, 'Applicants', Icons.person_add),
                        _buildLifecycleConnector(lifecycleStage >= 2),
                        _buildLifecycleStep(2, lifecycleStage, 'In Progress', Icons.play_circle),
                        _buildLifecycleConnector(lifecycleStage >= 3),
                        _buildLifecycleStep(3, lifecycleStage, 'Completed', Icons.check_circle),
                      ],
                    ),
                    if (pendingCount > 0 || approvedCount > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (pendingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: warningOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pending, size: 12, color: warningOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$pendingCount pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: warningOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (approvedCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: successGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 12, color: successGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$approvedCount approved',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: successGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Stats Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOpportunityStatItem(Icons.currency_rupee, '₹${_formatAmount(budget)}', 'Budget'),
                    Container(height: 30, width: 1, color: Colors.grey.shade300),
                    _buildOpportunityStatItem(Icons.people, '$volunteersNeeded', 'Needed'),
                    Container(height: 30, width: 1, color: Colors.grey.shade300),
                    _buildOpportunityStatItem(Icons.how_to_reg, '$approvedCount', 'Joined'),
                  ],
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showOpportunityDetails(docId, data),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(color: primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewApplicants(docId, data),
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.people_alt, size: 18, color: Colors.white),
                            if (pendingCount > 0)
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: errorRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$pendingCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        label: const Text('Applicants', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showOpportunityOptions(docId, data),
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLifecycleStep(int step, int currentStep, String label, IconData icon) {
    final isActive = currentStep >= step;
    final isCurrent = currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? primary : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive && !isCurrent ? Icons.check : icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? primary : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleConnector(bool isActive) {
    return Container(
      height: 2,
      width: 20,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isActive ? primary : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildOpportunityStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'open':
        color = successGreen;
        icon = Icons.check_circle;
        break;
      case 'closed':
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      case 'in_progress':
        color = warningOrange;
        icon = Icons.hourglass_empty;
        break;
      default:
        color = primary;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase().replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSectorColor(String sector) {
    // Use primary color for all sectors for a cleaner look
    return primary;
  }

  void _showOpportunityOptions(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionItem(Icons.edit, 'Edit Opportunity', Colors.blue, () {
              Navigator.pop(context);
              _showEditOpportunityDialog(docId, data);
            }),
            _buildOptionItem(Icons.share, 'Share Opportunity', Colors.green, () {
              Navigator.pop(context);
              // Share functionality
            }),
            if (data['status'] == 'open')
              _buildOptionItem(Icons.pause_circle, 'Close Opportunity', warningOrange, () {
                Navigator.pop(context);
                _updateOpportunityStatus(docId, 'closed');
              }),
            if (data['status'] == 'closed')
              _buildOptionItem(Icons.play_circle, 'Reopen Opportunity', successGreen, () {
                Navigator.pop(context);
                _updateOpportunityStatus(docId, 'open');
              }),
            _buildOptionItem(Icons.delete, 'Delete Opportunity', errorRed, () {
              Navigator.pop(context);
              _deleteOpportunity(docId);
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  void _showOpportunityDetails(String docId, Map<String, dynamic> data) {
    // Navigate to the detailed opportunity screen with tabs for Details, Volunteers, and Impact
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NgoCsrOpportunityDetailScreen(
          opportunityId: docId,
          opportunityData: data,
          ngoId: widget.ngoData.id,
        ),
      ),
    ).then((_) => _loadStats()); // Refresh stats when returning
  }

  Widget _buildDetailStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildNextStepItem(int number, String text, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: active ? primary : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: active ? Colors.black87 : Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewApplicants(String docId, Map<String, dynamic> data) {
    // Navigate to the detailed opportunity screen - it will show the Volunteers tab
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NgoCsrOpportunityDetailScreen(
          opportunityId: docId,
          opportunityData: data,
          ngoId: widget.ngoData.id,
        ),
      ),
    ).then((_) => _loadStats()); // Refresh stats when returning
  }

  // Legacy method kept for compatibility - the actual applicant viewing is now in the detail screen
  Widget _buildApplicantSection(String title, List<QueryDocumentSnapshot> docs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
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
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _buildApplicantCard(doc.id, data);
        }),
      ],
    );
  }

  Widget _buildApplicantCard(String docId, Map<String, dynamic> data) {
    final volunteerName = data['volunteerName'] ?? 'Volunteer';
    final volunteerEmail = data['volunteerEmail'] ?? '';
    final status = data['status'] ?? 'pending';
    final appliedAt = data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              CircleAvatar(
                radius: 24,
                backgroundColor: primary.withOpacity(0.1),
                child: Text(
                  volunteerName.isNotEmpty ? volunteerName[0].toUpperCase() : 'V',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      volunteerEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (appliedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Applied ${_formatRelativeTime(appliedAt.toDate())}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateApplicationStatus(docId, 'rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: errorRed,
                      side: BorderSide(color: errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateApplicationStatus(docId, 'approved'),
                    icon: const Icon(Icons.check, size: 18, color: Colors.white),
                    label: const Text('Approve', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      padding: const EdgeInsets.symmetric(vertical: 10),
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

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _updateOpportunityStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('csr_opportunities')
          .doc(docId)
          .update({'status': status});

      _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opportunity ${status == 'open' ? 'reopened' : 'closed'}'),
            backgroundColor: status == 'open' ? successGreen : warningOrange,
          ),
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

  void _showEditOpportunityDialog(String docId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    final budgetController = TextEditingController(text: (data['budget'] ?? 0).toString());
    final volunteersController = TextEditingController(text: (data['volunteersNeeded'] ?? 0).toString());
    String selectedSector = data['sector'] ?? 'Education';

    final sectors = [
      'Education', 'Healthcare', 'Environment', 'Rural Development',
      'Women Empowerment', 'Child Welfare', 'Disaster Relief', 'Skill Development', 'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Edit Opportunity'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleController, 'Opportunity Title', Icons.title),
                const SizedBox(height: 12),
                _buildTextField(descriptionController, 'Description', Icons.description, maxLines: 3),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSector,
                  decoration: InputDecoration(
                    labelText: 'Sector',
                    prefixIcon: Icon(Icons.category, color: primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (value) => setDialogState(() => selectedSector = value!),
                ),
                const SizedBox(height: 12),
                _buildTextField(budgetController, 'Budget (₹)', Icons.currency_rupee, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(volunteersController, 'Volunteers Needed', Icons.people, isNumber: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Please fill all required fields'), backgroundColor: errorRed),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('csr_opportunities').doc(docId).update({
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'sector': selectedSector,
                    'budget': double.tryParse(budgetController.text) ?? 0,
                    'volunteersNeeded': int.tryParse(volunteersController.text) ?? 0,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Opportunity updated successfully!'), backgroundColor: successGreen),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildPartnersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_partnerships')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        final docs = snapshot.data?.docs ?? [];
        final activeDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'active';
        }).toList();

        if (activeDocs.isEmpty) {
          return _buildEmptyState(
            Icons.handshake,
            'No CSR Partners Yet',
            'Apply for CSR opportunities to get corporate sponsors',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeDocs.length,
          itemBuilder: (context, index) {
            final data = activeDocs[index].data() as Map<String, dynamic>;
            return _buildPartnerCard(data);
          },
        );
      },
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> data) {
    final companyName = data['companyName'] ?? 'Company';
    final amount = (data['amount'] ?? 0).toDouble();
    final projectName = data['projectName'] ?? 'CSR Project';
    final startDate = data['startDate'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.business, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  projectName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (startDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Since ${_formatDate(startDate.toDate())}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatAmount(amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerApplicationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        final allDocs = snapshot.data?.docs ?? [];
        
        // Filter applications for opportunities created by this NGO
        final relevantDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['opportunityCreatedBy'] == widget.ngoData.id;
        }).toList();

        if (relevantDocs.isEmpty) {
          return _buildEmptyState(
            Icons.people_outline,
            'No Volunteer Applications',
            'Create CSR opportunities and volunteers will apply',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: relevantDocs.length,
          itemBuilder: (context, index) {
            final data = relevantDocs[index].data() as Map<String, dynamic>;
            return _buildVolunteerApplicationCard(data, relevantDocs[index].id);
          },
        );
      },
    );
  }

  Widget _buildVolunteerApplicationCard(Map<String, dynamic> data, String docId) {
    final volunteerName = data['volunteerName'] ?? 'Volunteer';
    final volunteerEmail = data['volunteerEmail'] ?? '';
    final opportunityTitle = data['opportunityTitle'] ?? 'Opportunity';
    final status = data['status'] ?? 'pending';
    final appliedAt = data['createdAt'] as Timestamp?;

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primary.withOpacity(0.1),
                child: Text(
                  volunteerName.isNotEmpty ? volunteerName[0].toUpperCase() : 'V',
                  style: const TextStyle(
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      volunteerEmail,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.work_outline, size: 16, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    opportunityTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (appliedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Applied on ${_formatDate(appliedAt.toDate())}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateApplicationStatus(docId, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateApplicationStatus(docId, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Approve', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Impact Tracking Tab - Shows verified contributions from volunteers and NGO activities
  Widget _buildImpactTrackingTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .where('opportunityCreatedBy', isEqualTo: widget.ngoData.id)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, approvedSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('volunteer_activities')
              .where('ngoId', isEqualTo: widget.ngoData.id)
              .snapshots(),
          builder: (context, activitiesSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('volunteer_tasks')
                  .where('ngoId', isEqualTo: widget.ngoData.id)
                  .snapshots(),
              builder: (context, tasksSnapshot) {
                // Debug: Print task snapshot status
                if (tasksSnapshot.hasError) {
                  debugPrint('Tasks error: ${tasksSnapshot.error}');
                }
                debugPrint('Tasks query for ngoId: ${widget.ngoData.id}');
                debugPrint('Tasks found: ${tasksSnapshot.data?.docs.length ?? 0}');
                
                // Calculate impact metrics
                int totalHours = 0;
                int totalActivities = 0;
                int approvedVolunteers = approvedSnapshot.data?.docs.length ?? 0;
                
                final activities = activitiesSnapshot.data?.docs ?? [];
                for (var doc in activities) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalHours += (data['hoursWorked'] ?? 0) as int;
                  totalActivities++;
                }

                final tasks = tasksSnapshot.data?.docs ?? [];

                return RefreshIndicator(
                  onRefresh: _loadStats,
                  color: primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Impact Summary Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.insights, color: Colors.white.withOpacity(0.9), size: 28),
                                const SizedBox(width: 12),
                                const Text(
                                  'Impact Dashboard',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildImpactMetric(Icons.people, '$approvedVolunteers', 'Active Volunteers')),
                                Container(height: 50, width: 1, color: Colors.white.withOpacity(0.3)),
                                Expanded(child: _buildImpactMetric(Icons.timer, '$totalHours', 'Hours Contributed')),
                                Container(height: 50, width: 1, color: Colors.white.withOpacity(0.3)),
                                Expanded(child: _buildImpactMetric(Icons.task_alt, '$totalActivities', 'Activities')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              Icons.add_task,
                              'Log Activity',
                              'Record volunteer work',
                              () => _showLogActivityDialog(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              Icons.share,
                              'Share Impact',
                              'Generate report',
                              () => _showImpactReportDialog(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Assigned Tasks Section
                      _buildSectionHeader('Assigned Tasks', Icons.assignment, tasks.length),
                      const SizedBox(height: 12),
                      
                      if (tasks.isEmpty)
                        _buildEmptyCard(
                          Icons.assignment_outlined,
                          'No Tasks Assigned',
                          'Assign tasks to volunteers from the Volunteers tab',
                        )
                      else
                        ...tasks.take(5).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildTaskCard(data, doc.id);
                        }),
                      
                      if (tasks.length > 5)
                        Center(
                          child: TextButton(
                            onPressed: () => _showAllTasksDialog(),
                            child: Text('View all ${tasks.length} tasks →', style: TextStyle(color: primary)),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Active Volunteers Section
                      _buildSectionHeader('Active Volunteers', Icons.people_alt, approvedVolunteers),
                      const SizedBox(height: 12),
                      
                      if (approvedVolunteers == 0)
                        _buildEmptyCard(
                          Icons.people_outline,
                          'No Active Volunteers Yet',
                          'Approve volunteer applications to see them here',
                        )
                      else
                        ...((approvedSnapshot.data?.docs ?? []).take(5).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildActiveVolunteerCard(data, doc.id);
                        })),
                      
                      if (approvedVolunteers > 5)
                        TextButton(
                          onPressed: () => _tabController.animateTo(1),
                          child: Text('View all $approvedVolunteers volunteers →', style: TextStyle(color: primary)),
                        ),

                      const SizedBox(height: 24),

                      // Recent Activities Section
                      _buildSectionHeader('Recent Activities', Icons.history, activities.length),
                      const SizedBox(height: 12),

                      if (activities.isEmpty)
                        _buildEmptyCard(
                          Icons.event_note,
                          'No Activities Logged',
                          'Start logging volunteer activities to track impact',
                        )
                      else
                        ...activities.take(5).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildActivityCard(data);
                        }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildImpactMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        const SizedBox(height: 8),
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
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
              child: Icon(icon, color: primary, size: 24),
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
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVolunteerCard(Map<String, dynamic> data, String docId) {
    final name = data['volunteerName'] ?? 'Volunteer';
    final email = data['volunteerEmail'] ?? '';
    final opportunityTitle = data['opportunityTitle'] ?? 'CSR Opportunity';
    final approvedAt = data['updatedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: successGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'V',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  opportunityTitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (approvedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Since ${_formatDate(approvedAt.toDate())}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _showAssignTaskDialog(docId, data),
                icon: Icon(Icons.add_task, color: primary, size: 22),
                tooltip: 'Assign Task',
                style: IconButton.styleFrom(
                  backgroundColor: primary.withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () => _showVolunteerProfile(docId, data),
                icon: Icon(Icons.person, color: Colors.grey.shade600, size: 22),
                tooltip: 'View Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Activity';
    final description = data['description'] ?? '';
    final hours = data['hoursWorked'] ?? 0;
    final volunteerName = data['volunteerName'] ?? 'Volunteer';
    final createdAt = data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_circle, color: successGreen, size: 20),
              ),
              const SizedBox(width: 12),
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
                    ),
                    Text(
                      'by $volunteerName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 14, color: primary),
                    const SizedBox(width: 4),
                    Text(
                      '$hours hrs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatDate(createdAt.toDate()),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data, String docId) {
    final task = data['task'] ?? 'Task';
    final volunteerName = data['volunteerName'] ?? 'Volunteer';
    final status = data['status'] ?? 'pending';
    final dueDate = data['dueDate'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'completed':
        statusColor = successGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'in_progress':
        statusColor = warningOrange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'In Progress';
        break;
      default:
        statusColor = primary;
        statusIcon = Icons.pending;
        statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.assignment, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned to: $volunteerName',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Due date
              if (dueDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_formatDate(dueDate.toDate())}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              // Actions
              if (status == 'pending')
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
                  onSelected: (value) => _handleTaskAction(docId, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'in_progress',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, size: 18),
                          SizedBox(width: 8),
                          Text('Mark In Progress'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'completed',
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 18),
                          SizedBox(width: 8),
                          Text('Mark Completed'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                )
              else if (status == 'in_progress')
                IconButton(
                  icon: Icon(Icons.check_circle_outline, color: successGreen),
                  onPressed: () => _handleTaskAction(docId, 'completed'),
                  tooltip: 'Mark as Completed',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleTaskAction(String docId, String action) async {
    try {
      if (action == 'delete') {
        await FirebaseFirestore.instance.collection('volunteer_tasks').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted'), backgroundColor: Colors.grey),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('volunteer_tasks').doc(docId).update({
          'status': action,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task marked as ${action.replaceAll('_', ' ')}'),
              backgroundColor: successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
        );
      }
    }
  }

  void _showAllTasksDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.assignment, color: primary, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'All Assigned Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('volunteer_tasks')
                      .where('ngoId', isEqualTo: widget.ngoData.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final tasks = snapshot.data?.docs ?? [];

                    if (tasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks assigned yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final doc = tasks[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildTaskCard(data, doc.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogActivityDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final hoursController = TextEditingController();
    String? selectedVolunteerId;
    String? selectedVolunteerName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.add_task, color: primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Log Volunteer Activity',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Volunteer Selector
                      _buildFormLabel('Select Volunteer', true),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('csr_volunteer_applications')
                            .where('opportunityCreatedBy', isEqualTo: widget.ngoData.id)
                            .where('status', isEqualTo: 'approved')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final volunteers = snapshot.data?.docs ?? [];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedVolunteerId,
                              hint: const Text('Choose a volunteer'),
                              decoration: const InputDecoration(border: InputBorder.none),
                              items: volunteers.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(data['volunteerName'] ?? 'Volunteer'),
                                  onTap: () {
                                    setDialogState(() {
                                      selectedVolunteerName = data['volunteerName'];
                                    });
                                  },
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedVolunteerId = value;
                                });
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildFormLabel('Activity Title', true),
                      const SizedBox(height: 8),
                      _buildStyledTextField(
                        controller: titleController,
                        hint: 'E.g., Community clean-up drive',
                        icon: Icons.title,
                      ),
                      const SizedBox(height: 20),
                      _buildFormLabel('Description', false),
                      const SizedBox(height: 8),
                      _buildStyledTextField(
                        controller: descriptionController,
                        hint: 'Describe the activity...',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      _buildFormLabel('Hours Worked', true),
                      const SizedBox(height: 8),
                      _buildStyledTextField(
                        controller: hoursController,
                        hint: 'Enter hours',
                        icon: Icons.timer,
                        isNumber: true,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedVolunteerId == null || titleController.text.isEmpty || hoursController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Please fill all required fields'), backgroundColor: errorRed),
                        );
                        return;
                      }

                      try {
                        await FirebaseFirestore.instance.collection('volunteer_activities').add({
                          'ngoId': widget.ngoData.id,
                          'ngoName': widget.ngoData.ngoName,
                          'volunteerId': selectedVolunteerId,
                          'volunteerName': selectedVolunteerName,
                          'title': titleController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'hoursWorked': int.tryParse(hoursController.text) ?? 0,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Activity logged successfully!'), backgroundColor: successGreen),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Log Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImpactReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.analytics, color: primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Impact Report'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Generate a comprehensive impact report to share with corporate partners.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            _buildReportOption(Icons.picture_as_pdf, 'PDF Report', 'Detailed document'),
            const SizedBox(height: 8),
            _buildReportOption(Icons.table_chart, 'Excel Sheet', 'Data export'),
            const SizedBox(height: 8),
            _buildReportOption(Icons.share, 'Share Summary', 'Quick share'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title will be generated...'), backgroundColor: primary),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showAssignTaskDialog(String applicationId, Map<String, dynamic> volunteerData) {
    final taskController = TextEditingController();
    final dueDateController = TextEditingController();
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primary.withOpacity(0.1),
                    child: Text(
                      (volunteerData['volunteerName'] ?? 'V')[0].toUpperCase(),
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assign Task to', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          volunteerData['volunteerName'] ?? 'Volunteer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFormLabel('Task Description', true),
              const SizedBox(height: 8),
              _buildStyledTextField(
                controller: taskController,
                hint: 'Describe the task...',
                icon: Icons.task,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildFormLabel('Due Date', false),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() {
                      selectedDate = date;
                      dueDateController.text = _formatDate(date);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        dueDateController.text.isNotEmpty ? dueDateController.text : 'Select due date',
                        style: TextStyle(
                          color: dueDateController.text.isNotEmpty ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (taskController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Please enter task description'), backgroundColor: errorRed),
                      );
                      return;
                    }

                    try {
                      debugPrint('Saving task with ngoId: ${widget.ngoData.id}');
                      await FirebaseFirestore.instance.collection('volunteer_tasks').add({
                        'applicationId': applicationId,
                        'volunteerId': volunteerData['volunteerId'],
                        'volunteerName': volunteerData['volunteerName'],
                        'ngoId': widget.ngoData.id,
                        'ngoName': widget.ngoData.ngoName,
                        'task': taskController.text.trim(),
                        'dueDate': selectedDate,
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      debugPrint('Task saved successfully!');

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Task assigned successfully!'), backgroundColor: successGreen),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Assign Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVolunteerProfile(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primaryDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        (data['volunteerName'] ?? 'V')[0].toUpperCase(),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['volunteerName'] ?? 'Volunteer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['volunteerEmail'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildProfileInfoCard('Opportunity', data['opportunityTitle'] ?? 'N/A', Icons.work),
                    const SizedBox(height: 12),
                    _buildProfileInfoCard('Status', 'Approved', Icons.verified, color: successGreen),
                    const SizedBox(height: 12),
                    if (data['volunteerPhone'] != null && data['volunteerPhone'].toString().isNotEmpty)
                      _buildProfileInfoCard('Phone', data['volunteerPhone'], Icons.phone),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAssignTaskDialog(docId, data);
                            },
                            icon: const Icon(Icons.add_task),
                            label: const Text('Assign Task'),
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
                              Navigator.pop(context);
                              _showLogActivityDialog();
                            },
                            icon: const Icon(Icons.edit_note, color: Colors.white),
                            label: const Text('Log Activity', style: TextStyle(color: Colors.white)),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (color ?? primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color ?? primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProjectsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_applications')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            Icons.folder_open,
            'No Projects Yet',
            'Apply for CSR opportunities to see your applications here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildProjectCard(data);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> data) {
    final title = data['opportunityTitle'] ?? 'CSR Project';
    final companyName = data['companyName'] ?? 'Company';
    final status = data['status'] ?? 'pending';
    final createdAt = data['createdAt'] as Timestamp?;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work, color: primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Applied ${_formatDate(createdAt.toDate())}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle, {bool showCreateButton = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (showCreateButton) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showCreateOpportunityDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Create Opportunity', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Card for other organizations' opportunities
  Widget _buildOpportunityCard(Map<String, dynamic> data, String docId) {
    final companyName = data['companyName'] ?? 'Company';
    final budget = (data['budget'] ?? 0).toDouble();
    final title = data['title'] ?? 'CSR Opportunity';
    final description = data['description'] ?? '';
    final sector = data['sector'] ?? 'General';
    final volunteersNeeded = data['volunteersNeeded'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getSectorColor(sector).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sector,
                  style: TextStyle(
                    fontSize: 11,
                    color: _getSectorColor(sector),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.currency_rupee, size: 12, color: successGreen),
                    Text(
                      _formatAmount(budget),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.business, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                companyName,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (volunteersNeeded > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: primary),
                const SizedBox(width: 6),
                Text(
                  '$volunteersNeeded volunteers needed',
                  style: TextStyle(
                    fontSize: 12,
                    color: primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _applyForOpportunity(docId, data),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Apply for Partnership',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyForOpportunity(String docId, Map<String, dynamic> data) async {
    // Check if already applied
    final existingApplication = await FirebaseFirestore.instance
        .collection('csr_applications')
        .where('opportunityId', isEqualTo: docId)
        .where('ngoId', isEqualTo: widget.ngoData.id)
        .get();

    if (existingApplication.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already applied for this opportunity'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('csr_applications').add({
        'opportunityId': docId,
        'opportunityTitle': data['title'],
        'companyName': data['companyName'],
        'ngoId': widget.ngoData.id,
        'ngoName': widget.ngoData.ngoName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Switch to My Projects tab
        _tabController.animateTo(3);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateApplicationStatus(String docId, String status) async {
    try {
      debugPrint('NGO: Updating application $docId to status=$status');
      await FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .doc(docId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
        if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('NGO: Successfully updated application $docId to status=$status');
      _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status == 'approved' ? 'approved' : 'rejected'}'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
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

  Future<void> _deleteOpportunity(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Opportunity'),
        content: const Text('Are you sure you want to delete this CSR opportunity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('csr_opportunities')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opportunity deleted'),
            backgroundColor: Colors.orange,
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

  void _showCreateOpportunityDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final budgetController = TextEditingController();
    final companyController = TextEditingController(text: widget.ngoData.ngoName);
    final volunteersController = TextEditingController(text: '0');
    String selectedSector = 'Education';
    int currentStep = 0;

    final sectors = [
      'Education',
      'Healthcare',
      'Environment',
      'Rural Development',
      'Women Empowerment',
      'Child Welfare',
      'Disaster Relief',
      'Skill Development',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.add_business, color: primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Create CSR Opportunity',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Connect with volunteers and partners',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    _buildStepIndicator(0, currentStep, 'Basic Info'),
                    Expanded(child: Container(height: 2, color: currentStep >= 1 ? primary : Colors.grey.shade300)),
                    _buildStepIndicator(1, currentStep, 'Details'),
                    Expanded(child: Container(height: 2, color: currentStep >= 2 ? primary : Colors.grey.shade300)),
                    _buildStepIndicator(2, currentStep, 'Budget'),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentStep == 0) ...[
                        _buildFormLabel('Opportunity Title', true),
                        const SizedBox(height: 8),
                        _buildStyledTextField(
                          controller: titleController,
                          hint: 'E.g., Education for Rural Children',
                          icon: Icons.title,
                        ),
                        const SizedBox(height: 20),
                        _buildFormLabel('Organization Name', true),
                        const SizedBox(height: 8),
                        _buildStyledTextField(
                          controller: companyController,
                          hint: 'Your organization name',
                          icon: Icons.business,
                        ),
                        const SizedBox(height: 20),
                        _buildFormLabel('Sector', true),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedSector,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: sectors.map((s) => DropdownMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getSectorColor(s),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(s),
                                ],
                              ),
                            )).toList(),
                            onChanged: (value) => setDialogState(() => selectedSector = value!),
                          ),
                        ),
                      ],
                      
                      if (currentStep == 1) ...[
                        _buildFormLabel('Description', true),
                        const SizedBox(height: 8),
                        _buildStyledTextField(
                          controller: descriptionController,
                          hint: 'Describe your CSR opportunity in detail...',
                          icon: Icons.description,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tip: Be specific about goals, expected impact, and timeline to attract more partners.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      if (currentStep == 2) ...[
                        _buildFormLabel('Budget (₹)', true),
                        const SizedBox(height: 8),
                        _buildStyledTextField(
                          controller: budgetController,
                          hint: 'Enter budget amount',
                          icon: Icons.currency_rupee,
                          isNumber: true,
                        ),
                        const SizedBox(height: 20),
                        _buildFormLabel('Volunteers Needed', false),
                        const SizedBox(height: 8),
                        _buildStyledTextField(
                          controller: volunteersController,
                          hint: 'Number of volunteers (0 if none)',
                          icon: Icons.people,
                          isNumber: true,
                        ),
                        const SizedBox(height: 24),
                        // Preview Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.preview, size: 18, color: primary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Preview',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                titleController.text.isNotEmpty ? titleController.text : 'Opportunity Title',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by ${companyController.text}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getSectorColor(selectedSector).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      selectedSector,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getSectorColor(selectedSector),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹${budgetController.text.isNotEmpty ? budgetController.text : '0'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: successGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setDialogState(() => currentStep--),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: BorderSide(color: primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: currentStep > 0 ? 2 : 1,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (currentStep < 2) {
                            // Validation for each step
                            if (currentStep == 0 && (titleController.text.isEmpty || companyController.text.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text('Please fill all required fields'), backgroundColor: errorRed),
                              );
                              return;
                            }
                            if (currentStep == 1 && descriptionController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text('Please add a description'), backgroundColor: errorRed),
                              );
                              return;
                            }
                            setDialogState(() => currentStep++);
                          } else {
                            // Create opportunity
                            if (budgetController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text('Please enter a budget'), backgroundColor: errorRed),
                              );
                              return;
                            }

                            try {
                              await FirebaseFirestore.instance.collection('csr_opportunities').add({
                                'title': titleController.text.trim(),
                                'companyName': companyController.text.trim(),
                                'description': descriptionController.text.trim(),
                                'sector': selectedSector,
                                'budget': double.tryParse(budgetController.text) ?? 0,
                                'volunteersNeeded': int.tryParse(volunteersController.text) ?? 0,
                                'status': 'open',
                                'createdBy': widget.ngoData.id,
                                'createdByName': widget.ngoData.ngoName,
                                'location': 'India',
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              Navigator.pop(context);
                              _loadStats();
                              
                              // Show success dialog
                              _showSuccessDialog();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          currentStep < 2 ? 'Continue' : 'Create Opportunity',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, int currentStep, String label) {
    final isActive = currentStep >= step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? primary : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && currentStep > step
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? primary : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildFormLabel(String label, bool required) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(color: errorRed, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: successGreen, size: 56),
              ),
              const SizedBox(height: 24),
              const Text(
                'Opportunity Created!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your CSR opportunity is now live. Volunteers and partners can start applying.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Next Steps
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What happens next?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildSuccessStepItem(Icons.notifications, 'Get notified when volunteers apply'),
                    _buildSuccessStepItem(Icons.person_search, 'Review volunteer profiles'),
                    _buildSuccessStepItem(Icons.handshake, 'Approve and connect with volunteers'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got it!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessStepItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
