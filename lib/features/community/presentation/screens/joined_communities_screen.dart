import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/community_controller.dart';
import '../../domain/models/community.dart';
import 'community_detail_screen.dart';
import 'create_post_screen.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';

class JoinedCommunitiesScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType;

  const JoinedCommunitiesScreen({
    Key? key,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
  }) : super(key: key);

  @override
  State<JoinedCommunitiesScreen> createState() => _JoinedCommunitiesScreenState();
}

class _JoinedCommunitiesScreenState extends State<JoinedCommunitiesScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMembersSheet(String communityId, String communityName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Members of $communityName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: context.read<CommunityController>().streamCommunityMembers(communityId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: primary));
                    }
                    final members = snapshot.data ?? [];
                    if (members.isEmpty) {
                      return const Center(child: Text('No members found'));
                    }
                    return ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final name = member['memberName'] ?? 'Member';
                        final logo = member['memberLogo'] ?? '';
                        final role = member['role'] ?? 'member';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primary.withOpacity(0.1),
                            backgroundImage: logo.isNotEmpty ? NetworkImage(logo) : null,
                            child: logo.isEmpty ? const Icon(Icons.person, color: primary) : null,
                          ),
                          title: Text(name),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: role == 'creator' ? const Color(0xFFE5F6F8) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              role == 'creator' ? 'Admin' : 'Member',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: role == 'creator' ? primary : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Joined Communities',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: userId == null
            ? const Center(child: Text('Please login to view joined communities'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('members')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: ListSkeleton(itemCount: 3, height: 120),
                    );
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  final memberDocs = allDocs.where((doc) => doc.id == userId).toList();
                  if (memberDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No Joined Communities yet',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Search and Filter Bar
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Search your communities...',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.tune, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),

                      // Section Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Joined Communities',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Text(
                              '${memberDocs.length} Communities',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary),
                            ),
                          ],
                        ),
                      ),

                      // Communities List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          itemCount: memberDocs.length,
                          itemBuilder: (context, index) {
                            final memberDoc = memberDocs[index];
                            final communityId = memberDoc.reference.parent.parent!.id;
                            final memberData = memberDoc.data() as Map<String, dynamic>?;
                            final role = memberData != null && memberData.containsKey('role') ? memberData['role'] as String? ?? 'member' : 'member';

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('communities').doc(communityId).get(),
                              builder: (context, commSnapshot) {
                                if (commSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: SkeletonContainer(height: 120),
                                  );
                                }

                                if (!commSnapshot.hasData || !commSnapshot.data!.exists) {
                                  return const SizedBox.shrink();
                                }

                                final community = Community.fromMap(
                                  commSnapshot.data!.id,
                                  commSnapshot.data!.data() as Map<String, dynamic>,
                                );

                                final searchQuery = _searchController.text.toLowerCase();
                                if (searchQuery.isNotEmpty && !community.name.toLowerCase().contains(searchQuery)) {
                                  return const SizedBox.shrink();
                                }

                                return _buildJoinedCommunityCard(community, role);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildJoinedCommunityCard(Community community, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityDetailScreen(
                    communityId: community.id,
                    userId: widget.userId,
                    userName: widget.userName,
                    userPhoto: widget.userPhoto,
                    userType: widget.userType,
                  ),
                ),
              );
            },
            child: Column(
              children: [
          // Top Info Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE0F4F7),
                  backgroundImage: community.imageUrl.isNotEmpty ? NetworkImage(community.imageUrl) : null,
                  child: community.imageUrl.isEmpty ? const Icon(Icons.group, color: primary, size: 28) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        community.description.isNotEmpty ? community.description : 'Learning and growing together',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${community.memberCount} Members',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: role == 'creator' ? const Color(0xFFE5F6F8) : const Color(0xFFE0F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role == 'creator' ? 'Admin' : 'Member',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: role == 'creator' ? primary : const Color(0xFF00acc1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCardActionButton(
                  icon: Icons.group_outlined,
                  label: 'View Community',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityDetailScreen(
                          communityId: community.id,
                          userId: widget.userId,
                          userName: widget.userName,
                          userPhoto: widget.userPhoto,
                          userType: widget.userType,
                        ),
                      ),
                    );
                  },
                ),
                Container(width: 1, height: 20, color: Colors.grey.shade200),
                _buildCardActionButton(
                  icon: Icons.edit_outlined,
                  label: 'New Post',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatePostScreen(
                          userId: widget.userId,
                          userName: widget.userName,
                          userPhoto: widget.userPhoto,
                          userType: widget.userType,
                          communityId: community.id,
                          communityName: community.name,
                        ),
                      ),
                    );
                  },
                ),
                Container(width: 1, height: 20, color: Colors.grey.shade200),
                _buildCardActionButton(
                  icon: Icons.people_outline,
                  label: 'Members',
                  onTap: () => _showMembersSheet(community.id, community.name),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
),
);
}

  Widget _buildCardActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}
