import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/community.dart';
import '../controllers/community_controller.dart';
import 'community_detail_screen.dart';

class AllCommunitiesScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType;

  const AllCommunitiesScreen({
    Key? key,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
  }) : super(key: key);

  @override
  State<AllCommunitiesScreen> createState() => _AllCommunitiesScreenState();
}

class _AllCommunitiesScreenState extends State<AllCommunitiesScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all'; // all, public, private

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Communities',
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
                hintText: 'Search communities...',
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
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Public', 'public'),
                const SizedBox(width: 8),
                _buildFilterChip('Private', 'private'),
              ],
            ),
          ),
          // Communities List
          Expanded(
            child: StreamBuilder<List<Community>>(
              stream: context.read<CommunityController>().streamCommunities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var communities = snapshot.data ?? [];

                // Apply filters
                communities = communities.where((community) {
                  final name = community.name.toLowerCase();
                  final isPublic = community.isPublic;

                  // Search filter
                  if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
                    return false;
                  }

                  // Privacy filter
                  if (_filter == 'public' && !isPublic) return false;
                  if (_filter == 'private' && isPublic) return false;

                  return true;
                }).toList();

                if (communities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No communities found',
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
                    itemCount: communities.length,
                    itemBuilder: (context, index) {
                      final community = communities[index];
                      return _buildCommunityListItem(community);
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityListItem(Community community) {
    final displayImage = community.creatorLogo;
    final name = community.name;
    final description = community.description;
    final membersCount = community.memberCount;
    final isPublic = community.isPublic;

    return GestureDetector(
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: displayImage.isNotEmpty
                  ? Image.network(
                      displayImage,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.group, color: primary, size: 40),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.group, color: primary, size: 40),
                    ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPublic ? primary.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPublic ? Icons.public : Icons.lock,
                                size: 12,
                                color: isPublic ? primary : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPublic ? 'Public' : 'Private',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isPublic ? primary : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '$membersCount members',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
