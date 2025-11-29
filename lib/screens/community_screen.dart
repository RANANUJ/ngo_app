import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_detail_screen.dart';
import 'community_post_detail_screen.dart';
import 'create_community_screen.dart';
import 'create_post_screen.dart';
import 'community_events_screen.dart';
import 'ask_experts_screen.dart';
import 'all_communities_screen.dart';
import 'all_posts_screen.dart';

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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            // Search Bar
            _buildSearchBar(),
            // Tab Bar
            _buildTabBar(),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCommunityTab(),
                  _buildEventsTab(),
                  _buildAskExpertsTab(),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Community wisdom and support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.grey.shade600),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        decoration: InputDecoration(
          hintText: 'Search community, events, topic...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primary,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Community'),
          Tab(text: 'Events'),
          Tab(text: 'Ask the Experts'),
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
            // Popular Community Section
            _buildSectionHeader('Popular Community', () {
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
            // Your Community Section
            _buildSectionHeader('Your Community', () {
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
            // Recent Posts Section
            _buildSectionHeader('Recent Post', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllPostsScreen(
                    userId: widget.userId,
                    userName: widget.userName,
                    userPhoto: widget.userPhoto,
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            _buildRecentPosts(),
            const SizedBox(height: 80),
          ],
        ),
      ),
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
            child: Text(
              'See All',
              style: TextStyle(
                fontSize: 14,
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCommunities() {
    return SizedBox(
      height: 200,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('communities')
            .orderBy('membersCount', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final communities = snapshot.data?.docs ?? [];

          if (communities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No communities yet',
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
              final data = communities[index].data() as Map<String, dynamic>;
              data['id'] = communities[index].id;
              return _buildCommunityCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> community) {
    // Check both coverUrl and imageUrl - prefer coverUrl for card display
    final coverUrl = community['coverUrl'] ?? '';
    final profileUrl = community['imageUrl'] ?? '';
    final displayImage = coverUrl.isNotEmpty ? coverUrl : profileUrl;
    final name = community['name'] ?? 'Community';
    final membersCount = community['membersCount'] ?? 0;
    final isPublic = community['isPublic'] ?? true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(
              communityId: community['id'],
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
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Full Image with overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: displayImage.isNotEmpty
                        ? Image.network(
                            displayImage,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primary,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Icon(Icons.group, color: primary, size: 40),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Icon(Icons.group, color: primary, size: 40),
                            ),
                          ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  // Public/Private Badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPublic ? Colors.white.withOpacity(0.9) : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPublic ? Icons.public : Icons.lock,
                            color: isPublic ? Colors.grey.shade700 : Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPublic ? 'Public' : 'Private',
                            style: TextStyle(
                              color: isPublic ? Colors.grey.shade700 : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Name and Members at bottom
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$membersCount members',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Join Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () => _joinCommunity(community['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Join',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

    try {
      // Check if already a member
      final memberDoc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .get();

      if (memberDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are already a member')),
        );
        return;
      }

      // Add as member
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .set({
        'userId': userId,
        'userName': widget.userName ?? 'User',
        'userPhoto': widget.userPhoto,
        'userType': widget.userType,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Increment members count
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
          .update({
        'membersCount': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Joined community successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining community: $e')),
      );
    }
  }

  Widget _buildYourCommunities() {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    return SizedBox(
      height: 70,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('members')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final memberDocs = snapshot.data?.docs ?? [];

          if (memberDocs.isEmpty) {
            return Center(
              child: Text(
                'Join a community to see it here',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: memberDocs.length,
            itemBuilder: (context, index) {
              final communityRef = memberDocs[index].reference.parent.parent;
              return FutureBuilder<DocumentSnapshot>(
                future: communityRef?.get(),
                builder: (context, communitySnapshot) {
                  if (!communitySnapshot.hasData) {
                    return const SizedBox(width: 100);
                  }

                  final community = communitySnapshot.data!.data() as Map<String, dynamic>?;
                  if (community == null) return const SizedBox();

                  return _buildYourCommunityItem(
                    communitySnapshot.data!.id,
                    community['name'] ?? 'Community',
                    community['imageUrl'],
                    community['membersCount'] ?? 0,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildYourCommunityItem(String id, String name, String? imageUrl, int membersCount) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(
              communityId: id,
              userId: widget.userId,
              userName: widget.userName,
              userPhoto: widget.userPhoto,
              userType: widget.userType,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: primary.withOpacity(0.2),
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Icon(Icons.group, color: primary)
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$membersCount members',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No posts yet. Be the first to share!',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final data = posts[index].data() as Map<String, dynamic>;
            data['id'] = posts[index].id;
            return _buildPostCard(data);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final userName = post['userName'] ?? 'User';
    final userPhoto = post['userPhoto'];
    final communityName = post['communityName'] ?? '';
    final content = post['content'] ?? '';
    final createdAt = (post['createdAt'] as Timestamp?)?.toDate();
    final likesCount = post['likesCount'] ?? 0;
    final commentsCount = post['commentsCount'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityPostDetailScreen(
              postId: post['id'],
              userId: widget.userId,
              userName: widget.userName,
              userPhoto: widget.userPhoto,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: primary.withOpacity(0.2),
              backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                  ? NetworkImage(userPhoto)
                  : null,
              child: userPhoto == null || userPhoto.isEmpty
                  ? Icon(Icons.person, color: primary, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (communityName.isNotEmpty) ...[
                        Text(
                          ' · ',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        Text(
                          communityName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (createdAt != null)
                    Text(
                      _getTimeAgo(createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.home_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '$likesCount',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '$commentsCount',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildEventsTab() {
    return CommunityEventsScreen(
      userId: widget.userId,
      userName: widget.userName,
      userPhoto: widget.userPhoto,
      userType: widget.userType,
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
            ),
            _buildCreateOption(
              icon: Icons.help_outline,
              title: 'Ask Question',
              subtitle: 'Get help from experts',
              onTap: () {
                Navigator.pop(context);
                // Navigate to ask question screen
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
          color: primary.withOpacity(0.1),
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
