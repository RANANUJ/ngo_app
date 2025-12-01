import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_feed_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userType;
  final String? userPhoto;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userType,
    this.userPhoto,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const Color primary = Color(0xFF0099B8);
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Check if it's an NGO or volunteer
      if (widget.userType == 'ngo') {
        final ngoDoc = await FirebaseFirestore.instance
            .collection('ngo_registrations')
            .doc(widget.userId)
            .get();
        
        if (ngoDoc.exists) {
          setState(() {
            _userData = ngoDoc.data();
            _isLoading = false;
          });
          return;
        }
      }
      
      // Try volunteers collection
      final volunteerDoc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(widget.userId)
          .get();
      
      if (volunteerDoc.exists) {
        setState(() {
          _userData = volunteerDoc.data();
          _isLoading = false;
        });
        return;
      }

      // If not found in either collection
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 16),
                  _buildUserPosts(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final photoUrl = widget.userPhoto ?? _userData?['photoUrl'] ?? _userData?['profileImageUrl'];
    final isNgo = widget.userType == 'ngo';
    final bio = _userData?['bio'] ?? _userData?['missionVision'] ?? '';
    final city = _userData?['city'] ?? _userData?['address']?['city'] ?? '';
    final state = _userData?['state'] ?? _userData?['address']?['state'] ?? '';
    final location = [city, state].where((s) => s.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          // Profile image
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? Icon(
                    isNgo ? Icons.business : Icons.person,
                    size: 50,
                    color: Colors.grey.shade400,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            widget.userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // User type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isNgo ? primary.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isNgo ? 'NGO' : 'Volunteer',
              style: TextStyle(
                color: isNgo ? primary : Colors.purple,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Location
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
          // Bio
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              bio,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          // Stats row
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        final postsCount = snapshot.data?.docs.length ?? 0;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatItem('Posts', postsCount.toString()),
            const SizedBox(width: 40),
            // Add more stats if needed
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildUserPosts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Posts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('community_posts')
              .where('userId', isEqualTo: widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final posts = snapshot.data?.docs ?? [];

            if (posts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.grid_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final data = posts[index].data() as Map<String, dynamic>;
                final imageUrl = data['imageUrl'] as String?;
                final videoUrl = data['videoUrl'] as String?;
                final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostFeedScreen(
                          posts: posts,
                          initialIndex: index,
                          userId: FirebaseAuth.instance.currentUser?.uid,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.broken_image,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          )
                        else if (!hasVideo)
                          Center(
                            child: Icon(
                              Icons.notes,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        // Video indicator
                        if (hasVideo)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
