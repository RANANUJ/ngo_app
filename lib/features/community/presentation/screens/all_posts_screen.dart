import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import '../../domain/models/community_post.dart';
import '../../domain/models/community_comment.dart';
import '../controllers/community_controller.dart';
import 'community_post_detail_screen.dart';
import 'package:ngo_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'dart:io';
import '../utils/video_cache_manager.dart';
class AllPostsScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? userPhoto;

  const AllPostsScreen({
    Key? key,
    this.userId,
    this.userName,
    this.userPhoto,
  }) : super(key: key);

  @override
  State<AllPostsScreen> createState() => _AllPostsScreenState();
}

class _AllPostsScreenState extends State<AllPostsScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CommunityController>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Posts',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search posts...',
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
          ),
          // Posts List
          Expanded(
            child: StreamBuilder<List<CommunityPost>>(
              stream: controller.streamCommunityPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var posts = snapshot.data ?? [];

                // Shuffle posts for random order display as original legacy screen did
                posts = List.from(posts)..shuffle();

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  posts = posts.where((post) {
                    final content = post.content.toLowerCase();
                    final authorName = post.authorName.toLowerCase();
                    return content.contains(_searchQuery) || authorName.contains(_searchQuery);
                  }).toList();
                }

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No posts found',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  color: primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return _buildPostCard(post);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final postId = post.id;
    final authorId = post.authorId;
    final authorName = post.authorName.isEmpty ? 'User' : post.authorName;
    final authorPhoto = post.authorPhoto;
    final authorType = post.authorType.isEmpty ? 'volunteer' : post.authorType;
    final communityName = post.communityName;
    final content = post.content;
    final imageUrl = post.imageUrl;
    final videoUrl = post.videoUrl;
    final createdAt = post.createdAt;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info - Tappable to view profile
          GestureDetector(
            onTap: () => _navigateToUserProfile(authorId, authorName, authorType, authorPhoto),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primary.withValues(alpha: 0.2),
                    backgroundImage: authorPhoto.isNotEmpty
                        ? NetworkImage(authorPhoto)
                        : null,
                    child: authorPhoto.isEmpty
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
                                authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (communityName.isNotEmpty) ...[
                              Text(' · ', style: TextStyle(color: Colors.grey.shade500)),
                              Flexible(
                                child: Text(
                                  communityName,
                                  style: const TextStyle(
                                    color: primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _getTimeAgo(createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                content,
                style: const TextStyle(fontSize: 14, height: 1.4),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Image
          if (hasImage)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          // Video thumbnail with play button
          if (hasVideo)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _VideoThumbnail(videoUrl: videoUrl),
            ),
          // Actions - Like, Comment, Share
          Padding(
            padding: const EdgeInsets.all(12),
            child: _PostActions(
              post: post,
              currentUserName: widget.userName,
              onCommentTap: () => _showCommentsSheet(postId, post),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUserProfile(String? userId, String userName, String userType, String? userPhoto) {
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile not available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userId,
          userName: userName,
          userType: userType,
          userPhoto: userPhoto,
        ),
      ),
    );
  }

  void _showCommentsSheet(String postId, CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(
        postId: postId,
        post: post,
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Video Thumbnail Widget with play button
class _VideoThumbnail extends StatefulWidget {
  final String videoUrl;

  const _VideoThumbnail({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    var url = widget.videoUrl;
    if (url.contains('ngo-app-d0961.appspot.com')) {
      debugPrint("AllPostsScreen: Mapping old storage bucket to active bucket.");
      url = url.replaceAll('ngo-app-d0961.appspot.com', 'connect-ngo-82057.firebasestorage.app');
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      final cachedFile = await VideoCacheManager.getCachedFile(url);
      if (!mounted) return;

      if (cachedFile != null) {
        debugPrint("AllPostsScreen: Loading thumbnail from cache: ${cachedFile.path}");
        _controller = VideoPlayerController.file(cachedFile);
      } else {
        debugPrint("AllPostsScreen: Loading thumbnail from network: $url");
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
        VideoCacheManager.prefetchVideo(url);
      }

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      } catch (e) {
        debugPrint('Error initializing video: $e');
      }
    } else {
      debugPrint("AllPostsScreen: Invalid video URL structure: '$url'");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey.shade900,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: double.infinity,
        height: 200,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
            if (!_isPlaying)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
              ),
          ],
        ),
      ),
    );
  }
}

// Post Actions Widget with Like functionality
class _PostActions extends StatelessWidget {
  static const Color primary = Color(0xFF0099B8);
  final CommunityPost post;
  final String? currentUserName;
  final VoidCallback onCommentTap;

  const _PostActions({
    Key? key,
    required this.post,
    this.currentUserName,
    required this.onCommentTap,
  }) : super(key: key);

  Future<void> _toggleLike(BuildContext context, bool isLiked) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final controller = context.read<CommunityController>();
    await controller.toggleLikePost(
      postId: post.id,
      userId: userId,
      userName: currentUserName ?? 'User',
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final controller = context.read<CommunityController>();

    if (userId == null) {
      return Row(
        children: [
          Row(
            children: [
              Icon(Icons.favorite_border, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${post.likesCount}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${post.commentsCount}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      );
    }

    return StreamBuilder<bool>(
      stream: controller.streamPostLikeStatus(post.id, userId),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;

        return Row(
          children: [
            // Like button
            GestureDetector(
              onTap: () => _toggleLike(context, isLiked),
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isLiked ? Colors.red : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Comment button
            GestureDetector(
              onTap: onCommentTap,
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Share button
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.share_outlined, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Share',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Comments Bottom Sheet
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final CommunityPost post;

  const _CommentsSheet({
    Key? key,
    required this.postId,
    required this.post,
  }) : super(key: key);

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final controller = context.read<CommunityController>();

      // Get user info defaults
      String userName = user.displayName ?? 'User';
      String userPhoto = user.photoURL ?? '';
      String userType = 'volunteer';

      final volunteerDoc = await FirebaseAuthenticationHelper.getProfileData(user.uid);
      if (volunteerDoc != null) {
        userName = volunteerDoc['displayName'] ?? userName;
        userPhoto = volunteerDoc['photoUrl'] ?? userPhoto;
      }

      await controller.addComment(
        postId: widget.postId,
        content: _commentController.text.trim(),
        authorId: user.uid,
        authorName: userName,
        authorPhoto: userPhoto,
        authorType: userType,
      );

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CommunityController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          // Comments list
          Expanded(
            child: StreamBuilder<List<CommunityComment>>(
              stream: controller.streamPostComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _buildCommentItem(comment);
                  },
                );
              },
            ),
          ),
          // Comment input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isPosting ? null : _postComment,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 20),
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

  Widget _buildCommentItem(CommunityComment comment) {
    final userName = comment.authorName.isEmpty ? 'User' : comment.authorName;
    final userPhoto = comment.authorPhoto;
    final content = comment.content;
    final createdAt = comment.createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: userPhoto.isNotEmpty
                ? NetworkImage(userPhoto)
                : null,
            child: userPhoto.isEmpty
                ? const Icon(Icons.person, color: Colors.grey, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(
                        text: userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: content,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(createdAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}

// Helper to fetch user profiles without writing full firestore queries in screen logic
class FirebaseAuthenticationHelper {
  static Future<Map<String, dynamic>?> getProfileData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('volunteers').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (_) {}
    return null;
  }
}
