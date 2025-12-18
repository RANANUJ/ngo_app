import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NgoNotificationsScreen extends StatefulWidget {
  final String? ngoId;
  final String ngoName;

  const NgoNotificationsScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
  }) : super(key: key);

  @override
  State<NgoNotificationsScreen> createState() => _NgoNotificationsScreenState();
}

class _NgoNotificationsScreenState extends State<NgoNotificationsScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  // Notification Settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _donationAlerts = true;
  bool _volunteerAlerts = true;
  bool _campaignUpdates = true;
  bool _eventReminders = true;
  bool _weeklyDigest = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadSettings();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: widget.ngoId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      setState(() {
        _notifications = snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ngo_settings')
          .doc(widget.ngoId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _pushNotifications = data['pushNotifications'] ?? true;
          _emailNotifications = data['emailNotifications'] ?? true;
          _donationAlerts = data['donationAlerts'] ?? true;
          _volunteerAlerts = data['volunteerAlerts'] ?? true;
          _campaignUpdates = data['campaignUpdates'] ?? true;
          _eventReminders = data['eventReminders'] ?? true;
          _weeklyDigest = data['weeklyDigest'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await FirebaseFirestore.instance
          .collection('ngo_settings')
          .doc(widget.ngoId)
          .set({
        'pushNotifications': _pushNotifications,
        'emailNotifications': _emailNotifications,
        'donationAlerts': _donationAlerts,
        'volunteerAlerts': _volunteerAlerts,
        'campaignUpdates': _campaignUpdates,
        'eventReminders': _eventReminders,
        'weeklyDigest': _weeklyDigest,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var notification in _notifications.where((n) => n['read'] != true)) {
        batch.update(
          FirebaseFirestore.instance.collection('notifications').doc(notification['id']),
          {'read': true},
        );
      }
      await batch.commit();
      _loadNotifications();
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (var notification in _notifications) {
          batch.delete(
            FirebaseFirestore.instance.collection('notifications').doc(notification['id']),
          );
        }
        await batch.commit();
        _loadNotifications();
      } catch (e) {
        debugPrint('Error clearing notifications: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onSelected: (value) {
                if (value == 'read') {
                  _markAllAsRead();
                } else if (value == 'clear') {
                  _clearAllNotifications();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear all', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            labelColor: primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primary,
            tabs: const [
              Tab(text: 'All Notifications'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationsTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications about donations,\nvolunteers, and updates here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['read'] ?? false;
    final String type = notification['type'] ?? 'general';
    
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'donation':
        icon = Icons.volunteer_activism;
        iconColor = Colors.green;
        break;
      case 'volunteer':
        icon = Icons.people;
        iconColor = Colors.blue;
        break;
      case 'campaign':
        icon = Icons.campaign;
        iconColor = Colors.orange;
        break;
      case 'event':
        icon = Icons.event;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        iconColor = primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isRead ? null : Border.all(color: primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification['title'] ?? 'Notification',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['message'] ?? '',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(notification['createdAt']),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return 'Just now';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General Settings
          _buildSettingsSection(
            'General',
            [
              _buildSwitchTile(
                'Push Notifications',
                'Receive push notifications on this device',
                Icons.notifications_active,
                _pushNotifications,
                (value) => setState(() => _pushNotifications = value),
              ),
              _buildSwitchTile(
                'Email Notifications',
                'Receive notifications via email',
                Icons.email,
                _emailNotifications,
                (value) => setState(() => _emailNotifications = value),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Alert Settings
          _buildSettingsSection(
            'Alerts',
            [
              _buildSwitchTile(
                'Donation Alerts',
                'Get notified when you receive donations',
                Icons.volunteer_activism,
                _donationAlerts,
                (value) => setState(() => _donationAlerts = value),
              ),
              _buildSwitchTile(
                'Volunteer Requests',
                'Get notified about volunteer applications',
                Icons.people,
                _volunteerAlerts,
                (value) => setState(() => _volunteerAlerts = value),
              ),
              _buildSwitchTile(
                'Campaign Updates',
                'Updates about your campaigns',
                Icons.campaign,
                _campaignUpdates,
                (value) => setState(() => _campaignUpdates = value),
              ),
              _buildSwitchTile(
                'Event Reminders',
                'Reminders for upcoming events',
                Icons.event,
                _eventReminders,
                (value) => setState(() => _eventReminders = value),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Digest Settings
          _buildSettingsSection(
            'Digest',
            [
              _buildSwitchTile(
                'Weekly Digest',
                'Receive a weekly summary of activities',
                Icons.summarize,
                _weeklyDigest,
                (value) => setState(() => _weeklyDigest = value),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      secondary: Icon(icon, color: primary),
      value: value,
      activeColor: primary,
      onChanged: onChanged,
    );
  }
}
