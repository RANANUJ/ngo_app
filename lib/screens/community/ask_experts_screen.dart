import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, primary.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expert Avatars
          Row(
            children: [
              _buildOverlappingAvatars(),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 14, color: primary),
                    const SizedBox(width: 4),
                    Text(
                      '50+ Experts',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Confused about where to start? Ask an expert!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get professional advice on your queries from industry experts and community members.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAskQuestionDialog(),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Ask a question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlappingAvatars() {
    final List<Color> avatarColors = [
      primary,
      Colors.orange,
      Colors.purple,
      Colors.green,
    ];
    
    return SizedBox(
      width: 110,
      height: 44,
      child: Stack(
        children: List.generate(4, (index) {
          return Positioned(
            left: index * 24.0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: avatarColors[index].withOpacity(0.2),
              ),
              child: Icon(Icons.person, color: avatarColors[index], size: 20),
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
            child: Text(
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('expert_discussions')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Fallback without orderBy
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('expert_discussions')
                .limit(10)
                .snapshots(),
            builder: (context, fallbackSnapshot) {
              if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var discussions = fallbackSnapshot.data?.docs ?? [];
              discussions = List.from(discussions)..sort((a, b) {
                final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
                final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              if (discussions.isEmpty) {
                return _buildEmptyDiscussions();
              }

              return _buildDiscussionsListView(discussions);
            },
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final discussions = snapshot.data?.docs ?? [];

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

  Widget _buildDiscussionsListView(List<QueryDocumentSnapshot> discussions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: discussions.length,
      itemBuilder: (context, index) {
        final data = discussions[index].data() as Map<String, dynamic>;
        data['id'] = discussions[index].id;
        return _buildDiscussionCard(data);
      },
    );
  }

  Widget _buildDiscussionCard(Map<String, dynamic> discussion) {
    final discussionId = discussion['id'];
    final userName = discussion['userName'] ?? 'User';
    final userPhoto = discussion['userPhoto'];
    final question = discussion['question'] ?? '';
    final createdAt = (discussion['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: primary.withOpacity(0.1),
                    backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                        ? NetworkImage(userPhoto)
                        : null,
                    child: userPhoto == null || userPhoto.isEmpty
                        ? Icon(Icons.person, color: primary, size: 22)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (createdAt != null)
                        Text(
                          _getTimeAgo(createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: Colors.grey.shade500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'report', child: Text('Report')),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                  ],
                  onSelected: (value) {
                    // Handle menu actions
                  },
                ),
              ],
            ),
          ),
          // Question
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              question,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Divider(height: 1, color: Colors.grey.shade200),
          // Action buttons
          _DiscussionActions(
            discussionId: discussionId,
            userId: widget.userId,
            userName: widget.userName,
            userPhoto: widget.userPhoto,
            userType: widget.userType,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
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

                      await FirebaseFirestore.instance.collection('expert_discussions').add({
                        'userId': userId,
                        'userName': widget.userName ?? 'User',
                        'userPhoto': widget.userPhoto,
                        'userType': widget.userType,
                        'question': questionController.text.trim(),
                        'likesCount': 0,
                        'commentsCount': 0,
                        'sharesCount': 0,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

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
  final String discussionId;
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType;

  const _DiscussionActions({
    Key? key,
    required this.discussionId,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
  }) : super(key: key);

  Future<void> _toggleLike(bool isLiked) async {
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final discussionRef = FirebaseFirestore.instance.collection('expert_discussions').doc(discussionId);
    final likeRef = discussionRef.collection('likes').doc(currentUserId);

    if (isLiked) {
      await likeRef.delete();
      await discussionRef.update({'likesCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'userId': currentUserId, 'createdAt': FieldValue.serverTimestamp()});
      await discussionRef.update({'likesCount': FieldValue.increment(1)});
    }
  }

  void _showAnswersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnswersSheet(
        discussionId: discussionId,
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('expert_discussions')
          .doc(discussionId)
          .snapshots(),
      builder: (context, discussionSnapshot) {
        final discussionData = discussionSnapshot.data?.data() as Map<String, dynamic>?;
        final likesCount = discussionData?['likesCount'] ?? 0;
        final commentsCount = discussionData?['commentsCount'] ?? 0;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('expert_discussions')
              .doc(discussionId)
              .collection('likes')
              .doc(currentUserId)
              .snapshots(),
          builder: (context, likeSnapshot) {
            final isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Like button
                  TextButton.icon(
                    onPressed: () => _toggleLike(isLiked),
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
                    label: Text(
                      'Share',
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
                ],
              ),
            );
          },
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

      String userName = widget.userName ?? 'User';
      String? userPhoto = widget.userPhoto;

      // Try to get updated user info
      final volunteerDoc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(currentUserId)
          .get();
      
      if (volunteerDoc.exists) {
        final data = volunteerDoc.data()!;
        userName = data['displayName'] ?? userName;
        userPhoto = data['photoUrl'] ?? userPhoto;
      }

      // Add answer
      await FirebaseFirestore.instance
          .collection('expert_discussions')
          .doc(widget.discussionId)
          .collection('answers')
          .add({
        'userId': currentUserId,
        'userName': userName,
        'userPhoto': userPhoto,
        'userType': widget.userType,
        'answer': _answerController.text.trim(),
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update answers count
      await FirebaseFirestore.instance
          .collection('expert_discussions')
          .doc(widget.discussionId)
          .update({'commentsCount': FieldValue.increment(1)});

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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expert_discussions')
                  .doc(widget.discussionId)
                  .collection('answers')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Fallback without orderBy
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('expert_discussions')
                        .doc(widget.discussionId)
                        .collection('answers')
                        .snapshots(),
                    builder: (context, fallbackSnapshot) {
                      if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var answers = fallbackSnapshot.data?.docs ?? [];
                      answers = List.from(answers)..sort((a, b) {
                        final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
                        final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
                        if (aTime == null || bTime == null) return 0;
                        return aTime.compareTo(bTime);
                      });

                      if (answers.isEmpty) {
                        return _buildEmptyAnswers();
                      }

                      return _buildAnswersList(answers);
                    },
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final answers = snapshot.data?.docs ?? [];

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
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                      decoration: BoxDecoration(
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
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.question_answer_outlined, size: 48, color: primary),
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

  Widget _buildAnswersList(List<QueryDocumentSnapshot> answers) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: answers.length,
      separatorBuilder: (_, __) => Divider(height: 32, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final data = answers[index].data() as Map<String, dynamic>;
        data['id'] = answers[index].id;
        return _AnswerItem(
          answerId: data['id'],
          discussionId: widget.discussionId,
          data: data,
        );
      },
    );
  }
}

// Individual Answer Item with Like functionality
class _AnswerItem extends StatelessWidget {
  static const Color primary = Color(0xFF0099B8);
  final String answerId;
  final String discussionId;
  final Map<String, dynamic> data;

  const _AnswerItem({
    Key? key,
    required this.answerId,
    required this.discussionId,
    required this.data,
  }) : super(key: key);

  Future<void> _toggleLike(bool isLiked) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final answerRef = FirebaseFirestore.instance
        .collection('expert_discussions')
        .doc(discussionId)
        .collection('answers')
        .doc(answerId);
    final likeRef = answerRef.collection('likes').doc(currentUserId);

    if (isLiked) {
      await likeRef.delete();
      await answerRef.update({'likesCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'userId': currentUserId, 'createdAt': FieldValue.serverTimestamp()});
      await answerRef.update({'likesCount': FieldValue.increment(1)});
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
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
    final userName = data['userName'] ?? 'User';
    final userPhoto = data['userPhoto'] as String?;
    final userType = data['userType'] ?? 'volunteer';
    final answer = data['answer'] ?? '';
    final createdAt = data['createdAt'] as Timestamp?;
    final likesCount = data['likesCount'] ?? 0;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User info
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: userType == 'ngo' ? primary : Colors.purple.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                    ? NetworkImage(userPhoto)
                    : null,
                child: userPhoto == null || userPhoto.isEmpty
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
                              ? primary.withOpacity(0.1) 
                              : Colors.purple.withOpacity(0.1),
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
        ),
        const SizedBox(height: 12),
        // Answer text
        Text(
          answer,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // Like button for answer
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('expert_discussions')
              .doc(discussionId)
              .collection('answers')
              .doc(answerId)
              .collection('likes')
              .doc(currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            final isLiked = snapshot.hasData && snapshot.data!.exists;

            return GestureDetector(
              onTap: () => _toggleLike(isLiked),
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 18,
                    color: isLiked ? primary : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('expert_discussions')
                        .doc(discussionId)
                        .collection('answers')
                        .doc(answerId)
                        .snapshots(),
                    builder: (context, answerSnapshot) {
                      int count = likesCount;
                      if (answerSnapshot.hasData && answerSnapshot.data!.exists) {
                        count = (answerSnapshot.data!.data() as Map<String, dynamic>?)?['likesCount'] ?? 0;
                      }
                      return Text(
                        count > 0 ? '$count helpful' : 'Helpful',
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
}
