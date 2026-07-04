import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'package:ngo_app/features/donations/presentation/screens/donation_request_screen.dart';
import 'package:ngo_app/features/donations/presentation/screens/donation_history_screen.dart';
import 'package:ngo_app/screens/campaigns/create_donation_post_screen.dart';
import 'package:ngo_app/screens/emergency/emergency_donation_screen.dart';
import 'package:ngo_app/features/resources/presentation/screens/share_resource_screen.dart';
import 'package:ngo_app/screens/impact/share_impact_screen.dart';
import 'package:ngo_app/screens/impact/needs_forecasting_screen.dart';
import 'package:ngo_app/screens/impact/csr_integration_screen.dart';
import '../controllers/donation_controller.dart';
import '../../domain/models/donation.dart';

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
  
  // Month selection
  late DateTime _selectedMonth;
  
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _loadDonationData();
  }

  Future<void> _loadDonationData() async {
    try {
      final controller = context.read<DonationController>();
      final donations = await controller.getNgoCombinedDonations(widget.ngoData.id);

      // Use selected month instead of current month
      final startOfCurrentMonth = _selectedMonth;
      final startOfLastMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);

      List<Donation> allCurrentMonthDonations = [];
      List<Donation> allLastMonthDonations = [];

      for (var donation in donations) {
        final date = donation.createdAt;
        if (date.isAfter(startOfCurrentMonth) || date.isAtSameMomentAs(startOfCurrentMonth)) {
          allCurrentMonthDonations.add(donation);
        } else if (date.isAfter(startOfLastMonth) && date.isBefore(startOfCurrentMonth)) {
          allLastMonthDonations.add(donation);
        }
      }

      // Process current month data by day of month (1-31)
      Map<int, double> currentDayData = {};
      double totalAmount = 0;
      for (var donation in allCurrentMonthDonations) {
        final date = donation.createdAt;
        final dayOfMonth = date.day - 1; // 0-based for chart indexing
        final amount = donation.amount;
        currentDayData[dayOfMonth] = (currentDayData[dayOfMonth] ?? 0) + amount;
        totalAmount += amount;
      }

      // Process last month data by day of month
      Map<int, double> lastDayData = {};
      for (var donation in allLastMonthDonations) {
        final date = donation.createdAt;
        final dayOfMonth = date.day - 1; // 0-based for chart indexing
        final amount = donation.amount;
        lastDayData[dayOfMonth] = (lastDayData[dayOfMonth] ?? 0) + amount;
      }

      if (mounted) {
        setState(() {
          // Convert to list for chart (scale to thousands for better visualization)
          currentMonthData = List.generate(7, (i) => (currentDayData[i] ?? 0) / 1000);
          lastMonthData = List.generate(7, (i) => (lastDayData[i] ?? 0) / 1000);
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
                      // Month Selector
                      _buildMonthSelector(),
                      const SizedBox(height: 16),
                      
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

  Widget _buildMonthSelector() {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: primary),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
              });
              _loadDonationData();
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedMonth = DateTime(pickedDate.year, pickedDate.month, 1);
                  });
                  _loadDonationData();
                }
              },
              child: Text(
                '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: primary),
            onPressed: () {
              // Don't allow going to future months
              final now = DateTime.now();
              if (_selectedMonth.year < now.year || 
                  (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                });
                _loadDonationData();
              }
            },
          ),
        ],
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
            color: Colors.grey.withValues(alpha: 0.1),
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
                        const days = ['1', '2', '3', '4', '5', '6', '7'];
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
              color: Colors.grey.withValues(alpha: 0.1),
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
