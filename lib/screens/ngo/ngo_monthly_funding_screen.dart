import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/monthly_funding_service.dart';
import '../../services/email_service.dart';

class NgoMonthlyFundingScreen extends StatefulWidget {
  final String ngoId;
  final String ngoName;
  final String? ngoEmail;

  const NgoMonthlyFundingScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
    this.ngoEmail,
  }) : super(key: key);

  @override
  State<NgoMonthlyFundingScreen> createState() => _NgoMonthlyFundingScreenState();
}

class _NgoMonthlyFundingScreenState extends State<NgoMonthlyFundingScreen> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  late TabController _tabController;
  final MonthlyFundingService _fundingService = MonthlyFundingService();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  
  DateTime _selectedMonth = DateTime.now();
  MonthlyFundingStats? _stats;
  List<DonorSummary> _topDonors = [];
  List<MonthlyFundingData> _transactions = [];
  List<SubscriptionData> _subscriptions = [];
  Map<String, double> _yearlyTrend = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _fundingService.getMonthlyStats(
        ngoId: widget.ngoId, month: _selectedMonth.month, year: _selectedMonth.year,
      );
      final donors = await _fundingService.getTopDonors(ngoId: widget.ngoId, limit: 20);
      final trend = await _fundingService.getYearlyTrend(ngoId: widget.ngoId, year: _selectedMonth.year);
      final transactions = await _fundingService.getAllDonations(ngoId: widget.ngoId);
      final subscriptions = await _fundingService.getAllSubscriptions(ngoId: widget.ngoId);
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _topDonors = donors;
          _yearlyTrend = trend;
          _transactions = transactions;
          _subscriptions = subscriptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      appBar: AppBar(
        backgroundColor: primary, elevation: 0,
        title: const Text('Monthly Funding', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.calendar_month, color: Colors.white), onPressed: _selectMonth),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'), Tab(text: 'Transactions'), Tab(text: 'Subscriptions'), Tab(text: 'Donors'),
          ],
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildTransactionsTab(), _buildSubscriptionsTab(), _buildDonorsTab()],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 16),
            _buildStatCards(),
            const SizedBox(height: 20),
            _buildTrendChart(),
            const SizedBox(height: 20),
            _buildCategoryBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () {
            setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
            _loadData();
          }),
          Expanded(child: Text(DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          IconButton(
            icon: Icon(Icons.chevron_right, color: _selectedMonth.month >= DateTime.now().month && _selectedMonth.year >= DateTime.now().year ? Colors.white38 : Colors.white),
            onPressed: _selectedMonth.month >= DateTime.now().month && _selectedMonth.year >= DateTime.now().year ? null : () {
              setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4,
      children: [
        _statCard('Total Raised', currencyFormat.format(_stats?.totalAmount ?? 0), Icons.currency_rupee, Colors.green, () => _showDetailDialog('Total Raised', 'Total amount raised this month from all monthly donations.', currencyFormat.format(_stats?.totalAmount ?? 0))),
        _statCard('Transactions', '${_stats?.totalTransactions ?? 0}', Icons.receipt_long, Colors.blue, () { _tabController.animateTo(1); }),
        _statCard('Unique Donors', '${_stats?.totalDonors ?? 0}', Icons.people, Colors.orange, () { _tabController.animateTo(3); }),
        _statCard('Avg. Donation', currencyFormat.format(_stats?.averageDonation ?? 0), Icons.analytics, Colors.purple, () => _showDetailDialog('Average Donation', 'Average donation amount per transaction this month.', currencyFormat.format(_stats?.averageDonation ?? 0))),
        _statCard('Active Plans', '${_stats?.activeSubscriptions ?? 0}', Icons.subscriptions, Colors.teal, () { _tabController.animateTo(2); }),
        _statCard('Pending Thanks', '${_stats?.thankYouPending ?? 0}', Icons.mail_outline, Colors.red, () => _showPendingThanks()),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20)),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            ]),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(String title, String description, String value) {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(description, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  void _showPendingThanks() {
    // Get pending thank you emails from all transactions (not filtered by month)
    final pending = _transactions.where((t) => !(t.thankYouSent) && t.status == 'completed').toList();
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3, expand: false,
        builder: (context, scrollController) => Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            const Icon(Icons.mail_outline, color: Colors.red), const SizedBox(width: 8),
            Text('Pending Thank You (${pending.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ])),
          Expanded(child: pending.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
                const SizedBox(height: 16), const Text('All thank you emails sent!', style: TextStyle(fontSize: 16)),
              ]))
            : ListView.builder(controller: scrollController, itemCount: pending.length, itemBuilder: (context, index) => _buildTransactionTile(pending[index]))),
        ]),
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_yearlyTrend.isEmpty) return const SizedBox.shrink();
    final maxValue = _yearlyTrend.values.fold<double>(1, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Yearly Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: _yearlyTrend.entries.map((e) {
          final height = maxValue > 0 ? (e.value / maxValue) * 120 : 0.0;
          final isCurrentMonth = e.key == DateFormat('MMM').format(_selectedMonth);
          return Expanded(child: GestureDetector(
            onTap: () => _showDetailDialog(e.key, 'Total raised in ${e.key}', currencyFormat.format(e.value)),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (e.value > 0) Text(currencyFormat.format(e.value).replaceAll('₹', ''), style: TextStyle(fontSize: 7, color: isCurrentMonth ? primary : Colors.grey)),
              Container(height: height < 4 && e.value > 0 ? 4 : height, margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: isCurrentMonth ? primary : primary.withOpacity(0.3), borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
              const SizedBox(height: 4),
              Text(e.key, style: TextStyle(fontSize: 9, color: isCurrentMonth ? primary : Colors.grey, fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal)),
            ]),
          ));
        }).toList())),
      ]),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_stats?.categoryWiseAmount.isEmpty ?? true) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Category Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._stats!.categoryWiseAmount.entries.map((e) {
          final percentage = (_stats!.totalAmount > 0) ? (e.value / _stats!.totalAmount * 100) : 0;
          return GestureDetector(
            onTap: () => _showDetailDialog(_formatCategoryName(e.key), 'Total raised for ${_formatCategoryName(e.key)}', currencyFormat.format(e.value)),
            child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(_formatCategoryName(e.key), style: const TextStyle(fontSize: 13))),
                Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(width: 8),
                Text(currencyFormat.format(e.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: percentage / 100, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(primary)),
            ])),
          );
        }).toList(),
      ]),
    );
  }

  String _formatCategoryName(String category) {
    switch (category) {
      case 'education': return '📚 Education';
      case 'healthcare': return '🏥 Healthcare';
      case 'food': return '🍲 Food & Nutrition';
      case 'shelter': return '🏠 Shelter';
      case 'environment': return '🌱 Environment';
      case 'animals': return '🐾 Animal Welfare';
      case 'disaster': return '🆘 Disaster Relief';
      case 'general': return '💝 General Support';
      default: return '💝 ${category[0].toUpperCase()}${category.substring(1)}';
    }
  }

  Widget _buildTransactionsTab() {
    // Show all transactions, not filtered by month - month filter is for overview stats only
    if (_transactions.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text('No transactions yet', style: TextStyle(color: Colors.grey.shade600)),
      ]));
    }
    
    // Group by month for better display
    final groupedTransactions = <String, List<MonthlyFundingData>>{};
    for (final t in _transactions) {
      final monthKey = DateFormat('MMMM yyyy').format(t.donationDate);
      groupedTransactions.putIfAbsent(monthKey, () => []);
      groupedTransactions[monthKey]!.add(t);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final month = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[month]!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (index > 0) const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(month, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey))),
          ...transactions.map((t) => _buildTransactionTile(t)),
        ]);
      },
    );
  }

  void _showAllTransactions() {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
        builder: (context, scrollController) => Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.all(16), child: Text('All Transactions (${_transactions.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Expanded(child: ListView.builder(controller: scrollController, itemCount: _transactions.length, padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) => _buildTransactionTile(_transactions[index]))),
        ]),
      ),
    );
  }

  Widget _buildTransactionTile(MonthlyFundingData donation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: primary.withOpacity(0.1),
          backgroundImage: donation.donorProfileImage != null ? NetworkImage(donation.donorProfileImage!) : null,
          child: donation.donorProfileImage == null ? Text(donation.donorName.isNotEmpty ? donation.donorName[0].toUpperCase() : 'A', style: TextStyle(color: primary, fontWeight: FontWeight.bold)) : null,
        ),
        title: Text(donation.donorName.isEmpty ? 'Anonymous' : donation.donorName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(DateFormat('dd MMM yyyy, hh:mm a').format(donation.donationDate), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(_formatCategoryName(donation.category), style: TextStyle(fontSize: 11, color: primary)),
        ]),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(currencyFormat.format(donation.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (donation.thankYouSent) const Icon(Icons.check_circle, color: Colors.green, size: 14) else const Icon(Icons.mail_outline, color: Colors.orange, size: 14),
            const SizedBox(width: 4),
            Text(donation.status.toUpperCase(), style: TextStyle(fontSize: 9, color: donation.status == 'completed' ? Colors.green : Colors.orange)),
          ]),
        ]),
        onTap: () => _showTransactionDetails(donation),
      ),
    );
  }

  void _showTransactionDetails(MonthlyFundingData donation) {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            CircleAvatar(radius: 30, backgroundColor: primary.withOpacity(0.1),
              backgroundImage: donation.donorProfileImage != null ? NetworkImage(donation.donorProfileImage!) : null,
              child: donation.donorProfileImage == null ? Text(donation.donorName.isNotEmpty ? donation.donorName[0].toUpperCase() : 'A', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 24)) : null),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(donation.donorName.isEmpty ? 'Anonymous Donor' : donation.donorName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(donation.donorEmail.isEmpty ? 'No email provided' : donation.donorEmail, style: TextStyle(color: Colors.grey.shade600)),
            ])),
          ]),
          const Divider(height: 32),
          _detailRow(Icons.currency_rupee, 'Amount', currencyFormat.format(donation.amount), Colors.green),
          _detailRow(Icons.calendar_today, 'Date', DateFormat('dd MMMM yyyy, hh:mm a').format(donation.donationDate), Colors.blue),
          _detailRow(Icons.category, 'Category', _formatCategoryName(donation.category), primary),
          _detailRow(Icons.receipt, 'Payment ID', donation.paymentId.isNotEmpty ? donation.paymentId : 'N/A', Colors.purple),
          _detailRow(Icons.check_circle, 'Status', donation.status.toUpperCase(), donation.status == 'completed' ? Colors.green : Colors.orange),
          _detailRow(Icons.mail, 'Thank You Sent', donation.thankYouSent ? 'Yes ✓' : 'Not Yet', donation.thankYouSent ? Colors.green : Colors.red),
          const SizedBox(height: 20),
          if (!donation.thankYouSent && donation.donorEmail.isNotEmpty)
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(context); _sendThankYou(donation); },
              icon: const Icon(Icons.mail), label: const Text('Send Thank You Email'),
              style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.all(14)),
            )),
        ]),
      )),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ])),
    ]));
  }

  Widget _buildSubscriptionsTab() {
    if (_subscriptions.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16), Text('No subscriptions yet', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Text('Monthly subscription plans will appear here', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ]));
    }
    final active = _subscriptions.where((s) => s.status == 'active').toList();
    final paused = _subscriptions.where((s) => s.status == 'paused').toList();
    final other = _subscriptions.where((s) => s.status != 'active' && s.status != 'paused').toList();
    
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (active.isNotEmpty) ...[
        _sectionHeader('Active Subscriptions', Icons.check_circle, Colors.green, active.length),
        ...active.map((s) => _buildSubscriptionTile(s)),
      ],
      if (paused.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionHeader('Paused Subscriptions', Icons.pause_circle, Colors.orange, paused.length),
        ...paused.map((s) => _buildSubscriptionTile(s)),
      ],
      if (other.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionHeader('Other Subscriptions', Icons.subscriptions, Colors.grey, other.length),
        ...other.map((s) => _buildSubscriptionTile(s)),
      ],
    ]);
  }

  Widget _sectionHeader(String title, IconData icon, Color color, int count) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Icon(icon, color: color, size: 20), const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const Spacer(),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
    ]));
  }

  Widget _buildSubscriptionTile(SubscriptionData sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: sub.status == 'active' ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3))),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(backgroundColor: primary.withOpacity(0.1),
          backgroundImage: sub.donorProfileImage != null ? NetworkImage(sub.donorProfileImage!) : null,
          child: sub.donorProfileImage == null ? Text(sub.donorName.isNotEmpty ? sub.donorName[0].toUpperCase() : 'A', style: TextStyle(color: primary, fontWeight: FontWeight.bold)) : null),
        title: Text(sub.donorName.isEmpty ? 'Anonymous' : sub.donorName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${currencyFormat.format(sub.amount)}/month', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
          Text('Deduction: Day ${sub.deductionDay}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: sub.status == 'active' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(sub.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub.status == 'active' ? Colors.green : Colors.orange))),
        onTap: () => _showSubscriptionDetails(sub),
      ),
    );
  }

  void _showSubscriptionDetails(SubscriptionData sub) {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        Row(children: [
          CircleAvatar(radius: 30, backgroundColor: primary.withOpacity(0.1),
            backgroundImage: sub.donorProfileImage != null ? NetworkImage(sub.donorProfileImage!) : null,
            child: sub.donorProfileImage == null ? Text(sub.donorName.isNotEmpty ? sub.donorName[0].toUpperCase() : 'A', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 24)) : null),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sub.donorName.isEmpty ? 'Anonymous Subscriber' : sub.donorName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(sub.donorEmail.isEmpty ? 'No email provided' : sub.donorEmail, style: TextStyle(color: Colors.grey.shade600)),
          ])),
        ]),
        const Divider(height: 32),
        _detailRow(Icons.currency_rupee, 'Monthly Amount', currencyFormat.format(sub.amount), Colors.green),
        _detailRow(Icons.category, 'Category', _formatCategoryName(sub.category), primary),
        _detailRow(Icons.calendar_today, 'Deduction Day', 'Day ${sub.deductionDay} of every month', Colors.blue),
        _detailRow(Icons.play_arrow, 'Started On', DateFormat('dd MMM yyyy').format(sub.createdAt), Colors.purple),
        if (sub.lastPaymentDate != null) _detailRow(Icons.payment, 'Last Payment', DateFormat('dd MMM yyyy').format(sub.lastPaymentDate!), Colors.teal),
        if (sub.nextPaymentDate != null) _detailRow(Icons.schedule, 'Next Payment', DateFormat('dd MMM yyyy').format(sub.nextPaymentDate!), Colors.orange),
        _detailRow(Icons.check_circle, 'Status', sub.status.toUpperCase(), sub.status == 'active' ? Colors.green : Colors.orange),
      ])),
    );
  }

  Widget _buildDonorsTab() {
    if (_topDonors.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16), Text('No donors yet', style: TextStyle(color: Colors.grey.shade600)),
      ]));
    }
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _topDonors.length, itemBuilder: (context, index) {
      final donor = _topDonors[index];
      return Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: donor.isTopDonor ? Border.all(color: Colors.amber, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
        child: InkWell(
          onTap: () => _showDonorDetails(donor),
          child: Row(children: [
            Stack(children: [
              CircleAvatar(radius: 24, backgroundColor: primary.withOpacity(0.1),
                backgroundImage: donor.donorProfileImage != null ? NetworkImage(donor.donorProfileImage!) : null,
                child: donor.donorProfileImage == null ? Text(donor.donorName.isNotEmpty ? donor.donorName[0].toUpperCase() : 'A', style: TextStyle(color: primary, fontWeight: FontWeight.bold)) : null),
              if (donor.isTopDonor) Positioned(top: -2, right: -2, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.star, color: Colors.amber, size: 16))),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(donor.donorName.isEmpty ? 'Anonymous' : donor.donorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('#${index + 1}', style: TextStyle(fontSize: 10, color: primary, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.volunteer_activism, size: 12, color: Colors.grey.shade500), const SizedBox(width: 2),
                Text('${donor.donationCount} donations', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500), const SizedBox(width: 2),
                Flexible(child: Text('Since ${DateFormat('MMM yy').format(donor.firstDonation)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            const SizedBox(width: 8),
            Text(currencyFormat.format(donor.totalAmount), style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 14)),
          ]),
        ),
      );
    });
  }

  void _showDonorDetails(DonorSummary donor) {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        Row(children: [
          Stack(children: [
            CircleAvatar(radius: 35, backgroundColor: primary.withOpacity(0.1),
              backgroundImage: donor.donorProfileImage != null ? NetworkImage(donor.donorProfileImage!) : null,
              child: donor.donorProfileImage == null ? Text(donor.donorName.isNotEmpty ? donor.donorName[0].toUpperCase() : 'A', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 28)) : null),
            if (donor.isTopDonor) Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
              child: const Icon(Icons.star, color: Colors.white, size: 16))),
          ]),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(donor.donorName.isEmpty ? 'Anonymous Donor' : donor.donorName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (donor.donorEmail.isNotEmpty) Text(donor.donorEmail, style: TextStyle(color: Colors.grey.shade600)),
            if (donor.isTopDonor) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Text('⭐ Top Donor', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold))),
          ])),
        ]),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(currencyFormat.format(donor.totalAmount), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _donorStatCard('Total Donations', '${donor.donationCount}', Icons.volunteer_activism, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _donorStatCard('Member Since', DateFormat('MMM yyyy').format(donor.firstDonation), Icons.calendar_today, Colors.purple)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _donorStatCard('Last Donation', DateFormat('dd MMM yy').format(donor.lastDonation), Icons.history, Colors.teal)),
          const SizedBox(width: 12),
          Expanded(child: _donorStatCard('Avg. Donation', currencyFormat.format(donor.totalAmount / donor.donationCount), Icons.analytics, Colors.orange)),
        ]),
        const SizedBox(height: 20),
        if (donor.donorEmail.isNotEmpty)
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); _sendThankYouToDonor(donor); },
            icon: const Icon(Icons.mail), label: const Text('Send Thank You Email'), style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.all(14)))),
      ])),
    );
  }

  Widget _donorStatCard(String label, String value, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ]));
  }

  Future<void> _sendThankYou(MonthlyFundingData donation) async {
    final ngoEmail = widget.ngoEmail ?? 'noreply@ngoapp.com';
    final success = await EmailService.sendThankYouEmail(
      donorEmail: donation.donorEmail, donorName: donation.donorName, amount: donation.amount,
      campaignTitle: 'Monthly Donation - ${_formatCategoryName(donation.category)}',
      ngoName: widget.ngoName, donationDate: donation.donationDate, ngoEmail: ngoEmail,
    );
    if (success) {
      await _fundingService.markThankYouSent(donation.id);
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you email sent!'), backgroundColor: Colors.green));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send email'), backgroundColor: Colors.red));
    }
  }

  Future<void> _sendThankYouToDonor(DonorSummary donor) async {
    final ngoEmail = widget.ngoEmail ?? 'noreply@ngoapp.com';
    final success = await EmailService.sendThankYouEmail(
      donorEmail: donor.donorEmail, donorName: donor.donorName, amount: donor.totalAmount,
      campaignTitle: 'Monthly Donations', ngoName: widget.ngoName, donationDate: donor.lastDonation, ngoEmail: ngoEmail,
    );
    if (success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you email sent!'), backgroundColor: Colors.green));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send email'), backgroundColor: Colors.red));
    }
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedMonth, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDatePickerMode: DatePickerMode.year);
    if (picked != null) { setState(() => _selectedMonth = DateTime(picked.year, picked.month)); _loadData(); }
  }
}
