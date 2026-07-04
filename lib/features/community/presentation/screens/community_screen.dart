import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/community.dart';
import '../../domain/models/community_post.dart';
import '../controllers/community_controller.dart';
import 'community_detail_screen.dart';
import 'community_post_detail_screen.dart';
import 'create_community_screen.dart';
import 'create_post_screen.dart';
import 'ask_experts_screen.dart';
import 'all_communities_screen.dart';
import 'all_posts_screen.dart';
import 'post_feed_screen.dart';
import 'community_settings_screen.dart';
import 'package:ngo_app/features/profile/domain/models/user_profile.dart';
import 'package:ngo_app/features/profile/presentation/screens/unified_edit_profile_screen.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';
import 'joined_communities_screen.dart';
import 'points_history_sheet.dart';
import 'video_player_widget.dart';
import 'package:ngo_app/screens/volunteer/volunteer_settings_screen.dart';

class CommunityScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType; // 'ngo' or 'volunteer'

  const CommunityScreen({
    Key? key,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
  }) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            // Tab Bar
            _buildTabBar(),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  KeepAliveWrapper(child: _buildCommunityTab()),
                  KeepAliveWrapper(child: _buildProfileTab()),
                  KeepAliveWrapper(child: _buildAskExpertsTab()),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateOptions,
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.25,
                ),
                children: [
                  TextSpan(text: 'Community '),
                  TextSpan(
                    text: 'wisdom\n',
                    style: TextStyle(color: primary),
                  ),
                  TextSpan(text: 'and support'),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _tabController.index == 1 ? Icons.settings : Icons.favorite_border,
              color: Colors.grey.shade800,
              size: 24,
            ),
            onPressed: () {
              if (_tabController.index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunitySettingsScreen(
                      userId: widget.userId ?? FirebaseAuth.instance.currentUser!.uid,
                      userType: widget.userType,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JoinedCommunitiesScreen(
                      userId: widget.userId,
                      userName: widget.userName,
                      userPhoto: widget.userPhoto,
                      userType: widget.userType,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: TabBar(
        controller: _tabController,
        labelColor: primary,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: primary,
        indicatorWeight: 3,
        isScrollable: false,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 18),
                SizedBox(width: 4),
                Text('Community'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline_rounded, size: 18),
                SizedBox(width: 4),
                Text('Profile'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 16),
                SizedBox(width: 4),
                Text('Ask Expert'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      color: primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Search Bar and Filter
            _buildSearchBar(),
            
            const SizedBox(height: 16),
            
            // Promo Banner
            _buildPromoBanner(),
            
            const SizedBox(height: 20),
            
            // Categories Row
            _buildCategoriesRow(),
            
            const SizedBox(height: 24),
            
            // Popular Communities Section
            _buildSectionHeader('Popular Communities', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllCommunitiesScreen(
                    userId: widget.userId,
                    userName: widget.userName,
                    userPhoto: widget.userPhoto,
                    userType: widget.userType,
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            _buildPopularCommunities(),
            
            const SizedBox(height: 24),
            
            // Your Communities Section
            _buildSectionHeader('Your Communities', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllCommunitiesScreen(
                    userId: widget.userId,
                    userName: widget.userName,
                    userPhoto: widget.userPhoto,
                    userType: widget.userType,
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            _buildYourCommunities(),
            
            const SizedBox(height: 24),
            
            // Ask Expert Banner at the bottom
            _buildAskExpertPromoCard(),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search communities...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 22),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE0F4F7),
            const Color(0xFFE8F6F8),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBECEF).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Left side
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.25,
                    ),
                    children: [
                      TextSpan(text: 'Together we can\ncreate '),
                      TextSpan(
                        text: 'real change',
                        style: TextStyle(color: primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join communities, share ideas and support meaningful causes.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllCommunitiesScreen(
                            userId: widget.userId,
                            userName: widget.userName,
                            userPhoto: widget.userPhoto,
                            userType: widget.userType,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore Communities',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right side (illustration of connected users)
          Expanded(
            flex: 4,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center circle (main community icon)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.people_alt, color: Colors.white, size: 22),
                  ),
                  // Surrounding avatar 1 (Top-Left)
                  Positioned(
                    top: 10,
                    left: 5,
                    child: _buildSurroundingAvatar('https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100', 30),
                  ),
                  // Surrounding avatar 2 (Top-Right)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: _buildSurroundingAvatar('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100', 34),
                  ),
                  // Surrounding avatar 3 (Bottom-Right)
                  Positioned(
                    bottom: 15,
                    right: 0,
                    child: _buildSurroundingAvatar('https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100', 32),
                  ),
                  // Surrounding avatar 4 (Bottom-Left)
                  Positioned(
                    bottom: 0,
                    left: 20,
                    child: _buildSurroundingAvatar('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100', 26),
                  ),
                  // Connective decorations
                  // Little heart overlay
                  Positioned(
                    top: 40,
                    left: 0,
                    child: Icon(Icons.favorite, color: primary.withValues(alpha: 0.7), size: 12),
                  ),
                  // Little comment message overlay
                  Positioned(
                    top: 30,
                    right: 5,
                    child: Icon(Icons.chat_bubble, color: primary.withValues(alpha: 0.6), size: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurroundingAvatar(String url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.person, color: Colors.white, size: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesRow() {
    final categories = [
      {'name': 'Environment', 'icon': Icons.local_florist_rounded, 'defaultCount': 24},
      {'name': 'Health', 'icon': Icons.favorite_rounded, 'defaultCount': 18},
      {'name': 'Education', 'icon': Icons.school_rounded, 'defaultCount': 30},
      {'name': 'Social Help', 'icon': Icons.handshake_rounded, 'defaultCount': 22},
      {'name': 'Animals', 'icon': Icons.pets_rounded, 'defaultCount': 16},
    ];

    final controller = context.read<CommunityController>();

    return StreamBuilder<List<Community>>(
      stream: controller.streamCommunities(),
      builder: (context, snapshot) {
        final communities = snapshot.data ?? [];
        
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catName = cat['name'] as String;
              final isSelected = _selectedCategory.toLowerCase() == catName.toLowerCase();
              
              final count = communities.isEmpty
                  ? cat['defaultCount']
                  : communities.where((c) => c.category.toLowerCase() == catName.toLowerCase()).length;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategory = '';
                    } else {
                      _selectedCategory = catName;
                    }
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE0F4F7) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primary : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        color: isSelected ? primary : Colors.grey.shade700,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        catName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primary : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count Communities',
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? primary.withValues(alpha: 0.8) : Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 10, color: primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCommunities() {
    final controller = context.read<CommunityController>();

    return SizedBox(
      height: 215,
      child: StreamBuilder<List<Community>>(
        stream: controller.streamCommunities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SkeletonContainer(width: 160, height: 200),
              ),
            );
          }

          final searchQuery = _searchController.text.toLowerCase();
          var communities = snapshot.data ?? [];
          
          if (searchQuery.isNotEmpty) {
            communities = communities.where((c) => c.name.toLowerCase().contains(searchQuery)).toList();
          }
          
          if (_selectedCategory.isNotEmpty) {
            communities = communities.where((c) => c.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
          }

          if (communities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No communities found',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return _buildCommunityCard(community);
            },
          );
        },
      ),
    );
  }

  Widget _buildCommunityCard(Community community, {bool isJoined = false}) {
    final profileUrl = community.imageUrl;
    final name = community.name;
    final tagline = community.description.isNotEmpty ? community.description : 'Makes a difference';
    final membersCount = community.memberCount;
    final isPublic = community.isPublic;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(
              communityId: community.id,
              userId: widget.userId,
              userName: widget.userName,
              userPhoto: widget.userPhoto,
              userType: widget.userType,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPublic ? Icons.public : Icons.lock,
                      color: Colors.grey.shade500,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isPublic ? 'Public' : 'Private',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isJoined)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F4F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: primary,
                          size: 9,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'Joined',
                          style: TextStyle(
                            color: primary,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE0F4F7),
              backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
              child: profileUrl.isEmpty
                  ? const Icon(Icons.group, color: primary, size: 28)
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.verified, color: primary, size: 13),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              tagline,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(
                  '$membersCount Members',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: isJoined
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommunityDetailScreen(
                              communityId: community.id,
                              userId: widget.userId,
                              userName: widget.userName,
                              userPhoto: widget.userPhoto,
                              userType: widget.userType,
                            ),
                          ),
                        );
                      }
                    : () => _joinCommunity(community.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined ? Colors.white : primary,
                  foregroundColor: isJoined ? primary : Colors.white,
                  elevation: 0,
                  side: isJoined ? const BorderSide(color: primary, width: 1) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  isJoined ? 'View' : 'Join',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinCommunity(String communityId) async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final controller = context.read<CommunityController>();

    try {
      final user = FirebaseAuth.instance.currentUser;
      String userName = widget.userName ?? user?.displayName ?? 'User';
      String userPhoto = widget.userPhoto ?? user?.photoURL ?? '';

      final volunteerDoc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(userId)
          .get();
      if (volunteerDoc.exists) {
        final data = volunteerDoc.data()!;
        userName = data['displayName'] ?? userName;
        userPhoto = data['photoUrl'] ?? userPhoto;
      }

      await controller.joinCommunity(
        communityId: communityId,
        userId: userId,
        userName: userName,
        userLogo: userPhoto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined community successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining community: $e')),
        );
      }
    }
  }

  Widget _buildYourCommunities() {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    final controller = context.read<CommunityController>();

    return SizedBox(
      height: 215,
      child: StreamBuilder<List<Community>>(
        stream: controller.streamCommunities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SkeletonContainer(width: 160, height: 200),
              ),
            );
          }

          var communities = snapshot.data ?? [];
          communities = communities.where((c) => c.creatorId == userId).toList();

          if (communities.isEmpty) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Center(
                child: Text(
                  'Create a community to see it here',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return _buildCommunityCard(community, isJoined: true);
            },
          );
        },
      ),
    );
  }

  Widget _buildAskExpertPromoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F5F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.question_mark_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need advice or have a question?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Connect with experts and community members who can help.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(2);
            },
            icon: const Icon(Icons.chat_bubble_outline, size: 13),
            label: const Text(
              'Ask an Expert',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildProfileTab() {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Header
          _buildProfileHeader(userId),
          const SizedBox(height: 24),
          // User Posts list
          _buildUserPostsList(userId),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String? userId) {
    final controller = context.read<CommunityController>();

    return StreamBuilder<DocumentSnapshot>(
      stream: widget.userType == 'ngo'
          ? FirebaseFirestore.instance.collection('ngo_registrations').doc(userId).snapshots()
          : FirebaseFirestore.instance.collection('volunteers').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String userName = widget.userName ?? 'User';
        String? photoUrl = widget.userPhoto;
        String bio = '';
        String city = '';
        String state = '';
        int points = 120;
        
        UserProfile? currentProfile;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            userName = data['displayName'] ?? data['ngoName'] ?? userName;
            photoUrl = data['photoUrl'] ?? data['ngoLogo'] ?? data['profileImageUrl'] ?? photoUrl;
            bio = data['bio'] ?? data['missionVision'] ?? '';
            city = data['city'] ?? '';
            state = data['state'] ?? '';
            points = data['points'] ?? data['volunteerPoints'] ?? points;
            currentProfile = UserProfile.fromMap(userId!, widget.userType, data);
          }
        }

        final location = [city, state].where((s) => s.isNotEmpty).join(', ');
        final finalLocation = location.isNotEmpty ? location : 'Kangra, Himachal Pradesh';
        final finalBio = bio.isNotEmpty ? bio : 'Passionate about making a positive impact through volunteering and community support.';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Icon(
                                    widget.userType == 'ngo' ? Icons.business : Icons.person,
                                    size: 46,
                                    color: primary,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0099B8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: primary,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.userType == 'ngo'
                                ? const Color(0xFFE0F2FE)
                                : const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.userType == 'ngo' ? 'NGO' : 'Volunteer',
                            style: TextStyle(
                              color: widget.userType == 'ngo' ? const Color(0xFF0284C7) : const Color(0xFF9333EA),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0F2FE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF0284C7),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  finalLocation,
                                  style: const TextStyle(
                                    color: Color(0xFF0284C7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          finalBio,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (currentProfile != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UnifiedEditProfileScreen(
                            currentProfile: currentProfile!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 14, color: primary),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primary, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: StreamBuilder<List<CommunityPost>>(
                        stream: controller.streamCommunityPosts(),
                        builder: (context, postSnapshot) {
                          final allPosts = postSnapshot.data ?? [];
                          final userPostsCount = allPosts.where((p) => p.authorId == userId).length;
                          return _buildStatItem(
                            icon: Icons.edit_note_rounded,
                            value: '$userPostsCount',
                            label: 'Posts',
                          );
                        },
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JoinedCommunitiesScreen(
                                userId: widget.userId,
                                userName: widget.userName,
                                userPhoto: widget.userPhoto,
                                userType: widget.userType,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collectionGroup('members').snapshots(),
                          builder: (context, snapshot) {
                            final allDocs = snapshot.data?.docs ?? [];
                            final userCommsCount = allDocs.where((doc) => doc.id == userId).length;
                            return _buildStatItem(
                              icon: Icons.people_outline_rounded,
                              value: '$userCommsCount',
                              label: 'Communities',
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => PointsHistorySheet(
                              userId: userId!,
                              currentPoints: points,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: _buildStatItem(
                          icon: Icons.emoji_events_outlined,
                          value: '$points',
                          label: 'Points',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primary,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUserPostsList(String? userId) {
    final controller = context.read<CommunityController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Posts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list, size: 16, color: primary),
                    SizedBox(width: 4),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 13,
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<CommunityPost>>(
          stream: controller.streamCommunityPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListSkeleton(itemCount: 2, height: 100);
            }

            var allPosts = snapshot.data ?? [];
            final posts = allPosts.where((p) => p.authorId == userId).toList();

            if (posts.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.post_add, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No posts yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: posts.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildProfilePostCard(post, posts, index);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfilePostCard(CommunityPost post, List<CommunityPost> posts, int index) {
    final imageUrl = post.imageUrl ?? '';
    final videoUrl = post.videoUrl ?? '';
    final hasVideo = videoUrl.isNotEmpty;
    final content = post.content;
    final likesCount = post.likesCount;
    final commentsCount = post.commentsCount;
    final timeStr = _getTimeAgo(post.createdAt);

    final textSegments = <TextSpan>[];
    final words = content.split(' ');
    final regularTextBuffer = StringBuffer();

    for (var word in words) {
      if (word.startsWith('#')) {
        if (regularTextBuffer.isNotEmpty) {
          textSegments.add(TextSpan(text: regularTextBuffer.toString()));
          regularTextBuffer.clear();
        }
        textSegments.add(TextSpan(
          text: '$word ',
          style: const TextStyle(color: primary, fontWeight: FontWeight.bold),
        ));
      } else {
        regularTextBuffer.write('$word ');
      }
    }
    if (regularTextBuffer.isNotEmpty) {
      textSegments.add(TextSpan(text: regularTextBuffer.toString()));
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostFeedScreen(
              posts: posts,
              initialIndex: index,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE0F4F7),
                  backgroundImage: post.authorPhoto.isNotEmpty ? NetworkImage(post.authorPhoto) : null,
                  child: post.authorPhoto.isEmpty
                      ? const Icon(Icons.person, color: primary, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName.isNotEmpty ? post.authorName : 'Kartik Rana',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade500, size: 20),
                  onPressed: () {},
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: textSegments.isNotEmpty
                    ? textSegments
                    : [TextSpan(text: content)],
              ),
            ),
            const SizedBox(height: 12),
            if (imageUrl.isNotEmpty || hasVideo)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : VideoThumbnailPlayer(
                        videoUrl: videoUrl,
                        width: double.infinity,
                        height: 200,
                      ),
              ),
            if (imageUrl.isNotEmpty || hasVideo) const SizedBox(height: 16),
            Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '$likesCount',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '$commentsCount',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.share_outlined, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Share',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 14, color: Color(0xFF0284C7)),
                      SizedBox(width: 4),
                      Text(
                        'View Insights',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAskExpertsTab() {
    return AskExpertsScreen(
      userId: widget.userId,
      userName: widget.userName,
      userPhoto: widget.userPhoto,
      userType: widget.userType,
    );
  }

  void _showCreateOptions() {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create New',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildCreateOption(
              icon: Icons.group_add,
              title: 'Create Community',
              subtitle: 'Start a new community group',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateCommunityScreen(
                      userId: widget.userId,
                      userName: widget.userName,
                      userPhoto: widget.userPhoto,
                      userType: widget.userType,
                    ),
                  ),
                );
              },
            ),
            _buildCreateOption(
              icon: Icons.post_add,
              title: 'Create Post',
              subtitle: 'Share with the community',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostScreen(
                      userId: widget.userId,
                      userName: widget.userName,
                      userPhoto: widget.userPhoto,
                      userType: widget.userType,
                    ),
                  ),
                );
              },
            ),            _buildCreateOption(
              icon: Icons.help_outline,
              title: 'Ask Question',
              subtitle: 'Get help from experts',
              onTap: () {
                Navigator.pop(context);
                // Trigger Ask Experts tab and show dialog
                _tabController.animateTo(2);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
