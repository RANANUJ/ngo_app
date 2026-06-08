import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'ngo_reset_password_screen.dart';

class NgoPrivacySecurityScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const NgoPrivacySecurityScreen({
    Key? key,
    required this.ngoData,
  }) : super(key: key);

  @override
  State<NgoPrivacySecurityScreen> createState() => _NgoPrivacySecurityScreenState();
}

class _NgoPrivacySecurityScreenState extends State<NgoPrivacySecurityScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  bool _isLoading = false;
  
  // Privacy Settings
  bool _showPhonePublicly = true;
  bool _showEmailPublicly = true;
  bool _showAddressPublicly = true;
  bool _allowVolunteerMessages = true;
  bool _allowDonorMessages = true;
  bool _showInDiscovery = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ngo_settings')
          .doc(widget.ngoData.id)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _showPhonePublicly = data['showPhonePublicly'] ?? true;
          _showEmailPublicly = data['showEmailPublicly'] ?? true;
          _showAddressPublicly = data['showAddressPublicly'] ?? true;
          _allowVolunteerMessages = data['allowVolunteerMessages'] ?? true;
          _allowDonorMessages = data['allowDonorMessages'] ?? true;
          _showInDiscovery = data['showInDiscovery'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('ngo_settings')
          .doc(widget.ngoData.id)
          .set({
        'showPhonePublicly': _showPhonePublicly,
        'showEmailPublicly': _showEmailPublicly,
        'showAddressPublicly': _showAddressPublicly,
        'allowVolunteerMessages': _allowVolunteerMessages,
        'allowDonorMessages': _allowDonorMessages,
        'showInDiscovery': _showInDiscovery,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
          'Privacy & Security',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Info Section
            _buildSectionTitle('Account Information'),
            const SizedBox(height: 12),
            _buildAccountInfoCard(),
            const SizedBox(height: 24),

            // Security Section
            _buildSectionTitle('Security'),
            const SizedBox(height: 12),
            _buildSecuritySection(),
            const SizedBox(height: 24),

            // Privacy Section
            _buildSectionTitle('Privacy Settings'),
            const SizedBox(height: 12),
            _buildPrivacySection(),
            const SizedBox(height: 24),

            // Visibility Section
            _buildSectionTitle('Profile Visibility'),
            const SizedBox(height: 12),
            _buildVisibilitySection(),
            const SizedBox(height: 24),

            // Communication Section
            _buildSectionTitle('Communication'),
            const SizedBox(height: 12),
            _buildCommunicationSection(),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Settings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildAccountInfoCard() {
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
        children: [
          _buildInfoRow(Icons.email, 'Email', widget.ngoData.email, true),
          const Divider(),
          _buildInfoRow(Icons.phone, 'Phone', widget.ngoData.mobileNo, _showPhonePublicly),
          const Divider(),
          _buildInfoRow(Icons.badge, 'NGO ID', widget.ngoData.registrationNo, true),
          const Divider(),
          _buildInfoRow(Icons.verified, 'Verification Status', 'Verified', true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isPublic) {
    return Padding(
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
                  label,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPublic ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPublic ? 'Public' : 'Private',
              style: TextStyle(
                fontSize: 11,
                color: isPublic ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
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
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock, color: primary),
            ),
            title: const Text('Change Password'),
            subtitle: const Text('Update your login password'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NgoResetPasswordScreen(
                    ngoEmail: widget.ngoData.email,
                    ngoId: widget.ngoData.id,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.security, color: Colors.orange),
            ),
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text('Add extra security to your account'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Two-Factor Authentication coming soon!')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.devices, color: Colors.blue),
            ),
            title: const Text('Active Sessions'),
            subtitle: const Text('Manage your logged-in devices'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            onTap: () {
              _showActiveSessionsDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showActiveSessionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Sessions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSessionItem('This Device', 'Active now', true),
            const Divider(),
            _buildSessionItem('Android Device', 'Last active 2 hours ago', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All other sessions logged out')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout Others', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(String device, String status, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.smartphone, color: isCurrent ? primary : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(status, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Current',
                style: TextStyle(fontSize: 10, color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
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
          SwitchListTile(
            secondary: Icon(Icons.phone, color: primary),
            title: const Text('Show Phone Number'),
            subtitle: const Text('Display phone on public profile'),
            value: _showPhonePublicly,
            activeColor: primary,
            onChanged: (value) => setState(() => _showPhonePublicly = value),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(Icons.email, color: primary),
            title: const Text('Show Email Address'),
            subtitle: const Text('Display email on public profile'),
            value: _showEmailPublicly,
            activeColor: primary,
            onChanged: (value) => setState(() => _showEmailPublicly = value),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(Icons.location_on, color: primary),
            title: const Text('Show Address'),
            subtitle: const Text('Display address on public profile'),
            value: _showAddressPublicly,
            activeColor: primary,
            onChanged: (value) => setState(() => _showAddressPublicly = value),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySection() {
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
      child: SwitchListTile(
        secondary: Icon(Icons.explore, color: primary),
        title: const Text('Show in Discovery'),
        subtitle: const Text('Allow users to find your NGO in search'),
        value: _showInDiscovery,
        activeColor: primary,
        onChanged: (value) => setState(() => _showInDiscovery = value),
      ),
    );
  }

  Widget _buildCommunicationSection() {
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
          SwitchListTile(
            secondary: Icon(Icons.people, color: primary),
            title: const Text('Volunteer Messages'),
            subtitle: const Text('Allow volunteers to message you'),
            value: _allowVolunteerMessages,
            activeColor: primary,
            onChanged: (value) => setState(() => _allowVolunteerMessages = value),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(Icons.volunteer_activism, color: primary),
            title: const Text('Donor Messages'),
            subtitle: const Text('Allow donors to message you'),
            value: _allowDonorMessages,
            activeColor: primary,
            onChanged: (value) => setState(() => _allowDonorMessages = value),
          ),
        ],
      ),
    );
  }
}
