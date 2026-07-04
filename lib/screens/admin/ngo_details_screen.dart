import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'review_ngo_screen.dart';

class NgoDetailsScreen extends StatefulWidget {
  final NgoRegistrationRequest request;
  const NgoDetailsScreen({Key? key, required this.request}) : super(key: key);

  @override
  State<NgoDetailsScreen> createState() => _NgoDetailsScreenState();
}

class _NgoDetailsScreenState extends State<NgoDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NgoRegistrationService _service = NgoRegistrationService();
  bool _isActionLoading = false;
  static const Color primaryColor = Color(0xFF0099B8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _approve() async {
    setState(() => _isActionLoading = true);
    final success = await _service.approveRegistration(widget.request.id);
    setState(() => _isActionLoading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NGO Approved Successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error approving NGO'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reject NGO Registration'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final reason = controller.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a rejection reason')),
                  );
                  return;
                }
                Navigator.pop(context);
                setState(() => _isActionLoading = true);
                final success = await _service.rejectRegistration(widget.request.id, reason);
                setState(() => _isActionLoading = false);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('NGO Registration Rejected'), backgroundColor: Colors.orange),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error rejecting NGO'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is not available')),
      );
      return;
    }
    
    String sanitizedUrl = urlString.trim();
    if (sanitizedUrl.startsWith('http://')) {
      sanitizedUrl = sanitizedUrl.replaceFirst('http://', 'https://');
    } else if (!sanitizedUrl.startsWith('https://')) {
      sanitizedUrl = 'https://$sanitizedUrl';
    }

    final Uri url = Uri.parse(sanitizedUrl);
    
    // Security check: Validate host is parsed and scheme is strictly HTTP/HTTPS
    if (url.host.isEmpty || !['http', 'https'].contains(url.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid link target or URL format')),
      );
      return;
    }

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open document link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (widget.request.status) {
      case RegistrationStatus.approved:
        statusColor = Colors.green;
        break;
      case RegistrationStatus.rejected:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'NGO Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (widget.request.status == RegistrationStatus.pending)
            TextButton.icon(
              icon: const Icon(Icons.verified_user_outlined, size: 18, color: primaryColor),
              label: const Text('Verify NGO', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewNgoScreen(request: widget.request),
                  ),
                ).then((_) => Navigator.pop(context));
              },
            ),
        ],
      ),
      body: _isActionLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // Top Header Row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        backgroundImage: widget.request.profileImageUrl != null && widget.request.profileImageUrl!.isNotEmpty
                            ? NetworkImage(widget.request.profileImageUrl!)
                            : null,
                        child: widget.request.profileImageUrl == null || widget.request.profileImageUrl!.isEmpty
                            ? const Icon(Icons.business, color: primaryColor, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.request.ngoName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.request.category,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.request.status.name.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // TabBar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: primaryColor,
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Documents'),
                      Tab(text: 'Activity'),
                    ],
                  ),
                ),

                // TabBarView Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildDocumentsTab(),
                      _buildActivityTab(),
                    ],
                  ),
                ),

                // Bottom Action buttons for pending registrations
                if (widget.request.status == RegistrationStatus.pending)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _showRejectDialog,
                            child: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _approve,
                            child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Basic Information'),
        _buildInfoRow('Organization Name', widget.request.ngoName),
        _buildInfoRow('Email Address', widget.request.email),
        _buildInfoRow('Phone Number', widget.request.officialPhone),
        _buildInfoRow('Website', widget.request.websiteLink.isNotEmpty ? widget.request.websiteLink : 'N/A'),
        _buildInfoRow('Registration Number', widget.request.registrationNo),
        _buildInfoRow('Founded Year', widget.request.yearOfEstablishment),
        _buildInfoRow('Head Office Address', widget.request.headOfficeAddress),
        _buildInfoRow('Category', widget.request.category),
        _buildInfoRow('Type', widget.request.ngoType),
        const SizedBox(height: 24),
        _buildSectionHeader('About Organization'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mission & Vision',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
              ),
              const SizedBox(height: 6),
              Text(
                widget.request.missionVision.isNotEmpty
                    ? widget.request.missionVision
                    : 'No mission/vision details provided.',
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'Areas of Work & Achievements',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
              ),
              const SizedBox(height: 6),
              Text(
                widget.request.achievements.isNotEmpty
                    ? widget.request.achievements
                    : 'No achievements listed.',
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        if (widget.request.status == RegistrationStatus.rejected && widget.request.rejectionReason != null) ...[
          const SizedBox(height: 24),
          _buildSectionHeader('Rejection Reason'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              widget.request.rejectionReason!,
              style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildDocumentsTab() {
    final docs = <Map<String, dynamic>>[
      {
        'title': 'Registration Certificate',
        'uploaded': widget.request.registrationCertUploaded,
        'url': widget.request.registrationCertUrl,
        'icon': Icons.card_membership_outlined,
      },
      {
        'title': 'PAN Card Proof',
        'uploaded': widget.request.panCardUploaded,
        'url': widget.request.panCardUrl,
        'icon': Icons.payment_outlined,
      },
      {
        'title': 'ID Proof Document',
        'uploaded': widget.request.idProofUploaded,
        'url': widget.request.idProofUrl,
        'icon': Icons.badge_outlined,
      },
      {
        'title': '12A & 80G Certificate',
        'uploaded': widget.request.certificate12A80GUploaded,
        'url': widget.request.certificate12A80GUrl,
        'icon': Icons.receipt_long_outlined,
      },
      {
        'title': 'Past Work Proof',
        'uploaded': widget.request.pastWorkProofUploaded,
        'url': widget.request.pastWorkProofUrl,
        'icon': Icons.folder_open_outlined,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final bool isUploaded = doc['uploaded'] == true;
        final String? url = doc['url'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: ListTile(
            leading: Icon(doc['icon'], color: isUploaded ? primaryColor : Colors.grey),
            title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: Text(
              isUploaded ? 'Document Uploaded' : 'Not Uploaded',
              style: TextStyle(fontSize: 12, color: isUploaded ? Colors.green : Colors.grey),
            ),
            trailing: isUploaded
                ? TextButton(
                    onPressed: () => _launchUrl(url),
                    child: const Text('View File', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  )
                : const Icon(Icons.close, color: Colors.grey, size: 20),
          ),
        );
      },
    );
  }

  Widget _buildActivityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildActivityItem(
          title: 'Registration Request Submitted',
          description: 'The NGO submitted the initial verification application.',
          time: widget.request.submittedAt,
          icon: Icons.assignment_turned_in,
          color: Colors.blue,
        ),
        if (widget.request.reviewedAt != null) ...[
          const SizedBox(height: 12),
          _buildActivityItem(
            title: widget.request.status == RegistrationStatus.approved
                ? 'Application Approved'
                : 'Application Rejected',
            description: widget.request.status == RegistrationStatus.approved
                ? 'Authorized admin marked the registration as approved.'
                : 'Registration request rejected with feedback notes.',
            time: widget.request.reviewedAt!,
            icon: widget.request.status == RegistrationStatus.approved
                ? Icons.check_circle
                : Icons.cancel,
            color: widget.request.status == RegistrationStatus.approved
                ? Colors.green
                : Colors.red,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String description,
    required DateTime time,
    required IconData icon,
    required Color color,
  }) {
    final formattedTime = '${time.day}/${time.month}/${time.year} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 4),
              Text(formattedTime, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ],
          ),
        )
      ],
    );
  }
}
