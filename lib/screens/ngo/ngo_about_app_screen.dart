import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class NgoAboutAppScreen extends StatefulWidget {
  const NgoAboutAppScreen({Key? key}) : super(key: key);

  @override
  State<NgoAboutAppScreen> createState() => _NgoAboutAppScreenState();
}

class _NgoAboutAppScreenState extends State<NgoAboutAppScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About App',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App Logo & Info
            _buildAppHeader(),
            const SizedBox(height: 24),

            // About Section
            _buildAboutSection(),
            const SizedBox(height: 16),

            // Features Section
            _buildFeaturesSection(),
            const SizedBox(height: 16),

            // Legal Section
            _buildLegalSection(),
            const SizedBox(height: 16),

            // Social Links
            _buildSocialSection(),
            const SizedBox(height: 16),

            // Developer Info
            _buildDeveloperSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.volunteer_activism, size: 50, color: primary),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'NGO Connect',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version $_appVersion (Build $_buildNumber)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connecting NGOs, Volunteers & Donors',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Icon(Icons.info_outline, color: primary),
              const SizedBox(width: 12),
              const Text(
                'About NGO Connect',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'NGO Connect is a comprehensive platform designed to bridge the gap between NGOs, volunteers, and donors. Our mission is to make social impact more accessible, transparent, and effective.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We believe in the power of community and technology to create positive change in society. Through our platform, NGOs can reach more people, volunteers can find meaningful opportunities, and donors can contribute to causes they care about.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {'icon': Icons.campaign, 'title': 'Campaign Management', 'desc': 'Create and manage fundraising campaigns'},
      {'icon': Icons.people, 'title': 'Volunteer Connect', 'desc': 'Find and manage volunteers'},
      {'icon': Icons.volunteer_activism, 'title': 'Donations', 'desc': 'Secure donation processing'},
      {'icon': Icons.analytics, 'title': 'Analytics', 'desc': 'Track your impact with detailed reports'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Icon(Icons.star_outline, color: primary),
              const SizedBox(width: 12),
              const Text(
                'Key Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(feature['icon'] as IconData, color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        feature['desc'] as String,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          ListTile(
            leading: Icon(Icons.privacy_tip, color: primary),
            title: const Text('Privacy Policy'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            onTap: () => _showPolicyDialog('Privacy Policy', _privacyPolicyText),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.description, color: primary),
            title: const Text('Terms of Service'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            onTap: () => _showPolicyDialog('Terms of Service', _termsOfServiceText),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.cookie, color: primary),
            title: const Text('Cookie Policy'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            onTap: () => _showPolicyDialog('Cookie Policy', _cookiePolicyText),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.security, color: primary),
            title: const Text('Data Security'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            onTap: () => _showPolicyDialog('Data Security', _dataSecurityText),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.gavel, color: primary),
            title: const Text('Refund Policy'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            onTap: () => _showPolicyDialog('Refund Policy', _refundPolicyText),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Icon(Icons.share, color: primary),
              const SizedBox(width: 12),
              const Text(
                'Connect With Us',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialIcon(Icons.language, 'Website', () => _launchUrl('https://www.ngoconnect.com')),
              _buildSocialIcon(Icons.facebook, 'Facebook', () => _launchUrl('https://www.facebook.com/ngoconnect')),
              _buildSocialIcon(Icons.camera_alt, 'Instagram', () => _launchUrl('https://www.instagram.com/ngoconnect')),
              _buildSocialIcon(Icons.alternate_email, 'Twitter', () => _launchUrl('https://www.twitter.com/ngoconnect')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        children: [
          Row(
            children: [
              Icon(Icons.code, color: primary),
              const SizedBox(width: 12),
              const Text(
                'Developer Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Developed by', 'NGO Connect Team'),
          const SizedBox(height: 8),
          _buildInfoRow('Email', 'developer@ngoconnect.com'),
          const SizedBox(height: 8),
          _buildInfoRow('Last Updated', 'January 2025'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl('mailto:developer@ngoconnect.com'),
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Report Bug'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rateApp(),
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text('Rate App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© 2025 NGO Connect. All rights reserved.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showPolicyDialog(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  void _rateApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate NGO Connect'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 64, color: Colors.amber.shade600),
            const SizedBox(height: 16),
            const Text(
              'If you enjoy using NGO Connect, please take a moment to rate us!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open app store for rating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your support!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            child: const Text('Rate Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Policy Texts
  static const String _privacyPolicyText = '''
PRIVACY POLICY

Last Updated: January 2025

1. INFORMATION WE COLLECT
We collect information you provide directly to us, including:
- Personal information (name, email, phone number)
- NGO registration details and documents
- Payment information for donations
- Location data for campaign discovery
- Usage data and app analytics

2. HOW WE USE YOUR INFORMATION
We use the information we collect to:
- Provide and improve our services
- Process donations and transactions
- Connect NGOs with volunteers and donors
- Send notifications and updates
- Ensure platform security

3. INFORMATION SHARING
We do not sell your personal information. We may share information:
- With your consent
- With service providers who assist our operations
- To comply with legal obligations
- To protect rights and safety

4. DATA SECURITY
We implement industry-standard security measures to protect your data, including encryption, secure servers, and regular security audits.

5. YOUR RIGHTS
You have the right to:
- Access your personal data
- Request correction of inaccurate data
- Request deletion of your data
- Opt out of marketing communications

6. CONTACT US
For privacy-related inquiries, contact us at privacy@ngoconnect.com
''';

  static const String _termsOfServiceText = '''
TERMS OF SERVICE

Last Updated: January 2025

1. ACCEPTANCE OF TERMS
By using NGO Connect, you agree to these Terms of Service. If you do not agree, please do not use our platform.

2. ELIGIBILITY
- NGOs must be registered under applicable laws
- Users must be at least 18 years old
- Accurate information must be provided during registration

3. USER RESPONSIBILITIES
Users agree to:
- Provide accurate and truthful information
- Use the platform for lawful purposes only
- Not engage in fraudulent activities
- Respect intellectual property rights

4. NGO RESPONSIBILITIES
NGOs must:
- Maintain valid registration status
- Use donations for stated purposes
- Provide accurate campaign information
- Comply with all applicable laws

5. DONATIONS
- All donations are voluntary
- Platform fees may apply
- Refund policies are subject to campaign terms
- Tax receipts are the responsibility of NGOs

6. INTELLECTUAL PROPERTY
All content on NGO Connect is protected by copyright and other intellectual property laws.

7. LIMITATION OF LIABILITY
NGO Connect is not liable for:
- User-generated content
- Third-party actions
- Indirect or consequential damages

8. TERMINATION
We reserve the right to terminate accounts that violate these terms.

9. CHANGES TO TERMS
We may update these terms periodically. Continued use constitutes acceptance.

10. CONTACT
For questions, contact us at legal@ngoconnect.com
''';

  static const String _cookiePolicyText = '''
COOKIE POLICY

Last Updated: January 2025

1. WHAT ARE COOKIES?
Cookies are small text files stored on your device when you use our app or website.

2. HOW WE USE COOKIES
We use cookies to:
- Remember your preferences
- Maintain your session
- Analyze app usage
- Improve user experience

3. TYPES OF COOKIES WE USE
- Essential cookies: Required for basic functionality
- Analytics cookies: Help us understand usage patterns
- Preference cookies: Remember your settings

4. MANAGING COOKIES
You can control cookies through your device settings. Note that disabling certain cookies may affect app functionality.

5. THIRD-PARTY COOKIES
We may use third-party services that set their own cookies for analytics and functionality purposes.

6. UPDATES TO THIS POLICY
We may update this policy periodically. Check back for any changes.

7. CONTACT US
For questions about our cookie policy, contact us at privacy@ngoconnect.com
''';

  static const String _dataSecurityText = '''
DATA SECURITY

Last Updated: January 2025

1. OUR COMMITMENT
We are committed to protecting your data with industry-leading security measures.

2. SECURITY MEASURES
We implement:
- End-to-end encryption for sensitive data
- Secure SSL/TLS connections
- Regular security audits
- Multi-factor authentication options
- Secure payment processing through certified gateways

3. DATA STORAGE
- Data is stored on secure cloud servers
- Regular backups are performed
- Access is restricted to authorized personnel

4. INCIDENT RESPONSE
In case of a data breach:
- We will notify affected users promptly
- We will take immediate remedial action
- We will cooperate with authorities

5. YOUR ROLE
Help us keep your data secure by:
- Using strong passwords
- Not sharing login credentials
- Reporting suspicious activity

6. COMPLIANCE
We comply with applicable data protection laws including:
- Information Technology Act, 2000
- GDPR (for EU users)
- Other relevant regulations

7. CONTACT
For security concerns, contact us at security@ngoconnect.com
''';

  static const String _refundPolicyText = '''
REFUND POLICY

Last Updated: January 2025

1. GENERAL POLICY
Donations made through NGO Connect are generally non-refundable as they are charitable contributions.

2. ELIGIBLE REFUNDS
Refunds may be considered in cases of:
- Duplicate transactions
- Technical errors in payment processing
- Unauthorized transactions
- Campaign cancellation before funds disbursement

3. REFUND PROCESS
To request a refund:
- Contact support within 7 days of donation
- Provide transaction details
- Explain the reason for refund request
- Allow 5-7 business days for processing

4. NON-REFUNDABLE SITUATIONS
Refunds are not available when:
- Funds have been disbursed to the NGO
- Campaign has been completed
- More than 30 days have passed
- No valid reason is provided

5. PLATFORM FEES
Platform fees may or may not be refunded depending on the circumstances.

6. DISPUTE RESOLUTION
If you disagree with a refund decision:
- Contact our support team
- Provide additional documentation
- Request escalation if needed

7. CONTACT
For refund inquiries, contact us at support@ngoconnect.com
''';
}
