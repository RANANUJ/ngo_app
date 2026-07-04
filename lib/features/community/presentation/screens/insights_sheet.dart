import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngo_app/features/profile/presentation/screens/user_profile_screen.dart';

class InsightsSheet extends StatelessWidget {
  final String postId;

  const InsightsSheet({
    Key? key,
    required this.postId,
  }) : super(key: key);

  static const Color primary = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .doc(postId)
            .collection('views')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 250,
              child: Center(
                child: CircularProgressIndicator(color: primary),
              ),
            );
          }

          final viewDocs = snapshot.data?.docs ?? [];
          final int viewCount = viewDocs.length;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title / Stats summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Post Insights',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$viewCount Views',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // List of viewers
              if (viewDocs.isEmpty)
                const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'No viewers recorded yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: viewDocs.length,
                      itemBuilder: (context, index) {
                        final data = viewDocs[index].data() as Map<String, dynamic>;
                        final String viewerId = data['userId'] ?? '';
                        final String name = data['userName'] ?? 'User';
                        final String username = data['userUsername'] ?? '';
                        final String photo = data['userPhoto'] ?? '';
                        final String area = data['area'] ?? 'Unknown';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: primary.withOpacity(0.1),
                            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                            child: photo.isEmpty
                                ? const Icon(Icons.person, color: primary, size: 22)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (username.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '@$username',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  area,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                          onTap: () {
                            if (viewerId.isEmpty) return;
                            _navigateToProfile(context, viewerId, name, photo);
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToProfile(BuildContext context, String viewerId, String viewerName, String viewerPhoto) async {
    // Show a small loader dialog while detecting userType
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: primary),
      ),
    );

    try {
      String userType = 'volunteer';
      final volDoc = await FirebaseFirestore.instance.collection('volunteers').doc(viewerId).get();
      if (!volDoc.exists) {
        final ngoDoc = await FirebaseFirestore.instance.collection('ngo_registrations').doc(viewerId).get();
        if (ngoDoc.exists) {
          userType = 'ngo';
        }
      }

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              userId: viewerId,
              userName: viewerName,
              userType: userType,
              userPhoto: viewerPhoto.isNotEmpty ? viewerPhoto : null,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }
}
