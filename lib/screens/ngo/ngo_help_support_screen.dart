import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NgoHelpSupportScreen extends StatefulWidget {
  const NgoHelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<NgoHelpSupportScreen> createState() => _NgoHelpSupportScreenState();
}

class _NgoHelpSupportScreenState extends State<NgoHelpSupportScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _faqCategories = [
    {
      'title': 'Getting Started',
      'icon': Icons.play_circle_outline,
      'color': Colors.blue,
      'faqs': [
        {
          'question': 'How do I set up my NGO profile?',
          'answer': 'Go to your Profile tab and tap on "Edit Profile". Fill in all the required information including your NGO logo, description, address, and contact details. Make sure to upload valid documents for verification.',
        },
        {
          'question': 'How do I get my NGO verified?',
          'answer': 'To get verified, complete your profile with all required information and upload necessary documents like registration certificate, PAN card, and 12A/80G certificates. Our team will review and verify your account within 3-5 business days.',
        },
        {
          'question': 'What documents are required for registration?',
          'answer': 'Required documents include: NGO Registration Certificate, PAN Card, 12A Certificate, 80G Certificate (if applicable), and Bank Account details. Additional documents may be required based on your NGO type.',
        },
      ],
    },
    {
      'title': 'Campaigns & Donations',
      'icon': Icons.campaign,
      'color': Colors.green,
      'faqs': [
        {
          'question': 'How do I create a campaign?',
          'answer': 'Navigate to the Create tab and select "Create Campaign". Fill in campaign details including title, description, target amount, and duration. Add compelling images and publish your campaign.',
        },
        {
          'question': 'How are donations processed?',
          'answer': 'Donations are processed through our secure payment gateway. Funds are typically transferred to your registered bank account within 7-14 business days after deducting platform fees.',
        },
        {
          'question': 'What are the platform fees?',
          'answer': 'We charge a minimal platform fee of 2.5% on donations to cover payment gateway charges and platform maintenance. There are no hidden fees.',
        },
      ],
    },
    {
      'title': 'Volunteers',
      'icon': Icons.people,
      'color': Colors.orange,
      'faqs': [
        {
          'question': 'How do I find volunteers?',
          'answer': 'Create volunteer opportunities from the Create tab. Interested volunteers can apply through the app. You can review applications and approve suitable candidates from your dashboard.',
        },
        {
          'question': 'How do I manage volunteers?',
          'answer': 'Go to the Community tab to view and manage your volunteers. You can assign tasks, track their work, provide feedback, and generate volunteer certificates.',
        },
        {
          'question': 'Can I issue certificates to volunteers?',
          'answer': 'Yes! You can generate and issue certificates to volunteers who have completed their volunteering hours. Go to Community > Volunteers > Select volunteer > Issue Certificate.',
        },
      ],
    },
    {
      'title': 'Account & Security',
      'icon': Icons.security,
      'color': Colors.purple,
      'faqs': [
        {
          'question': 'How do I reset my password?',
          'answer': 'Go to Profile > Settings & Support > Privacy & Security > Change Password. You can either change your password directly or request a password reset email.',
        },
        {
          'question': 'How do I update my bank details?',
          'answer': 'Go to Profile > Edit Profile > Bank Details section. Update your bank information and submit. Changes will be verified and updated within 48 hours.',
        },
        {
          'question': 'Is my data secure?',
          'answer': 'Yes, we use industry-standard encryption to protect your data. All transactions are processed through secure payment gateways. We never share your personal information with third parties without consent.',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqCategories;
    
    return _faqCategories.map((category) {
      final filteredFaqs = (category['faqs'] as List).where((faq) {
        return faq['question'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
               faq['answer'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
      
      return {
        ...category,
        'faqs': filteredFaqs,
      };
    }).where((category) => (category['faqs'] as List).isNotEmpty).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: 16),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQuickActions(),
            ),
            const SizedBox(height: 24),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 24),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // FAQ Categories
            ..._filteredFaqs.map((category) => _buildFaqCategory(category)).toList(),
            
            if (_filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No results found for "$_searchQuery"',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Contact Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildContactSection(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find answers to your questions or contact our support team',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.email,
            title: 'Email Us',
            subtitle: 'Get help via email',
            onTap: () => _launchEmail(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.call,
            title: 'Call Us',
            subtitle: 'Talk to support',
            onTap: () => _launchPhone(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.chat,
            title: 'Live Chat',
            subtitle: 'Chat with us',
            onTap: () => _showLiveChatDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search for help...',
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey.shade500),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildFaqCategory(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (category['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category['icon'] as IconData, color: category['color'] as Color),
          ),
          title: Text(
            category['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${(category['faqs'] as List).length} questions'),
          children: [
            const Divider(),
            ...(category['faqs'] as List).map((faq) => _buildFaqItem(faq)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(Map<String, dynamic> faq) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          faq['question'] as String,
          style: const TextStyle(fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq['answer'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
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
          const Text(
            'Still need help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our support team is here to help you 24/7',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email,
            title: 'Email Support',
            value: 'support@ngoapp.com',
            onTap: () => _launchEmail(),
          ),
          const Divider(),
          _buildContactItem(
            icon: Icons.phone,
            title: 'Phone Support',
            value: '+91 1800-XXX-XXXX',
            onTap: () => _launchPhone(),
          ),
          const Divider(),
          _buildContactItem(
            icon: Icons.access_time,
            title: 'Working Hours',
            value: 'Mon-Sat, 9 AM - 6 PM',
            onTap: null,
          ),
          const Divider(),
          _buildContactItem(
            icon: Icons.location_on,
            title: 'Office Address',
            value: 'Mumbai, Maharashtra, India',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@ngoapp.com',
      queryParameters: {
        'subject': 'Support Request - NGO App',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+911800XXXXXXX');
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone app')),
      );
    }
  }

  void _showLiveChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.chat, color: Color(0xFF0099B8)),
            SizedBox(width: 8),
            Text('Live Chat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Live chat support is coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'In the meantime, you can reach us via email or phone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
