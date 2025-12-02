import 'package:flutter/material.dart';

class VolunteerPrivacyPolicyScreen extends StatelessWidget {
  const VolunteerPrivacyPolicyScreen({Key? key}) : super(key: key);

  static const Color primary = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.privacy_tip,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connect NGO',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: December 2, 2025',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              'Introduction',
              '''Welcome to Connect NGO. We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.

Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.''',
            ),
            
            _buildSection(
              'Information We Collect',
              '''We collect information that you provide directly to us, including:

• Personal Information: Name, email address, phone number, location, profile photo
• Account Information: Login credentials, preferences, settings
• Volunteer Information: Skills, interests, availability, hours volunteered
• Donation Information: Payment details (processed securely), donation history
• Communication Data: Messages, feedback, support requests
• Location Data: When using SOS or location-based features''',
            ),
            
            _buildSection(
              'How We Use Your Information',
              '''We use the information we collect to:

• Provide, maintain, and improve our services
• Process donations and volunteer registrations
• Connect you with NGOs and campaigns
• Send notifications about events, campaigns, and updates
• Respond to your comments, questions, and requests
• Monitor and analyze trends, usage, and activities
• Detect, investigate, and prevent fraudulent transactions
• Personalize your experience on the platform''',
            ),
            
            _buildSection(
              'Information Sharing',
              '''We may share your information in the following situations:

• With NGOs: When you register as a volunteer or make donations
• With Service Providers: Third-party vendors who assist in our operations
• For Legal Purposes: To comply with legal obligations or protect rights
• With Your Consent: When you give us permission to share
• Aggregated Data: Non-personal statistical data for analytics

We do not sell your personal information to third parties.''',
            ),
            
            _buildSection(
              'Data Security',
              '''We implement appropriate technical and organizational security measures to protect your personal information, including:

• Encryption of data in transit and at rest
• Secure authentication mechanisms
• Regular security assessments
• Access controls and monitoring
• Secure data storage on Firebase

However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.''',
            ),
            
            _buildSection(
              'Your Rights',
              '''You have the right to:

• Access: Request a copy of your personal data
• Correction: Request correction of inaccurate data
• Deletion: Request deletion of your personal data
• Portability: Request transfer of your data
• Opt-out: Unsubscribe from marketing communications
• Withdraw Consent: Revoke consent for data processing

To exercise these rights, contact us at privacy@connectngo.com''',
            ),
            
            _buildSection(
              'Data Retention',
              '''We retain your personal information for as long as:

• Your account is active
• Necessary to provide services
• Required by law
• Needed for legitimate business purposes

When you delete your account, we will delete or anonymize your data within 30 days, except where required by law to retain.''',
            ),
            
            _buildSection(
              'Children\'s Privacy',
              '''Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.''',
            ),
            
            _buildSection(
              'Third-Party Services',
              '''Our app may contain links to third-party websites and services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies.

We use the following third-party services:
• Firebase (Google) for authentication and data storage
• Payment gateways for donation processing
• Analytics services for app improvement''',
            ),
            
            _buildSection(
              'Changes to This Policy',
              '''We may update this privacy policy from time to time. We will notify you of any changes by:

• Posting the new policy on this page
• Updating the "Last updated" date
• Sending a notification through the app

We encourage you to review this policy periodically for any changes.''',
            ),
            
            _buildSection(
              'Contact Us',
              '''If you have questions or concerns about this privacy policy, please contact us:

Email: privacy@connectngo.com
Phone: +91 1800-123-4567
Address: 123 NGO Street, New Delhi, India - 110001

For data protection inquiries, you may also contact our Data Protection Officer at dpo@connectngo.com''',
            ),
            
            const SizedBox(height: 20),
            
            // Consent Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 12),
                      const Text(
                        'Your Consent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By using our app, you consent to the collection and use of information in accordance with this policy. If you do not agree with any part of this policy, you may choose to stop using our services.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
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
}
