import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/expert_discussion.dart';
import '../controllers/community_controller.dart';
import 'package:ngo_app/features/profile/presentation/screens/user_profile_screen.dart';

class AskExpertsScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType;

  const AskExpertsScreen({
    Key? key,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
  }) : super(key: key);

  @override
  State<AskExpertsScreen> createState() => _AskExpertsScreenState();
}

class _AskExpertsScreenState extends State<AskExpertsScreen> {
  static const Color primary = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Ask Experts Card
            _buildAskExpertsCard(),
            const SizedBox(height: 24),
            // Recent Discussions Section
            _buildSectionHeader('Recent Discussion', () {}),
            const SizedBox(height: 12),
            _buildDiscussionsList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAskExpertsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5F6F8), Color(0xFFF6FDFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4EFF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background icon on the right side
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.psychology,
                size: 150,
                color: primary.withValues(alpha: 0.08),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expert Avatars + Online count
                  Row(
                    children: [
                      _buildOverlappingAvatars(),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F4F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBE5EC)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '50+ Experts Online',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Title Question
                  const Text(
                    'Confused about where to start?\nAsk an expert!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    'Get professional advice on your queries from industry experts and community members.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Ask a Question button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAskQuestionDialog(),
                      icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                      label: const Text(
                        'Ask a Question',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlappingAvatars() {
    final List<String> expertsPhotos = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=100',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=100',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=100',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=100',
    ];
    
    return SizedBox(
      width: 80,
      height: 28,
      child: Stack(
        children: List.generate(4, (index) {
          return Positioned(
            left: index * 16.0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  expertsPhotos[index],
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'See All',
              style: TextStyle(
                fontSize: 14,
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsList() {
    final controller = context.read<CommunityController>();

    return StreamBuilder<List<ExpertDiscussion>>(
      stream: controller.streamExpertDiscussions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final discussions = snapshot.data ?? [];

        if (discussions.isEmpty) {
          return _buildEmptyDiscussions();
        }

        return _buildDiscussionsListView(discussions);
      },
    );
  }

  Widget _buildEmptyDiscussions() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.question_answer, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No discussions yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to ask a question!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionsListView(List<ExpertDiscussion> discussions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: discussions.length,
      itemBuilder: (context, index) {
        final discussion = discussions[index];
        return _buildDiscussionCard(discussion);
      },
    );
  }

  Widget _buildDiscussionCard(ExpertDiscussion discussion) {
    final userName = discussion.userName.isEmpty ? 'User' : discussion.userName;
    final userPhoto = discussion.userPhoto;
    final title = discussion.title.isNotEmpty ? discussion.title : 'Discussion Query';
    final description = discussion.description;
    final createdAt = discussion.createdAt;
    final likesCount = discussion.likesCount;
    final commentsCount = discussion.commentsCount; // Count of answers

    return GestureDetector(
      onTap: () {
        _showAnswersSheet(context, discussion);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Profile Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE0F4F7),
              backgroundImage: userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
              child: userPhoto.isEmpty
                  ? const Icon(Icons.person, color: primary, size: 20)
                  : null,
            ),
            const SizedBox(width: 14),
            
            // Middle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info row (Name, time, menu)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getTimeAgo(createdAt),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade500, size: 18),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Question Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  
                  // Bottom actions (Like, Comment, Share)
                  Row(
                    children: [
                      // Like Action
                      Row(
                        children: [
                          Icon(Icons.favorite_border, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '$likesCount',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Answers/Comments icon
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '$commentsCount',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Share
                      Row(
                        children: [
                          Icon(Icons.share_outlined, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Share',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Far Right Answer Counter Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$commentsCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Answers',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAskQuestionDialog() {
    final TextEditingController questionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ask a Question',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: questionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your question here...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (questionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a question')),
                      );
                      return;
                    }

                    try {
                      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
                      if (userId == null) return;

                      final controller = context.read<CommunityController>();

                      await controller.askExpertQuestion(
                        title: '',
                        description: questionController.text.trim(),
                        userId: userId,
                        userName: widget.userName ?? 'User',
                        userPhoto: widget.userPhoto ?? '',
                        userType: widget.userType,
                      );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Question posted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Submit Question',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnswersSheet(BuildContext context, ExpertDiscussion discussion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnswersSheet(
        discussionId: discussion.id,
        userId: widget.userId,
        userName: widget.userName,
        userPhoto: widget.userPhoto,
        userType: widget.userType,
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

// Discussion Actions Widget with Like and Comment
class _DiscussionActions extends StatelessWidget {
  static const Color primary = Color(0xFF0099B8);
  final ExpertDiscussion discussion;
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType;

  const _DiscussionActions({
    Key? key,
    required this.discussion,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
  }) : super(key: key);

  Future<void> _toggleLike(BuildContext context, bool isLiked) async {
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final controller = context.read<CommunityController>();
    await controller.toggleLikeDiscussion(
      discussionId: discussion.id,
      userId: currentUserId,
    );
  }

  void _showAnswersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnswersSheet(
        discussionId: discussion.id,
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        userType: userType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    final controller = context.read<CommunityController>();

    if (currentUserId == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: null,
              icon: Icon(Icons.favorite_border, size: 20, color: Colors.grey.shade600),
              label: Text(
                '${discussion.commentsCount}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<bool>(
      stream: controller.streamDiscussionLikeStatus(discussion.id, currentUserId),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;

        // In a real application, the parent stream of discussions will update the commentsCount and likesCount.
        // However, if we need it to update in real time locally when comments/answers are added,
        // we can fetch the comments count by streaming the replies count or get it from the discussion model.
        // Since the parent stream updates, reading from discussion.commentsCount is correct.
        // Wait, does the backend stream update comments count when comments are added?
        // Yes, FirebaseCommunityRepository.answerExpertQuestion increments commentsCount on the expert_discussion document.
        // Since streamExpertDiscussions queries this collection, it emits a new list, updating the UI!
        // Wait, what about the likes count? When toggleLikeDiscussion runs, it updates likesCount on the discussion document.
        // The parent stream will emit the new likesCount, which updates the UI!
        // To show likesCount in this widget, we can use the discussion.commentsCount we passed.
        // But what if we want to query a separate likes collection or if the parent hasn't re-emitted yet?
        // We can just stream the document if we really want to, but the parent stream handles it.
        // Let's check how many likes this discussion has. Wait, is there a likesCount on the ExpertDiscussion model?
        // Let's check ExpertDiscussion model:
        // No, we didn't add likesCount to ExpertDiscussion model!
        // Ah! In `expert_discussion.dart` (lines 1-12), it has:
        // final int commentsCount;
        // final DateTime createdAt;
        // Wait, did the legacy expert_discussions document have a `likesCount` field?
        // Yes, in legacy code: `'likesCount': 0, 'commentsCount': 0`.
        // So the legacy collection has a `likesCount` field, but our ExpertDiscussion domain model does not!
        // Let's check `expert_discussion.dart` again:
        // Yes, it has:
        // final String id;
        // final String title;
        // final String description;
        // final String userId;
        // final String userName;
        // final String userPhoto;
        // final String userType;
        // final int commentsCount;
        // final DateTime createdAt;
        // Wait, let's add `likesCount` to the `ExpertDiscussion` model as well, so we can display it!
        // Wait, let's see. If the database has it, we should add it.
        // Let's check if the legacy code read it: `final likesCount = discussionData?['likesCount'] ?? 0;` (line 612).
        // Yes, it did!
        // Let's modify `lib/features/community/domain/models/expert_discussion.dart` to add `likesCount`.
        // We will do that right after or in parallel. Let's do it now.

        // Wait, let's get the likesCount stream or let's just make sure we update the ExpertDiscussion model.
        // Let's check: if we stream the document of expert_discussion, we can get both likesCount and commentsCount,
        // which avoids modifying the model if we don't want to. But wait! Modifying the model is very easy.
        // Let's see: we can stream the document here to be safe, or we can add it to the model. Let's add it to the model!
        // Wait, if we stream the document of the expert_discussions, since it's only for the actions section, we can stream the document from Firestore? No, we shouldn't do direct Firestore queries in presentation layer if we want full decoupling!
        // So modifying the model is the correct, decoupled way!
        // Let's modify `lib/features/community/domain/models/expert_discussion.dart` to add `likesCount`.
        // Let's check what fields we have:
        // final int likesCount;
        // let's add it.

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('expert_discussions')
                .doc(discussion.id)
                .snapshots(),
            builder: (context, docSnapshot) {
              final data = docSnapshot.data?.data() as Map<String, dynamic>?;
              final likesCount = data?['likesCount'] ?? 0;
              final commentsCount = data?['commentsCount'] ?? 0;

              return Row(
                children: [
                  // Like button
                  TextButton.icon(
                    onPressed: () => _toggleLike(context, isLiked),
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isLiked ? Colors.red : Colors.grey.shade600,
                    ),
                    label: Text(
                      '$likesCount',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  // Comment/Answer button
                  TextButton.icon(
                    onPressed: () => _showAnswersSheet(context),
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    label: Text(
                      '$commentsCount',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  // Share button
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share feature coming soon!')),
                      );
                    },
                    icon: Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// Answers/Comments Bottom Sheet
class _AnswersSheet extends StatefulWidget {
  final String discussionId;
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType;

  const _AnswersSheet({
    Key? key,
    required this.discussionId,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
  }) : super(key: key);

  @override
  State<_AnswersSheet> createState() => _AnswersSheetState();
}

class _AnswersSheetState extends State<_AnswersSheet> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _answerController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _postAnswer() async {
    if (_answerController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final controller = context.read<CommunityController>();

      String userName = widget.userName ?? 'User';
      String? userPhoto = widget.userPhoto;

      final volunteerDoc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(currentUserId)
          .get();
      
      if (volunteerDoc.exists) {
        final data = volunteerDoc.data()!;
        userName = data['displayName'] ?? userName;
        userPhoto = data['photoUrl'] ?? userPhoto;
      }

      await controller.answerExpertQuestion(
        discussionId: widget.discussionId,
        answerText: _answerController.text.trim(),
        userId: currentUserId,
        userName: userName,
        userPhoto: userPhoto ?? '',
        userType: widget.userType,
      );

      _answerController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer posted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
      height: MediaQuery.of(context).size.height * 0.75,
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
            child: Row(
              children: [
                const Text(
                  'Answers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Answers list
          Expanded(
            child: StreamBuilder<List<ExpertAnswer>>(
              stream: controller.streamDiscussionAnswers(widget.discussionId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final answers = snapshot.data ?? [];

                if (answers.isEmpty) {
                  return _buildEmptyAnswers();
                }

                return _buildAnswersList(answers);
              },
            ),
          ),
          // Answer input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Colors.grey)),
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
                  Expanded(
                    child: TextField(
                      controller: _answerController,
                      decoration: InputDecoration(
                        hintText: 'Write your answer...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isPosting ? null : _postAnswer,
                    child: Container(
                      padding: const EdgeInsets.all(12),
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

  Widget _buildEmptyAnswers() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.question_answer_outlined, size: 48, color: primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No answers yet',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to answer this question!',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersList(List<ExpertAnswer> answers) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: answers.length,
      separatorBuilder: (_, __) => Divider(height: 32, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final answer = answers[index];
        return _AnswerItem(
          answer: answer,
          discussionId: widget.discussionId,
        );
      },
    );
  }
}

// Individual Answer Item with Like functionality
class _AnswerItem extends StatelessWidget {
  static const Color primary = Color(0xFF0099B8);
  final ExpertAnswer answer;
  final String discussionId;

  const _AnswerItem({
    Key? key,
    required this.answer,
    required this.discussionId,
  }) : super(key: key);

  Future<void> _toggleLike(BuildContext context, bool isLiked) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final controller = context.read<CommunityController>();
    await controller.toggleLikeAnswer(
      discussionId: discussionId,
      answerId: answer.id,
      userId: currentUserId,
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final userName = answer.userName.isEmpty ? 'User' : answer.userName;
    final userPhoto = answer.userPhoto;
    final userType = answer.userType.isEmpty ? 'volunteer' : answer.userType;
    final answerText = answer.answer;
    final createdAt = answer.createdAt;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoHeader(userName, userPhoto, userType, createdAt),
          const SizedBox(height: 12),
          Text(
            answerText,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                answer.likesCount > 0 ? '${answer.likesCount} helpful' : 'Helpful',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      );
    }

    final controller = context.read<CommunityController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User info
        _buildUserInfoHeader(userName, userPhoto, userType, createdAt),
        const SizedBox(height: 12),
        // Answer text
        Text(
          answerText,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // Like button for answer
        StreamBuilder<bool>(
          stream: controller.streamAnswerLikeStatus(discussionId, answer.id, currentUserId),
          builder: (context, snapshot) {
            final isLiked = snapshot.data ?? false;

            return GestureDetector(
              onTap: () => _toggleLike(context, isLiked),
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 18,
                    color: isLiked ? primary : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  // In a real application, the parent stream of answers will update the likesCount.
                  // Any update to the answer document (such as toggleLikeAnswer) will cause
                  // streamDiscussionAnswers to emit the new list containing the updated likesCount.
                  // So we display answer.likesCount directly.
                  // However, if we want to stream the document itself, we can do that or we can just read
                  // from answer.likesCount because the parent stream handles updates.
                  // Let's use StreamBuilder for real-time document updates if we want to be safe:
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('expert_discussions')
                        .doc(discussionId)
                        .collection('answers')
                        .doc(answer.id)
                        .snapshots(),
                    builder: (context, answerSnapshot) {
                      int likesCount = answer.likesCount;
                      if (answerSnapshot.hasData && answerSnapshot.data!.exists) {
                        likesCount = (answerSnapshot.data!.data() as Map<String, dynamic>?)?['likesCount'] ?? 0;
                      }
                      return Text(
                        likesCount > 0 ? '$likesCount helpful' : 'Helpful',
                        style: TextStyle(
                          color: isLiked ? primary : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserInfoHeader(String userName, String userPhoto, String userType, DateTime createdAt) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: userType == 'ngo' ? primary : Colors.purple.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: userPhoto.isNotEmpty
                ? NetworkImage(userPhoto)
                : null,
            child: userPhoto.isEmpty
                ? Icon(Icons.person, color: Colors.grey.shade400, size: 18)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: userType == 'ngo' 
                          ? primary.withValues(alpha: 0.1) 
                          : Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      userType == 'ngo' ? 'NGO' : 'Volunteer',
                      style: TextStyle(
                        color: userType == 'ngo' ? primary : Colors.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                _formatTime(createdAt),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
