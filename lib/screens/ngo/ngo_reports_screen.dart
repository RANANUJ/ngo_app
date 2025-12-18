import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class NgoReportsScreen extends StatefulWidget {
  final String? ngoId;
  final String ngoName;

  const NgoReportsScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
  }) : super(key: key);

  @override
  State<NgoReportsScreen> createState() => _NgoReportsScreenState();
}

class _NgoReportsScreenState extends State<NgoReportsScreen> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  
  late TabController _tabController;
  bool _isLoading = true;
  
  // Stats data
  int _totalCampaigns = 0;
  int _activeCampaigns = 0;
  int _totalVolunteers = 0;
  int _totalDonations = 0;
  double _totalDonationAmount = 0;
  int _totalEvents = 0;
  int _totalOpportunities = 0;
  
  List<Map<String, dynamic>> _recentCampaigns = [];
  List<Map<String, dynamic>> _recentDonations = [];
  List<Map<String, dynamic>> _monthlyStats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    await Future.wait([
      _loadCampaignStats(),
      _loadVolunteerStats(),
      _loadDonationStats(),
      _loadEventStats(),
      _loadRecentCampaigns(),
      _loadRecentDonations(),
    ]);
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadCampaignStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('ngoId', isEqualTo: widget.ngoId)
          .get();
      
      int active = 0;
      for (var doc in snapshot.docs) {
        if (doc.data()['status'] == 'active') active++;
      }
      
      setState(() {
        _totalCampaigns = snapshot.docs.length;
        _activeCampaigns = active;
      });
    } catch (e) {
      debugPrint('Error loading campaign stats: $e');
    }
  }

  Future<void> _loadVolunteerStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('volunteer_requests')
          .where('ngoId', isEqualTo: widget.ngoId)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      setState(() => _totalVolunteers = snapshot.docs.length);
    } catch (e) {
      debugPrint('Error loading volunteer stats: $e');
    }
  }

  Future<void> _loadDonationStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('ngoId', isEqualTo: widget.ngoId)
          .get();
      
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0).toDouble();
      }
      
      setState(() {
        _totalDonations = snapshot.docs.length;
        _totalDonationAmount = total;
      });
    } catch (e) {
      debugPrint('Error loading donation stats: $e');
    }
  }

  Future<void> _loadEventStats() async {
    try {
      final opportunitiesSnapshot = await FirebaseFirestore.instance
          .collection('volunteer_opportunities')
          .where('ngoId', isEqualTo: widget.ngoId)
          .get();
      
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('ngoId', isEqualTo: widget.ngoId)
          .get();
      
      setState(() {
        _totalOpportunities = opportunitiesSnapshot.docs.length;
        _totalEvents = eventsSnapshot.docs.length;
      });
    } catch (e) {
      debugPrint('Error loading event stats: $e');
    }
  }

  Future<void> _loadRecentCampaigns() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('ngoId', isEqualTo: widget.ngoId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      setState(() {
        _recentCampaigns = snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading recent campaigns: $e');
    }
  }

  Future<void> _loadRecentDonations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('ngoId', isEqualTo: widget.ngoId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      setState(() {
        _recentDonations = snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading recent donations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primary),
            onPressed: _loadAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Campaigns'),
            Tab(text: 'Donations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCampaignsTab(),
                _buildDonationsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Performance Chart
            _buildSectionTitle('Performance Overview'),
            const SizedBox(height: 16),
            _buildPerformanceChart(),
            const SizedBox(height: 24),

            // Quick Stats Cards
            _buildSectionTitle('Quick Insights'),
            const SizedBox(height: 16),
            _buildQuickInsights(),
            const SizedBox(height: 24),

            // Activity Summary
            _buildSectionTitle('Activity Summary'),
            const SizedBox(height: 16),
            _buildActivitySummary(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard('Total Campaigns', _totalCampaigns.toString(), Icons.campaign, Colors.blue),
        _buildStatCard('Active Volunteers', _totalVolunteers.toString(), Icons.people, Colors.green),
        _buildStatCard('Donations', _totalDonations.toString(), Icons.volunteer_activism, Colors.orange),
        _buildStatCard('Opportunities', _totalOpportunities.toString(), Icons.work, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = ['Campaigns', 'Volunteers', 'Donations', 'Events'];
                  if (value.toInt() < labels.length) {
                    return Text(
                      labels[value.toInt()],
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _buildBarGroup(0, _totalCampaigns.toDouble(), Colors.blue),
            _buildBarGroup(1, _totalVolunteers.toDouble(), Colors.green),
            _buildBarGroup(2, _totalDonations.toDouble(), Colors.orange),
            _buildBarGroup(3, _totalEvents.toDouble(), Colors.purple),
          ],
        ),
      ),
    );
  }

  double _getMaxY() {
    final values = [_totalCampaigns, _totalVolunteers, _totalDonations, _totalEvents];
    final max = values.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 10 : (max * 1.2).toDouble();
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ],
    );
  }

  Widget _buildQuickInsights() {
    return Column(
      children: [
        _buildInsightCard(
          'Campaign Success Rate',
          _totalCampaigns > 0 ? '${((_activeCampaigns / _totalCampaigns) * 100).toStringAsFixed(0)}%' : '0%',
          'Active campaigns vs total',
          Icons.trending_up,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          'Total Donation Amount',
          '₹${_formatAmount(_totalDonationAmount)}',
          'Received from $_totalDonations donors',
          Icons.currency_rupee,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          'Volunteer Engagement',
          _totalVolunteers.toString(),
          'Active volunteers in your NGO',
          Icons.people_alt,
          Colors.blue,
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildInsightCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActivityRow('Campaigns Created', _totalCampaigns.toString(), Icons.campaign, Colors.blue),
          const Divider(),
          _buildActivityRow('Active Campaigns', _activeCampaigns.toString(), Icons.play_circle, Colors.green),
          const Divider(),
          _buildActivityRow('Volunteers Joined', _totalVolunteers.toString(), Icons.group_add, Colors.orange),
          const Divider(),
          _buildActivityRow('Opportunities Posted', _totalOpportunities.toString(), Icons.work_outline, Colors.purple),
          const Divider(),
          _buildActivityRow('Events Organized', _totalEvents.toString(), Icons.event, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildActivityRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campaign Stats
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard('Total', _totalCampaigns.toString(), Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard('Active', _activeCampaigns.toString(), Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard('Completed', '${_totalCampaigns - _activeCampaigns}', Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Recent Campaigns'),
          const SizedBox(height: 16),

          if (_recentCampaigns.isEmpty)
            _buildEmptyState('No campaigns yet', 'Create your first campaign to see analytics')
          else
            ...(_recentCampaigns.map((campaign) => _buildCampaignCard(campaign)).toList()),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final progress = (campaign['currentAmount'] ?? 0) / (campaign['targetAmount'] ?? 1);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign['title'] ?? 'Untitled Campaign',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(primary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${campaign['currentAmount'] ?? 0} raised',
                style: TextStyle(color: primary, fontWeight: FontWeight.w600),
              ),
              Text(
                'Goal: ₹${campaign['targetAmount'] ?? 0}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donation Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Donations Received',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${_formatAmount(_totalDonationAmount)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'From $_totalDonations donations',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Recent Donations'),
          const SizedBox(height: 16),

          if (_recentDonations.isEmpty)
            _buildEmptyState('No donations yet', 'Share your campaigns to receive donations')
          else
            ...(_recentDonations.map((donation) => _buildDonationCard(donation)).toList()),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volunteer_activism, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation['donorName'] ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  donation['campaignTitle'] ?? 'General Donation',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '₹${donation['amount'] ?? 0}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
