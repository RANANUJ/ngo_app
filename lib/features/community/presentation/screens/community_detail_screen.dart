import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/community.dart';
import '../../domain/models/community_post.dart';
import '../controllers/community_controller.dart';
import 'community_post_detail_screen.dart';
import 'create_post_screen.dart';
import 'edit_community_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String communityId;
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType;

  const CommunityDetailScreen({
    Key? key,
    required this.communityId,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
  }) : super(key: key);

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCommunityOptions(Community community) {
    final controller = context.read<CommunityController>();
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    final isCreator = community.creatorId == userId;

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
            if (isCreator) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: primary),
                title: const Text('Edit Community'),
                subtitle: const Text('Update name, description, privacy'),
                onTap: () {
                  Navigator.pop(context);
                  _editCommunity(community);
                },
              ),
              ListTile(
                leading: Icon(
                  community.isPublic ? Icons.lock : Icons.public,
                  color: Colors.orange,
                ),
                title: Text(
                  community.isPublic ? 'Make Private' : 'Make Public',
                ),
                subtitle: Text(
                  community.isPublic
                      ? 'Only invited members can join'
                      : 'Anyone can find and join',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _togglePrivacy(community, controller);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Community', style: TextStyle(color: Colors.red)),
                subtitle: const Text('This action cannot be undone'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteCommunity(controller);
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: Icon(Icons.share, color: Colors.grey.shade700),
              title: const Text('Share Community'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: Colors.grey.shade700),
              title: const Text('Report Community'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _editCommunity(Community community) async {
    // Navigate to EditCommunityScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCommunityScreen(
          communityId: widget.communityId,
          communityData: community.toMap()..['id'] = community.id,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _togglePrivacy(Community community, CommunityController controller) async {
    try {
      final newPrivacy = !community.isPublic;
      await controller.updateCommunity(
        communityId: widget.communityId,
        data: {'isPublic': newPrivacy},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newPrivacy ? 'Community is now Public' : 'Community is now Private',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _confirmDeleteCommunity(CommunityController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Community'),
        content: const Text(
          'Are you sure you want to delete this community? This will remove all posts, members, and data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCommunity(controller);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCommunity(CommunityController controller) async {
    try {
      await controller.deleteCommunity(communityId: widget.communityId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Community deleted'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting community: $e')),
        );
      }
    }
  }

  Future<void> _toggleMembership(bool isMember, CommunityController controller) async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      if (isMember) {
        // Leave community
        await controller.leaveCommunity(
          communityId: widget.communityId,
          userId: userId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left community')),
          );
        }
      } else {
        // Join community
        // Find default user info
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
          communityId: widget.communityId,
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CommunityController>();
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<Community?>(
      stream: controller.streamCommunity(widget.communityId),
      builder: (context, communitySnapshot) {
        if (communitySnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final community = communitySnapshot.data;
        if (community == null) {
          return const Scaffold(
            body: Center(child: Text('Community not found')),
          );
        }

        return StreamBuilder<bool>(
          stream: controller.streamMembership(widget.communityId, userId),
          builder: (context, membershipSnapshot) {
            final isMember = membershipSnapshot.data ?? false;

            return Scaffold(
              backgroundColor: const Color(0xFFF5F9FA),
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: primary,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () => _showCommunityOptions(community),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Cover Image
                          community.coverUrl.isNotEmpty
                              ? Image.network(
                                  community.coverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: primary,
                                  ),
                                )
                              : Container(color: primary),
                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                          // Community Info
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: community.imageUrl.isNotEmpty
                                        ? Image.network(
                                            community.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.group,
                                              color: primary,
                                              size: 30,
                                            ),
                                          )
                                        : const Icon(Icons.group, color: primary, size: 30),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        community.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            community.isPublic ? Icons.public : Icons.lock,
                                            color: Colors.white70,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${community.memberCount} members',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _toggleMembership(isMember, controller),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isMember ? Colors.white : primary,
                                    foregroundColor: isMember ? primary : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(isMember ? 'Joined' : 'Join'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                body: Column(
                  children: [
                    // Description
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        community.description,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Tab Bar
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: primary,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: primary,
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'About'),
                        ],
                      ),
                    ),
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPostsTab(isMember),
                          _buildAboutTab(community),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: isMember
                  ? FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatePostScreen(
                              userId: widget.userId,
                              userName: widget.userName,
                              userPhoto: widget.userPhoto,
                              userType: widget.userType,
                              communityId: widget.communityId,
                              communityName: community.name,
                            ),
                          ),
                        );
                      },
                      backgroundColor: primary,
                      child: const Icon(Icons.edit, color: Colors.white),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildPostsTab(bool isMember) {
    final controller = context.read<CommunityController>();

    return StreamBuilder<List<CommunityPost>>(
      stream: controller.streamCommunityPosts(communityId: widget.communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return _buildEmptyPosts(isMember);
        }

        return _buildPostsList(posts);
      },
    );
  }

  Widget _buildEmptyPosts(bool isMember) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          if (isMember) ...[
            const SizedBox(height: 8),
            Text(
              'Be the first to share something!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostsList(List<CommunityPost> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final userName = post.authorName.isEmpty ? 'User' : post.authorName;
    final userPhoto = post.authorPhoto;
    final content = post.content;
    final imageUrl = post.imageUrl;
    final createdAt = post.createdAt;
    final likesCount = post.likesCount;
    final commentsCount = post.commentsCount;
    final sharesCount = post.sharesCount;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityPostDetailScreen(
              postId: post.id,
              userId: widget.userId,
              userName: widget.userName,
              userPhoto: widget.userPhoto,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            ListTile(
              leading: CircleAvatar(
                backgroundColor: primary.withValues(alpha: 0.2),
                backgroundImage: userPhoto.isNotEmpty
                    ? NetworkImage(userPhoto)
                    : null,
                child: userPhoto.isEmpty
                    ? const Icon(Icons.person, color: primary)
                    : null,
              ),
              title: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _getTimeAgo(createdAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              trailing: IconButton(
                icon: Icon(Icons.more_horiz, color: Colors.grey.shade600),
                onPressed: () {},
              ),
            ),
            // Content
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            // Image
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildActionButton(
                    Icons.favorite_border,
                    '$likesCount Likes',
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    Icons.chat_bubble_outline,
                    '$commentsCount Comments',
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    Icons.share_outlined,
                    '$sharesCount Shares',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
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

  Widget _buildAboutTab(Community community) {
    final description = community.description.isEmpty ? 'No description' : community.description;
    final createdAt = community.createdAt;
    final creatorName = community.creatorName.isEmpty ? 'Unknown' : community.creatorName;
    final rules = community.rules;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Created by $creatorName',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Created on ${_formatDate(createdAt)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Rules Section
          if (rules.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Community Rules',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...rules.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: primary.withValues(alpha: 0.2),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
          // Members Section
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'See All',
                      style: const TextStyle(color: primary, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMembersList(),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    final controller = context.read<CommunityController>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.streamCommunityMembers(widget.communityId, limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return Text(
            'No members yet',
            style: TextStyle(color: Colors.grey.shade600),
          );
        }

        return Column(
          children: members.map((member) {
            final userName = member['userName'] ?? 'User';
            final userPhoto = member['userPhoto'] ?? '';
            final userType = member['userType'] ?? 'volunteer';

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: primary.withValues(alpha: 0.2),
                backgroundImage: userPhoto.isNotEmpty
                    ? NetworkImage(userPhoto)
                    : null,
                child: userPhoto.isEmpty
                    ? const Icon(Icons.person, color: primary)
                    : null,
              ),
              title: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                userType == 'ngo' ? 'NGO Member' : 'Volunteer',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
