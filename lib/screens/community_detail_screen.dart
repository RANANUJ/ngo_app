import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isMember = false;
  bool _isLoading = true;
  bool _isCreator = false;
  Map<String, dynamic>? _communityData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCommunityData();
    _checkMembership();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunityData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .get();

      if (doc.exists) {
        final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
        setState(() {
          _communityData = doc.data();
          _isCreator = _communityData?['creatorId'] == userId;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkMembership() async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final memberDoc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('members')
        .doc(userId)
        .get();

    setState(() => _isMember = memberDoc.exists);
  }

  void _showCommunityOptions() {
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
            if (_isCreator) ...[
              ListTile(
                leading: Icon(Icons.edit, color: primary),
                title: const Text('Edit Community'),
                subtitle: const Text('Update name, description, privacy'),
                onTap: () {
                  Navigator.pop(context);
                  _editCommunity();
                },
              ),
              ListTile(
                leading: Icon(
                  _communityData?['isPublic'] == true ? Icons.lock : Icons.public,
                  color: Colors.orange,
                ),
                title: Text(
                  _communityData?['isPublic'] == true 
                      ? 'Make Private' 
                      : 'Make Public',
                ),
                subtitle: Text(
                  _communityData?['isPublic'] == true 
                      ? 'Only invited members can join' 
                      : 'Anyone can find and join',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _togglePrivacy();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Community', style: TextStyle(color: Colors.red)),
                subtitle: const Text('This action cannot be undone'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteCommunity();
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

  void _editCommunity() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCommunityScreen(
          communityId: widget.communityId,
          communityData: _communityData!,
        ),
      ),
    );

    if (result == true) {
      _loadCommunityData();
    }
  }

  Future<void> _togglePrivacy() async {
    try {
      final newPrivacy = !(_communityData?['isPublic'] ?? true);
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .update({'isPublic': newPrivacy});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newPrivacy 
                ? 'Community is now Public' 
                : 'Community is now Private',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadCommunityData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _confirmDeleteCommunity() {
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
              _deleteCommunity();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCommunity() async {
    try {
      // Delete all members
      final members = await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .collection('members')
          .get();

      for (var doc in members.docs) {
        await doc.reference.delete();
      }

      // Delete all posts in this community
      final posts = await FirebaseFirestore.instance
          .collection('community_posts')
          .where('communityId', isEqualTo: widget.communityId)
          .get();

      for (var doc in posts.docs) {
        await doc.reference.delete();
      }

      // Delete the community
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Community deleted'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting community: $e')),
      );
    }
  }

  Future<void> _toggleMembership() async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      if (_isMember) {
        // Leave community
        await FirebaseFirestore.instance
            .collection('communities')
            .doc(widget.communityId)
            .collection('members')
            .doc(userId)
            .delete();

        await FirebaseFirestore.instance
            .collection('communities')
            .doc(widget.communityId)
            .update({
          'membersCount': FieldValue.increment(-1),
        });

        setState(() => _isMember = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left community')),
        );
      } else {
        // Join community
        await FirebaseFirestore.instance
            .collection('communities')
            .doc(widget.communityId)
            .collection('members')
            .doc(userId)
            .set({
          'userId': userId,
          'userName': widget.userName ?? 'User',
          'userPhoto': widget.userPhoto,
          'userType': widget.userType,
          'joinedAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('communities')
            .doc(widget.communityId)
            .update({
          'membersCount': FieldValue.increment(1),
        });

        setState(() => _isMember = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined community successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadCommunityData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _communityData?['name'] ?? 'Community';
    final description = _communityData?['description'] ?? '';
    final imageUrl = _communityData?['imageUrl'] ?? '';
    final coverUrl = _communityData?['coverUrl'] ?? '';
    final membersCount = _communityData?['membersCount'] ?? 0;
    final isPublic = _communityData?['isPublic'] ?? true;

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
                onPressed: _showCommunityOptions,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover Image
                  coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
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
                          Colors.black.withOpacity(0.7),
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
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.group,
                                      color: primary,
                                      size: 30,
                                    ),
                                  )
                                : Icon(Icons.group, color: primary, size: 30),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    isPublic ? Icons.public : Icons.lock,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$membersCount members',
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
                          onPressed: _toggleMembership,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isMember ? Colors.white : primary,
                            foregroundColor: _isMember ? primary : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(_isMember ? 'Joined' : 'Join'),
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
                description,
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
                  _buildPostsTab(),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isMember
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
                      communityName: name,
                    ),
                  ),
                );
              },
              backgroundColor: primary,
              child: const Icon(Icons.edit, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .where('communityId', isEqualTo: widget.communityId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Handle index error
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community_posts')
                .where('communityId', isEqualTo: widget.communityId)
                .snapshots(),
            builder: (context, fallbackSnapshot) {
              if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var posts = fallbackSnapshot.data?.docs ?? [];
              posts = List.from(posts)..sort((a, b) {
                final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
                final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              if (posts.isEmpty) {
                return _buildEmptyPosts();
              }

              return _buildPostsList(posts);
            },
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return _buildEmptyPosts();
        }

        return _buildPostsList(posts);
      },
    );
  }

  Widget _buildEmptyPosts() {
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
          if (_isMember) ...[
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

  Widget _buildPostsList(List<QueryDocumentSnapshot> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final data = posts[index].data() as Map<String, dynamic>;
        data['id'] = posts[index].id;
        return _buildPostCard(data);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final userName = post['userName'] ?? 'User';
    final userPhoto = post['userPhoto'];
    final content = post['content'] ?? '';
    final imageUrl = post['imageUrl'];
    final createdAt = (post['createdAt'] as Timestamp?)?.toDate();
    final likesCount = post['likesCount'] ?? 0;
    final commentsCount = post['commentsCount'] ?? 0;
    final sharesCount = post['sharesCount'] ?? 0;

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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                backgroundColor: primary.withOpacity(0.2),
                backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                    ? NetworkImage(userPhoto)
                    : null,
                child: userPhoto == null || userPhoto.isEmpty
                    ? Icon(Icons.person, color: primary)
                    : null,
              ),
              title: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: createdAt != null
                  ? Text(
                      _getTimeAgo(createdAt),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    )
                  : null,
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

  Widget _buildAboutTab() {
    final description = _communityData?['description'] ?? 'No description';
    final createdAt = (_communityData?['createdAt'] as Timestamp?)?.toDate();
    final creatorName = _communityData?['creatorName'] ?? 'Unknown';
    final rules = _communityData?['rules'] as List<dynamic>? ?? [];

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
                if (createdAt != null) ...[
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
                            backgroundColor: primary.withOpacity(0.2),
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
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
                      style: TextStyle(color: primary, fontSize: 14),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .collection('members')
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data?.docs ?? [];

        if (members.isEmpty) {
          return Text(
            'No members yet',
            style: TextStyle(color: Colors.grey.shade600),
          );
        }

        return Column(
          children: members.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: primary.withOpacity(0.2),
                backgroundImage: data['userPhoto'] != null && data['userPhoto'].isNotEmpty
                    ? NetworkImage(data['userPhoto'])
                    : null,
                child: data['userPhoto'] == null || data['userPhoto'].isEmpty
                    ? Icon(Icons.person, color: primary)
                    : null,
              ),
              title: Text(
                data['userName'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                data['userType'] == 'ngo' ? 'NGO Member' : 'Volunteer',
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
