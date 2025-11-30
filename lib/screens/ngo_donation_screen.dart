import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ngo_registration_service.dart';
import 'donation_request_screen.dart';
import 'donation_history_screen.dart';
import 'create_donation_post_screen.dart';
import 'emergency_donation_screen.dart';
import 'share_resource_screen.dart';
import 'share_impact_screen.dart';
import 'needs_forecasting_screen.dart';
import 'csr_integration_screen.dart';

class NgoDonationScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const NgoDonationScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<NgoDonationScreen> createState() => _NgoDonationScreenState();
}

class _NgoDonationScreenState extends State<NgoDonationScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  // Monthly donation data
  List<double> currentMonthData = [0, 0, 0, 0, 0, 0, 0];
  List<double> lastMonthData = [0, 0, 0, 0, 0, 0, 0];
  bool _isLoading = true;
  
  // Stats
  int _totalDonations = 0;
  double _totalAmount = 0;
  int _pendingRequests = 0;
  int _approvedRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadDonationData();
  }

  Future<void> _loadDonationData() async {
    try {
      final now = DateTime.now();
      final startOfCurrentMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);

      // Get current month donations
      final currentMonthSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfCurrentMonth))
          .get();

      // Get last month donations
      final lastMonthSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfLastMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfLastMonth))
          .get();

      // Get donation requests stats
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('donation_requests')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .get();

      // Process current month data by week
      Map<int, double> currentWeeklyData = {};
      double totalAmount = 0;
      for (var doc in currentMonthSnapshot.docs) {
        final data = doc.data();
        final date = (data['createdAt'] as Timestamp).toDate();
        final weekOfMonth = ((date.day - 1) / 7).floor();
        final amount = (data['amount'] ?? 0).toDouble();
        currentWeeklyData[weekOfMonth] = (currentWeeklyData[weekOfMonth] ?? 0) + amount;
        totalAmount += amount;
      }

      // Process last month data by week
      Map<int, double> lastWeeklyData = {};
      for (var doc in lastMonthSnapshot.docs) {
        final data = doc.data();
        final date = (data['createdAt'] as Timestamp).toDate();
        final weekOfMonth = ((date.day - 1) / 7).floor();
        final amount = (data['amount'] ?? 0).toDouble();
        lastWeeklyData[weekOfMonth] = (lastWeeklyData[weekOfMonth] ?? 0) + amount;
      }

      // Count pending and approved requests
      int pending = 0;
      int approved = 0;
      for (var doc in requestsSnapshot.docs) {
        final status = doc.data()['status'] ?? 'pending';
        if (status == 'pending') pending++;
        if (status == 'approved') approved++;
      }

      if (mounted) {
        setState(() {
          // Convert to list for chart (scale to thousands for better visualization)
          currentMonthData = List.generate(7, (i) => (currentWeeklyData[i] ?? 0) / 1000);
          lastMonthData = List.generate(7, (i) => (lastWeeklyData[i] ?? 0) / 1000);
          _totalDonations = currentMonthSnapshot.docs.length + lastMonthSnapshot.docs.length;
          _totalAmount = totalAmount;
          _pendingRequests = pending;
          _approvedRequests = approved;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading donation data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
          'Donation',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              color: primary,
              onRefresh: _loadDonationData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly Chart Section
                      _buildMonthlyChart(),
                      const SizedBox(height: 24),
                      
                      // Feature Grid
                      _buildFeatureGrid(),
                      const SizedBox(height: 24),
                      
                      // Create Donation Post Button
                      _buildCreatePostButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${(rod.toY * 1000).toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: currentMonthData[index],
                        color: primary,
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: lastMonthData[index],
                        color: Colors.amber,
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Current month', primary),
              const SizedBox(width: 24),
              _buildLegendItem('Last month', Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    double maxCurrent = currentMonthData.isNotEmpty 
        ? currentMonthData.reduce((a, b) => a > b ? a : b) 
        : 0;
    double maxLast = lastMonthData.isNotEmpty 
        ? lastMonthData.reduce((a, b) => a > b ? a : b) 
        : 0;
    double max = maxCurrent > maxLast ? maxCurrent : maxLast;
    return max > 0 ? max * 1.2 : 10; // Add 20% padding or default to 10
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureItem(
        title: 'Emergency',
        imagePath: 'assets/—Pngtree—emergency light flashing red warning_18600445.png',
        color: const Color(0xFFFFE4E4),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmergencyDonationScreen(ngoData: widget.ngoData),
          ),
        ),
      ),
      _FeatureItem(
        title: 'Donation Req',
        imagePath: 'assets/—Pngtree—money donation vector icon in_5684260.png',
        color: const Color(0xFFE8F5F5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonationRequestScreen(ngoData: widget.ngoData),
          ),
        ),
      ),
      _FeatureItem(
        title: 'CSR integration',
        imagePath: 'assets/csr.png',
        color: const Color(0xFFF5F5F5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CsrIntegrationScreen(ngoData: widget.ngoData),
          ),
        ),
      ),
      _FeatureItem(
        title: 'Share Resource',
        imagePath: 'assets/—Pngtree—share resource_5610380.png',
        color: const Color(0xFFE3F2FD),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShareResourceScreen(ngoData: widget.ngoData),
          ),
        ),
      ),
      _FeatureItem(
        title: 'Share Impact',
        imagePath: 'assets/52763616-impact-bulb-word-cloud-business-concept.jpg',
        color: const Color(0xFFFFF3E0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShareImpactScreen(ngoData: widget.ngoData),
          ),
        ),
      ),
      _FeatureItem(
        title: 'Donation\nHistory',
        imagePath: 'assets/teamwork-logo-abstract-two-hands-600nw-2282414665.webp',
        color: const Color(0xFFD7CCC8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonationHistoryScreen(ngoData: widget.ngoData),
          ),
        ),
      ),
      _FeatureItem(
        title: 'Needs\nForecasting',
        imagePath: 'assets/demand-forecasting-feature-image.webp',
        color: const Color(0xFFFFF9C4),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NeedsForecastingScreen(ngoData: widget.ngoData),
          ),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(feature);
      },
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return GestureDetector(
      onTap: feature.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  feature.imagePath,
                  width: 75,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: feature.color,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 32,
                        color: primary,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                feature.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateDonationPostScreen(ngoData: widget.ngoData),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Create Donation Post',
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

class _FeatureItem {
  final String title;
  final String imagePath;
  final Color color;
  final VoidCallback onTap;

  _FeatureItem({
    required this.title,
    required this.imagePath,
    required this.color,
    required this.onTap,
  });
}
