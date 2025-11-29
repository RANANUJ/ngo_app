import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_campaign_screen.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Map<String, dynamic> campaign;
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
    if (user == null || widget.campaign['id'] == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('campaign_participants')
        .doc('${widget.campaign['id']}_${user.uid}')
        .get();

    if (mounted) {
      setState(() {
        _hasJoined = doc.exists;
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
      final campaignId = widget.campaign['id'];
      
      // Add participant
      await FirebaseFirestore.instance
          .collection('campaign_participants')
          .doc('${campaignId}_${user.uid}')
          .set({
        'campaignId': campaignId,
        'userId': user.uid,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Update participant count
      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(campaignId)
          .update({
        'participants': FieldValue.increment(1),
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining campaign: $e')),
      );
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
          campaignId: widget.campaign['id'],
          campaignData: widget.campaign,
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
      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(widget.campaign['id'])
          .delete();

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting campaign: $e')),
      );
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
    final List<String> images = List<String>.from(campaign['images'] ?? []);
    final List<String> purposes = List<String>.from(campaign['purpose'] ?? []);
    final List<String> targets = List<String>.from(campaign['target'] ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
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
                      campaign['title'] ?? 'Campaign',
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
                '${campaign['participants']} people joined',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
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
                    campaign['description'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                    maxLines: _isDescriptionExpanded ? null : 5,
                    overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Text(
                      _isDescriptionExpanded ? 'View less' : 'View more',
                      style: TextStyle(
                        color: primary,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Purpose / Goal section
            _buildSectionTitle('Purpose / Goal of Campaign'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...((_isPurposeExpanded ? purposes : purposes.take(3)).map((purpose) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            purpose,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))),
                  if (purposes.length > 3)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPurposeExpanded = !_isPurposeExpanded;
                        });
                      },
                      child: Text(
                        _isPurposeExpanded ? 'View less' : 'View more',
                        style: TextStyle(
                          color: primary,
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Target section
            _buildSectionTitle('Target'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...((_isTargetExpanded ? targets : targets.take(3)).map((target) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            target,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))),
                  if (targets.length > 3)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isTargetExpanded = !_isTargetExpanded;
                        });
                      },
                      child: Text(
                        _isTargetExpanded ? 'View less' : 'View more',
                        style: TextStyle(
                          color: primary,
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      // Bottom action bar
      bottomNavigationBar: widget.isVolunteerView
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  // Join Campaign button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _hasJoined || _isJoining ? null : _joinCampaign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasJoined ? Colors.green : primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: _hasJoined ? Colors.green : Colors.grey,
                      ),
                      child: _isJoining
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _hasJoined ? 'Joined ✓' : 'Join Campaign',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Share button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.share_outlined, color: Colors.grey.shade600, size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Contact button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.phone_outlined, color: Colors.grey.shade600, size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contact',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
      ),
    );
  }
}
