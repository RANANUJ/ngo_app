import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ngo_registration_service.dart';

class NeedsForecastingScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const NeedsForecastingScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<NeedsForecastingScreen> createState() => _NeedsForecastingScreenState();
}

class _NeedsForecastingScreenState extends State<NeedsForecastingScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  bool _isLoading = true;
  Map<String, dynamic> _forecastData = {};
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadForecastingData();
  }

  Future<void> _loadForecastingData() async {
    try {
      // Get historical donation data
      final donationsSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .get();

      // Get donation requests data
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('donation_requests')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .get();

      // Analyze data and create forecasts
      Map<String, double> categoryDonations = {};
      Map<String, int> categoryRequests = {};
      double totalDonations = 0;

      for (var doc in donationsSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? 'General';
        final amount = (data['amount'] ?? 0).toDouble();
        categoryDonations[category] = (categoryDonations[category] ?? 0) + amount;
        totalDonations += amount;
      }

      for (var doc in requestsSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? 'General';
        categoryRequests[category] = (categoryRequests[category] ?? 0) + 1;
      }

      // Generate recommendations
      List<Map<String, dynamic>> recommendations = [];
      
      // Based on category analysis
      categoryRequests.forEach((category, count) {
        final donationAmount = categoryDonations[category] ?? 0;
        if (count > 0 && donationAmount < count * 1000) {
          recommendations.add({
            'title': 'Increase $category fundraising',
            'description': 'You have $count requests but limited funding in this category.',
            'priority': 'High',
            'icon': Icons.trending_up,
          });
        }
      });

      // Add general recommendations
      if (totalDonations < 10000) {
        recommendations.add({
          'title': 'Launch donation campaign',
          'description': 'Consider launching a targeted donation campaign to increase funding.',
          'priority': 'Medium',
          'icon': Icons.campaign,
        });
      }

      recommendations.add({
        'title': 'Engage regular donors',
        'description': 'Set up recurring donation options for consistent funding.',
        'priority': 'Medium',
        'icon': Icons.repeat,
      });

      recommendations.add({
        'title': 'Partner with corporates',
        'description': 'CSR partnerships can significantly boost your funding.',
        'priority': 'High',
        'icon': Icons.business,
      });

      if (mounted) {
        setState(() {
          _forecastData = {
            'totalDonations': totalDonations,
            'totalRequests': requestsSnapshot.docs.length,
            'categoryDonations': categoryDonations,
            'categoryRequests': categoryRequests,
            'projectedNextMonth': totalDonations * 1.1, // Simple projection
          };
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading forecast data: $e');
      if (mounted) setState(() => _isLoading = false);
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
          'Needs Forecasting',
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
              onRefresh: _loadForecastingData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    _buildOverviewSection(),
                    const SizedBox(height: 24),

                    // Projection
                    _buildProjectionCard(),
                    const SizedBox(height: 24),

                    // Recommendations
                    const Text(
                      'Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._recommendations.map((rec) => _buildRecommendationCard(rec)),
                    const SizedBox(height: 24),

                    // Category Analysis
                    _buildCategoryAnalysis(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Donations',
            '₹${(_forecastData['totalDonations'] ?? 0).toStringAsFixed(0)}',
            Icons.currency_rupee,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Active Requests',
            '${_forecastData['totalRequests'] ?? 0}',
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildProjectionCard() {
    final projected = _forecastData['projectedNextMonth'] ?? 0;
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'Next Month Projection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹${projected.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your historical data and trends',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    Color priorityColor;
    switch (rec['priority']) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(rec['icon'] as IconData, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rec['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rec['priority'],
                        style: TextStyle(
                          fontSize: 10,
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rec['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysis() {
    final categoryDonations = _forecastData['categoryDonations'] as Map<String, double>? ?? {};
    
    if (categoryDonations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.analytics, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No category data available yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Donations by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...categoryDonations.entries.map((entry) {
            final total = categoryDonations.values.fold(0.0, (a, b) => a + b);
            final percentage = total > 0 ? (entry.value / total) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(primary),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
