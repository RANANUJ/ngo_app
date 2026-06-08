import 'package:ngo_app/core/utils/network/network_utils.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ngo_app/core/services/language_service.dart';
import '../../l10n/app_localizations.dart';

class VolunteerSettingsScreen extends StatefulWidget {
  const VolunteerSettingsScreen({super.key});

  @override
  State<VolunteerSettingsScreen> createState() => _VolunteerSettingsScreenState();
}

class _VolunteerSettingsScreenState extends State<VolunteerSettingsScreen> {
  // Encryption key and IV (should be managed securely in production)
  final encrypt.Key _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows!');
  final encrypt.IV _iv = encrypt.IV.fromLength(16);
  late final encrypt.Encrypter _encrypter = encrypt.Encrypter(encrypt.AES(_key));

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

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Future<void> _loadSettings() async {
    try {
      // Load from FlutterSecureStorage
      final pushNotifications = await _secureStorage.read(key: 'pushNotifications');
      final emailNotifications = await _secureStorage.read(key: 'emailNotifications');
      final campaignUpdates = await _secureStorage.read(key: 'campaignUpdates');
      final eventReminders = await _secureStorage.read(key: 'eventReminders');
      final donationReceipts = await _secureStorage.read(key: 'donationReceipts');
      final sosAlerts = await _secureStorage.read(key: 'sosAlerts');
      final showProfile = await _secureStorage.read(key: 'showProfile');
      final showActivity = await _secureStorage.read(key: 'showActivity');
      final allowMessages = await _secureStorage.read(key: 'allowMessages');
      final darkMode = await _secureStorage.read(key: 'darkMode');
      final language = await _secureStorage.read(key: 'language');

      setState(() {
        _pushNotifications = pushNotifications == null ? true : pushNotifications == 'true';
        _emailNotifications = emailNotifications == null ? true : emailNotifications == 'true';
        _campaignUpdates = campaignUpdates == null ? true : campaignUpdates == 'true';
        _eventReminders = eventReminders == null ? true : eventReminders == 'true';
        _donationReceipts = donationReceipts == null ? true : donationReceipts == 'true';
        _sosAlerts = sosAlerts == null ? true : sosAlerts == 'true';
        _showProfile = showProfile == null ? true : showProfile == 'true';
        _showActivity = showActivity == null ? true : showActivity == 'true';
        _allowMessages = allowMessages == null ? true : allowMessages == 'true';
        _darkMode = darkMode == null ? false : darkMode == 'true';
        _language = language ?? 'English';
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
      secureLog('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      if (value is bool || value is String) {
        await _secureStorage.write(key: key, value: value.toString());
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
      secureLog('Error saving setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.settings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Settings
                  _buildSectionTitle(l10n.notifications),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.notifications,
                      title: l10n.pushNotifications,
                      subtitle: l10n.pushNotificationsDesc,
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() => _pushNotifications = value);
                        _saveSetting('pushNotifications', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.email,
                      title: l10n.emailNotifications,
                      subtitle: l10n.emailNotificationsDesc,
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() => _emailNotifications = value);
                        _saveSetting('emailNotifications', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.campaign,
                      title: l10n.campaignUpdates,
                      subtitle: l10n.campaignUpdatesDesc,
                      value: _campaignUpdates,
                      onChanged: (value) {
                        setState(() => _campaignUpdates = value);
                        _saveSetting('campaignUpdates', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.event,
                      title: l10n.eventReminders,
                      subtitle: l10n.eventRemindersDesc,
                      value: _eventReminders,
                      onChanged: (value) {
                        setState(() => _eventReminders = value);
                        _saveSetting('eventReminders', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.receipt,
                      title: l10n.donationReceipts,
                      subtitle: l10n.donationReceiptsDesc,
                      value: _donationReceipts,
                      onChanged: (value) {
                        setState(() => _donationReceipts = value);
                        _saveSetting('donationReceipts', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.warning,
                      title: l10n.sosAlerts,
                      subtitle: l10n.sosAlertsDesc,
                      value: _sosAlerts,
                      onChanged: (value) {
                        setState(() => _sosAlerts = value);
                        _saveSetting('sosAlerts', value);
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Privacy Settings
                  _buildSectionTitle(l10n.privacy),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.person,
                      title: l10n.showProfile,
                      subtitle: l10n.showProfileDesc,
                      value: _showProfile,
                      onChanged: (value) {
                        setState(() => _showProfile = value);
                        _saveSetting('showProfile', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.visibility,
                      title: l10n.showActivity,
                      subtitle: l10n.showActivityDesc,
                      value: _showActivity,
                      onChanged: (value) {
                        setState(() => _showActivity = value);
                        _saveSetting('showActivity', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.message,
                      title: l10n.allowMessages,
                      subtitle: l10n.allowMessagesDesc,
                      value: _allowMessages,
                      onChanged: (value) {
                        setState(() => _allowMessages = value);
                        _saveSetting('allowMessages', value);
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // App Settings
                  _buildSectionTitle(l10n.appSettings),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.dark_mode,
                      title: l10n.darkMode,
                      subtitle: l10n.darkModeDesc,
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() => _darkMode = value);
                        _saveSetting('darkMode', value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.languageChanged),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildLanguageTile(),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Account Actions
                  _buildSectionTitle(l10n.account),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: Icons.lock_reset,
                      title: l10n.changePassword,
                      subtitle: l10n.changePasswordDesc,
                      onTap: _showChangePasswordDialog,
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.download,
                      title: l10n.downloadMyData,
                      subtitle: l10n.downloadMyDataDesc,
                      onTap: _downloadData,
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.delete_forever,
                      title: l10n.deleteAccount,
                      subtitle: l10n.deleteAccountDesc,
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
                      title: l10n.appVersion,
                      value: '1.0.0',
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.description,
                      title: l10n.termsOfService,
                      onTap: () => _showTermsOfService(),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.privacy_tip,
                      title: l10n.privacyPolicy,
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      icon: Icons.star_rate,
                      title: l10n.rateTheApp,
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
    final languageService = Provider.of<LanguageService>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.language, color: primary, size: 20),
      ),
      title: Text(
        l10n.language,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: DropdownButton<String>(
        value: languageService.isHindi ? 'Hindi' : 'English',
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: 'English',
            child: Text(l10n.english),
          ),
          DropdownMenuItem(
            value: 'Hindi',
            child: Text(l10n.hindi),
          ),
        ],
        onChanged: (value) async {
          if (value != null) {
            final languageCode = value == 'Hindi' ? 'hi' : 'en';
            await languageService.changeLanguage(languageCode);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.languageChanged),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
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

  void _downloadData() async {
    // Show options dialog first
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.download, color: Color(0xFF0099B8)),
            const SizedBox(width: 12),
            Expanded(
              child: const Text(
                'Download My Data',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your data will be exported as a PDF file containing all your personal information, activities, and settings.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.file_download, color: Color(0xFF0099B8)),
              title: const Text('Download PDF'),
              subtitle: const Text('Save to your device'),
              onTap: () => Navigator.pop(context, 'download'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF0099B8)),
              title: const Text('Share PDF'),
              subtitle: const Text('Share via email, WhatsApp, etc.'),
              onTap: () => Navigator.pop(context, 'share'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing your data export...'),
                SizedBox(height: 8),
                Text(
                  'This may take a few moments',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Call the Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('exportUserData');
      final result = await callable.call();

      // Get the export ID from result
      final exportId = result.data['exportId'];
      
      if (exportId == null) {
        throw Exception('Export ID not received');
      }

      // Fetch the PDF data from Firestore
      final exportDoc = await FirebaseFirestore.instance
          .collection('data_exports')
          .doc(exportId)
          .get();

      if (!exportDoc.exists) {
        throw Exception('Export data not found');
      }

      final pdfBase64 = exportDoc.data()?['pdfData'];
      final fileName = exportDoc.data()?['fileName'] ?? 'ConnectNGO_UserData.pdf';

      if (pdfBase64 == null) {
        throw Exception('PDF data not available');
      }

      // Decode the base64 PDF
      final pdfBytes = base64Decode(pdfBase64);
      // Encrypt PDF bytes before saving
      final encrypted = _encrypter.encryptBytes(pdfBytes, iv: _iv);

      // Get the downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        // Try to use Downloads folder
        final downloadsPath = '/storage/emulated/0/Download';
        if (await Directory(downloadsPath).exists()) {
          directory = Directory(downloadsPath);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory!.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(encrypted.bytes);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (choice == 'share') {
        // Share the file
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'My Data Export - Connect NGO',
          text: 'Here is my data export from Connect NGO app.',
        );
      } else {
        // Show success with file location
        if (mounted) {
          _showDownloadSuccessDialog(filePath, file);
        }
      }

    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      secureLog('Data export error: $e');

      // Parse error message
      String errorMessage = 'Failed to export data. Please try again.';
      if (e.toString().contains('not-found')) {
        errorMessage = 'Profile not found. Please complete your registration.';
      } else if (e.toString().contains('unauthenticated')) {
        errorMessage = 'Session expired. Please login again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Storage permission required. Please grant permission and try again.';
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Export Error',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(errorMessage, style: const TextStyle(fontSize: 13)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _downloadData,
            ),
          ),
        );
      }
    }
  }

  void _showDownloadSuccessDialog(String filePath, File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Download Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your data has been exported successfully.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filePath.split('/').last,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Saved to Downloads',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // Share the file for opening
              await Share.shareXFiles(
                [XFile(filePath)],
                subject: 'My Data Export - Connect NGO',
              );
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open / Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
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
