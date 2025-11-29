import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'create_opportunity_screen.dart';
import 'opportunity_detail_screen.dart';

class NgoOpportunitiesScreen extends StatefulWidget {
  final String ngoId;
  final String ngoName;

  const NgoOpportunitiesScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
  }) : super(key: key);

  @override
  State<NgoOpportunitiesScreen> createState() => _NgoOpportunitiesScreenState();
}

class _NgoOpportunitiesScreenState extends State<NgoOpportunitiesScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = My Opportunities, 1 = Applications

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Volunteer Opportunities',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_border, color: primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _buildTab(0, 'My Opportunities'),
                const SizedBox(width: 16),
                _buildTab(1, 'Applications'),
                const SizedBox(width: 16),
                _buildTab(2, 'Accepted'),
              ],
            ),
          ),
          
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search opportunities',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _selectedTab == 0 
                ? _buildOpportunitiesList()
                : _selectedTab == 1
                    ? _buildApplicationsList()
                    : _buildAcceptedList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateOpportunityScreen(
                ngoId: widget.ngoId,
                ngoName: widget.ngoName,
              ),
            ),
          );
        },
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Opportunity',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? primary : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: title.length * 7.0,
            color: isSelected ? primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunitiesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_opportunities')
          .where('ngoId', isEqualTo: widget.ngoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        
        // Filter by search query and sort locally
        var opportunities = docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final cause = (data['cause'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) || cause.contains(_searchQuery);
        }).toList();

        // Sort by createdAt descending
        opportunities.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (opportunities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volunteer_activism_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No opportunities yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first opportunity!',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: opportunities.length,
          itemBuilder: (context, index) {
            final doc = opportunities[index];
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return _buildOpportunityCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildApplicationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('opportunity_applications')
          .where('ngoId', isEqualTo: widget.ngoId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No pending applications',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Volunteer applications will appear here',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildApplicationCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildAcceptedList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('opportunity_applications')
          .where('ngoId', isEqualTo: widget.ngoId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No accepted volunteers yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accepted volunteers will appear here',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildAcceptedVolunteerCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildAcceptedVolunteerCard(String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Volunteer photo
              _buildVolunteerAvatar(data['volunteerId'], data['volunteerPhotoUrl']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['volunteerName'] ?? 'Volunteer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Accepted',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
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
                      data['volunteerEmail'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Opportunity info
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('volunteer_opportunities')
                .doc(data['opportunityId'])
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final oppData = snapshot.data!.data() as Map<String, dynamic>?;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.volunteer_activism, color: primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Applied for: ${oppData?['title'] ?? 'Unknown opportunity'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _contactVolunteer(data['volunteerEmail']),
                  icon: Icon(Icons.email_outlined, size: 16, color: primary),
                  label: Text('Contact', style: TextStyle(color: primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _removeAcceptedVolunteer(docId),
                  icon: const Icon(Icons.person_remove_outlined, size: 16, color: Colors.red),
                  label: const Text('Remove', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _contactVolunteer(String? email) async {
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not available')),
      );
      return;
    }
    
    final uri = Uri.parse('mailto:$email');
    try {
      await launchUrl(uri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open email client: $e')),
      );
    }
  }

  Future<void> _removeAcceptedVolunteer(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Volunteer'),
        content: const Text('Are you sure you want to remove this accepted volunteer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('opportunity_applications')
            .doc(docId)
            .update({'status': 'removed'});
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Volunteer removed'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildOpportunityCard(Map<String, dynamic> data, String docId) {
    final images = List<String>.from(data['images'] ?? []);
    final imageUrl = images.isNotEmpty ? images[0] : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OpportunityDetailScreen(
              opportunity: data,
              isNgoView: true,
            ),
          ),
        ).then((result) {
          if (result == true) {
            setState(() {});
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Opportunity image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.volunteer_activism, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.volunteer_activism, color: Colors.grey, size: 32),
                      ),
              ),
              const SizedBox(width: 12),

              // Opportunity details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Opportunity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${data['applicationsCount'] ?? '0'} applications',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: data['status'] == 'active' 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['status'] ?? 'active',
                            style: TextStyle(
                              fontSize: 10,
                              color: data['status'] == 'active' 
                                  ? Colors.green 
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                onSelected: (value) {
                  if (value == 'edit') {
                    // TODO: Edit opportunity
                  } else if (value == 'delete') {
                    _deleteOpportunity(docId);
                  } else if (value == 'toggle') {
                    _toggleOpportunityStatus(docId, data['status']);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          data['status'] == 'active' 
                              ? Icons.pause_circle_outline 
                              : Icons.play_circle_outline,
                          color: primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(data['status'] == 'active' ? 'Pause' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Volunteer photo
              _buildVolunteerAvatar(data['volunteerId'], data['volunteerPhotoUrl']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['volunteerName'] ?? 'Volunteer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    Text(
                      data['volunteerEmail'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Opportunity info
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('volunteer_opportunities')
                .doc(data['opportunityId'])
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final oppData = snapshot.data!.data() as Map<String, dynamic>?;
              return Text(
                'Applied for: ${oppData?['title'] ?? 'Unknown opportunity'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectApplication(docId),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptApplication(docId, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerAvatar(String? volunteerId, String? fallbackPhotoUrl) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary.withOpacity(0.1),
      ),
      child: volunteerId != null
          ? FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('volunteers')
                  .doc(volunteerId)
                  .get(),
              builder: (context, snapshot) {
                String? photoUrl;
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  photoUrl = data?['photoUrl'];
                }
                
                photoUrl ??= fallbackPhotoUrl;
                
                if (photoUrl != null && photoUrl.isNotEmpty) {
                  return ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.person, color: primary, size: 24),
                        );
                      },
                    ),
                  );
                }
                return Center(
                  child: Icon(Icons.person, color: primary, size: 24),
                );
              },
            )
          : Center(
              child: Icon(Icons.person, color: primary, size: 24),
            ),
    );
  }

  Future<void> _deleteOpportunity(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Opportunity'),
        content: const Text('Are you sure you want to delete this opportunity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('volunteer_opportunities')
            .doc(docId)
            .delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opportunity deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  Future<void> _toggleOpportunityStatus(String docId, String? currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'paused' : 'active';
    
    try {
      await FirebaseFirestore.instance
          .collection('volunteer_opportunities')
          .doc(docId)
          .update({'status': newStatus});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opportunity ${newStatus == 'active' ? 'activated' : 'paused'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _acceptApplication(String docId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('opportunity_applications')
          .doc(docId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['volunteerName']} accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectApplication(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('opportunity_applications')
          .doc(docId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
