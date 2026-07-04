import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/community_post.dart';
import '../../domain/models/community_comment.dart';
import '../controllers/community_controller.dart';
import 'video_player_widget.dart';

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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showPostOptions(CommunityPost post, CommunityController controller) {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    final isOwner = userId == post.authorId;

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
                leading: const Icon(Icons.edit, color: primary),
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
                  _confirmDeletePost(controller);
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

  void _confirmDeletePost(CommunityController controller) {
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
                await controller.deletePost(postId: widget.postId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post deleted'),
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
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment(CommunityController controller) async {
    if (_commentController.text.trim().isEmpty) return;

    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
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

      await controller.addComment(
        postId: widget.postId,
        content: _commentController.text.trim(),
        authorId: userId,
        authorName: userName,
        authorPhoto: userPhoto,
        authorType: 'volunteer',
      );

      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added'),
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

  Future<void> _toggleLike(CommunityController controller, bool isLiked) async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    final userName = widget.userName ?? user?.displayName ?? 'User';

    await controller.toggleLikePost(
      postId: widget.postId,
      userId: userId,
      userName: userName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CommunityController>();
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<CommunityPost?>(
      stream: controller.streamCommunityPost(widget.postId),
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final post = postSnapshot.data;
        if (post == null) {
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

        return StreamBuilder<bool>(
          stream: controller.streamPostLikeStatus(widget.postId, userId),
          builder: (context, likeSnapshot) {
            final isLiked = likeSnapshot.data ?? false;

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
                    onPressed: () => _showPostOptions(post, controller),
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
                          _buildPostContent(post, isLiked, controller),
                          const Divider(height: 1),
                          _buildCommentsList(controller),
                        ],
                      ),
                    ),
                  ),
                  _buildCommentInput(controller),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostContent(CommunityPost post, bool isLiked, CommunityController controller) {
    final userName = post.authorName.isEmpty ? 'User' : post.authorName;
    final userPhoto = post.authorPhoto;
    final content = post.content;
    final imageUrl = post.imageUrl;
    final videoUrl = post.videoUrl;
    final createdAt = post.createdAt;
    final likesCount = post.likesCount;
    final commentsCount = post.commentsCount;
    final sharesCount = post.sharesCount;

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
                  backgroundColor: primary.withValues(alpha: 0.2),
                  backgroundImage: userPhoto.isNotEmpty
                      ? NetworkImage(userPhoto)
                      : null,
                  child: userPhoto.isEmpty
                      ? const Icon(Icons.person, color: primary)
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
                  onPressed: () => _showPostOptions(post, controller),
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
                if (post.title.isNotEmpty) ...[
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
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
                          const Icon(Icons.link, color: primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'View link',
                              style: const TextStyle(color: primary, fontSize: 13),
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
          // Video
          if (videoUrl != null && videoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CommunityVideoPlayer(videoUrl: videoUrl),
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
                    onPressed: () => _toggleLike(controller, isLiked),
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey.shade600,
                    ),
                    label: Text(
                      'Like',
                      style: TextStyle(
                        color: isLiked ? Colors.red : Colors.grey.shade600,
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

  Widget _buildCommentsList(CommunityController controller) {
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
          StreamBuilder<List<CommunityComment>>(
            stream: controller.streamPostComments(widget.postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final comments = snapshot.data ?? [];

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

  Widget _buildCommentsListView(List<CommunityComment> comments) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  Widget _buildCommentItem(CommunityComment comment) {
    final userName = comment.authorName.isEmpty ? 'User' : comment.authorName;
    final userPhoto = comment.authorPhoto;
    final content = comment.content;
    final createdAt = comment.createdAt;
    final likesCount = 0; // standard defaults
    final repliesCount = 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withValues(alpha: 0.2),
            backgroundImage: userPhoto.isNotEmpty
                ? NetworkImage(userPhoto)
                : null,
            child: userPhoto.isEmpty
                ? const Icon(Icons.person, color: primary, size: 18)
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

  Widget _buildCommentInput(CommunityController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withValues(alpha: 0.2),
            backgroundImage: widget.userPhoto != null && widget.userPhoto!.isNotEmpty
                ? NetworkImage(widget.userPhoto!)
                : null,
            child: widget.userPhoto == null || widget.userPhoto!.isEmpty
                ? const Icon(Icons.person, color: primary, size: 18)
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
            onPressed: () => _addComment(controller),
            icon: const Icon(Icons.send, color: primary),
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
