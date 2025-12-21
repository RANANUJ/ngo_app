import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class VolunteerCsrScreen extends StatefulWidget {
  const VolunteerCsrScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerCsrScreen> createState() => _VolunteerCsrScreenState();
}

class _VolunteerCsrScreenState extends State<VolunteerCsrScreen> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  late TabController _tabController;
  
  int _totalOpportunities = 0;
  int _totalCompanies = 0;
  int _appliedCount = 0;
  int _joinedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final opportunitiesSnapshot = await FirebaseFirestore.instance
          .collection('csr_opportunities')
          .where('status', isEqualTo: 'open')
          .get();
      
      final companiesSet = <String>{};
      for (var doc in opportunitiesSnapshot.docs) {
        final data = doc.data();
        final companyName = data['companyName'] as String?;
        if (companyName != null && companyName.isNotEmpty) {
          companiesSet.add(companyName);
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      int applied = 0;
      int joined = 0;
      
      if (user != null) {
        final applicationsSnapshot = await FirebaseFirestore.instance
            .collection('csr_volunteer_applications')
            .where('volunteerId', isEqualTo: user.uid)
            .get();
        
        for (var doc in applicationsSnapshot.docs) {
          final data = doc.data();
          final status = data['status'] as String?;
          if (status == 'pending') {
            applied++;
          } else if (status == 'approved' || status == 'accepted') {
            joined++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalOpportunities = opportunitiesSnapshot.docs.length;
          _totalCompanies = companiesSet.length;
          _appliedCount = applied;
          _joinedCount = joined;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _totalOpportunities = 0;
          _totalCompanies = 0;
          _appliedCount = 0;
          _joinedCount = 0;
        });
      }
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
          'CSR Opportunities',
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
          _buildStatsCard(),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Opportunities'),
                Tab(text: 'Companies'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOpportunitiesTab(),
                _buildCompaniesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.7)],
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
          _buildStatItem(Icons.work_outline, 'Opportunities', '$_totalOpportunities'),
          Container(width: 1, height: 50, color: Colors.white30),
          _buildStatItem(Icons.business, 'Companies', '$_totalCompanies'),
          Container(width: 1, height: 50, color: Colors.white30),
          _buildStatItem(Icons.check_circle_outline, 'Applied', '$_appliedCount'),
          Container(width: 1, height: 50, color: Colors.white30),
          _buildStatItem(Icons.groups, 'Joined', '$_joinedCount'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunitiesTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState(
        Icons.person_off,
        'Not Logged In',
        'Please log in to view opportunities',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_opportunities')
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        if (snapshot.hasError) {
          debugPrint('Error loading opportunities: ${snapshot.error}');
          return _buildEmptyState(
            Icons.error_outline,
            'Error',
            'Failed to load opportunities: ${snapshot.error}',
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            Icons.work_outline,
            'No CSR Opportunities',
            'Check back later for new corporate social responsibility opportunities',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final opportunityId = docs[index].id;
            return _buildEnhancedOpportunityCard(data, opportunityId, user.uid);
          },
        );
      },
    );
  }

  Widget _buildEnhancedOpportunityCard(Map<String, dynamic> data, String opportunityId, String userId) {
    final companyName = data['companyName'] ?? 'Unknown Company';
    final title = data['title'] ?? 'Untitled Opportunity';
    final description = data['description'] ?? 'No description available';
    final budget = data['budget']?.toString() ?? '0';
    final category = data['category'] ?? 'General';
    final location = data['location'] ?? 'Location TBD';
    final volunteersNeeded = data['volunteersNeeded'] ?? 0;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .where('opportunityId', isEqualTo: opportunityId)
          .where('volunteerId', isEqualTo: userId)
          .limit(1)
          .snapshots(includeMetadataChanges: true),
      builder: (context, appSnapshot) {
        String applicationStatus = 'none'; // none, pending, approved, rejected

        if (appSnapshot.hasData && appSnapshot.data!.docs.isNotEmpty) {
          final appDoc = appSnapshot.data!.docs.first;
          final appData = appDoc.data() as Map<String, dynamic>?;
          final rawStatus = appData?['status'];
          applicationStatus = rawStatus?.toString().toLowerCase() ?? 'pending';
          debugPrint('CSR Application Status for $opportunityId: rawStatus=$rawStatus, normalized=$applicationStatus, docId=${appDoc.id}');
          debugPrint('Full application data: $appData');
        } else {
          debugPrint('No application found for opportunityId=$opportunityId, userId=$userId');
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              final normalizedStatus = applicationStatus.toLowerCase();
              if (normalizedStatus == 'approved' || normalizedStatus == 'accepted') {
                _openOpportunityDetails(opportunityId, data);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with company
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.business, color: primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                            Text(
                              location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(applicationStatus),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Info chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(Icons.category, category, Colors.orange),
                          _buildInfoChip(Icons.currency_rupee, '₹$budget', Colors.green),
                          _buildInfoChip(Icons.people, '$volunteersNeeded volunteers', Colors.blue),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action button
                      _buildActionButton(applicationStatus, opportunityId, userId, data),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalizedStatus = status.toLowerCase();
    Color color;
    String text;
    IconData icon;

    switch (normalizedStatus) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case 'approved':
      case 'accepted':
        color = Colors.green;
        text = 'Joined';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        icon = Icons.cancel;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String status, String opportunityId, String userId, Map<String, dynamic> data) {
    final normalizedStatus = status.toLowerCase();
    if (normalizedStatus == 'approved' || normalizedStatus == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openOpportunityDetails(opportunityId, data),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: const Icon(Icons.arrow_forward, color: Colors.white),
          label: const Text(
            'View Details & Tasks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (normalizedStatus == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: const Icon(Icons.pending, color: Colors.orange),
          label: const Text(
            'Application Pending',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _applyAsVolunteer(opportunityId, userId, data),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          icon: const Icon(Icons.volunteer_activism, color: Colors.white),
          label: const Text(
            'Apply as Volunteer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _applyAsVolunteer(String opportunityId, String userId, Map<String, dynamic> opportunityData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Please log in to apply', isError: true);
        return;
      }

      // Check for existing application
      final existingApp = await FirebaseFirestore.instance
          .collection('csr_volunteer_applications')
          .where('opportunityId', isEqualTo: opportunityId)
          .where('volunteerId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingApp.docs.isNotEmpty) {
        _showMessage('You have already applied for this opportunity', isError: true);
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: primary)),
      );

      // Get volunteer info
      final volunteerDoc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(userId)
          .get();

      final volunteerData = volunteerDoc.data() ?? {};
      final volunteerName = volunteerData['name'] ?? volunteerData['displayName'] ?? user.displayName ?? 'Anonymous';
      final volunteerEmail = user.email ?? '';
      final volunteerPhone = volunteerData['phone'] ?? '';

      await FirebaseFirestore.instance.collection('csr_volunteer_applications').add({
        'opportunityId': opportunityId,
        'volunteerId': userId,
        'volunteerName': volunteerName,
        'volunteerEmail': volunteerEmail,
        'volunteerPhone': volunteerPhone,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
        'companyName': opportunityData['companyName'],
        'opportunityTitle': opportunityData['title'],
        'opportunityCreatedBy': opportunityData['createdBy'] ?? '',
      });

      Navigator.pop(context);
      await _loadStats(); // Refresh stats
      _showMessage('Application submitted successfully! Waiting for approval.');
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showMessage('Error submitting application: $e', isError: true);
    }
  }

  void _openOpportunityDetails(String opportunityId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpportunityDetailsScreen(
          opportunityId: opportunityId,
          opportunityData: data,
        ),
      ),
    );
  }

  Widget _buildCompaniesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('csr_opportunities')
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildEmptyState(
            Icons.error_outline,
            'Error',
            'Failed to load companies',
          );
        }

        // Group by company
        final companiesMap = <String, List<Map<String, dynamic>>>{};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final companyName = data['companyName'] ?? 'Unknown';
          if (!companiesMap.containsKey(companyName)) {
            companiesMap[companyName] = [];
          }
          companiesMap[companyName]!.add({...data, 'id': doc.id});
        }

        if (companiesMap.isEmpty) {
          return _buildEmptyState(
            Icons.business,
            'No Companies',
            'No companies with open opportunities',
          );
        }

        final companies = companiesMap.entries.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: companies.length,
          itemBuilder: (context, index) {
            final company = companies[index];
            return _buildCompanyCard(company.key, company.value);
          },
        );
      },
    );
  }

  Widget _buildCompanyCard(String companyName, List<Map<String, dynamic>> opportunities) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business, color: primary, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${opportunities.length} ${opportunities.length == 1 ? "Opportunity" : "Opportunities"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            ...opportunities.take(2).map((opp) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      opp['title'] ?? 'Untitled',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )).toList(),
            if (opportunities.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${opportunities.length - 2} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// Opportunity Details Screen
class OpportunityDetailsScreen extends StatefulWidget {
  final String opportunityId;
  final Map<String, dynamic> opportunityData;

  const OpportunityDetailsScreen({
    Key? key,
    required this.opportunityId,
    required this.opportunityData,
  }) : super(key: key);

  @override
  State<OpportunityDetailsScreen> createState() => _OpportunityDetailsScreenState();
}

class _OpportunityDetailsScreenState extends State<OpportunityDetailsScreen> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyName = widget.opportunityData['companyName'] ?? 'Unknown Company';
    final title = widget.opportunityData['title'] ?? 'Untitled Opportunity';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: primary,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'My Tasks'),
                Tab(text: 'Updates'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildMyTasksTab(),
                _buildUpdatesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final description = widget.opportunityData['description'] ?? 'No description available';
    final budget = widget.opportunityData['budget']?.toString() ?? '0';
    final category = widget.opportunityData['category'] ?? 'General';
    final location = widget.opportunityData['location'] ?? 'Location TBD';
    final volunteersNeeded = widget.opportunityData['volunteersNeeded'] ?? 0;
    final duration = widget.opportunityData['duration'] ?? 'Not specified';
    final skills = widget.opportunityData['skills'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.currency_rupee, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  '₹$budget',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Budget',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Info cards
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(Icons.people, 'Volunteers', '$volunteersNeeded needed'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(Icons.access_time, 'Duration', duration),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(Icons.category, 'Category', category),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(Icons.location_on, 'Location', location),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Description
          _buildSection('Description', description),
          
          const SizedBox(height: 24),
          
          // Required Skills
          if (skills.isNotEmpty) ...[
            const Text(
              'Required Skills',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) => Chip(
                label: Text(skill.toString()),
                backgroundColor: primary.withOpacity(0.1),
                labelStyle: const TextStyle(color: primary),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: primary, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
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
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyTasksTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_tasks')
          .where('opportunityId', isEqualTo: widget.opportunityId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Filter tasks for this volunteer locally
        final allTasks = snapshot.data?.docs ?? [];
        final tasks = allTasks.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['volunteerId'] == user.uid;
        }).toList();
        
        // Sort locally by assignedAt descending
        tasks.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['assignedAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['assignedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No tasks assigned yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final taskData = tasks[index].data() as Map<String, dynamic>;
            final taskId = tasks[index].id;
            return _buildTaskCard(taskData, taskId);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data, String taskId) {
    final title = data['title'] ?? 'Untitled Task';
    final description = data['description'] ?? 'No description';
    final status = data['status'] ?? 'pending';
    final assignedAt = (data['assignedAt'] as Timestamp?)?.toDate();
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (assignedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Assigned: ${DateFormat('MMM dd, yyyy').format(assignedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (status != 'completed') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'pending')
                    TextButton.icon(
                      onPressed: () => _updateTaskStatus(taskId, 'in_progress'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Task'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  if (status == 'in_progress')
                    TextButton.icon(
                      onPressed: () => _showSubmitTaskDialog(taskId),
                      icon: const Icon(Icons.check),
                      label: const Text('Complete Task'),
                      style: TextButton.styleFrom(foregroundColor: Colors.green),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('volunteer_tasks')
          .doc(taskId)
          .update({
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showSubmitTaskDialog(String taskId) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add any completion notes:'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Optional notes...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _submitTask(taskId, notesController.text);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTask(String taskId, String notes) async {
    try {
      await FirebaseFirestore.instance
          .collection('volunteer_tasks')
          .doc(taskId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'completionNotes': notes,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task completed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildUpdatesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_activities')
          .where('opportunityId', isEqualTo: widget.opportunityId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Sort locally by createdAt descending
        final updates = snapshot.data?.docs ?? [];
        updates.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (updates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.update, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No updates yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: updates.length,
          itemBuilder: (context, index) {
            final updateData = updates[index].data() as Map<String, dynamic>;
            return _buildUpdateCard(updateData);
          },
        );
      },
    );
  }

  Widget _buildUpdateCard(Map<String, dynamic> data) {
    final volunteerName = data['volunteerName'] ?? 'Volunteer';
    final description = data['description'] ?? 'No description';
    final hoursWorked = data['hoursWorked'] ?? 0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.volunteer_activism, color: primary, size: 20),
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
                      Text(
                        '$hoursWorked hours logged',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
