import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ngo_app/features/storage/data/services/receipt_service.dart';

class MonthlyDonationScreen extends StatefulWidget {
  const MonthlyDonationScreen({Key? key}) : super(key: key);

  @override
  State<MonthlyDonationScreen> createState() => _MonthlyDonationScreenState();
}

class _MonthlyDonationScreenState extends State<MonthlyDonationScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  static const Color accent = Color(0xFF00BCD4);

  late TabController _tabController;
  late Razorpay _razorpay;

  bool _isLoading = true;
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _donationHistory = [];
  List<Map<String, dynamic>> _ngos = [];
  Map<String, dynamic>? _userData;

  // For new subscription
  String? _selectedNgoId;
  String? _selectedNgoName;
  String? _selectedCategory;
  int _selectedAmount = 500;
  int _selectedDay = 1;
  
  final List<int> _suggestedAmounts = [100, 250, 500, 1000, 2500, 5000];
  final TextEditingController _customAmountController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'education', 'name': 'Education', 'icon': Icons.school, 'color': Colors.blue},
    {'id': 'food', 'name': 'Food & Hunger', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'id': 'health', 'name': 'Healthcare', 'icon': Icons.local_hospital, 'color': Colors.red},
    {'id': 'environment', 'name': 'Environment', 'icon': Icons.eco, 'color': Colors.green},
    {'id': 'women', 'name': 'Women Empowerment', 'icon': Icons.woman, 'color': Colors.pink},
    {'id': 'children', 'name': 'Child Welfare', 'icon': Icons.child_care, 'color': Colors.purple},
    {'id': 'elderly', 'name': 'Elderly Care', 'icon': Icons.elderly, 'color': Colors.brown},
    {'id': 'disaster', 'name': 'Disaster Relief', 'icon': Icons.warning, 'color': Colors.amber},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initRazorpay();
    _loadData();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _razorpay.clear();
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        _userData = userDoc.data();
      }

      // Load subscriptions
      final subsSnapshot = await FirebaseFirestore.instance
          .collection('monthly_subscriptions')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      _subscriptions = subsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by createdAt
      _subscriptions.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      // Load donation history
      final historySnapshot = await FirebaseFirestore.instance
          .collection('monthly_donations')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      _donationHistory = historySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by date
      _donationHistory.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      // Load verified NGOs
      final ngosSnapshot = await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .where('status', isEqualTo: 'approved')
          .get();
      
      _ngos = ngosSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Monthly Donations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Subscribe', icon: Icon(Icons.add_card, size: 20)),
            Tab(text: 'My Plans', icon: Icon(Icons.subscriptions, size: 20)),
            Tab(text: 'History', icon: Icon(Icons.history, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSubscribeTab(),
                _buildMyPlansTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  // ==================== SUBSCRIBE TAB ====================
  Widget _buildSubscribeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(),
          const SizedBox(height: 20),

          // Category Selection
          _buildSectionTitle('Select Cause', Icons.category),
          const SizedBox(height: 12),
          _buildCategoryGrid(),
          const SizedBox(height: 20),

          // NGO Selection
          _buildSectionTitle('Select NGO (Optional)', Icons.business),
          const SizedBox(height: 12),
          _buildNgoSelector(),
          const SizedBox(height: 20),

          // Amount Selection
          _buildSectionTitle('Select Amount', Icons.currency_rupee),
          const SizedBox(height: 12),
          _buildAmountSelector(),
          const SizedBox(height: 20),

          // Date Selection
          _buildSectionTitle('Monthly Deduction Date', Icons.calendar_today),
          const SizedBox(height: 12),
          _buildDateSelector(),
          const SizedBox(height: 24),

          // Impact Preview
          _buildImpactPreview(),
          const SizedBox(height: 24),

          // Subscribe Button
          _buildSubscribeButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, accent],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Become a Monthly Donor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Make a lasting impact with recurring donations',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Cancel anytime • 80G Tax Benefits',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _selectedCategory == category['id'];
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category['id'];
              _selectedNgoId = null;
              _selectedNgoName = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? category['color'].withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? category['color'] : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category['icon'],
                  color: category['color'],
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNgoSelector() {
    // Filter NGOs by category if selected
    List<Map<String, dynamic>> filteredNgos = _ngos;
    if (_selectedCategory != null) {
      filteredNgos = _ngos.where((ngo) {
        final category = (ngo['category'] ?? '').toString().toLowerCase();
        return category.contains(_selectedCategory!.toLowerCase());
      }).toList();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedNgoId,
          hint: Text(
            _selectedCategory == null
                ? 'Select a cause first'
                : 'Any NGO in ${_getCategoryName(_selectedCategory!)}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Any NGO (Auto-distribute)',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ...filteredNgos.map((ngo) {
              return DropdownMenuItem<String>(
                value: ngo['id'],
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: primary.withOpacity(0.1),
                      backgroundImage: ngo['logoUrl'] != null
                          ? NetworkImage(ngo['logoUrl'])
                          : null,
                      child: ngo['logoUrl'] == null
                          ? Text(
                              ((ngo['ngoName'] ?? 'N').toString().isNotEmpty 
                                  ? (ngo['ngoName'] as String)[0] 
                                  : 'N').toUpperCase(),
                              style: TextStyle(color: primary, fontSize: 12),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ngo['ngoName'] ?? 'Unknown NGO',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: _selectedCategory == null
              ? null
              : (value) {
                  setState(() {
                    _selectedNgoId = value;
                    _selectedNgoName = filteredNgos
                        .firstWhere(
                          (ngo) => ngo['id'] == value,
                          orElse: () => {'ngoName': null},
                        )['ngoName'];
                  });
                },
        ),
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    return _categories.firstWhere(
      (c) => c['id'] == categoryId,
      orElse: () => {'name': 'Unknown'},
    )['name'];
  }

  Widget _buildAmountSelector() {
    return Column(
      children: [
        // Preset amounts
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _suggestedAmounts.map((amount) {
            final isSelected = _selectedAmount == amount;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAmount = amount;
                  _customAmountController.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primary : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '₹$amount',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Custom amount input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter custom amount',
              prefixIcon: const Icon(Icons.currency_rupee, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) {
              final amount = int.tryParse(value);
              if (amount != null && amount > 0) {
                setState(() => _selectedAmount = amount);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose the day of month for automatic deduction:',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [1, 5, 10, 15, 20, 25].map((day) {
                final isSelected = _selectedDay == day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primary : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _getOrdinalSuffix(day),
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next deduction: ${_getNextDeductionDate()}',
                    style: TextStyle(color: primary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  String _getNextDeductionDate() {
    final now = DateTime.now();
    DateTime nextDate;
    
    if (now.day <= _selectedDay) {
      nextDate = DateTime(now.year, now.month, _selectedDay);
    } else {
      nextDate = DateTime(now.year, now.month + 1, _selectedDay);
    }
    
    return DateFormat('d MMMM yyyy').format(nextDate);
  }

  Widget _buildImpactPreview() {
    if (_selectedCategory == null) return const SizedBox.shrink();

    final monthlyAmount = _selectedAmount;
    final yearlyAmount = monthlyAmount * 12;

    Map<String, String> impacts = {
      'education': '$monthlyAmount can provide school supplies for ${(monthlyAmount / 100).floor()} children',
      'food': '$monthlyAmount can provide meals for ${(monthlyAmount / 30).floor()} people',
      'health': '$monthlyAmount can provide medicine for ${(monthlyAmount / 200).floor()} patients',
      'environment': '$monthlyAmount can help plant ${(monthlyAmount / 50).floor()} trees',
      'women': '$monthlyAmount can support ${(monthlyAmount / 500).floor()} women entrepreneurs',
      'children': '$monthlyAmount can support ${(monthlyAmount / 300).floor()} children\'s education',
      'elderly': '$monthlyAmount can provide care for ${(monthlyAmount / 400).floor()} senior citizens',
      'disaster': '$monthlyAmount can provide relief supplies for ${(monthlyAmount / 150).floor()} families',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Your Impact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Monthly: ₹$monthlyAmount - ${impacts[_selectedCategory] ?? "Makes a difference"}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Yearly: ₹$yearlyAmount - Multiply your impact 12x!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    final isValid = _selectedCategory != null && _selectedAmount >= 10;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid ? _createSubscription : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isValid ? 4 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.card_membership),
            const SizedBox(width: 8),
            Text(
              'Subscribe ₹$_selectedAmount/month',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MY PLANS TAB ====================
  Widget _buildMyPlansTab() {
    if (_subscriptions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.subscriptions,
        title: 'No Active Subscriptions',
        subtitle: 'Start your monthly giving journey today!',
        actionLabel: 'Create Subscription',
        onAction: () => _tabController.animateTo(0),
      );
    }

    final activeSubscriptions = _subscriptions.where((s) => s['status'] == 'active').toList();
    final pausedSubscriptions = _subscriptions.where((s) => s['status'] == 'paused').toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSubscriptionSummary(),
            const SizedBox(height: 24),
            
            // Active Subscriptions
            if (activeSubscriptions.isNotEmpty) ...[
              _buildSectionHeader('Active Subscriptions', Icons.check_circle, primary),
              const SizedBox(height: 12),
              ...activeSubscriptions.map((sub) => _buildSubscriptionCard(sub)),
              const SizedBox(height: 20),
            ],
            
            // Paused Subscriptions
            if (pausedSubscriptions.isNotEmpty) ...[
              _buildSectionHeader('Paused Subscriptions', Icons.pause_circle, Colors.grey.shade600),
              const SizedBox(height: 12),
              ...pausedSubscriptions.map((sub) => _buildSubscriptionCard(sub)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionSummary() {
    final activeCount = _subscriptions.where((s) => s['status'] == 'active').length;
    final pausedCount = _subscriptions.where((s) => s['status'] == 'paused').length;
    final totalMonthly = _subscriptions
        .where((s) => s['status'] == 'active')
        .fold<int>(0, (sum, s) => sum + ((s['amount'] ?? 0) as int));
    
    // Calculate total donated
    final totalDonated = _donationHistory.fold<int>(
      0, (sum, d) => sum + ((d['amount'] ?? 0) as int));

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Monthly Giving',
                        '₹$totalMonthly',
                        Icons.calendar_month,
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.white24,
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Donated',
                        '₹$totalDonated',
                        Icons.favorite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('Active', activeCount.toString(), Colors.greenAccent),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildMiniStat('Paused', pausedCount.toString(), Colors.orangeAccent),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildMiniStat('Donations', _donationHistory.length.toString(), Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription) {
    final isActive = subscription['status'] == 'active';
    final isPaused = subscription['status'] == 'paused';
    final amount = subscription['amount'] ?? 0;
    final category = subscription['category'] ?? 'general';
    final ngoName = subscription['ngoName'] ?? 'Any NGO';
    final deductionDay = subscription['deductionDay'] ?? 1;
    final createdAt = (subscription['createdAt'] as Timestamp?)?.toDate();
    final nextDeduction = _getNextDeductionDateFromDay(deductionDay);

    final categoryData = _categories.firstWhere(
      (c) => c['id'] == category,
      orElse: () => {'name': 'General', 'icon': Icons.volunteer_activism, 'color': primary},
    );

    return GestureDetector(
      onTap: () => _showSubscriptionDetails(subscription),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Category Icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          categoryData['color'].withValues(alpha: 0.2),
                          categoryData['color'].withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      categoryData['icon'],
                      color: categoryData['color'],
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                categoryData['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(isActive, isPaused),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.business, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                ngoName,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (createdAt != null)
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                'Since ${DateFormat('MMM yyyy').format(createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹$amount',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        '/month',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Footer with actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event, size: 14, color: primary),
                        const SizedBox(width: 4),
                        Text(
                          'Next: $nextDeduction',
                          style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (isActive) ...[
                    _buildActionButton('Pause', Icons.pause, Colors.orange, () => _pauseSubscription(subscription['id'])),
                  ] else if (isPaused) ...[
                    _buildActionButton('Resume', Icons.play_arrow, Colors.green, () => _resumeSubscription(subscription['id'])),
                  ],
                  const SizedBox(width: 8),
                  _buildActionButton('Cancel', Icons.close, Colors.red, () => _showCancelDialog(subscription)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, bool isPaused) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;
    
    if (isActive) {
      bgColor = primary.withValues(alpha: 0.1);
      textColor = primary;
      text = 'Active';
      icon = Icons.check_circle;
    } else if (isPaused) {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade600;
      text = 'Paused';
      icon = Icons.pause_circle;
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey;
      text = 'Inactive';
      icon = Icons.cancel;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    // Use consistent primary/grey colors
    final displayColor = label == 'Cancel' ? Colors.grey.shade600 : primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: displayColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: displayColor),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: displayColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionDetails(Map<String, dynamic> subscription) {
    final amount = subscription['amount'] ?? 0;
    final category = subscription['category'] ?? 'general';
    final ngoName = subscription['ngoName'] ?? 'Any NGO';
    final ngoId = subscription['ngoId'];
    final deductionDay = subscription['deductionDay'] ?? 1;
    final createdAt = (subscription['createdAt'] as Timestamp?)?.toDate();
    final status = subscription['status'] ?? 'active';
    final paymentId = subscription['paymentId'] ?? 'N/A';
    
    final categoryData = _categories.firstWhere(
      (c) => c['id'] == category,
      orElse: () => {'name': 'General', 'icon': Icons.volunteer_activism, 'color': primary},
    );

    // Count donations for this subscription
    final donationsCount = _donationHistory
        .where((d) => d['subscriptionId'] == subscription['id'])
        .length;
    final totalPaid = donationsCount * (amount as int);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryData['color'].withValues(alpha: 0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: categoryData['color'].withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoryData['icon'],
                      color: categoryData['color'],
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    categoryData['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ngoName,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusBadge(status == 'active', status == 'paused'),
                ],
              ),
            ),
            
            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Amount Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, accent],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Monthly',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                '₹$amount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(height: 40, width: 1, color: Colors.white24),
                          Column(
                            children: [
                              const Text(
                                'Total Paid',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                '₹$totalPaid',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Details List
                    _buildDetailRow(Icons.calendar_today, 'Deduction Date', '${deductionDay}${_getOrdinalSuffix(deductionDay)} of each month'),
                    _buildDetailRow(Icons.event, 'Next Deduction', _getNextDeductionDateFromDay(deductionDay)),
                    _buildDetailRow(Icons.history, 'Payments Made', '$donationsCount'),
                    if (createdAt != null)
                      _buildDetailRow(Icons.access_time, 'Started On', DateFormat('d MMMM yyyy').format(createdAt)),
                    _buildDetailRow(Icons.receipt_long, 'Subscription ID', subscription['id'].toString().substring(0, 12) + '...'),
                    if (ngoId != null && ngoId.toString().isNotEmpty)
                      _buildDetailRow(Icons.business, 'NGO ID', ngoId.toString().substring(0, 12) + '...'),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  if (status == 'active')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _pauseSubscription(subscription['id']);
                        },
                        icon: Icon(Icons.pause, color: Colors.grey.shade600),
                        label: Text('Pause', style: TextStyle(color: Colors.grey.shade600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  else if (status == 'paused')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _resumeSubscription(subscription['id']);
                        },
                        icon: const Icon(Icons.play_arrow, color: primary),
                        label: const Text('Resume', style: TextStyle(color: primary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCancelDialog(subscription);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _getNextDeductionDateFromDay(int day) {
    final now = DateTime.now();
    DateTime nextDate;
    
    if (now.day <= day) {
      nextDate = DateTime(now.year, now.month, day);
    } else {
      nextDate = DateTime(now.year, now.month + 1, day);
    }
    
    return DateFormat('d MMM yyyy').format(nextDate);
  }

  // ==================== HISTORY TAB ====================
  Widget _buildHistoryTab() {
    if (_donationHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Donation History',
        subtitle: 'Your monthly donations will appear here',
        actionLabel: 'Start Donating',
        onAction: () => _tabController.animateTo(0),
      );
    }

    // Group by month
    Map<String, List<Map<String, dynamic>>> groupedHistory = {};
    for (var donation in _donationHistory) {
      final date = (donation['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final monthKey = DateFormat('MMMM yyyy').format(date);
      groupedHistory.putIfAbsent(monthKey, () => []).add(donation);
    }

    // Calculate total
    final totalDonated = _donationHistory.fold<int>(
      0, (sum, d) => sum + ((d['amount'] ?? 0) as int));
    
    // Calculate average donation
    final avgDonation = _donationHistory.isNotEmpty 
        ? (totalDonated / _donationHistory.length).round() 
        : 0;
    
    // Get unique months
    final uniqueMonths = groupedHistory.keys.length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primary, accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Main stats row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.volunteer_activism, color: Colors.white, size: 24),
                            const SizedBox(height: 4),
                            const Text(
                              'Total Donated',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            Text(
                              '₹$totalDonated',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 50, width: 1, color: Colors.white24),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                            const SizedBox(height: 4),
                            const Text(
                              'Payments',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            Text(
                              '${_donationHistory.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Mini stats
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHistoryMiniStat('Avg/Payment', '₹$avgDonation'),
                        Container(height: 24, width: 1, color: Colors.white24),
                        _buildHistoryMiniStat('Months Active', '$uniqueMonths'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Transaction History
            Row(
              children: [
                Icon(Icons.history, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Grouped donations
            ...groupedHistory.entries.map((entry) {
              final monthKey = entry.key;
              final donations = entry.value;
              final monthTotal = donations.fold<int>(0, (sum, d) => sum + ((d['amount'] ?? 0) as int));
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              monthKey,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '₹$monthTotal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Donation Cards
                  ...donations.map((donation) => _buildHistoryCard(donation)),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> donation) {
    final amount = donation['amount'] ?? 0;
    final ngoName = donation['ngoName'] ?? 'NGO';
    final category = donation['category'] ?? 'general';
    final status = donation['status'] ?? 'completed';
    final date = (donation['createdAt'] as Timestamp?)?.toDate();

    final categoryData = _categories.firstWhere(
      (c) => c['id'] == category,
      orElse: () => {'name': 'General', 'icon': Icons.volunteer_activism, 'color': primary},
    );

    return GestureDetector(
      onTap: () => _showDonationDetails(donation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryData['color'].withValues(alpha: 0.2),
                    categoryData['color'].withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categoryData['icon'],
                color: categoryData['color'],
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ngoName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category, size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        categoryData['name'],
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM yyyy, hh:mm a').format(date),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Amount and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status == 'completed'
                        ? primary.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == 'completed' ? Icons.check_circle : Icons.pending,
                        size: 10,
                        color: status == 'completed' ? primary : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        status == 'completed' ? 'Paid' : 'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: status == 'completed' ? primary : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Arrow indicator
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _downloadReceipt(Map<String, dynamic> donation, String refNumber) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Generating receipt...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      final amount = donation['amount'] ?? 0;
      final ngoName = donation['ngoName'] ?? 'NGO';
      final category = donation['category'] ?? 'general';
      final date = (donation['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final paymentId = donation['paymentId'];
      final subscriptionId = donation['subscriptionId'];
      
      final categoryData = _categories.firstWhere(
        (c) => c['id'] == category,
        orElse: () => {'name': 'General', 'icon': Icons.volunteer_activism, 'color': primary},
      );

      await ReceiptService.generateAndShareReceipt(
        receiptNumber: refNumber,
        date: date,
        amount: amount,
        ngoName: ngoName,
        category: categoryData['name'],
        donorName: _userData?['name'] ?? 'Donor',
        donorEmail: _userData?['email'] ?? '',
        donorPhone: _userData?['phone'],
        paymentId: paymentId,
        paymentMethod: 'Razorpay',
        isMonthlySubscription: subscriptionId != null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDonationDetails(Map<String, dynamic> donation) {
    final amount = donation['amount'] ?? 0;
    final ngoName = donation['ngoName'] ?? 'NGO';
    final category = donation['category'] ?? 'general';
    final status = donation['status'] ?? 'completed';
    final date = (donation['createdAt'] as Timestamp?)?.toDate();
    final paymentId = donation['paymentId'];
    final subscriptionId = donation['subscriptionId'];
    
    final categoryData = _categories.firstWhere(
      (c) => c['id'] == category,
      orElse: () => {'name': 'General', 'icon': Icons.volunteer_activism, 'color': primary},
    );

    // Generate a reference number
    final refNumber = 'TXN${date?.millisecondsSinceEpoch.toString().substring(5, 13) ?? '00000000'}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Success Header with gradient
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Success icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              status == 'completed' ? Icons.check : Icons.schedule,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            status == 'completed' ? 'Payment Successful' : 'Payment Pending',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹$amount',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (date != null)
                            Text(
                              DateFormat('dd MMM yyyy • hh:mm a').format(date),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Transaction Reference
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tag, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 10),
                          Text(
                            'Reference: $refNumber',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              // Copy to clipboard functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reference copied!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Icon(Icons.copy, size: 18, color: primary),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Details Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRANSACTION DETAILS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Details Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                _buildReceiptRow(
                                  'Donated To',
                                  ngoName,
                                  iconData: Icons.business_rounded,
                                ),
                                _buildDivider(),
                                _buildReceiptRow(
                                  'Category',
                                  categoryData['name'],
                                  iconData: categoryData['icon'],
                                  iconColor: categoryData['color'],
                                ),
                                _buildDivider(),
                                _buildReceiptRow(
                                  'Payment Status',
                                  status == 'completed' ? 'Completed' : 'Pending',
                                  showBadge: true,
                                  badgeColor: status == 'completed' ? primary : Colors.grey,
                                ),
                                if (subscriptionId != null) ...[
                                  _buildDivider(),
                                  _buildReceiptRow(
                                    'Payment Type',
                                    'Monthly Auto-Pay',
                                    iconData: Icons.autorenew,
                                    iconColor: primary,
                                  ),
                                ],
                                if (paymentId != null) ...[
                                  _buildDivider(),
                                  _buildReceiptRow(
                                    'Payment ID',
                                    paymentId.toString().length > 16 
                                        ? '${paymentId.toString().substring(0, 16)}...' 
                                        : paymentId.toString(),
                                    iconData: Icons.receipt_long,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Thank you message
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Thank you for your generosity! Your contribution makes a difference.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          _downloadReceipt(donation, refNumber);
                        },
                        icon: Icon(Icons.download_rounded, size: 18, color: primary),
                        label: Text('Receipt', style: TextStyle(color: primary)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    IconData? iconData,
    Color? iconColor,
    bool showBadge = false,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (iconData != null) ...[
            Icon(iconData, size: 18, color: iconColor ?? Colors.grey.shade500),
            const SizedBox(width: 12),
          ],
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (showBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor?.withValues(alpha: 0.1) ?? Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: badgeColor ?? Colors.grey,
                ),
              ),
            )
          else
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100);
  }

  Widget _buildPaymentDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
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
              child: Icon(icon, size: 48, color: primary),
            ),
            const SizedBox(height: 24),
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
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _createSubscription() async {
    if (_selectedCategory == null || _selectedAmount < 10) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.card_membership, color: primary),
            const SizedBox(width: 12),
            Expanded(
              child: const Text(
                'Confirm Subscription',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmRow('Amount', '₹$_selectedAmount/month'),
            _buildConfirmRow('Category', _getCategoryName(_selectedCategory!)),
            _buildConfirmRow('NGO', _selectedNgoName ?? 'Any NGO'),
            _buildConfirmRow('Deduction Date', '${_selectedDay}${_getOrdinalSuffix(_selectedDay)} of each month'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can cancel anytime from the My Plans tab.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Proceed to Pay'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Process first payment via Razorpay
    _processFirstPayment();
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _processFirstPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String activeKeyId = 'rzp_test_Rsb9ATnbTWb7WI';
    try {
      final configDoc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('razorpay')
          .get();
      if (configDoc.exists) {
        activeKeyId = configDoc.data()?['keyId'] ?? 'rzp_test_Rsb9ATnbTWb7WI';
      }
    } catch (_) {}

    final options = {
      'key': activeKeyId,
      'amount': _selectedAmount * 100, // Amount in paise
      'name': 'Connect NGO',
      'description': 'Monthly Donation - ${_getCategoryName(_selectedCategory!)}',
      'prefill': {
        'email': user.email ?? '',
        'contact': _userData?['phone'] ?? '',
      },
      'theme': {'color': '#0099B8'},
      'notes': {
        'userId': user.uid,
        'category': _selectedCategory,
        'ngoId': _selectedNgoId ?? '',
        'ngoName': _selectedNgoName ?? 'Any NGO',
        'deductionDay': _selectedDay,
        'type': 'monthly_subscription',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open payment gateway'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Create subscription in Firestore
      final subscriptionRef = await FirebaseFirestore.instance
          .collection('monthly_subscriptions')
          .add({
        'userId': user.uid,
        'userName': _userData?['name'] ?? 'User',
        'userEmail': user.email,
        'amount': _selectedAmount,
        'category': _selectedCategory,
        'ngoId': _selectedNgoId,
        'ngoName': _selectedNgoName ?? 'Any NGO',
        'deductionDay': _selectedDay,
        'status': 'active',
        'razorpayPaymentId': response.paymentId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastPaymentDate': FieldValue.serverTimestamp(),
        'nextPaymentDate': _getNextPaymentTimestamp(),
      });

      // Record first donation
      await FirebaseFirestore.instance.collection('monthly_donations').add({
        'subscriptionId': subscriptionRef.id,
        'userId': user.uid,
        'amount': _selectedAmount,
        'category': _selectedCategory,
        'ngoId': _selectedNgoId,
        'ngoName': _selectedNgoName ?? 'Any NGO',
        'razorpayPaymentId': response.paymentId,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': user.uid,
        'userType': 'volunteer',
        'title': '🎉 Subscription Created!',
        'message': 'Your monthly donation of ₹$_selectedAmount has been set up successfully.',
        'type': 'subscription',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Subscription created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form and switch to My Plans tab
        setState(() {
          _selectedCategory = null;
          _selectedNgoId = null;
          _selectedNgoName = null;
          _selectedAmount = 500;
          _selectedDay = 1;
        });
        
        _loadData();
        _tabController.animateTo(1);
      }
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Timestamp _getNextPaymentTimestamp() {
    final now = DateTime.now();
    DateTime nextDate;
    
    if (now.day <= _selectedDay) {
      nextDate = DateTime(now.year, now.month + 1, _selectedDay);
    } else {
      nextDate = DateTime(now.year, now.month + 2, _selectedDay);
    }
    
    return Timestamp.fromDate(nextDate);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet: ${response.walletName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _pauseSubscription(String subscriptionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('monthly_subscriptions')
          .doc(subscriptionId)
          .update({'status': 'paused'});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription paused'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resumeSubscription(String subscriptionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('monthly_subscriptions')
          .doc(subscriptionId)
          .update({'status': 'active'});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription resumed'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCancelDialog(Map<String, dynamic> subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Cancel Subscription',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this subscription?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '₹${subscription['amount']}/month for ${subscription['ngoName'] ?? 'NGO'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Subscription', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelSubscription(subscription['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Plan'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription(String subscriptionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('monthly_subscriptions')
          .doc(subscriptionId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription cancelled'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
