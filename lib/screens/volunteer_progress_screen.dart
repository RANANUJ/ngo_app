import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class VolunteerProgressScreen extends StatefulWidget {
  const VolunteerProgressScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerProgressScreen> createState() => _VolunteerProgressScreenState();
}

class _VolunteerProgressScreenState extends State<VolunteerProgressScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  
  late TabController _tabController;
  bool _isLoading = true;
  
  // User stats
  int _hoursVolunteered = 0;
  int _eventsAttended = 0;
  int _campaignsJoined = 0;
  int _ngosHelped = 0;
  int _totalDonated = 0;
  int _peopleImpacted = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalPoints = 0;
  String _currentLevel = 'Beginner';
  int _levelProgress = 0;
  
  // Badges
  List<Map<String, dynamic>> _earnedBadges = [];
  List<Map<String, dynamic>> _allBadges = [];
  
  // Activity history
  List<Map<String, dynamic>> _recentActivities = [];
  
  // Monthly stats
  Map<String, int> _monthlyHours = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProgressData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load user profile stats
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _hoursVolunteered = data['hoursVolunteered'] ?? 0;
          _eventsAttended = data['eventsJoined'] ?? 0;
          _totalDonated = data['totalDonated'] ?? 0;
          _ngosHelped = data['ngosFollowed'] ?? 0;
          _currentStreak = data['currentStreak'] ?? 0;
          _longestStreak = data['longestStreak'] ?? 0;
          _totalPoints = data['volunteerPoints'] ?? 0;
        });
      }

      // Load campaigns joined
      final campaigns = await FirebaseFirestore.instance
          .collection('campaign_participants')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      _campaignsJoined = campaigns.docs.length;

      // Load event registrations
      final events = await FirebaseFirestore.instance
          .collection('event_registrations')
          .where('userId', isEqualTo: user.uid)
          .where('attended', isEqualTo: true)
          .get();
      
      if (events.docs.isNotEmpty) {
        _eventsAttended = events.docs.length;
      }

      // Calculate level and progress
      _calculateLevel();
      
      // Load badges
      _loadBadges();
      
      // Load recent activities
      await _loadRecentActivities();
      
      // Generate monthly stats (mock for now, would come from activity logs)
      _generateMonthlyStats();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading progress: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateLevel() {
    // Calculate total impact score
    int impactScore = (_hoursVolunteered * 10) + 
                      (_eventsAttended * 20) + 
                      (_campaignsJoined * 30) + 
                      (_totalDonated ~/ 100);
    
    _totalPoints = impactScore;
    _peopleImpacted = (_hoursVolunteered * 5) + (_eventsAttended * 10);
    
    // Determine level
    if (impactScore >= 5000) {
      _currentLevel = 'Legend';
      _levelProgress = 100;
    } else if (impactScore >= 2500) {
      _currentLevel = 'Champion';
      _levelProgress = ((impactScore - 2500) / 2500 * 100).toInt();
    } else if (impactScore >= 1000) {
      _currentLevel = 'Expert';
      _levelProgress = ((impactScore - 1000) / 1500 * 100).toInt();
    } else if (impactScore >= 500) {
      _currentLevel = 'Intermediate';
      _levelProgress = ((impactScore - 500) / 500 * 100).toInt();
    } else if (impactScore >= 100) {
      _currentLevel = 'Beginner';
      _levelProgress = ((impactScore - 100) / 400 * 100).toInt();
    } else {
      _currentLevel = 'Newcomer';
      _levelProgress = (impactScore / 100 * 100).toInt();
    }
  }

  void _loadBadges() {
    // Define all available badges
    _allBadges = [
      {
        'id': 'first_event',
        'name': 'First Step',
        'description': 'Attended your first event',
        'icon': Icons.flag,
        'color': Colors.green,
        'requirement': 1,
        'type': 'events',
      },
      {
        'id': 'event_5',
        'name': 'Event Explorer',
        'description': 'Attended 5 events',
        'icon': Icons.explore,
        'color': Colors.blue,
        'requirement': 5,
        'type': 'events',
      },
      {
        'id': 'event_10',
        'name': 'Event Master',
        'description': 'Attended 10 events',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'requirement': 10,
        'type': 'events',
      },
      {
        'id': 'hours_10',
        'name': 'Dedicated',
        'description': 'Volunteered 10+ hours',
        'icon': Icons.access_time_filled,
        'color': Colors.purple,
        'requirement': 10,
        'type': 'hours',
      },
      {
        'id': 'hours_50',
        'name': 'Time Giver',
        'description': 'Volunteered 50+ hours',
        'icon': Icons.timer,
        'color': Colors.indigo,
        'requirement': 50,
        'type': 'hours',
      },
      {
        'id': 'hours_100',
        'name': 'Century Hero',
        'description': 'Volunteered 100+ hours',
        'icon': Icons.military_tech,
        'color': Colors.orange,
        'requirement': 100,
        'type': 'hours',
      },
      {
        'id': 'campaign_1',
        'name': 'Campaign Starter',
        'description': 'Joined your first campaign',
        'icon': Icons.campaign,
        'color': Colors.teal,
        'requirement': 1,
        'type': 'campaigns',
      },
      {
        'id': 'campaign_5',
        'name': 'Campaign Champion',
        'description': 'Joined 5 campaigns',
        'icon': Icons.stars,
        'color': Colors.red,
        'requirement': 5,
        'type': 'campaigns',
      },
      {
        'id': 'donor_first',
        'name': 'Generous Heart',
        'description': 'Made your first donation',
        'icon': Icons.favorite,
        'color': Colors.pink,
        'requirement': 1,
        'type': 'donations',
      },
      {
        'id': 'streak_7',
        'name': 'Week Warrior',
        'description': '7 day activity streak',
        'icon': Icons.local_fire_department,
        'color': Colors.deepOrange,
        'requirement': 7,
        'type': 'streak',
      },
      {
        'id': 'streak_30',
        'name': 'Monthly Master',
        'description': '30 day activity streak',
        'icon': Icons.whatshot,
        'color': Colors.red,
        'requirement': 30,
        'type': 'streak',
      },
      {
        'id': 'ngo_helper',
        'name': 'NGO Friend',
        'description': 'Connected with 3 NGOs',
        'icon': Icons.handshake,
        'color': Colors.cyan,
        'requirement': 3,
        'type': 'ngos',
      },
    ];

    // Check which badges are earned
    _earnedBadges = _allBadges.where((badge) {
      int current = 0;
      switch (badge['type']) {
        case 'events':
          current = _eventsAttended;
          break;
        case 'hours':
          current = _hoursVolunteered;
          break;
        case 'campaigns':
          current = _campaignsJoined;
          break;
        case 'donations':
          current = _totalDonated > 0 ? 1 : 0;
          break;
        case 'streak':
          current = _longestStreak;
          break;
        case 'ngos':
          current = _ngosHelped;
          break;
      }
      return current >= badge['requirement'];
    }).toList();
  }

  Future<void> _loadRecentActivities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<Map<String, dynamic>> activities = [];

    // Load event registrations
    final events = await FirebaseFirestore.instance
        .collection('event_registrations')
        .where('userId', isEqualTo: user.uid)
        .orderBy('registeredAt', descending: true)
        .limit(5)
        .get();

    for (var doc in events.docs) {
      final data = doc.data();
      activities.add({
        'type': 'event',
        'title': 'Registered for ${data['eventTitle'] ?? 'an event'}',
        'date': (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'icon': Icons.event,
        'color': Colors.blue,
        'points': 20,
      });
    }

    // Load campaign participations
    final campaigns = await FirebaseFirestore.instance
        .collection('campaign_participants')
        .where('userId', isEqualTo: user.uid)
        .orderBy('joinedAt', descending: true)
        .limit(5)
        .get();

    for (var doc in campaigns.docs) {
      final data = doc.data();
      activities.add({
        'type': 'campaign',
        'title': 'Joined ${data['campaignName'] ?? 'a campaign'}',
        'date': (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'icon': Icons.campaign,
        'color': Colors.green,
        'points': 30,
      });
    }

    // Sort by date
    activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    setState(() {
      _recentActivities = activities.take(10).toList();
    });
  }

  void _generateMonthlyStats() {
    // Generate last 6 months of stats (would come from actual activity logs)
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = months[month.month - 1];
      // Mock data - in real app, aggregate from activity logs
      _monthlyHours[monthKey] = (math.Random().nextInt(20) + (_hoursVolunteered > 0 ? 5 : 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildLevelCard()),
                SliverToBoxAdapter(child: _buildStatsGrid()),
                SliverToBoxAdapter(child: _buildStreakCard()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: primary,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Badges'),
                        Tab(text: 'Activity'),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildBadgesTab(),
                      _buildActivityTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareProgress,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'My Progress',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                primary.withOpacity(0.8),
                const Color(0xFF00BCD4),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getLevelColor(),
            _getLevelColor().withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getLevelColor().withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Icon(
                    _getLevelIcon(),
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentLevel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalPoints Impact Points',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_earnedBadges.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress to next level',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$_levelProgress%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _levelProgress / 100,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor() {
    switch (_currentLevel) {
      case 'Legend':
        return Colors.amber[700]!;
      case 'Champion':
        return Colors.purple;
      case 'Expert':
        return Colors.blue;
      case 'Intermediate':
        return Colors.green;
      case 'Beginner':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon() {
    switch (_currentLevel) {
      case 'Legend':
        return Icons.military_tech;
      case 'Champion':
        return Icons.emoji_events;
      case 'Expert':
        return Icons.star;
      case 'Intermediate':
        return Icons.trending_up;
      case 'Beginner':
        return Icons.eco;
      default:
        return Icons.person;
    }
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.access_time_filled,
                  value: '$_hoursVolunteered',
                  label: 'Hours',
                  color: Colors.purple,
                  subtitle: 'Volunteered',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.event_available,
                  value: '$_eventsAttended',
                  label: 'Events',
                  color: Colors.blue,
                  subtitle: 'Attended',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.campaign,
                  value: '$_campaignsJoined',
                  label: 'Campaigns',
                  color: Colors.green,
                  subtitle: 'Joined',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  value: '$_peopleImpacted',
                  label: 'People',
                  color: Colors.orange,
                  subtitle: 'Impacted',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required String subtitle,
  }) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            '$label\n$subtitle',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_currentStreak Day Streak',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Longest: $_longestStreak days',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                'This Week',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(7, (index) {
                  bool isActive = index < (_currentStreak % 7 == 0 ? 7 : _currentStreak % 7);
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? Colors.orange : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Activity Chart
          _buildSectionTitle('Monthly Activity'),
          const SizedBox(height: 12),
          _buildMonthlyChart(),
          const SizedBox(height: 24),
          
          // Impact Summary
          _buildSectionTitle('Your Impact'),
          const SizedBox(height: 12),
          _buildImpactCards(),
          const SizedBox(height: 24),
          
          // Goals
          _buildSectionTitle('Current Goals'),
          const SizedBox(height: 12),
          _buildGoalsSection(),
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
        color: Colors.black87,
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      height: 200,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hours Volunteered',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Last 6 months',
                  style: TextStyle(
                    fontSize: 11,
                    color: primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _monthlyHours.entries.map((entry) {
                double maxHeight = 100;
                double barHeight = (_monthlyHours.values.isNotEmpty)
                    ? (entry.value / (_monthlyHours.values.reduce(math.max) + 1)) * maxHeight
                    : 0;
                barHeight = math.max(barHeight, 5);
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.value}h',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 30,
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [primary, primary.withOpacity(0.6)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCards() {
    return Row(
      children: [
        Expanded(
          child: _buildImpactCard(
            icon: Icons.eco,
            title: 'Trees Planted',
            value: '${(_eventsAttended * 2)}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildImpactCard(
            icon: Icons.restaurant,
            title: 'Meals Served',
            value: '${(_hoursVolunteered * 3)}',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildImpactCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
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
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
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
        children: [
          _buildGoalItem(
            title: 'Volunteer 50 hours',
            current: _hoursVolunteered,
            target: 50,
            color: Colors.purple,
          ),
          const Divider(height: 24),
          _buildGoalItem(
            title: 'Attend 10 events',
            current: _eventsAttended,
            target: 10,
            color: Colors.blue,
          ),
          const Divider(height: 24),
          _buildGoalItem(
            title: 'Join 5 campaigns',
            current: _campaignsJoined,
            target: 5,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem({
    required String title,
    required int current,
    required int target,
    required Color color,
  }) {
    double progress = (current / target).clamp(0.0, 1.0);
    bool isCompleted = current >= target;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                if (isCompleted) const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
            Text(
              '$current / $target',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earned Badges
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Earned Badges (${_earnedBadges.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_earnedBadges.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No badges yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start volunteering to earn badges!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: _earnedBadges.length,
              itemBuilder: (context, index) {
                final badge = _earnedBadges[index];
                return _buildBadgeCard(badge, earned: true);
              },
            ),
          
          const SizedBox(height: 32),
          
          // Locked Badges
          Row(
            children: [
              Icon(Icons.lock, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                'Locked Badges (${_allBadges.length - _earnedBadges.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: _allBadges.where((b) => !_earnedBadges.contains(b)).length,
            itemBuilder: (context, index) {
              final lockedBadges = _allBadges.where((b) => !_earnedBadges.contains(b)).toList();
              final badge = lockedBadges[index];
              return _buildBadgeCard(badge, earned: false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge, {required bool earned}) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge, earned),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: earned ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: earned
              ? Border.all(color: (badge['color'] as Color).withOpacity(0.3), width: 2)
              : null,
          boxShadow: earned
              ? [
                  BoxShadow(
                    color: (badge['color'] as Color).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: earned
                        ? (badge['color'] as Color).withOpacity(0.1)
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    badge['icon'] as IconData,
                    color: earned ? badge['color'] as Color : Colors.grey[400],
                    size: 28,
                  ),
                ),
                if (!earned)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, color: Colors.white, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              badge['name'] as String,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: earned ? Colors.black87 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(Map<String, dynamic> badge, bool earned) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: earned
                    ? (badge['color'] as Color).withOpacity(0.1)
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                badge['icon'] as IconData,
                color: earned ? badge['color'] as Color : Colors.grey[400],
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge['name'] as String,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge['description'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: earned ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                earned ? '✓ Earned!' : 'Keep going to unlock!',
                style: TextStyle(
                  color: earned ? Colors.green[700] : Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return _recentActivities.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No activity yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your activities will appear here',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _recentActivities.length,
            itemBuilder: (context, index) {
              final activity = _recentActivities[index];
              return _buildActivityItem(activity, isLast: index == _recentActivities.length - 1);
            },
          );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, {required bool isLast}) {
    final date = activity['date'] as DateTime;
    final timeAgo = _getTimeAgo(date);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activity['icon'] as IconData,
                  color: activity['color'] as Color,
                  size: 20,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${activity['points']} pts',
                          style: TextStyle(
                            fontSize: 11,
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _shareProgress() {
    // Would implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share feature coming soon!'),
        backgroundColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
