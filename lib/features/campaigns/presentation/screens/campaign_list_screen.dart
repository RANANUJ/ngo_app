import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/campaign.dart';
import '../controllers/campaign_controller.dart';
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

  Stream<List<Campaign>> _getCampaignsStream(CampaignController controller) {
    if (widget.ngoId != null && !widget.isVolunteerView) {
      return controller.streamNgoCampaigns(widget.ngoId!);
    } else if (widget.isVolunteerView) {
      return controller.streamAllCampaigns();
    }
    return controller.streamAllCampaigns();
  }

  @override
  Widget build(BuildContext context) {
    final campaignController = Provider.of<CampaignController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
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
            child: StreamBuilder<List<Campaign>>(
              stream: _getCampaignsStream(campaignController),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final allList = snapshot.data ?? [];

                // Filter by status if volunteer view, search query, and sort by createdAt locally
                var campaigns = allList.where((campaign) {
                  if (widget.isVolunteerView && campaign.status != 'active') {
                    return false;
                  }
                  if (_searchQuery.isEmpty) return true;
                  final title = campaign.title.toLowerCase();
                  final description = campaign.description.toLowerCase();
                  return title.contains(_searchQuery) || description.contains(_searchQuery);
                }).toList();

                // Sort by createdAt descending (newest first)
                campaigns.sort((a, b) {
                  final aTime = a.createdAt;
                  final bTime = b.createdAt;
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
                    final campaign = campaigns[index];
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

  Widget _buildCampaignCard(Campaign campaign) {
    final imageUrl = campaign.images.isNotEmpty ? campaign.images[0] : '';
    final eventDate = campaign.eventDate;
    final location = campaign.location;
    final latitude = campaign.latitude;
    final longitude = campaign.longitude;

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
              // Campaign image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 100,
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
                      campaign.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Date row
                    if (eventDate != null)
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
                    // Location row
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${campaign.participantsCount} joined',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (widget.isVolunteerView && campaign.ngoName.isNotEmpty) ...[
                          const Spacer(),
                          Flexible(
                            child: Text(
                              'by ${campaign.ngoName}',
                              style: TextStyle(
                                fontSize: 10,
                                color: primary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
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
}
