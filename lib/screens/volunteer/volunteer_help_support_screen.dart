import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VolunteerHelpSupportScreen extends StatelessWidget {
  const VolunteerHelpSupportScreen({Key? key}) : super(key: key);

  static const Color primary = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Us Section
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 12),
            _buildContactCard(context),
            
            const SizedBox(height: 24),
            
            // FAQ Section
            _buildSectionTitle('Frequently Asked Questions'),
            const SizedBox(height: 12),
            _buildFAQSection(),
            
            const SizedBox(height: 24),
            
            // Quick Links
            _buildSectionTitle('Quick Links'),
            const SizedBox(height: 12),
            _buildQuickLinksCard(context),
            
            const SizedBox(height: 24),
            
            // Report a Problem
            _buildSectionTitle('Report a Problem'),
            const SizedBox(height: 12),
            _buildReportCard(context),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildContactTile(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'support@connectngo.com',
            onTap: () => _launchEmail('support@connectngo.com'),
          ),
          _buildDivider(),
          _buildContactTile(
            icon: Icons.phone,
            title: 'Phone Support',
            subtitle: '+91 1800-123-4567',
            onTap: () => _launchPhone('+911800123456'),
          ),
          _buildDivider(),
          _buildContactTile(
            icon: Icons.chat,
            title: 'Live Chat',
            subtitle: 'Available 9 AM - 6 PM',
            onTap: () => _showLiveChat(context),
          ),
          _buildDivider(),
          _buildContactTile(
            icon: Icons.location_on,
            title: 'Visit Us',
            subtitle: '123 NGO Street, New Delhi, India',
            onTap: () => _launchMaps(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade200, indent: 72);
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'How do I register as a volunteer?',
        'answer': 'Go to Explore > Find an NGO > Click on the NGO > Click "Register as Volunteer" and fill in the required details. The NGO will review and approve your registration.',
      },
      {
        'question': 'How do I make a donation?',
        'answer': 'You can donate through the app by going to any NGO profile or campaign page and clicking the "Donate" button. We support various payment methods including UPI, Cards, and Net Banking.',
      },
      {
        'question': 'How do I join a campaign?',
        'answer': 'Browse campaigns in the Explore tab, click on any campaign that interests you, and click "Join Campaign". You\'ll receive updates about the campaign activities.',
      },
      {
        'question': 'How do I use the SOS feature?',
        'answer': 'The SOS feature is available in the Home tab. Click on "SOS" to send an emergency alert to nearby NGOs. Make sure location services are enabled for accurate location sharing.',
      },
      {
        'question': 'How can I track my volunteer hours?',
        'answer': 'Your volunteer hours are automatically tracked when you participate in events. You can view your total hours in your Profile section under "Hours Volunteered".',
      },
      {
        'question': 'How do I get donation receipts?',
        'answer': 'Donation receipts are automatically sent to your registered email after each successful donation. You can also view your donation history in Profile > Donation History.',
      },
      {
        'question': 'Can I volunteer for multiple NGOs?',
        'answer': 'Yes! You can register as a volunteer with multiple NGOs. Each NGO will review and approve your registration independently.',
      },
      {
        'question': 'How do I update my profile?',
        'answer': 'Go to Profile > Edit Profile to update your personal information, profile photo, and other details.',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: faqs.asMap().entries.map((entry) {
          final index = entry.key;
          final faq = entry.value;
          return Column(
            children: [
              if (index > 0) Divider(height: 1, color: Colors.grey.shade200),
              _buildFAQTile(faq['question']!, faq['answer']!),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconColor: primary,
      collapsedIconColor: Colors.grey,
      children: [
        Text(
          answer,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinksCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLinkTile(
            icon: Icons.play_circle_outline,
            title: 'Getting Started Guide',
            onTap: () => _showGettingStartedGuide(context),
          ),
          _buildDivider(),
          _buildLinkTile(
            icon: Icons.video_library,
            title: 'Video Tutorials',
            onTap: () => _showVideoTutorials(context),
          ),
          _buildDivider(),
          _buildLinkTile(
            icon: Icons.article,
            title: 'User Manual',
            onTap: () => _launchUrl('https://connectngo.com/manual'),
          ),
          _buildDivider(),
          _buildLinkTile(
            icon: Icons.forum,
            title: 'Community Forum',
            onTap: () => _launchUrl('https://connectngo.com/forum'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.open_in_new,
        color: Colors.grey.shade400,
        size: 18,
      ),
    );
  }

  Widget _buildReportCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bug_report,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Found a bug or issue?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Help us improve by reporting any issues you encounter. Your feedback is valuable to us!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReportDialog(context),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Report an Issue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchMaps() async {
    final uri = Uri.parse('https://maps.google.com/?q=New+Delhi,+India');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLiveChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live chat feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showGettingStartedGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Getting Started'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideStep('1', 'Create your profile', 'Update your profile with accurate information'),
              _buildGuideStep('2', 'Explore NGOs', 'Browse and discover NGOs that match your interests'),
              _buildGuideStep('3', 'Register as volunteer', 'Join NGOs as a volunteer to participate in activities'),
              _buildGuideStep('4', 'Join campaigns', 'Participate in campaigns to make an impact'),
              _buildGuideStep('5', 'Attend events', 'Join events organized by NGOs'),
              _buildGuideStep('6', 'Make donations', 'Support causes you care about'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
    );
  }

  void _showVideoTutorials(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video tutorials coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final issueController = TextEditingController();
    String selectedType = 'Bug';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Report an Issue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Issue Type',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Bug', 'Feature Request', 'Performance', 'Other']
                      .map((type) => ChoiceChip(
                            label: Text(type),
                            selected: selectedType == type,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => selectedType = type);
                              }
                            },
                            selectedColor: primary.withOpacity(0.2),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: issueController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Describe the issue',
                    hintText: 'Please provide details...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your feedback!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
