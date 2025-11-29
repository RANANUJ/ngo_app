import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'edit_opportunity_screen.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> opportunity;
  final bool isNgoView;

  const OpportunityDetailScreen({
    Key? key,
    required this.opportunity,
    this.isNgoView = false,
  }) : super(key: key);

  @override
  State<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  static const Color primary = Color(0xFF0099B8);
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isJoining = false;
  bool _hasJoined = false;
  
  // Expansion states
  bool _isDescriptionExpanded = false;
  bool _isPurposeExpanded = false;
  bool _isTargetExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
  }

  Future<void> _checkIfJoined() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.opportunity['id'] == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('opportunity_applications')
        .where('opportunityId', isEqualTo: widget.opportunity['id'])
        .where('volunteerId', isEqualTo: user.uid)
        .get();

    if (mounted) {
      setState(() {
        _hasJoined = doc.docs.isNotEmpty;
      });
    }
  }

  Future<void> _joinOpportunity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to join')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
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
        'opportunityId': widget.opportunity['id'],
        'ngoId': widget.opportunity['ngoId'],
        'ngoName': widget.opportunity['ngoName'],
        'volunteerId': user.uid,
        'volunteerName': volunteerName,
        'volunteerEmail': user.email,
        'volunteerPhotoUrl': volunteerPhotoUrl,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      // Update applications count
      await FirebaseFirestore.instance
          .collection('volunteer_opportunities')
          .doc(widget.opportunity['id'])
          .update({
        'applicationsCount': FieldValue.increment(1),
      });

      if (mounted) {
        setState(() {
          _hasJoined = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully applied for the opportunity!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _shareOpportunity() {
    final title = widget.opportunity['title'] ?? 'Volunteer Opportunity';
    final ngoName = widget.opportunity['ngoName'] ?? '';
    final cause = widget.opportunity['cause'] ?? '';
    final location = widget.opportunity['location'] ?? '';
    
    Share.share(
      'Check out this volunteer opportunity!\n\n'
      '$title\n'
      'By: $ngoName\n'
      'Cause: $cause\n'
      'Location: $location\n\n'
      'Join now on NGO Connect App!',
    );
  }

  Future<void> _contactNgo() async {
    final phone = widget.opportunity['contactPhone'];
    final email = widget.opportunity['contactEmail'];
    
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else if (email != null && email.isNotEmpty) {
      final uri = Uri.parse('mailto:$email');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact information not available')),
      );
    }
  }

  Future<void> _openLocation() async {
    final latitude = widget.opportunity['latitude'];
    final longitude = widget.opportunity['longitude'];
    final address = widget.opportunity['location'] ?? '';
    
    if (latitude != null && longitude != null) {
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (address.isNotEmpty) {
      final encodedAddress = Uri.encodeComponent(address);
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
    }
  }

  void _editOpportunity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditOpportunityScreen(
          opportunityId: widget.opportunity['id'],
          opportunityData: widget.opportunity,
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
        title: const Text('Delete Opportunity'),
        content: const Text('Are you sure you want to delete this volunteer opportunity? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOpportunity();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOpportunity() async {
    try {
      await FirebaseFirestore.instance
          .collection('volunteer_opportunities')
          .doc(widget.opportunity['id'])
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opportunity deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting opportunity: $e')),
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
    final opportunity = widget.opportunity;
    final List<String> images = List<String>.from(opportunity['images'] ?? []);
    final List<String> purposes = List<String>.from(opportunity['purpose'] ?? []);
    final List<String> targets = List<String>.from(opportunity['target'] ?? []);

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
          'Volunteer Opportunity',
          style: TextStyle(
            color: primary,
            fontSize: 18,
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
                      _editOpportunity();
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
                      opportunity['title'] ?? 'Volunteer Opportunity',
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
              )
            else
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.volunteer_activism, size: 60, color: Colors.grey),
                ),
              ),

            // Participants count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${opportunity['applicationsCount'] ?? 0}+ people joined',
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
                    opportunity['description'] ?? '',
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

            // Details section
            const SizedBox(height: 16),
            _buildSectionTitle('Details'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                children: [
                  _buildDetailRow(Icons.location_on, 'Location', opportunity['location'] ?? 'Not specified', onTap: _openLocation),
                  _buildDetailRow(Icons.access_time, 'Time', opportunity['time'] ?? 'Flexible'),
                  _buildDetailRow(Icons.people, 'Volunteers Needed', '${opportunity['volunteersNeeded'] ?? 'Not specified'}'),
                  _buildDetailRow(Icons.category, 'Cause', opportunity['cause'] ?? 'Not specified'),
                  _buildDetailRow(Icons.business, 'NGO', opportunity['ngoName'] ?? 'Not specified'),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      // Bottom action bar
      bottomNavigationBar: Container(
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
                onPressed: _hasJoined || _isJoining ? null : _joinOpportunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasJoined ? Colors.green : primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _hasJoined ? 'Applied' : 'Join Campaign',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Share button
            GestureDetector(
              onTap: _shareOpportunity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.share, color: primary, size: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Contact button
            GestureDetector(
              onTap: _contactNgo,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.phone, color: primary, size: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
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
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: onTap != null ? primary : Colors.black87,
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, color: primary, size: 16),
          ],
        ),
      ),
    );
  }
}
