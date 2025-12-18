import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../opportunity_detail_screen.dart';

class VolunteerOpportunitiesScreen extends StatefulWidget {
  final bool isEmbedded;
  
  const VolunteerOpportunitiesScreen({
    Key? key, 
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  State<VolunteerOpportunitiesScreen> createState() => _VolunteerOpportunitiesScreenState();
}

class _VolunteerOpportunitiesScreenState extends State<VolunteerOpportunitiesScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = Opportunities, 1 = Sent, 2 = Accepted

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Tab Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _buildTab(0, AppLocalizations.of(context)!.opportunities),
              const SizedBox(width: 24),
              _buildTab(1, AppLocalizations.of(context)!.sent),
              const SizedBox(width: 24),
              _buildTab(2, AppLocalizations.of(context)!.accepted),
            ],
          ),
        ),
        
        // Search and Filter Row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.search,
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
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.tune, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Container(
        color: const Color(0xFFF5F9FA),
        child: content,
      );
    }

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
          AppLocalizations.of(context)!.opportunities,
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: content,
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
            width: title.length * 8.0,
            color: isSelected ? primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOpportunitiesList();
      case 1:
        return _buildSentRequestsList();
      case 2:
        return _buildAcceptedList();
      default:
        return _buildOpportunitiesList();
    }
  }

  Widget _buildOpportunitiesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_opportunities')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        
        // Filter by search query and sort by createdAt locally
        var opportunities = docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final ngoName = (data['ngoName'] ?? '').toString().toLowerCase();
          final cause = (data['cause'] ?? '').toString().toLowerCase();
          final location = (data['location'] ?? '').toString().toLowerCase();
          return ngoName.contains(_searchQuery) || 
                 cause.contains(_searchQuery) || 
                 location.contains(_searchQuery);
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
          return _buildEmptyState(
            icon: Icons.volunteer_activism_outlined,
            title: AppLocalizations.of(context)!.noOpportunitiesFound,
            subtitle: AppLocalizations.of(context)!.checkBackLater,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: opportunities.length,
          itemBuilder: (context, index) {
            final doc = opportunities[index];
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return _buildOpportunityCard(data, showApplyButton: true);
          },
        );
      },
    );
  }

  Widget _buildSentRequestsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: AppLocalizations.of(context)!.pleaseLogin,
        subtitle: AppLocalizations.of(context)!.loginToSeeSentRequests,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('opportunity_applications')
          .where('volunteerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mail_outline,
            title: AppLocalizations.of(context)!.noSentRequests,
            subtitle: AppLocalizations.of(context)!.appliedOpportunitiesAppearHere,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('volunteer_opportunities')
                  .doc(data['opportunityId'])
                  .get(),
              builder: (context, oppSnapshot) {
                if (!oppSnapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final oppData = oppSnapshot.data!.data() as Map<String, dynamic>?;
                if (oppData == null) return const SizedBox.shrink();
                oppData['id'] = data['opportunityId'];
                return _buildOpportunityCard(oppData, showApplyButton: false, status: 'Pending');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAcceptedList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: AppLocalizations.of(context)!.pleaseLogin,
        subtitle: AppLocalizations.of(context)!.loginToSeeAcceptedOpportunities,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('opportunity_applications')
          .where('volunteerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: AppLocalizations.of(context)!.noAcceptedOpportunities,
            subtitle: AppLocalizations.of(context)!.acceptedOpportunitiesAppearHere,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('volunteer_opportunities')
                  .doc(data['opportunityId'])
                  .get(),
              builder: (context, oppSnapshot) {
                if (!oppSnapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final oppData = oppSnapshot.data!.data() as Map<String, dynamic>?;
                if (oppData == null) return const SizedBox.shrink();
                oppData['id'] = data['opportunityId'];
                return _buildOpportunityCard(oppData, showApplyButton: false, status: 'Accepted');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOpportunityCard(Map<String, dynamic> data, 
      {bool showApplyButton = true, String? status}) {
    final images = List<String>.from(data['images'] ?? []);
    final imageUrl = images.isNotEmpty ? images[0] : '';
    final eventDate = (data['eventDate'] as Timestamp?)?.toDate();
    final location = data['location'] as String?;
    final latitude = data['latitude'] as double?;
    final longitude = data['longitude'] as double?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OpportunityDetailScreen(opportunity: data),
          ),
        );
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
                        width: 100,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 120,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.volunteer_activism, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.volunteer_activism, color: Colors.grey, size: 40),
                      ),
              ),
              const SizedBox(width: 12),

              // Opportunity details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['ngoName'] ?? 'NGO Name',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showApplyButton)
                          ElevatedButton(
                            onPressed: () => _applyForOpportunity(data),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              minimumSize: const Size(60, 28),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.apply,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(AppLocalizations.of(context)!.cause, data['cause'] ?? AppLocalizations.of(context)!.notSpecified),
                    _buildDetailRow(AppLocalizations.of(context)!.time, data['time'] ?? AppLocalizations.of(context)!.flexible),
                    _buildDetailRow(AppLocalizations.of(context)!.needs, '${data['volunteersNeeded'] ?? 0} ${AppLocalizations.of(context)!.volunteers}'),
                    // Event Date
                    if (eventDate != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(eventDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Location (clickable)
                    if (location != null && location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => _openLocation(location, latitude, longitude),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: const Color(0xFF0099B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF0099B8),
                                  fontWeight: FontWeight.w500,
                                  decoration: (latitude != null && longitude != null)
                                      ? TextDecoration.underline
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (latitude != null && longitude != null)
                              Icon(Icons.open_in_new, size: 10, color: const Color(0xFF0099B8)),
                          ],
                        ),
                      ),
                    ],
                    if (status != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'Accepted' 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'Accepted' ? Colors.green : Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _openLocation(String address, double? lat, double? lng) async {
    String url;
    if (lat != null && lng != null) {
      url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    } else {
      url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    }
    
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyForOpportunity(Map<String, dynamic> opportunity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to apply')),
      );
      return;
    }

    try {
      // Check if already applied
      final existingApplication = await FirebaseFirestore.instance
          .collection('opportunity_applications')
          .where('opportunityId', isEqualTo: opportunity['id'])
          .where('volunteerId', isEqualTo: user.uid)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already applied for this opportunity'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get volunteer data
      final volunteerDoc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(user.uid)
          .get();

      String volunteerName = user.displayName ?? 'Volunteer';
      String? volunteerPhotoUrl = user.photoURL;

      if (volunteerDoc.exists) {
        final data = volunteerDoc.data()!;
        volunteerName = data['displayName'] ?? volunteerName;
        volunteerPhotoUrl = data['photoUrl'] ?? volunteerPhotoUrl;
      }

      // Create application
      await FirebaseFirestore.instance.collection('opportunity_applications').add({
        'opportunityId': opportunity['id'],
        'ngoId': opportunity['ngoId'],
        'ngoName': opportunity['ngoName'],
        'volunteerId': user.uid,
        'volunteerName': volunteerName,
        'volunteerEmail': user.email,
        'volunteerPhotoUrl': volunteerPhotoUrl,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      // Update volunteers count
      await FirebaseFirestore.instance
          .collection('volunteer_opportunities')
          .doc(opportunity['id'])
          .update({
        'applicationsCount': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Switch to Sent tab
      setState(() => _selectedTab = 1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
