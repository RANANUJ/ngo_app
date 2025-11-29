import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ngo_registration_service.dart';
import '../services/local_storage_service.dart';
import 'user_type_screen.dart';
import 'ngo_public_profile_screen.dart';
import 'ngo_volunteers_screen.dart';
import 'create_campaign_screen.dart';
import 'campaign_list_screen.dart';
import 'government_schemes_screen.dart';
import 'ngo_opportunities_screen.dart';
import 'event_calendar_screen.dart';

class NgoHomeScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;
  
  const NgoHomeScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<NgoHomeScreen> createState() => _NgoHomeScreenState();
}

class _NgoHomeScreenState extends State<NgoHomeScreen> {
  static const Color primary = Color(0xFF0099B8);
  int _selectedIndex = 0;
  String? _ngoLogo;
  bool _isRefreshing = false;
  
  // Data variables for real-time updates
  int _campaignsCount = 0;
  int _opportunitiesCount = 0;
  int _volunteersCount = 0;
  Map<String, dynamic>? _ngoData;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadNgoLogo(),
      _loadCampaignsCount(),
      _loadOpportunitiesCount(),
      _loadVolunteersCount(),
      _loadNgoDetails(),
    ]);
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadAllData();
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed successfully'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _loadCampaignsCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .get();
      if (mounted) {
        setState(() => _campaignsCount = snapshot.docs.length);
      }
    } catch (e) {
      debugPrint('Error loading campaigns count: $e');
    }
  }

  Future<void> _loadOpportunitiesCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('volunteer_opportunities')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .get();
      if (mounted) {
        setState(() => _opportunitiesCount = snapshot.docs.length);
      }
    } catch (e) {
      debugPrint('Error loading opportunities count: $e');
    }
  }

  Future<void> _loadVolunteersCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('volunteer_requests')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .where('status', isEqualTo: 'accepted')
          .get();
      if (mounted) {
        setState(() => _volunteersCount = snapshot.docs.length);
      }
    } catch (e) {
      debugPrint('Error loading volunteers count: $e');
    }
  }

  Future<void> _loadNgoDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .doc(widget.ngoData.id)
          .get();
      if (doc.exists && mounted) {
        setState(() => _ngoData = doc.data());
      }
    } catch (e) {
      debugPrint('Error loading NGO details: $e');
    }
  }

  Future<void> _loadNgoLogo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .doc(widget.ngoData.id)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _ngoLogo = data['ngoLogo'] ?? widget.ngoData.profileImageUrl;
        });
      }
    } catch (e) {
      debugPrint('Error loading NGO logo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildExploreTab();
      case 2:
        return _buildCreateTab();
      case 3:
        return _buildCommunityTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with NGO Info
            _buildHeader(),
            
            const SizedBox(height: 20),
            
            // Quick Task Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQuickTaskBar(),
            ),
            
            const SizedBox(height: 24),
            
            // Features Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFeaturesGrid(),
            ),
            
            const SizedBox(height: 24),
            
            // Event Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildEventBanner(),
            ),
            
            const SizedBox(height: 24),
            
            // Book Demo Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDemoButton(),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Check if NGO has uploaded a profile image - prioritize _ngoLogo from Firestore
    final String? profileImageUrl = _ngoLogo ?? widget.ngoData.profileImageUrl;
    final bool hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // NGO Profile Image with Verified Badge
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withOpacity(0.1),
                  image: hasProfileImage
                      ? DecorationImage(
                          image: NetworkImage(profileImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasProfileImage
                    ? null
                    : Center(
                        child: Icon(
                          Icons.person,
                          color: primary,
                          size: 32,
                        ),
                      ),
              ),
              Positioned(
                bottom: -2,
                left: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified,
                    color: primary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          
          // NGO Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ngoData.ngoName.isNotEmpty 
                      ? widget.ngoData.ngoName 
                      : 'Your NGO',
                  style: TextStyle(
                    color: primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.ngoData.missionVision.isNotEmpty
                      ? widget.ngoData.missionVision
                      : 'Empowering lives, building futures',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${widget.ngoData.registrationNo.isNotEmpty ? widget.ngoData.registrationNo : 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Icons
          Column(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: Colors.amber.shade700),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.campaign_outlined, color: primary),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTaskBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickTaskItem('assets/icons8-task-completed-48.png', 'Quick Task', null),
          _buildQuickTaskItem('assets/shield.png', 'Event Calendar', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventCalendarScreen(
                  ngoId: widget.ngoData.id!,
                  ngoName: widget.ngoData.ngoName,
                ),
              ),
            );
          }),
          _buildQuickTaskItem('assets/progress (1).png', 'Progress', null),
          _buildQuickTaskItem('assets/new-user.png', 'Add Admin', null),
        ],
      ),
    );
  }

  Widget _buildQuickTaskItem(String imagePath, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            imagePath,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    // Light cyan background color for all cards
    final Color cardBgColor = const Color(0xFFE8F6F8);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildFeatureCardWithImage('assets/Email campaign-amico.png', 'Campaign', cardBgColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildFeatureCardWithImage('assets/Charity-cuate.png', 'Donation', cardBgColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildFeatureCardWithImage('assets/Team spirit-pana.png', 'Volunteer', cardBgColor)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildFeatureCardWithImage('assets/Shared goals-amico.png', 'Collaboration', cardBgColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildFeatureCardWithImage('assets/—Pngtree—government icon_4270824.png', 'Govt. Schemes', cardBgColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildFeatureCardWithImage('assets/Online connection-rafiki.png', 'Connection', cardBgColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCardWithImage(String imagePath, String label, Color bgColor) {
    return GestureDetector(
      onTap: () => _onFeatureCardTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image, color: primary, size: 35);
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String label, Color bgColor, Color iconColor) {
    return GestureDetector(
      onTap: () => _onFeatureCardTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBanner() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Light Orange/Peach Left Section
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8CC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.people_outline,
                  color: Colors.orange.shade600,
                  size: 32,
                ),
              ),
            ),
          ),
          
          // Event Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '27 FEBRUARY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'INTERNATIONAL NGO DAY',
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Let's remember the power of a single meal to change a child's life.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
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

  Widget _buildDemoButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Book a Demo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildExploreTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Explore NGOs & Campaigns',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildCreateOption(
            Icons.campaign,
            'Create Campaign',
            'Start a new fundraising campaign',
            primary,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateCampaignScreen(
                  ngoId: widget.ngoData.id,
                  ngoName: widget.ngoData.ngoName,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCreateOption(Icons.event, 'Create Event', 'Organize a volunteer event', primary, () {}),
          const SizedBox(height: 12),
          _buildCreateOption(Icons.article, 'Post Update', 'Share news with your community', primary, () {}),
          const SizedBox(height: 12),
          _buildCreateOption(Icons.photo_library, 'Share Gallery', 'Upload photos of your work', primary, () {}),
        ],
      ),
    );
  }

  Widget _buildCreateOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Community Coming Soon',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _onFeatureCardTap(String label) {
    switch (label) {
      case 'Volunteer':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NgoVolunteersScreen(
              ngoId: widget.ngoData.id,
              ngoName: widget.ngoData.ngoName,
            ),
          ),
        );
        break;
      case 'Campaign':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampaignListScreen(
              ngoId: widget.ngoData.id,
            ),
          ),
        );
        break;
      case 'Govt. Schemes':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GovernmentSchemesScreen(),
          ),
        );
        break;
      case 'Collaboration':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NgoOpportunitiesScreen(
              ngoId: widget.ngoData.id,
              ngoName: widget.ngoData.ngoName,
            ),
          ),
        );
        break;
      case 'Donation':
      case 'Connection':
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label - Coming Soon!'),
            duration: const Duration(seconds: 1),
          ),
        );
        break;
    }
  }

  Widget _buildProfileTab() {
    // Check if NGO has uploaded a profile image - prioritize _ngoLogo from Firestore
    final String? profileImageUrl = _ngoLogo ?? widget.ngoData.profileImageUrl;
    final bool hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header Card with Edit Button
          Container(
            width: double.infinity,
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
                // Profile Image with Camera Edit Button
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
                      child: hasProfileImage
                          ? ClipOval(
                              child: Image.network(
                                profileImageUrl,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.person, size: 50, color: primary);
                                },
                              ),
                            )
                          : Icon(Icons.person, size: 50, color: primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
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
                  widget.ngoData.ngoName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Verified NGO',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Edit Profile Button
                OutlinedButton.icon(
                  onPressed: _editProfile,
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
          const SizedBox(height: 16),

          // How volunteers see your NGO - Preview Box
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NgoPublicProfileScreen(
                    ngoData: widget.ngoData,
                    isEditable: true,
                  ),
                ),
              );
              // Reload logo after returning from profile edit
              _loadNgoLogo();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.visibility,
                      color: primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How volunteers see your NGO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Preview and update your public profile',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistics Overview Card
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem(Icons.campaign, '0', 'Campaigns', Colors.blue),
                    _buildStatItem(Icons.volunteer_activism, '0', 'Volunteers', Colors.green),
                    _buildStatItem(Icons.currency_rupee, '0', 'Donations', Colors.orange),
                    _buildStatItem(Icons.event, '0', 'Events', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // NGO Details Card
          Container(
            width: double.infinity,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NGO Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _editProfile,
                      icon: Icon(Icons.edit, color: primary, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailItem(Icons.badge, 'Registration No', widget.ngoData.registrationNo),
                _buildDetailItem(Icons.business, 'Type', widget.ngoData.ngoType),
                _buildDetailItem(Icons.category, 'Category', widget.ngoData.category),
                _buildDetailItem(Icons.phone, 'Phone', widget.ngoData.mobileNo),
                _buildDetailItem(Icons.email, 'Email', widget.ngoData.email),
                _buildDetailItem(Icons.location_on, 'Address', widget.ngoData.headOfficeAddress),
                _buildDetailItem(Icons.calendar_today, 'Established', widget.ngoData.yearOfEstablishment),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Documents Section
          Container(
            width: double.infinity,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _manageDocuments,
                      icon: Icon(Icons.folder_open, color: primary, size: 18),
                      label: Text('Manage', style: TextStyle(color: primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDocumentItem('Registration Certificate', widget.ngoData.registrationCertUploaded),
                _buildDocumentItem('PAN Card', widget.ngoData.panCardUploaded),
                _buildDocumentItem('12A/80G Certificate', widget.ngoData.certificate12A80GUploaded),
                _buildDocumentItem('ID Proof', widget.ngoData.idProofUploaded),
                _buildDocumentItem('Past Work Proof', widget.ngoData.pastWorkProofUploaded),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Container(
            width: double.infinity,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionItem(Icons.share, 'Share Profile', 'Share your NGO profile', _shareProfile),
                _buildActionItem(Icons.qr_code, 'QR Code', 'Generate donation QR', _generateQRCode),
                _buildActionItem(Icons.download, 'Download Certificate', 'Get verification certificate', _downloadCertificate),
                _buildActionItem(Icons.analytics, 'View Reports', 'Analytics & insights', _viewReports),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings & Support
          Container(
            width: double.infinity,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings & Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionItem(Icons.notifications, 'Notifications', 'Manage notifications', _notificationSettings),
                _buildActionItem(Icons.lock, 'Privacy & Security', 'Password & security', _privacySettings),
                _buildActionItem(Icons.help_outline, 'Help & Support', 'Get help', _helpSupport),
                _buildActionItem(Icons.info_outline, 'About App', 'Version & info', _aboutApp),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =============== PROFILE HELPER WIDGETS ===============

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String name, bool uploaded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: uploaded ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              uploaded ? Icons.check_circle : Icons.pending,
              color: uploaded ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            uploaded ? 'Verified' : 'Pending',
            style: TextStyle(
              color: uploaded ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============== PROFILE ACTION METHODS ===============

  void _pickProfileImage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Update Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera feature coming soon!')),
                  );
                }),
                _buildImageSourceOption(Icons.photo_library, 'Gallery', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gallery feature coming soon!')),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Profile - Coming Soon!')),
    );
  }

  void _manageDocuments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document Management - Coming Soon!')),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share Profile - Coming Soon!')),
    );
  }

  void _generateQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Donation QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.qr_code_2, size: 150, color: primary),
            ),
            const SizedBox(height: 16),
            Text(
              widget.ngoData.ngoName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Scan to donate',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR Code downloaded!')),
              );
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _downloadCertificate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Certificate Download - Coming Soon!')),
    );
  }

  void _viewReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reports & Analytics - Coming Soon!')),
    );
  }

  void _notificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification Settings - Coming Soon!')),
    );
  }

  void _privacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy Settings - Coming Soon!')),
    );
  }

  void _helpSupport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help & Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSupportOption(Icons.email, 'Email Support', 'support@ngoconnect.com'),
            _buildSupportOption(Icons.phone, 'Phone Support', '+91 1800-XXX-XXXX'),
            _buildSupportOption(Icons.chat, 'Live Chat', 'Available 9 AM - 6 PM'),
            _buildSupportOption(Icons.help, 'FAQs', 'Browse common questions'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: primary),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title - Coming Soon!')),
        );
      },
    );
  }

  void _aboutApp() {
    showAboutDialog(
      context: context,
      applicationName: 'NGO Connect',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.volunteer_activism, color: primary, size: 48),
      ),
      children: [
        const Text(
          'NGO Connect helps NGOs manage their activities, connect with volunteers, and receive donations seamlessly.',
        ),
        const SizedBox(height: 16),
        Text(
          '© 2024 NGO Connect. All rights reserved.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
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
      final localStorageService = LocalStorageService();
      await localStorageService.clearNgoLogin();
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
