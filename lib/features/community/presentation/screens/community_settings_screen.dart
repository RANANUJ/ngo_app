import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngo_app/features/community/domain/models/community_post.dart';
import 'package:ngo_app/features/community/presentation/controllers/community_controller.dart';
import 'package:ngo_app/features/community/presentation/screens/post_feed_screen.dart';
import 'package:ngo_app/features/community/presentation/screens/video_player_widget.dart';

class CommunitySettingsScreen extends StatelessWidget {
  final String userId;
  final String userType;

  const CommunitySettingsScreen({
    Key? key,
    required this.userId,
    required this.userType,
  }) : super(key: key);

  static const Color primary = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Community Settings'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('My Content'),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            icon: Icons.favorite_rounded,
            color: Colors.red,
            title: 'Liked Videos',
            subtitle: 'Revisit the video posts you liked',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LikedPostsGridScreen(userId: userId),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            context,
            icon: Icons.bookmark_rounded,
            color: primary,
            title: 'Saved Posts',
            subtitle: 'Access the community posts you saved',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SavedPostsGridScreen(userId: userId, userType: userType),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader('Community Safety'),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            icon: Icons.gavel_rounded,
            color: Colors.orange.shade700,
            title: 'Community Guidelines',
            subtitle: 'Learn about our community rules',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CommunityGuidelinesScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
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
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Sub-Screen for Liked Reels/Videos
class LikedPostsGridScreen extends StatelessWidget {
  final String userId;

  const LikedPostsGridScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CommunityController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Liked Videos'),
        backgroundColor: CommunitySettingsScreen.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<CommunityPost>>(
        stream: controller.streamLikedPosts(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CommunitySettingsScreen.primary));
          }

          final posts = (snapshot.data ?? [])
              .where((post) => post.videoUrl != null && post.videoUrl!.isNotEmpty)
              .toList();

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_collection_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No liked videos yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostFeedScreen(
                        posts: posts,
                        initialIndex: index,
                        userId: userId,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoThumbnailPlayer(videoUrl: post.videoUrl!),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Row(
                          children: [
                            const Icon(Icons.favorite, color: Colors.red, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${post.likesCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
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
    );
  }
}

// Sub-Screen for Saved Posts
class SavedPostsGridScreen extends StatelessWidget {
  final String userId;
  final String userType;

  const SavedPostsGridScreen({Key? key, required this.userId, required this.userType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CommunityController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Saved Posts'),
        backgroundColor: CommunitySettingsScreen.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<CommunityPost>>(
        stream: controller.streamSavedPosts(userId, userType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CommunitySettingsScreen.primary));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No saved posts yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
              final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostFeedScreen(
                        posts: posts,
                        initialIndex: index,
                        userId: userId,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.grey.shade200,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasVideo)
                          VideoThumbnailPlayer(videoUrl: post.videoUrl!)
                        else if (hasImage)
                          Image.network(post.imageUrl!, fit: BoxFit.cover)
                        else
                          Container(
                            color: Colors.grey.shade900,
                            padding: const EdgeInsets.all(8),
                            child: Center(
                              child: Text(
                                post.content,
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        if (hasVideo)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Guidelines page
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Community Guidelines'),
        backgroundColor: CommunitySettingsScreen.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'NGO Community Guidelines',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'We are committed to maintaining a safe, collaborative, and inspiring space for NGOs and volunteers. Help us keep the community positive by following these simple rules:',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildGuidelineItem(
            '1. Respect and Inclusivity',
            'Treat every member with kindness and respect. Harassment, hate speech, discrimination, and bullying of any form will not be tolerated.',
          ),
          const SizedBox(height: 16),
          _buildGuidelineItem(
            '2. Authentic Sharing',
            'Only share updates, campaigns, and content that are genuine and verify any facts. Fake requests or misleading news will be removed.',
          ),
          const SizedBox(height: 16),
          _buildGuidelineItem(
            '3. Safe Space for Beneficiaries',
            'When posting photos or videos of project beneficiaries, ensure you have their consent. Maintain their dignity and privacy.',
          ),
          const SizedBox(height: 16),
          _buildGuidelineItem(
            '4. No Spam or Self-Promotion',
            'Keep posts relevant to NGO initiatives, volunteering opportunity details, and social help. Commercial ads or irrelevant links are not allowed.',
          ),
          const SizedBox(height: 16),
          _buildGuidelineItem(
            '5. Reporting violations',
            'If you see posts violating these guidelines, report them immediately to our administrative team using the flag option.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CommunitySettingsScreen.primary),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.45),
        ),
      ],
    );
  }
}
