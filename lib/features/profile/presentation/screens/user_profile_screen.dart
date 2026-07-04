import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ngo_app/features/profile/presentation/controllers/profile_controller.dart';
import 'unified_edit_profile_screen.dart';
import 'package:ngo_app/features/community/presentation/controllers/community_controller.dart';
import 'package:ngo_app/features/community/presentation/screens/post_feed_screen.dart';
import 'package:ngo_app/features/community/domain/models/community_post.dart';
import 'package:ngo_app/features/community/presentation/screens/video_player_widget.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().loadUserProfile(widget.userId, widget.userType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final isLoading = profileController.isLoading;
    final userData = profileController.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(userData),
                  const SizedBox(height: 16),
                  _buildUserPosts(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(dynamic userData) {
    final photoUrl = widget.userPhoto ?? userData?.photoUrl;
    final isNgo = widget.userType == 'ngo';
    final bio = userData?.bio ?? '';
    final city = userData?.city ?? '';
    final state = userData?.state ?? '';
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
              color: isNgo ? primary.withValues(alpha: 0.1) : Colors.purple.withValues(alpha: 0.1),
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
          if (widget.userId == FirebaseAuth.instance.currentUser?.uid && userData != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 150,
              height: 36,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UnifiedEditProfileScreen(
                        currentProfile: userData,
                      ),
                    ),
                  ).then((_) {
                    context.read<ProfileController>().loadUserProfile(widget.userId, widget.userType);
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  foregroundColor: primary,
                  padding: EdgeInsets.zero,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 14),
                    SizedBox(width: 6),
                    Text('Edit Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
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
    final communityController = context.watch<CommunityController>();
    return StreamBuilder<List<CommunityPost>>(
      stream: communityController.streamCommunityPosts(userId: widget.userId),
      builder: (context, snapshot) {
        final postsCount = snapshot.data?.length ?? 0;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatItem('Posts', postsCount.toString()),
            const SizedBox(width: 40),
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
    final communityController = context.watch<CommunityController>();
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
        StreamBuilder<List<CommunityPost>>(
          stream: communityController.streamCommunityPosts(userId: widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final posts = snapshot.data ?? [];

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
                final post = posts[index];
                final imageUrl = post.imageUrl;
                final videoUrl = post.videoUrl;
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
                        else if (hasVideo)
                          VideoThumbnailPlayer(
                            videoUrl: videoUrl,
                            borderRadius: BorderRadius.circular(4),
                          )
                        else
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
                                color: Colors.black.withValues(alpha: 0.6),
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
