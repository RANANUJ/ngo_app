import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:ngo_app/features/profile/presentation/screens/user_profile_screen.dart';
import '../../domain/models/community_post.dart';
import '../../domain/models/community_comment.dart';
import '../controllers/community_controller.dart';
import 'dart:io';
import '../utils/video_cache_manager.dart';
import 'package:ngo_app/core/utils/route_observer.dart';
import 'insights_sheet.dart';

class PostFeedScreen extends StatefulWidget {
  final List<CommunityPost> posts;
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

class _PostFeedScreenState extends State<PostFeedScreen> with RouteAware {
  static const Color primary = Color(0xFF0099B8);
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController?> _videoControllers = {};
  final TextEditingController _commentController = TextEditingController();
  final Set<int> _failedVideos = {};
  bool _isRouteActive = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPushNext() {
    _isRouteActive = false;
    _videoControllers[_currentIndex]?.pause();
  }

  @override
  void didPopNext() {
    _isRouteActive = true;
    if (_isRouteActive) {
      _videoControllers[_currentIndex]?.play();
    }
  }
  
  // Cached user info
  String? _currentUserId;
  String _currentUserType = 'volunteer';

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
        });
        debugPrint('PostFeedScreen: Auth state updated - User ID = $_currentUserId');
      }
    });
  }

  String? _currentUserPhoto;
  String _currentUserName = 'Anonymous';
  String _currentUserArea = 'Unknown';
  String _currentUserUsername = '';

  void _loadCurrentUserProfile() async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      var doc = await FirebaseFirestore.instance.collection('volunteers').doc(uid).get();
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('ngo_registrations').doc(uid).get();
      }

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _currentUserName = data['displayName'] ?? data['ngoName'] ?? 'Anonymous';
            _currentUserPhoto = data['photoUrl'] ?? data['ngoLogo'] ?? data['profileImageUrl'];
            final city = data['city'] ?? '';
            final state = data['state'] ?? '';
            _currentUserArea = [city, state].where((s) => s.isNotEmpty).join(', ');
            if (_currentUserArea.isEmpty) _currentUserArea = 'Unknown';
            _currentUserUsername = data['username'] ?? '';
            _currentUserType = doc.reference.parent.id == 'ngo_registrations' ? 'ngo' : 'volunteer';
          });

          _recordViewForIndex(_currentIndex);
        }
      }
    } catch (e) {
      debugPrint('Error loading current user profile: $e');
    }
  }

  void _recordViewForIndex(int index) async {
    final uid = _currentUserId;
    if (uid == null || index < 0 || index >= widget.posts.length) return;

    final post = widget.posts[index];
    if (post.authorId == uid) return;

    try {
      final viewRef = FirebaseFirestore.instance
          .collection('community_posts')
          .doc(post.id)
          .collection('views')
          .doc(uid);

      final doc = await viewRef.get();
      if (!doc.exists) {
        await viewRef.set({
          'userId': uid,
          'userName': _currentUserName,
          'userUsername': _currentUserUsername,
          'userPhoto': _currentUserPhoto ?? '',
          'area': _currentUserArea,
          'viewedAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(post.id)
            .update({
          'viewsCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Error recording post view: $e');
    }
  }

  void _initializeUser() {
    _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    debugPrint('PostFeedScreen: Current user ID = $_currentUserId');
    _loadCurrentUserProfile();
  }

  void _showPostInsights(String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => InsightsSheet(postId: postId),
    );
  }

  void _initializeVideoControllers() {
    // Start by initializing current index and the next one to minimize immediate resource demand
    _initVideoController(_currentIndex);
    if (_currentIndex + 1 < widget.posts.length) {
      _initVideoController(_currentIndex + 1);
    }
  }

  void _initVideoController(int index) {
    if (_videoControllers.containsKey(index)) return;
    
    final post = widget.posts[index];
    var videoUrl = post.videoUrl;
    
    if (videoUrl != null && videoUrl.isNotEmpty) {
      if (videoUrl.contains('ngo-app-d0961.appspot.com')) {
        debugPrint("PostFeedScreen: Mapping old storage bucket to active bucket: 'connect-ngo-82057.firebasestorage.app'");
        videoUrl = videoUrl.replaceAll('ngo-app-d0961.appspot.com', 'connect-ngo-82057.firebasestorage.app');
      }
      
      debugPrint("PostFeedScreen: Initializing video at index $index with URL: '$videoUrl'");
      
      if (!videoUrl.startsWith('http://') && !videoUrl.startsWith('https://')) {
        debugPrint("PostFeedScreen: Invalid video URL structure (must start with http/https): '$videoUrl'");
        if (mounted) {
          setState(() {
            _failedVideos.add(index);
          });
        }
        return;
      }

      // Load from cache if already downloaded, else stream from network and trigger prefetch
      VideoCacheManager.getCachedFile(videoUrl).then((cachedFile) {
        if (!mounted) return;

        final VideoPlayerController videoController;
        if (cachedFile != null) {
          debugPrint("PostFeedScreen: Playing video at index $index from CACHE file: ${cachedFile.path}");
          videoController = VideoPlayerController.file(cachedFile);
        } else {
          debugPrint("PostFeedScreen: Playing video at index $index from NETWORK; caching in background.");
          videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl!));
          VideoCacheManager.prefetchVideo(videoUrl);
        }

        _videoControllers[index] = videoController;
        
        videoController.initialize().then((_) {
          if (mounted) {
            if (index == _currentIndex) {
              if (_isRouteActive) {
                videoController.play();
              }
              videoController.setLooping(true);
            }
            setState(() {});
          }
        }).catchError((error) {
          debugPrint("Video initialization failed for index $index: $error");
          if (mounted) {
            setState(() {
              _failedVideos.add(index);
            });
          }
        });
      });
    }
  }

  void _onPageChanged(int index) {
    _videoControllers[_currentIndex]?.pause();
    
    setState(() => _currentIndex = index);
    
    if (_isRouteActive) {
      _videoControllers[index]?.play();
    }
    
    _recordViewForIndex(index);
    
    // Pre-initialize player controllers for immediate adjacent posts (index - 1 to index + 1)
    for (int i = index - 1; i <= index + 1; i++) {
      if (i >= 0 && i < widget.posts.length) {
        _initVideoController(i);
      }
    }

    // Prefetch files into background cache for next posts (index + 1 to index + 2)
    for (int i = index + 1; i <= index + 2; i++) {
      if (i >= 0 && i < widget.posts.length) {
        final post = widget.posts[i];
        var url = post.videoUrl;
        if (url != null && url.isNotEmpty) {
          if (url.contains('ngo-app-d0961.appspot.com')) {
            url = url.replaceAll('ngo-app-d0961.appspot.com', 'connect-ngo-82057.firebasestorage.app');
          }
          VideoCacheManager.prefetchVideo(url);
        }
      }
    }
    
    // Limit cache to only immediate neighbors (max 3 total active controllers: index-1, index, index+1)
    _videoControllers.keys.toList().forEach((key) {
      if ((key - index).abs() > 1) {
        _videoControllers[key]?.dispose();
        _videoControllers.remove(key);
      }
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
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

  Widget _buildPostItem(CommunityPost post, int index) {
    final imageUrl = post.imageUrl;
    final videoUrl = post.videoUrl;
    final content = post.content;
    final userName = post.authorName.isEmpty ? 'User' : post.authorName;
    final userPhoto = post.authorPhoto;
    final userType = post.authorType.isEmpty ? 'volunteer' : post.authorType;
    final userId = post.authorId;
    final location = post.location;
    final likesCount = post.likesCount;
    final commentsCount = post.commentsCount;
    final createdAt = post.createdAt;

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
            fit: BoxFit.contain,
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
                    ? [primary, primary.withValues(alpha: 0.7)]
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
                    Colors.black.withValues(alpha: 0.7),
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
            right: 80,
            bottom: 180,
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
                    color: Colors.black.withValues(alpha: 0.5),
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
                color: Colors.black.withValues(alpha: 0.5),
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
                post.id,
                Icons.favorite,
                Icons.favorite_border,
                likesCount,
                post,
              ),
              const SizedBox(height: 20),
              // Comment button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showComments(post.id, post),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
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
                onTap: () => _sharePost(post),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: 20),
              // Save button
              StreamBuilder<bool>(
                stream: context.read<CommunityController>().streamSaveStatus(
                  post.id,
                  _currentUserId ?? '',
                  _currentUserType,
                ),
                builder: (context, snapshot) {
                  final isSaved = snapshot.data ?? false;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_currentUserId != null) {
                        context.read<CommunityController>().toggleSavePost(
                          postId: post.id,
                          userId: _currentUserId!,
                          userType: _currentUserType,
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Save',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Insights button (show only if current user is the author)
              if (post.authorId == _currentUserId) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showPostInsights(post.id),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Insights',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
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
                      backgroundImage: userPhoto.isNotEmpty
                          ? NetworkImage(userPhoto)
                          : null,
                      child: userPhoto.isEmpty
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
                ExpandableCaptionWidget(content: content),
              ],
              // Timestamp
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(createdAt),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(int index) {
    if (_failedVideos.contains(index)) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load video', style: TextStyle(color: Colors.white70)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _failedVideos.remove(index);
                    _videoControllers.remove(index);
                    _initVideoController(index);
                  });
                },
                child: const Text('Retry', style: TextStyle(color: primary)),
              )
            ],
          ),
        ),
      );
    }

    final controller = _videoControllers[index];
    
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final videoAspectRatio = controller.value.aspectRatio;

    return Center(
      child: AspectRatio(
        aspectRatio: videoAspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildActionButton(
    String postId,
    IconData activeIcon,
    IconData inactiveIcon,
    int initialLikesCount,
    CommunityPost post,
  ) {
    final userId = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Column(
        children: [
          GestureDetector(
            onTap: () => _toggleLike(post, false),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(inactiveIcon, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showLikes(postId),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                '$initialLikesCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final controller = context.read<CommunityController>();

    return StreamBuilder<bool>(
      stream: controller.streamPostLikeStatus(postId, userId),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;

        return Column(
          children: [
            GestureDetector(
              onTap: () => _toggleLike(post, isLiked),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLiked ? activeIcon : inactiveIcon,
                  color: isLiked ? Colors.red : Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showLikes(postId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: StreamBuilder<CommunityPost?>(
                  stream: controller.streamCommunityPost(postId),
                  builder: (context, postSnapshot) {
                    int likesCount = initialLikesCount;
                    if (postSnapshot.hasData && postSnapshot.data != null) {
                      likesCount = postSnapshot.data!.likesCount;
                    }
                    return Text(
                      '$likesCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleLike(CommunityPost post, bool isLiked) async {
    String? userId = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like posts')),
      );
      return;
    }

    try {
      final controller = context.read<CommunityController>();
      String userName = 'User';
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userName = user.displayName ?? 'User';
      }
      
      await controller.toggleLikePost(
        postId: post.id,
        userId: userId,
        userName: userName,
      );
    } catch (e) {
      debugPrint('Error toggling like: $e');
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

  void _showComments(String postId, CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(
        postId: postId,
        post: post,
        userId: _currentUserId,
      ),
    );
  }

  void _sharePost(CommunityPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  String _formatTimestamp(DateTime date) {
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

  void _showLikes(String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LikesSheet(
        postId: postId,
        currentUserId: _currentUserId,
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final CommunityPost post;
  final String? userId;

  const _CommentsSheet({
    Key? key,
    required this.postId,
    required this.post,
    this.userId,
  }) : super(key: key);

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
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
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    String? userId = _currentUserId;
    User? user = FirebaseAuth.instance.currentUser;
    
    if (userId == null) {
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
      String userName = 'User';
      String? userPhoto;
      String userType = 'volunteer';

      final volunteerDoc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(userId)
          .get();

      if (volunteerDoc.exists) {
        final data = volunteerDoc.data()!;
        userName = data['displayName'] ?? data['name'] ?? userName;
        userPhoto = data['photoUrl'] ?? data['profileImageUrl'];
        userType = 'volunteer';
      } else {
        final ngoDoc = await FirebaseFirestore.instance
            .collection('ngo_registrations')
            .doc(userId)
            .get();
        if (ngoDoc.exists) {
          final data = ngoDoc.data()!;
          userName = data['ngoName'] ?? data['name'] ?? userName;
          userPhoto = data['photoUrl'] ?? data['ngoLogo'] ?? data['profileImageUrl'];
          userType = 'ngo';
        }
      }

      final controller = context.read<CommunityController>();

      await controller.addComment(
        postId: widget.postId,
        content: _commentController.text.trim(),
        authorId: userId,
        authorName: userName,
        authorPhoto: userPhoto ?? '',
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
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
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
                    return _buildCommentItem(comments[index]);
                  },
                );
              },
            ),
          ),
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
                      focusNode: _commentFocusNode,
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
    final controller = context.read<CommunityController>();
    final uid = _currentUserId;

    final isPostAuthor = widget.post.authorId == uid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    userId: comment.authorId,
                    userName: userName,
                    userType: comment.authorType,
                    userPhoto: userPhoto.isNotEmpty ? userPhoto : null,
                  ),
                ),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
              child: userPhoto.isEmpty
                  ? Icon(Icons.person, color: Colors.grey.shade400, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(
                        text: userName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: content,
                        style: TextStyle(
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  child: Row(
                    children: [
                      Text(_formatTime(createdAt)),
                      if (comment.likesCount > 0) ...[
                        const SizedBox(width: 14),
                        Text(
                          '${comment.likesCount} ${comment.likesCount == 1 ? 'like' : 'likes'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () {
                          _commentController.text = '@$userName ';
                          _commentFocusNode.requestFocus();
                        },
                        child: const Text('Reply'),
                      ),
                      if (isPostAuthor) ...[
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () {
                            controller.togglePinComment(
                              postId: widget.postId,
                              commentId: comment.id,
                              currentPinState: comment.isPinned,
                            );
                          },
                          child: Text(comment.isPinned ? 'Unpin' : 'Pin'),
                        ),
                      ],
                      if (comment.isPinned) ...[
                        const SizedBox(width: 14),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin, size: 10, color: primary),
                            SizedBox(width: 2),
                            Text(
                              'Pinned',
                              style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (uid != null)
            StreamBuilder<bool>(
              stream: controller.streamCommentLikeStatus(widget.postId, comment.id, uid),
              builder: (context, snapshot) {
                final isLiked = snapshot.data ?? false;
                return GestureDetector(
                  onTap: () {
                    controller.toggleLikeComment(
                      postId: widget.postId,
                      commentId: comment.id,
                      userId: uid,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2.0, left: 8.0, right: 8.0),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey.shade400,
                      size: 13,
                    ),
                  ),
                );
              },
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

class _LikesSheet extends StatelessWidget {
  final String postId;
  final String? currentUserId;

  const _LikesSheet({Key? key, required this.postId, this.currentUserId}) : super(key: key);

  static const Color primary = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Likes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .doc(postId)
                  .collection('likes')
                  .orderBy('likedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primary));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No likes yet',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final userName = data['userName'] ?? 'User';
                    final userPhoto = data['userPhoto'] ?? '';
                    final userId = docs[index].id;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE5F6F8),
                        backgroundImage: userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
                        child: userPhoto.isEmpty ? const Icon(Icons.person, color: primary) : null,
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                              userId: userId,
                              userName: userName,
                              userType: 'volunteer',
                              userPhoto: userPhoto,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandableCaptionWidget extends StatefulWidget {
  final String content;

  const ExpandableCaptionWidget({Key? key, required this.content}) : super(key: key);

  @override
  State<ExpandableCaptionWidget> createState() => _ExpandableCaptionWidgetState();
}

class _ExpandableCaptionWidgetState extends State<ExpandableCaptionWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isLongText = widget.content.length > 80;

    return GestureDetector(
      onTap: () {
        if (isLongText) {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        }
      },
      child: RichText(
        maxLines: _isExpanded ? null : 2,
        overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
          children: [
            TextSpan(text: widget.content),
            if (isLongText && !_isExpanded)
              const TextSpan(
                text: ' ...more',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
