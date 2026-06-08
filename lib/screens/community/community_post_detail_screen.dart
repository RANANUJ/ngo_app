import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final String postId;
  final String? userId;
  final String? userName;
  final String? userPhoto;

  const CommunityPostDetailScreen({
    Key? key,
    required this.postId,
    this.userId,
    this.userName,
    this.userPhoto,
  }) : super(key: key);

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _commentController = TextEditingController();
  Map<String, dynamic>? _postData;
  bool _isLoading = true;
  bool _hasLiked = false;

  @override
  void initState() {
    super.initState();
    _loadPostData();
    _checkIfLiked();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .get();

      if (doc.exists) {
        setState(() {
          _postData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIfLiked() async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final likeDoc = await FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(userId)
        .get();

    setState(() => _hasLiked = likeDoc.exists);
  }

  Future<void> _toggleLike() async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      if (_hasLiked) {
        await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .collection('likes')
            .doc(userId)
            .delete();

        await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .update({'likesCount': FieldValue.increment(-1)});

        setState(() => _hasLiked = false);
      } else {
        await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .collection('likes')
            .doc(userId)
            .set({
          'userId': userId,
          'userName': widget.userName,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .update({'likesCount': FieldValue.increment(1)});

        setState(() => _hasLiked = true);
      }
      _loadPostData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showPostOptions() {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    final postOwnerId = _postData?['userId'];
    final isOwner = userId == postOwnerId;

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
            if (isOwner) ...[
              ListTile(
                leading: Icon(Icons.edit, color: primary),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePost();
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.bookmark_border, color: Colors.grey.shade700),
              title: const Text('Save Post'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.share, color: Colors.grey.shade700),
              title: const Text('Share Post'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: Colors.grey.shade700),
              title: const Text('Report Post'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('community_posts')
                    .doc(widget.postId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'userId': userId,
        'userName': widget.userName ?? 'User',
        'userPhoto': widget.userPhoto,
        'content': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'repliesCount': 0,
      });

      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .update({'commentsCount': FieldValue.increment(1)});

      _commentController.clear();
      _loadPostData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added'),
          backgroundColor: Colors.green,
        ),
      );
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

    if (_postData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Post not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostContent(),
                  const Divider(height: 1),
                  _buildCommentsList(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    final userName = _postData?['userName'] ?? 'User';
    final userPhoto = _postData?['userPhoto'];
    final content = _postData?['content'] ?? '';
    final imageUrl = _postData?['imageUrl'];
    final createdAt = (_postData?['createdAt'] as Timestamp?)?.toDate();
    final likesCount = _postData?['likesCount'] ?? 0;
    final commentsCount = _postData?['commentsCount'] ?? 0;
    final sharesCount = _postData?['sharesCount'] ?? 0;

    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primary.withOpacity(0.2),
                  backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                      ? NetworkImage(userPhoto)
                      : null,
                  child: userPhoto == null || userPhoto.isEmpty
                      ? Icon(Icons.person, color: primary)
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
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _getTimeAgo(createdAt),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.grey.shade600),
                  onPressed: () => _showPostOptions(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                // Check for links
                if (content.contains('http'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link, color: primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'View link',
                              style: TextStyle(color: primary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
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
          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.red.shade400),
                const SizedBox(width: 4),
                Text(
                  '$likesCount Likes',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '$commentsCount Comments',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.share_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '$sharesCount Shares',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          // Action Buttons
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _toggleLike,
                    icon: Icon(
                      _hasLiked ? Icons.favorite : Icons.favorite_border,
                      color: _hasLiked ? Colors.red : Colors.grey.shade600,
                    ),
                    label: Text(
                      'Like',
                      style: TextStyle(
                        color: _hasLiked ? Colors.red : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.chat_bubble_outline, color: Colors.grey.shade600),
                    label: Text(
                      'Comment',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.share_outlined, color: Colors.grey.shade600),
                    label: Text(
                      'Share',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Comments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community_posts')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // Fallback without orderBy
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('community_posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, fallbackSnapshot) {
                    if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    var comments = fallbackSnapshot.data?.docs ?? [];
                    comments = List.from(comments)..sort((a, b) {
                      final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
                      final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
                      if (aTime == null || bTime == null) return 0;
                      return bTime.compareTo(aTime);
                    });

                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first!',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }

                    return _buildCommentsListView(comments);
                  },
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final comments = snapshot.data?.docs ?? [];

              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No comments yet. Be the first!',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              return _buildCommentsListView(comments);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsListView(List<QueryDocumentSnapshot> comments) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final data = comments[index].data() as Map<String, dynamic>;
        return _buildCommentItem(data, comments[index].id);
      },
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, String commentId) {
    final userName = comment['userName'] ?? 'User';
    final userPhoto = comment['userPhoto'];
    final content = comment['content'] ?? '';
    final createdAt = (comment['createdAt'] as Timestamp?)?.toDate();
    final likesCount = comment['likesCount'] ?? 0;
    final repliesCount = comment['repliesCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withOpacity(0.2),
            backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                ? NetworkImage(userPhoto)
                : null,
            child: userPhoto == null || userPhoto.isEmpty
                ? Icon(Icons.person, color: primary, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (createdAt != null)
                      Text(
                        _getTimeAgo(createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        '$likesCount',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.favorite_border, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        '$repliesCount Reply',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withOpacity(0.2),
            backgroundImage: widget.userPhoto != null && widget.userPhoto!.isNotEmpty
                ? NetworkImage(widget.userPhoto!)
                : null,
            child: widget.userPhoto == null || widget.userPhoto!.isEmpty
                ? Icon(Icons.person, color: primary, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add your comment...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _addComment,
            icon: Icon(Icons.send, color: primary),
          ),
        ],
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
}
