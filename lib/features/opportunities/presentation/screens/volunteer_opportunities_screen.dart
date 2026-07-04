import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/opportunity.dart';
import '../../domain/models/opportunity_application.dart';
import '../controllers/opportunity_controller.dart';
import 'opportunity_detail_screen.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final content = Column(
      children: [
        // Tab Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _buildTab(0, l10n.opportunities),
              const SizedBox(width: 24),
              _buildTab(1, l10n.sent),
              const SizedBox(width: 24),
              _buildTab(2, l10n.accepted),
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
                    hintText: l10n.search,
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
          l10n.opportunities,
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
    final controller = Provider.of<OpportunityController>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Opportunity>>(
      stream: controller.streamAllOpportunities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListSkeleton(itemCount: 4, height: 80);
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final list = snapshot.data ?? [];

        // Filter and sort
        var opportunities = list.where((opp) {
          if (opp.status != 'active') return false;
          if (_searchQuery.isEmpty) return true;
          final ngoName = opp.ngoName.toLowerCase();
          final cause = opp.cause.toLowerCase();
          final location = opp.location.toLowerCase();
          return ngoName.contains(_searchQuery) ||
              cause.contains(_searchQuery) ||
              location.contains(_searchQuery);
        }).toList();

        opportunities.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (opportunities.isEmpty) {
          return _buildEmptyState(
            icon: Icons.volunteer_activism_outlined,
            title: l10n.noOpportunitiesFound,
            subtitle: l10n.checkBackLater,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: opportunities.length,
          itemBuilder: (context, index) {
            final opp = opportunities[index];
            return _buildOpportunityCard(opp, showApplyButton: true);
          },
        );
      },
    );
  }

  Widget _buildSentRequestsList() {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: l10n.pleaseLogin,
        subtitle: l10n.loginToSeeSentRequests,
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
          return const ListSkeleton(itemCount: 3, height: 80);
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mail_outline,
            title: l10n.noSentRequests,
            subtitle: l10n.appliedOpportunitiesAppearHere,
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
                final opp = Opportunity.fromMap(oppSnapshot.data!.id, oppData);
                return _buildOpportunityCard(opp, showApplyButton: false, status: 'Pending');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAcceptedList() {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: l10n.pleaseLogin,
        subtitle: l10n.loginToSeeAcceptedOpportunities,
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
          return const ListSkeleton(itemCount: 3, height: 80);
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: l10n.noAcceptedOpportunities,
            subtitle: l10n.acceptedOpportunitiesAppearHere,
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
                final opp = Opportunity.fromMap(oppSnapshot.data!.id, oppData);
                return _buildOpportunityCard(opp, showApplyButton: false, status: 'Accepted');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOpportunityCard(Opportunity opp, {bool showApplyButton = true, String? status}) {
    final imageUrl = opp.images.isNotEmpty ? opp.images[0] : '';
    final eventDate = opp.eventDate;
    final location = opp.location;
    final latitude = opp.latitude;
    final longitude = opp.longitude;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OpportunityDetailScreen(opportunity: opp),
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
              color: Colors.black.withValues(alpha: 0.03),
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

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opp.ngoName,
                            style: const TextStyle(
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OpportunityDetailScreen(opportunity: opp),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              minimumSize: const Size(60, 28),
                            ),
                            child: Text(
                              l10n.apply,
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
                    _buildDetailRow(l10n.cause, opp.cause.isNotEmpty ? opp.cause : l10n.notSpecified),
                    _buildDetailRow(l10n.time, opp.time.isNotEmpty ? opp.time : l10n.flexible),
                    _buildDetailRow(l10n.needs, '${opp.volunteersNeeded} ${l10n.volunteers}'),

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

                    if (location.isNotEmpty) ...[
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
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
