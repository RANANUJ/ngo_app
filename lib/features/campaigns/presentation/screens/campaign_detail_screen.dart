import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/campaign.dart';
import '../controllers/campaign_controller.dart';
import 'edit_campaign_screen.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;
  final bool isVolunteerView;
  final bool isNgoView;

  const CampaignDetailScreen({
    Key? key,
    required this.campaign,
    this.isVolunteerView = false,
    this.isNgoView = false,
  }) : super(key: key);

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  static const Color primary = Color(0xFF0099B8);
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isJoining = false;
  bool _hasJoined = false;

  // Expansion states for View more/less
  bool _isDescriptionExpanded = false;
  bool _isPurposeExpanded = false;
  bool _isTargetExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVolunteerView) {
      _checkIfJoined();
    }
  }

  Future<void> _checkIfJoined() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = Provider.of<CampaignController>(context, listen: false);
    final joined = await controller.hasJoinedCampaign(widget.campaign.id, user.uid);

    if (mounted) {
      setState(() {
        _hasJoined = joined;
      });
    }
  }

  Future<void> _joinCampaign() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to join')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final controller = Provider.of<CampaignController>(context, listen: false);
      await controller.joinCampaign(widget.campaign.id, user.uid);

      if (mounted) {
        setState(() {
          _hasJoined = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the campaign!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining campaign: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _editCampaign() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCampaignScreen(
          campaignId: widget.campaign.id,
          campaignData: widget.campaign.toMap()..['id'] = widget.campaign.id,
        ),
      ),
    ).then((updated) {
      if (updated == true) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: const Text('Are you sure you want to delete this campaign? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCampaign();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCampaign() async {
    try {
      final controller = Provider.of<CampaignController>(context, listen: false);
      await controller.deleteCampaign(widget.campaign.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting campaign: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    final List<String> images = campaign.images;
    final List<String> purposes = campaign.purpose;
    final List<String> targets = campaign.target;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Campaign',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: widget.isNgoView
            ? [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: primary),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCampaign();
                    } else if (value == 'delete') {
                      _showDeleteConfirmation();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with bookmark
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      campaign.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primary,
                        decoration: TextDecoration.underline,
                        decorationColor: primary,
                      ),
                    ),
                  ),
                  if (!widget.isNgoView)
                    Icon(Icons.bookmark_border, color: primary, size: 28),
                ],
              ),
            ),

            // Image carousel
            if (images.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Participants count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${campaign.participantsCount} people joined',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            // Event Date and Location
            if (campaign.eventDate != null || campaign.location.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      // Event Date
                      if (campaign.eventDate != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.calendar_today, color: primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Event Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  _formatDate(campaign.eventDate!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      // Location
                      if (campaign.location.isNotEmpty) ...[
                        if (campaign.eventDate != null) const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _openLocation(
                            campaign.location,
                            campaign.latitude,
                            campaign.longitude,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0099B8).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.location_on, color: Color(0xFF0099B8), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      campaign.location,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0099B8),
                                        decoration: (campaign.latitude != null && campaign.longitude != null)
                                            ? TextDecoration.underline
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (campaign.latitude != null && campaign.longitude != null)
                                Icon(Icons.open_in_new, color: const Color(0xFF0099B8), size: 18),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Page indicators
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 10 : 8,
                      height: _currentImageIndex == index ? 10 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? primary
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
              ),

            const SizedBox(height: 12),

            // Short Description section
            _buildSectionTitle('Short Description of Campaign'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                    maxLines: _isDescriptionExpanded ? null : 4,
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Text(
                      _isDescriptionExpanded ? 'View Less' : 'View More',
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Purpose section
            _buildSectionTitle('Purpose of Campaign'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...purposes
                      .take(_isPurposeExpanded ? purposes.length : 3)
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Expanded(
                                  child: Text(
                                    p,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  if (purposes.length > 3) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isPurposeExpanded = !_isPurposeExpanded;
                        });
                      },
                      child: Text(
                        _isPurposeExpanded ? 'View Less' : 'View More',
                        style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Target section
            _buildSectionTitle('Target to Achieve'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...targets
                      .take(_isTargetExpanded ? targets.length : 3)
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Expanded(
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  if (targets.length > 3) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isTargetExpanded = !_isTargetExpanded;
                        });
                      },
                      child: Text(
                        _isTargetExpanded ? 'View Less' : 'View More',
                        style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Join Button for Volunteers
            if (widget.isVolunteerView)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _hasJoined || _isJoining ? null : _joinCampaign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isJoining
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _hasJoined ? 'Joined Campaign' : 'Join Campaign',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
