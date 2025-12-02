import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VolunteerNotificationsScreen extends StatefulWidget {
  const VolunteerNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerNotificationsScreen> createState() => _VolunteerNotificationsScreenState();
}

class _VolunteerNotificationsScreenState extends State<VolunteerNotificationsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  
  late TabController _tabController;
  
  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _campaignUpdates = true;
  bool _eventReminders = true;
  bool _donationReceipts = true;
  bool _sosAlerts = true;
  bool _ngoUpdates = true;
  
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _pushNotifications = prefs.getBool('pushNotifications') ?? true;
        _emailNotifications = prefs.getBool('emailNotifications') ?? true;
        _campaignUpdates = prefs.getBool('campaignUpdates') ?? true;
        _eventReminders = prefs.getBool('eventReminders') ?? true;
        _donationReceipts = prefs.getBool('donationReceipts') ?? true;
        _sosAlerts = prefs.getBool('sosAlerts') ?? true;
        _ngoUpdates = prefs.getBool('ngoUpdates') ?? true;
        _isLoadingSettings = false;
      });
      
      // Load from Firestore
      if (_userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('volunteer_settings')
            .doc(_userId)
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
            _ngoUpdates = data['ngoUpdates'] ?? _ngoUpdates;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('pushNotifications', _pushNotifications);
      await prefs.setBool('emailNotifications', _emailNotifications);
      await prefs.setBool('campaignUpdates', _campaignUpdates);
      await prefs.setBool('eventReminders', _eventReminders);
      await prefs.setBool('donationReceipts', _donationReceipts);
      await prefs.setBool('sosAlerts', _sosAlerts);
      await prefs.setBool('ngoUpdates', _ngoUpdates);
      
      if (_userId != null) {
        await FirebaseFirestore.instance
            .collection('volunteer_settings')
            .doc(_userId)
            .set({
          'pushNotifications': _pushNotifications,
          'emailNotifications': _emailNotifications,
          'campaignUpdates': _campaignUpdates,
          'eventReminders': _eventReminders,
          'donationReceipts': _donationReceipts,
          'sosAlerts': _sosAlerts,
          'ngoUpdates': _ngoUpdates,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
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
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primary,
          tabs: const [
            Tab(text: 'All Notifications'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: _userId == null
          ? const Center(child: Text('Please login to view notifications'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildNotificationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildNotificationsWithoutOrder();
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              return _buildNotificationCard(data, notification.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationsWithoutOrder() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data?.docs ?? [];
        
        notifications.sort((a, b) {
          final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              return _buildNotificationCard(data, notification.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data, String notificationId) {
    final title = data['title'] ?? 'Notification';
    final message = data['message'] ?? data['body'] ?? '';
    final type = data['type'] ?? 'general';
    final isRead = data['isRead'] ?? false;
    final createdAt = data['createdAt'] as Timestamp?;

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notificationId);
      },
      child: GestureDetector(
        onTap: () => _markAsRead(notificationId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? Colors.grey.shade200 : primary.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }
    
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

          // Activity Settings
          _buildSettingsSection(
            'Activity Notifications',
            [
              _buildSwitchTile(
                'Campaign Updates',
                'Get notified about new campaigns',
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
              _buildSwitchTile(
                'NGO Updates',
                'Updates from NGOs you follow',
                Icons.business,
                _ngoUpdates,
                (value) => setState(() => _ngoUpdates = value),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Transaction Settings
          _buildSettingsSection(
            'Transaction Notifications',
            [
              _buildSwitchTile(
                'Donation Receipts',
                'Get receipts for your donations',
                Icons.receipt_long,
                _donationReceipts,
                (value) => setState(() => _donationReceipts = value),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Safety Settings
          _buildSettingsSection(
            'Safety',
            [
              _buildSwitchTile(
                'SOS Alerts',
                'Receive emergency SOS alerts',
                Icons.warning_amber,
                _sosAlerts,
                (value) => setState(() => _sosAlerts = value),
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
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primary, size: 20),
      ),
      value: value,
      activeColor: primary,
      onChanged: onChanged,
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'campaigncreated':
      case 'campaign':
        return Icons.campaign;
      case 'eventcreated':
      case 'eventreminder':
      case 'event':
        return Icons.event;
      case 'donationsuccess':
      case 'donation':
        return Icons.volunteer_activism;
      case 'volunteerapproved':
        return Icons.check_circle;
      case 'volunteerrejected':
        return Icons.cancel;
      case 'sos':
      case 'sosalert':
        return Icons.warning;
      case 'ngo':
        return Icons.business;
      case 'message':
        return Icons.message;
      case 'alert':
        return Icons.notification_important;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'campaigncreated':
      case 'campaign':
        return Colors.blue;
      case 'eventcreated':
      case 'eventreminder':
      case 'event':
        return Colors.purple;
      case 'donationsuccess':
      case 'donation':
        return Colors.green;
      case 'volunteerapproved':
        return Colors.green;
      case 'volunteerrejected':
        return Colors.red;
      case 'sos':
      case 'sosalert':
        return Colors.red;
      case 'ngo':
        return Colors.orange;
      case 'message':
        return Colors.teal;
      case 'alert':
        return Colors.red;
      default:
        return primary;
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final unreadNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
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
        
        final notifications = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: _userId)
            .get();
        
        for (var doc in notifications.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error clearing notifications: $e');
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
}
