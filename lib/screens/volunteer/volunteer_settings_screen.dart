import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VolunteerSettingsScreen extends StatefulWidget {
  const VolunteerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerSettingsScreen> createState() => _VolunteerSettingsScreenState();
}

class _VolunteerSettingsScreenState extends State<VolunteerSettingsScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  // Notification Settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _campaignUpdates = true;
  bool _eventReminders = true;
  bool _donationReceipts = true;
  bool _sosAlerts = true;
  
  // Privacy Settings
  bool _showProfile = true;
  bool _showActivity = true;
  bool _allowMessages = true;
  
  // App Settings
  bool _darkMode = false;
  String _language = 'English';
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load from SharedPreferences
      setState(() {
        _pushNotifications = prefs.getBool('pushNotifications') ?? true;
        _emailNotifications = prefs.getBool('emailNotifications') ?? true;
        _campaignUpdates = prefs.getBool('campaignUpdates') ?? true;
        _eventReminders = prefs.getBool('eventReminders') ?? true;
        _donationReceipts = prefs.getBool('donationReceipts') ?? true;
        _sosAlerts = prefs.getBool('sosAlerts') ?? true;
        _showProfile = prefs.getBool('showProfile') ?? true;
        _showActivity = prefs.getBool('showActivity') ?? true;
        _allowMessages = prefs.getBool('allowMessages') ?? true;
        _darkMode = prefs.getBool('darkMode') ?? false;
        _language = prefs.getString('language') ?? 'English';
        _isLoading = false;
      });
      
      // Also try to load from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('volunteer_settings')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _pushNotifications = data['pushNotifications'] ?? _pushNotifications;
            _emailNotifications = data['emailNotifications'] ?? _emailNotifications;
            _campaignUpdates = data['campaignUpdates'] ?? _campaignUpdates;
            _eventReminders = data['eventReminders'] ?? _eventReminders;
            _donationReceipts = data['donationReceipts'] ?? _donationReceipts;
            _sosAlerts = data['sosAlerts'] ?? _sosAlerts;
            _showProfile = data['showProfile'] ?? _showProfile;
            _showActivity = data['showActivity'] ?? _showActivity;
            _allowMessages = data['allowMessages'] ?? _allowMessages;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
      
      // Also save to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('volunteer_settings')
            .doc(user.uid)
            .set({key: value}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Settings
                  _buildSectionTitle('Notifications'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.notifications,
                      title: 'Push Notifications',
                      subtitle: 'Receive push notifications',
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() => _pushNotifications = value);
                        _saveSetting('pushNotifications', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.email,
                      title: 'Email Notifications',
                      subtitle: 'Receive email updates',
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() => _emailNotifications = value);
                        _saveSetting('emailNotifications', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.campaign,
                      title: 'Campaign Updates',
                      subtitle: 'Get notified about campaign updates',
                      value: _campaignUpdates,
                      onChanged: (value) {
                        setState(() => _campaignUpdates = value);
                        _saveSetting('campaignUpdates', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.event,
                      title: 'Event Reminders',
                      subtitle: 'Receive reminders for events',
                      value: _eventReminders,
                      onChanged: (value) {
                        setState(() => _eventReminders = value);
                        _saveSetting('eventReminders', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.receipt,
                      title: 'Donation Receipts',
                      subtitle: 'Get donation receipts',
                      value: _donationReceipts,
                      onChanged: (value) {
                        setState(() => _donationReceipts = value);
                        _saveSetting('donationReceipts', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.warning,
                      title: 'SOS Alerts',
                      subtitle: 'Receive emergency SOS alerts',
                      value: _sosAlerts,
                      onChanged: (value) {
                        setState(() => _sosAlerts = value);
                        _saveSetting('sosAlerts', value);
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Privacy Settings
                  _buildSectionTitle('Privacy'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.person,
                      title: 'Show Profile',
                      subtitle: 'Allow others to view your profile',
                      value: _showProfile,
                      onChanged: (value) {
                        setState(() => _showProfile = value);
                        _saveSetting('showProfile', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.visibility,
                      title: 'Show Activity',
                      subtitle: 'Show your activity to others',
                      value: _showActivity,
                      onChanged: (value) {
                        setState(() => _showActivity = value);
                        _saveSetting('showActivity', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.message,
                      title: 'Allow Messages',
                      subtitle: 'Let others send you messages',
                      value: _allowMessages,
                      onChanged: (value) {
                        setState(() => _allowMessages = value);
                        _saveSetting('allowMessages', value);
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // App Settings
                  _buildSectionTitle('App Settings'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      subtitle: 'Use dark theme',
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() => _darkMode = value);
                        _saveSetting('darkMode', value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Restart app to apply theme'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildLanguageTile(),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Account Actions
                  _buildSectionTitle('Account'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: Icons.lock_reset,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: _showChangePasswordDialog,
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.download,
                      title: 'Download My Data',
                      subtitle: 'Export your personal data',
                      onTap: _downloadData,
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.delete_forever,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account',
                      isDestructive: true,
                      onTap: _showDeleteAccountDialog,
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // App Info
                  _buildSectionTitle('About'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildInfoTile(
                      icon: Icons.info,
                      title: 'App Version',
                      value: '1.0.0',
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.description,
                      title: 'Terms of Service',
                      onTap: () => _showTermsOfService(),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.privacy_tip,
                      title: 'Privacy Policy',
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.star_rate,
                      title: 'Rate the App',
                      onTap: () => _rateApp(),
                    ),
                  ]),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade200, indent: 56);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
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
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: primary,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final color = isDestructive ? Colors.red : primary;
    
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
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
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.language, color: primary, size: 20),
      ),
      title: const Text(
        'Language',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: DropdownButton<String>(
        value: _language,
        underline: const SizedBox(),
        items: ['English', 'Hindi', 'Punjabi', 'Tamil', 'Telugu']
            .map((lang) => DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _language = value);
            _saveSetting('language', value);
          }
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
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
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user?.email != null) {
                  final credential = EmailAuthProvider.credential(
                    email: user!.email!,
                    password: currentPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPasswordController.text);
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Change', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _downloadData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your data export request has been submitted. You will receive an email shortly.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // Delete user data from Firestore
                  await FirebaseFirestore.instance
                      .collection('volunteers')
                      .doc(user.uid)
                      .delete();
                  
                  // Delete user account
                  await user.delete();
                  
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Text(
            '''
Terms of Service for Connect NGO App

1. Acceptance of Terms
By accessing and using the Connect NGO app, you accept and agree to be bound by these Terms of Service.

2. User Responsibilities
- Provide accurate information
- Maintain account security
- Use the platform responsibly
- Respect other users

3. Donations
- All donations are voluntary
- Receipts will be provided for donations
- Refund policies apply as per NGO guidelines

4. Volunteer Activities
- Volunteers must comply with NGO guidelines
- Safety protocols must be followed
- Report any issues to the platform

5. Privacy
Your privacy is important to us. Please review our Privacy Policy for details.

6. Modifications
We reserve the right to modify these terms at any time.

7. Contact
For questions, contact support@connectngo.com
            ''',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your interest! App store rating coming soon.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
