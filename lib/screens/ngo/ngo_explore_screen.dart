import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ngo_app/features/community/presentation/screens/post_feed_screen.dart';
import 'package:ngo_app/features/community/domain/models/community_post.dart';
import 'package:ngo_app/features/community/presentation/screens/video_player_widget.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';

class NgoExploreScreen extends StatefulWidget {
  final String? userId;
  
  const NgoExploreScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<NgoExploreScreen> createState() => _NgoExploreScreenState();
}

class _NgoExploreScreenState extends State<NgoExploreScreen> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserId;

  late Stream<QuerySnapshot> _feedStream;
  late Stream<QuerySnapshot> _ngosStream;
  late Stream<QuerySnapshot> _ngosFallbackStream;
  late Stream<QuerySnapshot> _volunteerStream;
  late Stream<QuerySnapshot> _volunteerFallbackStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Cache userId - prefer passed parameter, then try Firebase Auth
    _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    debugPrint('NgoExploreScreen: User ID = $_currentUserId');
    
    _initStreams();
    
    // Listen for auth state changes in case user wasn't fully loaded
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted && user != null && _currentUserId == null) {
        setState(() {
          _currentUserId = user.uid;
        });
        debugPrint('NgoExploreScreen: Auth state updated - User ID = $_currentUserId');
      }
    });
  }

  void _initStreams() {
    _feedStream = FirebaseFirestore.instance
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();

    _ngosStream = FirebaseFirestore.instance
        .collection('community_posts')
        .where('userType', isEqualTo: 'ngo')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();

    _ngosFallbackStream = FirebaseFirestore.instance
        .collection('community_posts')
        .snapshots();

    _volunteerStream = FirebaseFirestore.instance
        .collection('community_posts')
        .where('userType', isEqualTo: 'volunteer')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();

    _volunteerFallbackStream = FirebaseFirestore.instance
        .collection('community_posts')
        .snapshots();
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search here',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'My Feed'),
                  Tab(text: 'NGOs'),
                  Tab(text: 'Volunteer'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFeedGrid(), // All posts
                  _buildNgosGrid(), // Posts by NGOs
                  _buildVolunteerGrid(), // Posts by Volunteers
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // My Feed - All posts
  Widget _buildFeedGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _feedStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GridSkeleton();
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final posts = snapshot.data?.docs ?? [];
        
        if (posts.isEmpty) {
          return _buildEmptyState('No posts yet', 'Be the first to share something!');
        }
        
        return _buildStaggeredGrid(posts);
      },
    );
  }

  // NGOs tab - Posts by NGO members
  Widget _buildNgosGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ngosStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GridSkeleton();
        }
        
        if (snapshot.hasError) {
          // If index error, try without ordering
          return _buildNgosGridFallback();
        }
        
        final posts = snapshot.data?.docs ?? [];
        
        if (posts.isEmpty) {
          return _buildEmptyState('No NGO posts yet', 'NGO members haven\'t posted anything yet');
        }
        
        return _buildStaggeredGrid(posts);
      },
    );
  }

  Widget _buildNgosGridFallback() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ngosFallbackStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GridSkeleton();
        }
        
        final allPosts = snapshot.data?.docs ?? [];
        final ngoPosts = allPosts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['userType'] == 'ngo';
        }).toList();
        
        if (ngoPosts.isEmpty) {
          return _buildEmptyState('No NGO posts yet', 'NGO members haven\'t posted anything yet');
        }
        
        return _buildStaggeredGrid(ngoPosts);
      },
    );
  }

  // Volunteer tab - Posts by Volunteers
  Widget _buildVolunteerGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _volunteerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GridSkeleton();
        }
        
        if (snapshot.hasError) {
          // If index error, try without ordering
          return _buildVolunteerGridFallback();
        }
        
        final posts = snapshot.data?.docs ?? [];
        
        if (posts.isEmpty) {
          return _buildEmptyState('No volunteer posts yet', 'Volunteers haven\'t posted anything yet');
        }
        
        return _buildStaggeredGrid(posts);
      },
    );
  }

  Widget _buildVolunteerGridFallback() {
    return StreamBuilder<QuerySnapshot>(
      stream: _volunteerFallbackStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GridSkeleton();
        }
        
        final allPosts = snapshot.data?.docs ?? [];
        final volunteerPosts = allPosts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['userType'] == 'volunteer';
        }).toList();
        
        if (volunteerPosts.isEmpty) {
          return _buildEmptyState('No volunteer posts yet', 'Volunteers haven\'t posted anything yet');
        }
        
        return _buildStaggeredGrid(volunteerPosts);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredGrid(List<QueryDocumentSnapshot> posts) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _initStreams();
        });
      },
      color: primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: _buildGridRows(posts, posts),
        ),
      ),
    );
  }

  List<Widget> _buildGridRows(List<QueryDocumentSnapshot> posts, List<QueryDocumentSnapshot> allPosts) {
    List<Widget> rows = [];
    int index = 0;
    int rowType = 0;

    while (index < posts.length) {
      switch (rowType % 4) {
        case 0:
          // Row type 1: 2 equal squares
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: _buildGridItem(posts.length > index ? posts[index++] : null, 1, allPosts)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildGridItem(posts.length > index ? posts[index++] : null, 1, allPosts)),
                ],
              ),
            ),
          );
          break;
        case 1:
          // Row type 2: 1 large + 2 stacked small
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildGridItem(posts.length > index ? posts[index++] : null, 2, allPosts),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        _buildGridItem(posts.length > index ? posts[index++] : null, 1, allPosts),
                        const SizedBox(height: 8),
                        _buildGridItem(posts.length > index ? posts[index++] : null, 1, allPosts),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          break;
        case 2:
          // Row type 3: 3 equal squares
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: _buildGridItem(posts.length > index ? posts[index++] : null, 1, allPosts)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildGridItem(posts.length > index ? posts[index++] : null, 1, allPosts)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildGridItem(posts.length > index ? posts[index++] : null, 1, allPosts)),
                ],
              ),
            ),
          );
          break;
        case 3:
          // Row type 4: 2 stacked small + 1 large
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildGridItem(posts.length > index ? posts[index++] : null, 1, allPosts),
                        const SizedBox(height: 8),
                        _buildGridItem(posts.length > index ? posts[index++] : null, 1, allPosts),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGridItem(posts.length > index ? posts[index++] : null, 2, allPosts),
                  ),
                ],
              ),
            ),
          );
          break;
      }
      rowType++;
    }

    return rows;
  }

  Widget _buildGridItem(QueryDocumentSnapshot? doc, int sizeMultiplier, List<QueryDocumentSnapshot> allPosts) {
    if (doc == null) {
      return const SizedBox.shrink();
    }

    final data = doc.data() as Map<String, dynamic>;
    final baseHeight = (MediaQuery.of(context).size.width - 48) / 3;
    final height = baseHeight * sizeMultiplier + (sizeMultiplier > 1 ? 8 : 0);
    
    final imageUrl = data['imageUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    final content = data['content'] as String? ?? '';
    final userName = data['userName'] as String? ?? 'User';
    final userType = data['userType'] as String? ?? '';
    
    final int postIndex = allPosts.indexWhere((p) => p.id == doc.id);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostFeedScreen(
              posts: allPosts.map((doc) => CommunityPost.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList(),
              initialIndex: postIndex >= 0 ? postIndex : 0,
              userId: _currentUserId,
            ),
          ),
        );
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (videoUrl != null && videoUrl.isNotEmpty)
                Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoThumbnailPlayer(videoUrl: videoUrl),
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                    ),
                  ],
                )
              else if (imageUrl != null && imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildTextPost(content, userName, userType),
                )
              else
                _buildTextPost(content, userName, userType),
              
              // Overlay with user info for image/video posts
              if ((imageUrl != null && imageUrl.isNotEmpty) || (videoUrl != null && videoUrl.isNotEmpty))
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          userType == 'ngo' ? Icons.business : Icons.person,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextPost(String content, String userName, String userType) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: userType == 'ngo' 
              ? [primary.withValues(alpha: 0.8), primary]
              : [Colors.purple.shade400, Colors.purple.shade600],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                userType == 'ngo' ? Icons.business : Icons.person,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
