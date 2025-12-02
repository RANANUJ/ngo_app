import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../user_type_screen.dart';
import '../discover_ngo_screen.dart';
import '../campaign_list_screen.dart';
import '../government_schemes_screen.dart';
import 'volunteer_opportunities_screen.dart';
import '../community_screen.dart';
import 'volunteer_donation_screen.dart';
import 'volunteer_csr_screen.dart';
import '../ngo/ngo_explore_screen.dart';
import 'volunteer_events_screen.dart';
import 'volunteer_progress_screen.dart';
import 'volunteer_sos_screen.dart';
import '../../services/cache_service.dart';
import '../../services/notification_service.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerDashboardScreen> createState() => _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  static const Color primary = Color(0xFF0099B8);
  int _currentIndex = 0;
  
  // User ID - cached on init
  String? _userId;
  
  // Profile data
  String? _profilePhotoUrl;
  String _userName = 'User';
  String _userEmail = '';
  String _userPhone = '';
  String _userBio = '';
  String _userLocation = '';
  
  // Stats
  int _eventsJoined = 0;
  int _ngosFollowed = 0;
  int _totalDonated = 0;
  int _hoursVolunteered = 0;
  int _campaignsJoined = 0;
  
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    // Cache userId immediately
    _userId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('VolunteerDashboard: User ID = $_userId');
    _loadUserProfile();
    _preloadData();
    _initializeVolunteerNotifications();
  }

  Future<void> _initializeVolunteerNotifications() async {
    if (_userId != null) {
      await NotificationService().updateVolunteerFcmToken(_userId!);
    }
  }

  Future<void> _preloadData() async {
    // Preload data in background for smoother navigation
    DataPreloader().preloadAllData();
    
    // Preload NGO logos from discover screen
    _preloadNgoLogos();
  }

  Future<void> _preloadNgoLogos() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .where('status', isEqualTo: 'approved')
          .limit(20)
          .get();

      final imageUrls = <String>[];
      for (final doc in snapshot.docs) {
        final logoUrl = doc.data()['ngoLogo'];
        if (logoUrl != null && logoUrl.toString().isNotEmpty) {
          imageUrls.add(logoUrl);
        }
      }
      
      await CacheService().preloadNetworkImages(imageUrls);
      debugPrint('Preloaded ${imageUrls.length} NGO logos');
    } catch (e) {
      debugPrint('Error preloading NGO logos: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('VolunteerDashboard: No Firebase user found');
      return;
    }
    
    // Update userId if not set
    _userId ??= user.uid;

    try {
      // Load profile from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _profilePhotoUrl = data['photoUrl'] ?? user.photoURL;
          _userName = data['displayName'] ?? user.displayName ?? 'User';
          _userEmail = data['email'] ?? user.email ?? '';
          _userPhone = data['phone'] ?? '';
          _userBio = data['bio'] ?? '';
          _userLocation = data['location'] ?? '';
          _eventsJoined = data['eventsJoined'] ?? 0;
          _ngosFollowed = data['ngosFollowed'] ?? 0;
          _totalDonated = data['totalDonated'] ?? 0;
          _hoursVolunteered = data['hoursVolunteered'] ?? 0;
        });
      } else {
        // Create initial profile document
        await FirebaseFirestore.instance
            .collection('volunteers')
            .doc(user.uid)
            .set({
          'displayName': user.displayName ?? 'User',
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'phone': '',
          'bio': '',
          'location': '',
          'eventsJoined': 0,
          'ngosFollowed': 0,
          'totalDonated': 0,
          'hoursVolunteered': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _userName = user.displayName ?? 'User';
          _userEmail = user.email ?? '';
          _profilePhotoUrl = user.photoURL;
        });
      }

      // Load campaigns joined count
      final campaignsCount = await FirebaseFirestore.instance
          .collection('campaign_participants')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      setState(() {
        _campaignsJoined = campaignsCount.docs.length;
        _isLoadingProfile = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  String get userName => _userName.split(' ').first;

  String? get userPhotoUrl => _profilePhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _buildCurrentTab(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildExploreTab();
      case 2:
        return _buildMyFeedTab();
      case 3:
        return _buildCommunityTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Future<void> _refreshDashboard() async {
    // Reload all data
    await _loadUserProfile();
    // Trigger rebuild
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      color: primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Quick Actions (Events, Progress, Report Help, SOS)
            _buildQuickActions(),
            
            const SizedBox(height: 24),
            
            // Live Events Section Title
            _buildLiveEventsSection(),
            
            // Live Events Scrollable Cards
            _buildLiveEventsCards(),
            
            const SizedBox(height: 24),
            
            // Features Grid
            _buildFeaturesGrid(),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
              image: userPhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(userPhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: userPhotoUrl == null ? const Color(0xFFE0F4F7) : null,
            ),
            child: userPhotoUrl == null
                ? Icon(Icons.person, color: primary, size: 32)
                : null,
          ),
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $userName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0099B8),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ready to make in difference',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Notification Bell
          Icon(
            Icons.notifications,
            color: const Color(0xFFFFB800),
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuickActionWithImage(
            imagePath: 'assets/shield.png',
            label: 'Events',
            hasBadge: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VolunteerEventsScreen()),
            ),
          ),
          _buildQuickActionWithImage(
            imagePath: 'assets/progress (1).png',
            label: 'Progress',
            hasBadge: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VolunteerProgressScreen()),
            ),
          ),
          _buildQuickActionWithImage(
            imagePath: null,
            icon: Icons.people_outline,
            label: 'Report Help',
            hasBadge: true,
            onTap: () => _showComingSoon('Report Help'),
          ),
          _buildSOSButton(),
        ],
      ),
    );
  }

  Widget _buildQuickActionWithImage({
    String? imagePath,
    IconData? icon,
    required String label,
    required bool hasBadge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F4F7),
                  shape: BoxShape.circle,
                  border: Border.all(color: primary.withOpacity(0.3), width: 1.5),
                ),
                child: Center(
                  child: imagePath != null
                      ? Image.asset(
                          imagePath,
                          width: 28,
                          height: 28,
                          color: primary,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image, color: primary, size: 28),
                        )
                      : Icon(icon, color: primary, size: 28),
                ),
              ),
              if (hasBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () => _showSOSDialog(),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SOS',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveEventsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Live Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9800),
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VolunteerEventsScreen()),
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0099B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLiveEventsCards() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildImageEventCard(
            width: 180,
            imageUrl: 'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?w=400',
            overlayText: 'DONATION',
          ),
          const SizedBox(width: 12),
          _buildImageEventCard(
            width: 220,
            imageUrl: 'https://images.unsplash.com/photo-1593113630400-ea4288922497?w=400',
            date: '27 FEBRUARY',
            title: 'INTERNATIONAL NGO DAY',
            subtitle: "Let's remember the power of a single meal to change a child's life.",
            showJoinButton: true,
          ),
          const SizedBox(width: 12),
          _buildImageEventCard(
            width: 180,
            imageUrl: 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=400',
            overlayText: 'FOOD DRIVE',
          ),
        ],
      ),
    );
  }

  Widget _buildImageEventCard({
    required String imageUrl,
    double? width,
    String? overlayText,
    String? date,
    String? title,
    String? subtitle,
    bool showJoinButton = false,
  }) {
    return GestureDetector(
      onTap: () => _showComingSoon('Event Details'),
      child: Container(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
              if (showJoinButton)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              if (date != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            if (overlayText != null && !showJoinButton)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    overlayText,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (showJoinButton && title != null)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Join now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
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



  Widget _buildFeaturesGrid() {
    final features = [
      {
        'image': 'assets/Splash-BG.png',
        'label': 'Discover NGO',
        'bgColor': const Color(0xFFE0F4F7),
      },
      {
        'image': 'assets/—Pngtree—donation box and charity concept_8902949.png',
        'label': 'Donation Now',
        'bgColor': const Color(0xFFE0F4F7),
      },
      {
        'image': 'assets/—Pngtree—government icon_4270824.png',
        'label': 'Govt Prog.',
        'bgColor': const Color(0xFFE0F4F7),
      },
      {
        'image': 'assets/Office work-rafiki.png',
        'label': 'Job / Intern',
        'bgColor': const Color(0xFFE0F4F7),
      },
      {
        'image': 'assets/59dc768a-35a9-43a6-92a0-4406043b7d7e.png',
        'label': 'CSR Integration',
        'bgColor': const Color(0xFFE0F4F7),
      },
      {
        'image': 'assets/volunteer-2729696_640.png',
        'label': 'Volunteer',
        'bgColor': const Color(0xFFE0F4F7),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return _buildFeatureCard(
            imagePath: feature['image'] as String,
            label: feature['label'] as String,
            bgColor: feature['bgColor'] as Color,
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard({
    required String imagePath,
    required String label,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: () => _handleFeatureTap(label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                width: 75,
                height: 75,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image, color: primary, size: 35),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFeatureTap(String label) {
    if (label == 'Discover NGO') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DiscoverNgoScreen()),
      );
    } else if (label == 'Volunteer') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CampaignListScreen(isVolunteerView: true),
        ),
      );
    } else if (label == 'Govt Prog.') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GovernmentSchemesScreen(),
        ),
      );
    } else if (label == 'Donation Now') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VolunteerDonationScreen(),
        ),
      );
    } else if (label == 'CSR Integration') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VolunteerCsrScreen(),
        ),
      );
    } else {
      _showComingSoon(label);
    }
  }

  Widget _buildExploreTab() {
    return const VolunteerOpportunitiesScreen(isEmbedded: true);
  }

  Widget _buildMyFeedTab() {
    return NgoExploreScreen(userId: _userId);
  }

  Widget _buildCommunityTab() {
    return CommunityScreen(
      userId: _userId,
      userName: _userName,
      userPhoto: _profilePhotoUrl,
      userType: 'volunteer',
    );
  }

  Widget _buildProfileTab() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      color: primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Image with Edit
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withOpacity(0.1),
                          border: Border.all(color: primary.withOpacity(0.3), width: 3),
                        ),
                        child: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  _profilePhotoUrl!,
                                  fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.person, size: 50, color: primary),
                              ),
                            )
                          : Icon(Icons.person, size: 50, color: primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadProfilePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                if (_userLocation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _userLocation,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_userBio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _userBio,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Stats - Real-time data
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('$_campaignsJoined', 'Campaigns\nJoined', Colors.blue),
                    _buildStatItem('$_ngosFollowed', 'NGOs\nFollowed', Colors.green),
                    _buildStatItem('₹$_totalDonated', 'Total\nDonated', Colors.orange),
                    _buildStatItem('$_hoursVolunteered', 'Hours\nVolunteered', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Achievements Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Your Impact',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _campaignsJoined > 0
                      ? 'Great job! You\'ve joined $_campaignsJoined campaign${_campaignsJoined > 1 ? 's' : ''} so far.'
                      : 'Start your journey by joining a campaign!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_campaignsJoined / 10).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
                const SizedBox(height: 4),
                Text(
                  '${((_campaignsJoined / 10) * 100).clamp(0, 100).toInt()}% to next badge',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Menu Items
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMenuItem(Icons.campaign, 'My Campaigns', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CampaignListScreen(isVolunteerView: true),
                    ),
                  );
                }),
                _buildMenuDivider(),
                _buildMenuItem(Icons.history, 'Donation History', () => _showComingSoon('Donation History')),
                _buildMenuDivider(),
                _buildMenuItem(Icons.event_available, 'My Events', () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VolunteerEventsScreen()),
                  );
                }),
                _buildMenuDivider(),
                _buildMenuItem(Icons.favorite_border, 'Saved NGOs', () => _showComingSoon('Saved NGOs')),
                _buildMenuDivider(),
                _buildMenuItem(Icons.notifications_outlined, 'Notifications', () => _showComingSoon('Notifications')),
                _buildMenuDivider(),
                _buildMenuItem(Icons.settings, 'Settings', () => _showComingSoon('Settings')),
                _buildMenuDivider(),
                _buildMenuItem(Icons.help_outline, 'Help & Support', () => _showComingSoon('Help')),
                _buildMenuDivider(),
                _buildMenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', () => _showComingSoon('Privacy Policy')),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Divider(height: 1, color: Colors.grey.shade200, indent: 56);
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pop(context);
        return;
      }

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('volunteer_photos')
          .child('${user.uid}.jpg');

      await ref.putFile(File(image.path));
      final photoUrl = await ref.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(user.uid)
          .update({'photoUrl': photoUrl});

      // Update Firebase Auth profile
      await user.updatePhotoURL(photoUrl);

      setState(() {
        _profilePhotoUrl = photoUrl;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating photo: $e')),
      );
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final phoneController = TextEditingController(text: _userPhone);
    final bioController = TextEditingController(text: _userBio);
    final locationController = TextEditingController(text: _userLocation);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Tell us about yourself...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateProfile(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                bio: bioController.text.trim(),
                location: locationController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile({
    required String name,
    required String phone,
    required String bio,
    required String location,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(user.uid)
          .update({
        'displayName': name,
        'phone': phone,
        'bio': bio,
        'location': location,
      });

      // Update Firebase Auth display name
      await user.updateDisplayName(name);

      setState(() {
        _userName = name;
        _userPhone = phone;
        _userBio = bio;
        _userLocation = location;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
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
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primary),
      title: Text(title),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home, Icons.home_outlined, 'Home'),
          _buildNavItem(1, Icons.explore, Icons.explore_outlined, 'Explore'),
          _buildNavItem(2, Icons.dynamic_feed, Icons.dynamic_feed_outlined, 'My Feed'),
          _buildNavItem(3, Icons.groups, Icons.groups_outlined, 'Community'),
          _buildNavItem(4, Icons.person, Icons.person_outline, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F4F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? primary : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? primary : Colors.grey.shade500,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSOSDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VolunteerSOSScreen(
          odid: _userId ?? '',
          odname: _userName,
        ),
      ),
    );
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserTypeScreen()),
          (route) => false,
        );
      }
    }
  }
}

