import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:ngo_app/screens/profile/user_profile_screen.dart';

class PostFeedScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> posts;
  final int initialIndex;
  final String? userId;

  const PostFeedScreen({
    Key? key,
    required this.posts,
    this.initialIndex = 0,
    this.userId,
  }) : super(key: key);

  @override
  State<PostFeedScreen> createState() => _PostFeedScreenState();
}

class _PostFeedScreenState extends State<PostFeedScreen> {
  static const Color primary = Color(0xFF0099B8);
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController?> _videoControllers = {};
  final TextEditingController _commentController = TextEditingController();
  
  // Cached user info
  String? _currentUserId;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideoControllers();
    _initializeUser();
    
    // Listen for auth state changes in case user wasn't fully loaded
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted && user != null && _currentUserId == null) {
        setState(() {
          _currentUserId = user.uid;
          _currentUser = user;
        });
        debugPrint('PostFeedScreen: Auth state updated - User ID = $_currentUserId');
      }
    });
  }

  void _initializeUser() {
    // First try widget parameter, then try FirebaseAuth
    _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    _currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('PostFeedScreen: Current user ID = $_currentUserId');
    debugPrint('PostFeedScreen: Widget userId = ${widget.userId}');
    debugPrint('PostFeedScreen: FirebaseAuth currentUser = ${FirebaseAuth.instance.currentUser?.uid}');
  }
  void _initializeVideoControllers() {
    // Pre-initialize nearby video controllers
    for (int i = _currentIndex - 1; i <= _currentIndex + 1; i++) {
      if (i >= 0 && i < widget.posts.length) {
        _initVideoController(i);
      }
    }
  }

  void _initVideoController(int index) {
    if (_videoControllers.containsKey(index)) return;
    
    final data = widget.posts[index].data() as Map<String, dynamic>;
    final videoUrl = data['videoUrl'] as String?;
    
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoControllers[index] = videoController;
      
      videoController.initialize().then((_) {
        if (mounted && index == _currentIndex) {
          videoController.play();
          videoController.setLooping(true);
        }
        setState(() {});
      });
    }
  }

  void _onPageChanged(int index) {
    // Pause previous video
    _videoControllers[_currentIndex]?.pause();
    
    setState(() => _currentIndex = index);
    
    // Play current video
    _videoControllers[index]?.play();
    
    // Pre-load next videos
    for (int i = index - 1; i <= index + 1; i++) {
      if (i >= 0 && i < widget.posts.length) {
        _initVideoController(i);
      }
    }
    
    // Dispose far away controllers to save memory
    _videoControllers.keys.toList().forEach((key) {
      if ((key - index).abs() > 2) {
        _videoControllers[key]?.dispose();
        _videoControllers.remove(key);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          return _buildPostItem(widget.posts[index], index);
        },
      ),
    );
  }

  Widget _buildPostItem(QueryDocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    final content = data['content'] as String? ?? '';
    final userName = data['userName'] as String? ?? 'User';
    final userPhoto = data['userPhoto'] as String?;
    final userType = data['userType'] as String? ?? 'volunteer';
    final userId = data['userId'] as String?;
    final location = data['location'] as String?;
    final likesCount = data['likesCount'] ?? 0;
    final commentsCount = data['commentsCount'] ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;

    final isVideo = videoUrl != null && videoUrl.isNotEmpty;
    final hasMedia = isVideo || (imageUrl != null && imageUrl.isNotEmpty);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Media Content (Image or Video)
        if (isVideo)
          _buildVideoPlayer(index)
        else if (imageUrl != null && imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 64),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: userType == 'ngo'
                    ? [primary, primary.withOpacity(0.7)]
                    : [Colors.purple.shade600, Colors.purple.shade400],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

        // Gradient overlay for text visibility
        if (hasMedia)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

        // Video play/pause tap zone (center area only to avoid blocking buttons)
        if (isVideo)
          Positioned(
            top: 100,
            left: 0,
            right: 80, // Leave space for action buttons on the right
            bottom: 180, // Leave space for bottom content
            child: GestureDetector(
              onTap: () {
                final controller = _videoControllers[index];
                if (controller != null) {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                  setState(() {});
                }
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

        // Play button overlay (centered on screen)
        if (isVideo && _videoControllers[index]?.value.isPlaying == false)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 56),
                ),
              ),
            ),
          ),

        // Top bar - Close button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
        ),

        // Right side action buttons
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              // Like button
              _buildActionButton(
                doc.id,
                Icons.favorite,
                Icons.favorite_border,
                likesCount,
                'likes',
              ),
              const SizedBox(height: 20),
              // Comment button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showComments(doc.id, data),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.comment, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$commentsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Share button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _sharePost(data),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),

        // Bottom content - User info & caption
        Positioned(
          left: 16,
          right: 80,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info - Tappable to view profile
              GestureDetector(
                onTap: () => _navigateToUserProfile(userId, userName, userType, userPhoto),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                          ? NetworkImage(userPhoto)
                          : null,
                      child: userPhoto == null || userPhoto.isEmpty
                          ? Icon(
                              userType == 'ngo' ? Icons.business : Icons.person,
                              color: Colors.grey.shade600,
                              size: 18,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (location != null && location.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.white70, size: 12),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Caption
              if (hasMedia && content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Timestamp
              if (createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(createdAt),
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildVideoPlayer(int index) {
    final controller = _videoControllers[index];
    
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Calculate aspect ratios to determine proper fitting
    final screenSize = MediaQuery.of(context).size;
    final videoAspectRatio = controller.value.aspectRatio;
    final screenAspectRatio = screenSize.width / screenSize.height;

    return Center(
      child: AspectRatio(
        aspectRatio: videoAspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildActionButton(
    String docId,
    IconData activeIcon,
    IconData inactiveIcon,
    int count,
    String field,
  ) {
    // Use cached user ID first, then try fresh check
    final userId = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      // User not logged in - show button without like status
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggleLike(docId, false),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(inactiveIcon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .doc(docId)
          .collection(field)
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final isLiked = snapshot.hasData && snapshot.data!.exists;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _toggleLike(docId, isLiked),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLiked ? activeIcon : inactiveIcon,
                  color: isLiked ? Colors.red : Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 4),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community_posts')
                    .doc(docId)
                    .snapshots(),
                builder: (context, postSnapshot) {
                  int likesCount = count;
                  if (postSnapshot.hasData && postSnapshot.data!.data() != null) {
                    final data = postSnapshot.data!.data() as Map<String, dynamic>;
                    likesCount = data['likesCount'] ?? 0;
                  }
                  return Text(
                    '$likesCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleLike(String docId, bool isLiked) async {
    // Use cached user ID first
    String? userId = _currentUserId;
    
    if (userId == null) {
      // Try fresh check
      final user = FirebaseAuth.instance.currentUser;
      userId = user?.uid;
    }
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like posts')),
      );
      return;
    }

    await _performLikeAction(docId, isLiked, userId);
  }

  Future<void> _performLikeAction(String docId, bool isLiked, String userId) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('community_posts').doc(docId);
      final likeRef = postRef.collection('likes').doc(userId);

      if (isLiked) {
        await likeRef.delete();
        await postRef.update({'likesCount': FieldValue.increment(-1)});
      } else {
        await likeRef.set({'userId': userId, 'createdAt': FieldValue.serverTimestamp()});
        await postRef.update({'likesCount': FieldValue.increment(1)});
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _navigateToUserProfile(String? userId, String userName, String userType, String? userPhoto) {
    if (userId == null) {
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

  void _showComments(String docId, Map<String, dynamic> postData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(
        docId: docId,
        postData: postData,
        userId: _currentUserId,
      ),
    );
  }

  void _sharePost(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _CommentsSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> postData;
  final String? userId;

  const _CommentsSheet({
    Key? key,
    required this.docId,
    required this.postData,
    this.userId,
  }) : super(key: key);

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    // Use cached userId first
    String? userId = _currentUserId;
    User? user = FirebaseAuth.instance.currentUser;
    
    if (userId == null) {
      // Try fresh check
      if (user == null) {
        await Future.delayed(const Duration(milliseconds: 100));
        user = FirebaseAuth.instance.currentUser;
      }
      userId = user?.uid;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to comment')),
        );
        return;
      }
    }

    setState(() => _isPosting = true);

    try {
      // Get user info
      String userName = user?.displayName ?? 'User';
      String? userPhoto = user?.photoURL;
      String userType = 'volunteer';

      // Try to get from volunteers collection
      final volunteerDoc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(userId)
          .get();
      
      if (volunteerDoc.exists) {
        final data = volunteerDoc.data()!;
        userName = data['displayName'] ?? userName;
        userPhoto = data['photoUrl'] ?? userPhoto;
      }

      // Add comment
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.docId)
          .collection('comments')
          .add({
        'userId': userId,
        'userName': userName,
        'userPhoto': userPhoto,
        'userType': userType,
        'content': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update comments count
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.docId)
          .update({'commentsCount': FieldValue.increment(1)});

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Comments',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .doc(widget.docId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data?.docs ?? [];

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
                    final data = comments[index].data() as Map<String, dynamic>;
                    return _buildCommentItem(data);
                  },
                );
              },
            ),
          ),
          // Comment input
          SafeArea(
            child: Container(
              padding: EdgeInsets.only(
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

  Widget _buildCommentItem(Map<String, dynamic> data) {
    final userName = data['userName'] ?? 'User';
    final userPhoto = data['userPhoto'] as String?;
    final content = data['content'] ?? '';
    final createdAt = data['createdAt'] as Timestamp?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                ? NetworkImage(userPhoto)
                : null,
            child: userPhoto == null || userPhoto.isEmpty
                ? Icon(Icons.person, color: Colors.grey.shade600, size: 18)
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
                if (createdAt != null)
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

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}
