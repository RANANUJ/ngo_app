import 'package:flutter/material.dart';

class SettingsDetailsScreen extends StatefulWidget {
  final String settingName;
  const SettingsDetailsScreen({Key? key, required this.settingName}) : super(key: key);

  @override
  State<SettingsDetailsScreen> createState() => _SettingsDetailsScreenState();
}

class _SettingsDetailsScreenState extends State<SettingsDetailsScreen> {
  static const Color primaryColor = Color(0xFF0099B8);
  bool _isLoading = false;

  // General Settings values
  bool _maintenanceMode = false;
  bool _autoApproveApprovedDomain = false;

  // Notification settings values
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsAlerts = false;

  // Verification settings values
  bool _requireMoA = true;
  bool _require12A80G = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.settingName,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _buildSettingsContent(),
    );
  }

  Widget _buildSettingsContent() {
    switch (widget.settingName) {
      case 'General Settings':
        return _buildGeneralSettings();
      case 'Notification Settings':
        return _buildNotificationSettings();
      case 'Verification Settings':
        return _buildVerificationSettings();
      case 'Document Settings':
        return _buildDocumentSettings();
      case 'Email Templates':
        return _buildEmailTemplates();
      case 'Security Settings':
        return _buildSecuritySettings();
      case 'Activity Log':
        return _buildActivityLog();
      default:
        return const Center(child: Text('Settings detail page not found.'));
    }
  }

  Widget _buildGeneralSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSwitchTile(
          'App Maintenance Mode',
          'Temporarily disable access to all non-admin users.',
          _maintenanceMode,
          (val) => setState(() => _maintenanceMode = val),
        ),
        const Divider(height: 1),
        _buildSwitchTile(
          'Auto-approve trust domains',
          'Skip verify step for known government organizations.',
          _autoApproveApprovedDomain,
          (val) => setState(() => _autoApproveApprovedDomain = val),
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSwitchTile(
          'Email Notifications',
          'Send emails for verification requests and updates.',
          _emailNotifications,
          (val) => setState(() => _emailNotifications = val),
        ),
        const Divider(height: 1),
        _buildSwitchTile(
          'Push Notifications',
          'Send real-time alerts to admins on new registrations.',
          _pushNotifications,
          (val) => setState(() => _pushNotifications = val),
        ),
        const Divider(height: 1),
        _buildSwitchTile(
          'SMS Alerts',
          'Send critical alerts via SMS (charges apply).',
          _smsAlerts,
          (val) => setState(() => _smsAlerts = val),
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildVerificationSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSwitchTile(
          'Require Bylaws/MoA Auditing',
          'Force checklist approval of organizational bylaws.',
          _requireMoA,
          (val) => setState(() => _requireMoA = val),
        ),
        const Divider(height: 1),
        _buildSwitchTile(
          'Require 12A/80G status proof',
          'Require submission of tax exemption certifications.',
          _require12A80G,
          (val) => setState(() => _require12A80G = val),
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildDocumentSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader('Allowed Document Formats'),
        _buildDocFormatCheckbox('PDF (.pdf)', true),
        _buildDocFormatCheckbox('Images (.jpg, .png)', true),
        _buildDocFormatCheckbox('Word Docs (.doc, .docx)', false),
        const SizedBox(height: 24),
        _buildHeader('Maximum File Size Limit'),
        ListTile(
          title: const Text('File Size Limit (MB)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          trailing: DropdownButton<int>(
            value: 10,
            items: [5, 10, 20, 50].map((size) {
              return DropdownMenuItem(value: size, child: Text('$size MB'));
            }).toList(),
            onChanged: (_) {},
          ),
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildEmailTemplates() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildTemplateTile('NGO Approval Confirmation', 'Subject: Welcome to NgoApp! Your verification is approved...'),
        const Divider(height: 1),
        _buildTemplateTile('NGO Rejection Notice', 'Subject: Action Required: NgoApp registration status...'),
        const Divider(height: 1),
        _buildTemplateTile('Admin Invitation Email', 'Subject: You have been invited to join the Administrative team...'),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    final passController = TextEditingController(text: '********');
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader('Password Requirements'),
        _buildDocFormatCheckbox('Minimum 8 characters length', true),
        _buildDocFormatCheckbox('Require special characters', false),
        _buildDocFormatCheckbox('Force periodic password expiry (90 days)', false),
        const SizedBox(height: 24),
        _buildHeader('Change Password'),
        TextField(
          controller: passController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildActivityLog() {
    final logs = [
      {'action': 'NGO Approved', 'target': 'Green Earth Foundation', 'time': '10 mins ago', 'user': 'rana1452005@gmail.com'},
      {'action': 'User Status Changed', 'target': 'Rohit Sharma (Reviewer)', 'time': '1 hour ago', 'user': 'rana1452005@gmail.com'},
      {'action': 'Announcement Published', 'target': 'Update: Document Requirements', 'time': '2 hours ago', 'user': 'rana1452005@gmail.com'},
      {'action': 'Security settings updated', 'target': 'Password policy', 'time': '1 day ago', 'user': 'rana1452005@gmail.com'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const Icon(Icons.history_toggle_off, color: primaryColor),
            title: Text('${log['action']} - ${log['target']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('By: ${log['user']} • ${log['time']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      activeColor: primaryColor,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDocFormatCheckbox(String label, bool value) {
    return CheckboxListTile(
      activeColor: primaryColor,
      title: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
      value: value,
      onChanged: (_) {},
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildTemplateTile(String name, String subject) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subject, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
      trailing: IconButton(
        icon: const Icon(Icons.edit_note_outlined, color: primaryColor),
        onPressed: () {},
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          setState(() => _isLoading = true);
          Future.delayed(const Duration(milliseconds: 600), () {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings Saved Successfully'), backgroundColor: Colors.green),
            );
          });
        },
        child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
