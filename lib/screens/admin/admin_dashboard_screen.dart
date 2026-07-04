import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';
import 'ngo_details_screen.dart';
import 'user_details_screen.dart';
import 'announcements_screen.dart';
import 'settings_details_screen.dart';
import 'review_ngo_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color primaryColor = Color(0xFF0099B8);
  final NgoRegistrationService _registrationService = NgoRegistrationService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  // Search & Filter parameters
  final TextEditingController _ngoSearchController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  String _selectedNgoFilter = 'All';
  String _selectedUserFilter = 'All';

  @override
  void dispose() {
    _ngoSearchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  // Combined stream to fetch both volunteers and admins
  Stream<List<Map<String, dynamic>>> _streamAllUsers() {
    return FirebaseFirestore.instance.collection('volunteers').snapshots().asyncExpand((volSnap) {
      return FirebaseFirestore.instance.collection('admins').snapshots().map((adminSnap) {
        final List<Map<String, dynamic>> combined = [];
        for (final doc in adminSnap.docs) {
          combined.add({
            'id': doc.id,
            'collection': 'admins',
            ...doc.data(),
          });
        }
        for (final doc in volSnap.docs) {
          combined.add({
            'id': doc.id,
            'collection': 'volunteers',
            ...doc.data(),
          });
        }
        return combined;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      drawer: _buildDrawer(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.business_outlined), label: 'NGOs'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline_outlined), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
      body: _buildCurrentTabContent(),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'NGOs List';
      case 2:
        return 'System Users';
      case 3:
        return 'Performance Reports';
      default:
        return 'Console Settings';
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: primaryColor),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings, color: primaryColor, size: 40),
            ),
            accountName: const Text('NGO Application Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? 'admin@ngoapp.com'),
          ),
          ListTile(
            leading: const Icon(Icons.campaign_outlined, color: primaryColor),
            title: const Text('Announcements'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AnnouncementsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_toggle_off, color: primaryColor),
            title: const Text('Activity Log'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsDetailsScreen(settingName: 'Activity Log')));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pop(context); // Close Drawer
                Navigator.pop(context); // Pop Dashboard to Login Screen
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildNgosTab();
      case 2:
        return _buildUsersTab();
      case 3:
        return _buildReportsTab();
      default:
        return _buildSettingsTab();
    }
  }

  // ================= TAB 1: DASHBOARD TAB =================
  Widget _buildDashboardTab() {
    return StreamBuilder<List<NgoRegistrationRequest>>(
      stream: _registrationService.registrationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminDashboardSkeleton();
        }

        final registrations = snapshot.data ?? [];
        final total = registrations.length;
        final pending = registrations.where((r) => r.status == RegistrationStatus.pending).length;
        final approved = registrations.where((r) => r.status == RegistrationStatus.approved).length;
        final rejected = registrations.where((r) => r.status == RegistrationStatus.rejected).length;

        final recentApplications = registrations.take(5).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hello Header
            const Row(
              children: [
                Text(
                  'Hello, Admin 👋',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statistics Grid
            Row(
              children: [
                _buildStatItemCard('Total NGOs', '$total', Icons.business, Colors.blue),
                const SizedBox(width: 12),
                _buildStatItemCard('Verified', '$approved', Icons.verified, Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItemCard('Pending', '$pending', Icons.pending_actions, Colors.orange),
                const SizedBox(width: 12),
                _buildStatItemCard('Reported', '$rejected', Icons.report_problem, Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionBtn(Icons.assignment_outlined, 'Review NGOs', () {
                    setState(() {
                      _currentIndex = 1;
                      _selectedNgoFilter = 'Pending';
                    });
                  }),
                  _buildQuickActionBtn(Icons.verified_user_outlined, 'Verify NGO', () {
                    if (registrations.any((r) => r.status == RegistrationStatus.pending)) {
                      final firstPending = registrations.firstWhere((r) => r.status == RegistrationStatus.pending);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReviewNgoScreen(request: firstPending)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No pending NGOs to verify.')),
                      );
                    }
                  }),
                  _buildQuickActionBtn(Icons.person_outline, 'Users Manager', () => setState(() => _currentIndex = 2)),
                  _buildQuickActionBtn(Icons.analytics_outlined, 'Reports Data', () => setState(() => _currentIndex = 3)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Applications Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Applications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text('View All', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            recentApplications.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('No applications received yet.')),
                    ),
                  )
                : Column(
                    children: recentApplications.map((req) => _buildNgoListTile(req)).toList(),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildStatItemCard(String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  // ================= TAB 2: NGOS TAB =================
  Widget _buildNgosTab() {
    return StreamBuilder<List<NgoRegistrationRequest>>(
      stream: _registrationService.registrationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final registrations = snapshot.data ?? [];

        // Apply filters
        final searchQuery = _ngoSearchController.text.toLowerCase();
        final filteredList = registrations.where((ngo) {
          final matchesSearch = ngo.ngoName.toLowerCase().contains(searchQuery) ||
              ngo.email.toLowerCase().contains(searchQuery);

          bool matchesStatus = true;
          if (_selectedNgoFilter == 'Pending') {
            matchesStatus = ngo.status == RegistrationStatus.pending;
          } else if (_selectedNgoFilter == 'Verified') {
            matchesStatus = ngo.status == RegistrationStatus.approved;
          } else if (_selectedNgoFilter == 'Rejected') {
            matchesStatus = ngo.status == RegistrationStatus.rejected;
          }

          return matchesSearch && matchesStatus;
        }).toList();

        return Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _ngoSearchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search NGOs by name...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Horizontal status tab selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: ['All', 'Pending', 'Verified', 'Rejected'].map((tab) {
                  final isSelected = _selectedNgoFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selectedColor: primaryColor,
                      backgroundColor: Colors.white,
                      label: Text(tab, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedNgoFilter = tab),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Expanded List View
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No NGOs match filters.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return _buildNgoListTile(filteredList[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNgoListTile(NgoRegistrationRequest ngo) {
    Color statusColor;
    switch (ngo.status) {
      case RegistrationStatus.approved:
        statusColor = Colors.green;
        break;
      case RegistrationStatus.rejected:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NgoDetailsScreen(request: ngo)),
          );
        },
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: primaryColor.withOpacity(0.1),
          backgroundImage: ngo.profileImageUrl != null && ngo.profileImageUrl!.isNotEmpty
              ? NetworkImage(ngo.profileImageUrl!)
              : null,
          child: ngo.profileImageUrl == null || ngo.profileImageUrl!.isEmpty
              ? const Icon(Icons.business, color: primaryColor, size: 20)
              : null,
        ),
        title: Text(ngo.ngoName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(ngo.category, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            ngo.status.name.toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ================= TAB 3: USERS TAB =================
  Widget _buildUsersTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final users = snapshot.data ?? [];

        // Apply filters
        final searchQuery = _userSearchController.text.toLowerCase();
        final filteredList = users.where((usr) {
          final name = (usr['displayName'] ?? usr['ngoName'] ?? usr['name'] ?? 'User').toString().toLowerCase();
          final email = (usr['email'] ?? '').toString().toLowerCase();
          final matchesSearch = name.contains(searchQuery) || email.contains(searchQuery);

          bool matchesTab = true;
          final role = (usr['role'] ?? (usr['collection'] == 'admins' ? 'Admin' : 'Volunteer')).toString().toLowerCase();
          if (_selectedUserFilter == 'Admins') {
            matchesTab = role == 'admin';
          } else if (_selectedUserFilter == 'Reviewers') {
            matchesTab = role == 'reviewer';
          } else if (_selectedUserFilter == 'Others') {
            matchesTab = role != 'admin' && role != 'reviewer';
          }

          return matchesSearch && matchesTab;
        }).toList();

        return Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _userSearchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search users by name or email...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Tabs Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: ['All', 'Admins', 'Reviewers', 'Others'].map((tab) {
                  final isSelected = _selectedUserFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selectedColor: primaryColor,
                      backgroundColor: Colors.white,
                      label: Text(tab, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedUserFilter = tab),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Expanded List View
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No users match filters.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final usr = filteredList[index];
                        final name = usr['displayName'] ?? usr['ngoName'] ?? usr['name'] ?? 'User';
                        final email = usr['email'] ?? '';
                        final photoUrl = usr['photoUrl'] ?? usr['profileImageUrl'] ?? '';
                        final role = usr['role'] ?? (usr['collection'] == 'admins' ? 'Admin' : 'Volunteer');
                        final isActive = usr['status'] == 'Active' || usr['isActive'] != false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade100),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailsScreen(
                                    userData: usr,
                                    userId: usr['id'],
                                    collectionName: usr['collection'] ?? 'volunteers',
                                  ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: primaryColor.withOpacity(0.1),
                              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                              child: photoUrl.isEmpty
                                  ? const Icon(Icons.person, color: primaryColor, size: 18)
                                  : null,
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            subtitle: Text('$role • $email', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'BLOCKED',
                                style: TextStyle(
                                  color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ================= TAB 4: REPORTS TAB =================
  Widget _buildReportsTab() {
    return StreamBuilder<List<NgoRegistrationRequest>>(
      stream: _registrationService.registrationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final registrations = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Database Insights', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),

            // Chart 1: Registration Trend over Months
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NGO Registration Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text('Registrations submitted over the last 6 months.', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                    const SizedBox(height: 24),
                    _buildRegistrationTrendChart(registrations),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chart 2: Category Distribution
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top NGO Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text('Distribution of NGOs by registration focus category.', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                    const SizedBox(height: 24),
                    _buildCategoryChart(registrations),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRegistrationTrendChart(List<NgoRegistrationRequest> registrations) {
    final now = DateTime.now();
    final monthsData = List.generate(6, (index) {
      final targetMonth = DateTime(now.year, now.month - index, 1);
      final count = registrations.where((r) => r.submittedAt.year == targetMonth.year && r.submittedAt.month == targetMonth.month).length;
      return MapEntry(targetMonth, count);
    }).reversed.toList();

    return AspectRatio(
      aspectRatio: 1.8,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < monthsData.length) {
                    final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][monthsData[idx].key.month - 1];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(monthName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(monthsData.length, (index) {
                return FlSpot(index.toDouble(), monthsData[index].value.toDouble());
              }),
              isCurved: true,
              color: primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(List<NgoRegistrationRequest> registrations) {
    final counts = <String, int>{};
    for (final r in registrations) {
      if (r.category.isNotEmpty) {
        counts[r.category] = (counts[r.category] ?? 0) + 1;
      }
    }
    final sortedCategories = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayCategories = sortedCategories.take(4).toList();

    if (displayCategories.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No categories available yet.')),
      );
    }

    return AspectRatio(
      aspectRatio: 1.8,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < displayCategories.length) {
                    final cat = displayCategories[idx].key;
                    final shortCat = cat.length > 8 ? '${cat.substring(0, 7)}...' : cat;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(shortCat, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(displayCategories.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: displayCategories[index].value.toDouble(),
                  color: primaryColor,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ================= TAB 5: SETTINGS TAB =================
  Widget _buildSettingsTab() {
    final settingsList = [
      {'title': 'General Settings', 'icon': Icons.tune},
      {'title': 'Notification Settings', 'icon': Icons.notifications_none},
      {'title': 'Verification Settings', 'icon': Icons.verified_user_outlined},
      {'title': 'Document Settings', 'icon': Icons.description_outlined},
      {'title': 'Email Templates', 'icon': Icons.email_outlined},
      {'title': 'Security Settings', 'icon': Icons.security},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: settingsList.length,
      itemBuilder: (context, index) {
        final item = settingsList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsDetailsScreen(settingName: item['title'] as String),
                ),
              );
            },
            leading: Icon(item['icon'] as IconData, color: primaryColor),
            title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ),
        );
      },
    );
  }
}
