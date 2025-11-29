import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'campaign_detail_screen.dart';

class CampaignListScreen extends StatefulWidget {
  final String? ngoId; // If provided, show only this NGO's campaigns
  final bool isVolunteerView; // If true, show all active campaigns for volunteers

  const CampaignListScreen({
    Key? key,
    this.ngoId,
    this.isVolunteerView = false,
  }) : super(key: key);

  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _getCampaignsQuery() {
    // Use simple queries without composite indexes
    if (widget.ngoId != null && !widget.isVolunteerView) {
      // NGO viewing their own campaigns - simple where query
      return FirebaseFirestore.instance
          .collection('campaigns')
          .where('ngoId', isEqualTo: widget.ngoId);
    } else if (widget.isVolunteerView) {
      // Volunteer viewing all active campaigns
      return FirebaseFirestore.instance
          .collection('campaigns')
          .where('status', isEqualTo: 'active');
    }
    
    // Default - all campaigns
    return FirebaseFirestore.instance.collection('campaigns');
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
          widget.isVolunteerView ? 'CSR Campaigns' : 'My Campaigns',
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
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search campaigns',
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

          // Campaign list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getCampaignsQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Filter by search query and sort by createdAt locally
                var campaigns = docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final description = (data['description'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) || description.contains(_searchQuery);
                }).toList();

                // Sort by createdAt descending (newest first)
                campaigns.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                if (campaigns.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No campaigns found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        if (!widget.isVolunteerView) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Create your first campaign!',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final doc = campaigns[index];
                    final campaign = doc.data() as Map<String, dynamic>;
                    campaign['id'] = doc.id;
                    return _buildCampaignCard(campaign);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final images = List<String>.from(campaign['images'] ?? []);
    final imageUrl = images.isNotEmpty ? images[0] : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampaignDetailScreen(
              campaign: campaign,
              isVolunteerView: widget.isVolunteerView,
              isNgoView: !widget.isVolunteerView,
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
              // Campaign image
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
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.campaign, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),

              // Campaign details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign['title'] ?? 'Campaign',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign['description'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${campaign['participants'] ?? '0'}+ people joined',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (widget.isVolunteerView && campaign['ngoName'] != null) ...[
                          const Spacer(),
                          Text(
                            'by ${campaign['ngoName']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
