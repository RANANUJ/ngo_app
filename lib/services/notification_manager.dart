import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Enum for notification types
enum NotificationType {
  // Volunteer notifications
  campaignCreated,
  eventCreated,
  donationSuccess,
  volunteerApproved,
  volunteerRejected,
  eventReminder,
  campaignUpdate,
  
  // NGO notifications
  donationReceived,
  volunteerApplication,
  volunteerJoinedCampaign,
  volunteerJoinedEvent,
  sosAlert,
  weeklyDigest,
}

/// Comprehensive notification manager for both volunteers and NGOs
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Email configuration - In production, use environment variables or secure storage
  static const String _smtpEmail = 'connectngo.notifications@gmail.com';
  static const String _smtpPassword = 'your-app-password'; // Use App Password for Gmail
  
  // ==================== VOLUNTEER NOTIFICATIONS ====================

  /// Send notification when a new campaign is created
  Future<void> notifyCampaignCreated({
    required String campaignId,
    required String campaignName,
    required String ngoName,
    required String ngoId,
    String? imageUrl,
  }) async {
    try {
      // Get all volunteers who follow this NGO or have settings enabled
      final volunteers = await _getVolunteersWithSetting('campaignUpdates', true);
      
      for (final volunteer in volunteers) {
        final volunteerId = volunteer['id'] as String;
        final volunteerEmail = volunteer['email'] as String?;
        final emailEnabled = volunteer['emailNotifications'] ?? true;
        
        // Create in-app notification
        await _createNotification(
          userId: volunteerId,
          userType: 'volunteer',
          title: 'New Campaign: $campaignName',
          message: '$ngoName has started a new campaign. Join now to make an impact!',
          type: NotificationType.campaignCreated,
          data: {
            'campaignId': campaignId,
            'ngoId': ngoId,
            'ngoName': ngoName,
          },
        );
        
        // Send email if enabled
        if (emailEnabled && volunteerEmail != null && volunteerEmail.isNotEmpty) {
          await _sendEmail(
            to: volunteerEmail,
            subject: 'New Campaign: $campaignName',
            body: '''
Hello,

$ngoName has launched a new campaign: "$campaignName"

Join this campaign to make a positive impact in your community!

Open the Connect NGO app to learn more and participate.

Best regards,
Connect NGO Team
            ''',
          );
        }
        
        // Send push notification
        await _sendPushToUser(volunteerId, 'volunteer', 
          'New Campaign: $campaignName',
          '$ngoName has started a new campaign. Join now!',
        );
      }
    } catch (e) {
      debugPrint('Error notifying campaign created: $e');
    }
  }

  /// Send notification when a new event is created
  Future<void> notifyEventCreated({
    required String eventId,
    required String eventName,
    required String ngoName,
    required String ngoId,
    required DateTime eventDate,
    String? location,
  }) async {
    try {
      final volunteers = await _getVolunteersWithSetting('eventReminders', true);
      
      for (final volunteer in volunteers) {
        final volunteerId = volunteer['id'] as String;
        final volunteerEmail = volunteer['email'] as String?;
        final emailEnabled = volunteer['emailNotifications'] ?? true;
        
        // Create in-app notification
        await _createNotification(
          userId: volunteerId,
          userType: 'volunteer',
          title: 'New Event: $eventName',
          message: '$ngoName is organizing an event on ${_formatDate(eventDate)}. Register now!',
          type: NotificationType.eventCreated,
          data: {
            'eventId': eventId,
            'ngoId': ngoId,
            'ngoName': ngoName,
            'eventDate': eventDate.toIso8601String(),
            'location': location,
          },
        );
        
        // Send email if enabled
        if (emailEnabled && volunteerEmail != null && volunteerEmail.isNotEmpty) {
          await _sendEmail(
            to: volunteerEmail,
            subject: 'New Event: $eventName',
            body: '''
Hello,

$ngoName is organizing an event: "$eventName"

📅 Date: ${_formatDate(eventDate)}
📍 Location: ${location ?? 'To be announced'}

Don't miss this opportunity to participate and make a difference!

Open the Connect NGO app to register.

Best regards,
Connect NGO Team
            ''',
          );
        }
        
        // Send push notification
        await _sendPushToUser(volunteerId, 'volunteer',
          'New Event: $eventName',
          '${_formatDate(eventDate)} at ${location ?? 'TBA'}',
        );
      }
    } catch (e) {
      debugPrint('Error notifying event created: $e');
    }
  }

  /// Send notification when volunteer makes a donation
  Future<void> notifyDonationSuccess({
    required String volunteerId,
    required String volunteerEmail,
    required String volunteerName,
    required double amount,
    required String ngoName,
    required String ngoId,
    required String transactionId,
    String? campaignName,
  }) async {
    try {
      final settings = await _getVolunteerSettings(volunteerId);
      final emailEnabled = settings['emailNotifications'] ?? true;
      final donationReceipts = settings['donationReceipts'] ?? true;
      
      // Create in-app notification
      await _createNotification(
        userId: volunteerId,
        userType: 'volunteer',
        title: 'Donation Successful!',
        message: 'Your donation of ₹${amount.toStringAsFixed(0)} to $ngoName was successful.',
        type: NotificationType.donationSuccess,
        data: {
          'amount': amount,
          'ngoId': ngoId,
          'ngoName': ngoName,
          'transactionId': transactionId,
          'campaignName': campaignName,
        },
      );
      
      // Send email receipt if enabled
      if (emailEnabled && donationReceipts && volunteerEmail.isNotEmpty) {
        await _sendEmail(
          to: volunteerEmail,
          subject: 'Donation Receipt - ₹${amount.toStringAsFixed(0)} to $ngoName',
          body: '''
Dear $volunteerName,

Thank you for your generous donation!

DONATION RECEIPT
================
Amount: ₹${amount.toStringAsFixed(2)}
NGO: $ngoName
${campaignName != null ? 'Campaign: $campaignName\n' : ''}Transaction ID: $transactionId
Date: ${_formatDateTime(DateTime.now())}

Your contribution will help make a positive impact in the community.

Thank you for your support!

Best regards,
Connect NGO Team

This is an auto-generated receipt. Please keep it for your records.
          ''',
        );
      }
      
      // Send push notification
      await _sendPushToUser(volunteerId, 'volunteer',
        'Donation Successful!',
        'Thank you for donating ₹${amount.toStringAsFixed(0)} to $ngoName',
      );
    } catch (e) {
      debugPrint('Error notifying donation success: $e');
    }
  }

  /// Send event reminder notification
  Future<void> sendEventReminder({
    required String eventId,
    required String eventName,
    required String ngoName,
    required DateTime eventDate,
    required int hoursUntilEvent,
  }) async {
    try {
      // Get all participants of this event
      final participants = await _firestore
          .collection('event_participants')
          .where('eventId', isEqualTo: eventId)
          .get();
      
      for (final doc in participants.docs) {
        final volunteerId = doc.data()['userId'] as String?;
        if (volunteerId == null) continue;
        
        final settings = await _getVolunteerSettings(volunteerId);
        if (!(settings['eventReminders'] ?? true)) continue;
        
        final volunteerDoc = await _firestore.collection('volunteers').doc(volunteerId).get();
        final volunteerEmail = volunteerDoc.data()?['email'] as String?;
        final emailEnabled = settings['emailNotifications'] ?? true;
        
        // Create in-app notification
        await _createNotification(
          userId: volunteerId,
          userType: 'volunteer',
          title: 'Event Reminder: $eventName',
          message: 'Your event starts in $hoursUntilEvent hours. Don\'t forget to attend!',
          type: NotificationType.eventReminder,
          data: {
            'eventId': eventId,
            'eventDate': eventDate.toIso8601String(),
          },
        );
        
        // Send email reminder
        if (emailEnabled && volunteerEmail != null && volunteerEmail.isNotEmpty) {
          await _sendEmail(
            to: volunteerEmail,
            subject: 'Reminder: $eventName starts in $hoursUntilEvent hours',
            body: '''
Hello,

This is a reminder that the event "$eventName" by $ngoName starts in $hoursUntilEvent hours.

📅 Date: ${_formatDateTime(eventDate)}

Don't forget to attend!

Best regards,
Connect NGO Team
            ''',
          );
        }
        
        // Send push notification
        await _sendPushToUser(volunteerId, 'volunteer',
          '⏰ Event Reminder',
          '$eventName starts in $hoursUntilEvent hours!',
        );
      }
    } catch (e) {
      debugPrint('Error sending event reminder: $e');
    }
  }

  // ==================== NGO NOTIFICATIONS ====================

  /// Notify NGO when donation is received
  Future<void> notifyDonationReceived({
    required String ngoId,
    required String ngoEmail,
    required String ngoName,
    required String donorName,
    required String donorId,
    required double amount,
    required String transactionId,
    String? campaignName,
  }) async {
    try {
      final settings = await _getNgoSettings(ngoId);
      if (!(settings['donationAlerts'] ?? true)) return;
      
      final emailEnabled = settings['emailNotifications'] ?? true;
      
      // Create in-app notification
      await _createNotification(
        userId: ngoId,
        userType: 'ngo',
        title: 'Donation Received: ₹${amount.toStringAsFixed(0)}',
        message: '$donorName donated to ${campaignName ?? 'your organization'}',
        type: NotificationType.donationReceived,
        data: {
          'donorId': donorId,
          'donorName': donorName,
          'amount': amount,
          'transactionId': transactionId,
          'campaignName': campaignName,
        },
      );
      
      // Send email if enabled
      if (emailEnabled && ngoEmail.isNotEmpty) {
        await _sendEmail(
          to: ngoEmail,
          subject: 'New Donation Received - ₹${amount.toStringAsFixed(0)}',
          body: '''
Dear $ngoName Team,

Great news! You've received a new donation.

DONATION DETAILS
================
Donor: $donorName
Amount: ₹${amount.toStringAsFixed(2)}
${campaignName != null ? 'Campaign: $campaignName\n' : ''}Transaction ID: $transactionId
Date: ${_formatDateTime(DateTime.now())}

Thank you for your work in making a difference!

Best regards,
Connect NGO Team
          ''',
        );
      }
      
      // Send push notification
      await _sendPushToNgo(ngoId,
        '💰 Donation Received!',
        '$donorName donated ₹${amount.toStringAsFixed(0)}',
      );
    } catch (e) {
      debugPrint('Error notifying donation received: $e');
    }
  }

  /// Notify NGO when volunteer applies
  Future<void> notifyVolunteerApplication({
    required String ngoId,
    required String ngoEmail,
    required String ngoName,
    required String volunteerId,
    required String volunteerName,
    required String volunteerEmail,
    String? role,
  }) async {
    try {
      final settings = await _getNgoSettings(ngoId);
      if (!(settings['volunteerAlerts'] ?? true)) return;
      
      final emailEnabled = settings['emailNotifications'] ?? true;
      
      // Create in-app notification
      await _createNotification(
        userId: ngoId,
        userType: 'ngo',
        title: 'New Volunteer Application',
        message: '$volunteerName has applied to volunteer${role != null ? ' as $role' : ''}',
        type: NotificationType.volunteerApplication,
        data: {
          'volunteerId': volunteerId,
          'volunteerName': volunteerName,
          'volunteerEmail': volunteerEmail,
          'role': role,
        },
      );
      
      // Send email if enabled
      if (emailEnabled && ngoEmail.isNotEmpty) {
        await _sendEmail(
          to: ngoEmail,
          subject: 'New Volunteer Application - $volunteerName',
          body: '''
Dear $ngoName Team,

You have received a new volunteer application!

APPLICANT DETAILS
=================
Name: $volunteerName
Email: $volunteerEmail
${role != null ? 'Role: $role\n' : ''}Date: ${_formatDateTime(DateTime.now())}

Please review this application in the Connect NGO app.

Best regards,
Connect NGO Team
          ''',
        );
      }
      
      // Send push notification
      await _sendPushToNgo(ngoId,
        '👤 New Volunteer Application',
        '$volunteerName wants to join your organization',
      );
    } catch (e) {
      debugPrint('Error notifying volunteer application: $e');
    }
  }

  /// Notify NGO when volunteer joins campaign
  Future<void> notifyVolunteerJoinedCampaign({
    required String ngoId,
    required String campaignId,
    required String campaignName,
    required String volunteerId,
    required String volunteerName,
  }) async {
    try {
      final settings = await _getNgoSettings(ngoId);
      if (!(settings['campaignUpdates'] ?? true)) return;
      
      // Create in-app notification
      await _createNotification(
        userId: ngoId,
        userType: 'ngo',
        title: 'Volunteer Joined Campaign',
        message: '$volunteerName joined "$campaignName"',
        type: NotificationType.volunteerJoinedCampaign,
        data: {
          'campaignId': campaignId,
          'campaignName': campaignName,
          'volunteerId': volunteerId,
          'volunteerName': volunteerName,
        },
      );
      
      // Send push notification
      await _sendPushToNgo(ngoId,
        '🎉 Campaign Update',
        '$volunteerName joined "$campaignName"',
      );
    } catch (e) {
      debugPrint('Error notifying volunteer joined campaign: $e');
    }
  }

  /// Notify NGO when volunteer joins event
  Future<void> notifyVolunteerJoinedEvent({
    required String ngoId,
    required String eventId,
    required String eventName,
    required String volunteerId,
    required String volunteerName,
  }) async {
    try {
      final settings = await _getNgoSettings(ngoId);
      if (!(settings['eventReminders'] ?? true)) return;
      
      // Create in-app notification
      await _createNotification(
        userId: ngoId,
        userType: 'ngo',
        title: 'Volunteer Registered for Event',
        message: '$volunteerName registered for "$eventName"',
        type: NotificationType.volunteerJoinedEvent,
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'volunteerId': volunteerId,
          'volunteerName': volunteerName,
        },
      );
      
      // Send push notification
      await _sendPushToNgo(ngoId,
        '📅 Event Registration',
        '$volunteerName registered for "$eventName"',
      );
    } catch (e) {
      debugPrint('Error notifying volunteer joined event: $e');
    }
  }

  /// Notify volunteer about application status
  Future<void> notifyVolunteerApplicationStatus({
    required String volunteerId,
    required String volunteerEmail,
    required String volunteerName,
    required String ngoName,
    required String ngoId,
    required bool approved,
    String? rejectionReason,
  }) async {
    try {
      final title = approved ? 'Application Approved!' : 'Application Update';
      final message = approved 
          ? 'Congratulations! Your volunteer application to $ngoName has been approved.'
          : 'Your application to $ngoName was not approved.${rejectionReason != null ? ' Reason: $rejectionReason' : ''}';
      
      // Create in-app notification
      await _createNotification(
        userId: volunteerId,
        userType: 'volunteer',
        title: title,
        message: message,
        type: approved ? NotificationType.volunteerApproved : NotificationType.volunteerRejected,
        data: {
          'ngoId': ngoId,
          'ngoName': ngoName,
          'approved': approved,
          'rejectionReason': rejectionReason,
        },
      );
      
      // Send email
      final settings = await _getVolunteerSettings(volunteerId);
      if ((settings['emailNotifications'] ?? true) && volunteerEmail.isNotEmpty) {
        await _sendEmail(
          to: volunteerEmail,
          subject: approved ? 'Welcome to $ngoName!' : 'Application Update from $ngoName',
          body: approved ? '''
Dear $volunteerName,

Congratulations! 🎉

Your volunteer application to $ngoName has been approved!

You can now:
- Participate in campaigns
- Join events
- Contribute to the organization's mission

Log in to the Connect NGO app to get started.

Welcome aboard!

Best regards,
Connect NGO Team
          ''' : '''
Dear $volunteerName,

Thank you for your interest in volunteering with $ngoName.

Unfortunately, your application was not approved at this time.
${rejectionReason != null ? '\nReason: $rejectionReason\n' : ''}
We encourage you to explore other opportunities on Connect NGO.

Best regards,
Connect NGO Team
          ''',
        );
      }
      
      // Send push notification
      await _sendPushToUser(volunteerId, 'volunteer',
        title,
        approved ? 'You\'re now a volunteer at $ngoName!' : 'Your application to $ngoName was reviewed',
      );
    } catch (e) {
      debugPrint('Error notifying application status: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Create a notification in Firestore
  Future<void> _createNotification({
    required String userId,
    required String userType,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'recipientId': userId, // For backward compatibility
        'userType': userType,
        'title': title,
        'message': message,
        'body': message, // For backward compatibility
        'type': type.name,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Get volunteer settings
  Future<Map<String, dynamic>> _getVolunteerSettings(String volunteerId) async {
    try {
      final doc = await _firestore.collection('volunteer_settings').doc(volunteerId).get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Get NGO settings
  Future<Map<String, dynamic>> _getNgoSettings(String ngoId) async {
    try {
      final doc = await _firestore.collection('ngo_settings').doc(ngoId).get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Get volunteers with a specific setting enabled
  Future<List<Map<String, dynamic>>> _getVolunteersWithSetting(String setting, bool value) async {
    try {
      // Get all volunteers
      final volunteersSnapshot = await _firestore.collection('volunteers').get();
      final List<Map<String, dynamic>> result = [];
      
      for (final doc in volunteersSnapshot.docs) {
        final volunteerId = doc.id;
        final volunteerData = doc.data();
        
        // Check settings
        final settingsDoc = await _firestore.collection('volunteer_settings').doc(volunteerId).get();
        final settings = settingsDoc.data() ?? {};
        
        // If setting doesn't exist, default to true (notifications enabled by default)
        if ((settings[setting] ?? true) == value) {
          result.add({
            'id': volunteerId,
            ...volunteerData,
            ...settings,
          });
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting volunteers with setting: $e');
      return [];
    }
  }

  /// Send push notification to a user
  Future<void> _sendPushToUser(String userId, String userType, String title, String body) async {
    try {
      final collection = userType == 'volunteer' ? 'volunteers' : 'ngo_registrations';
      final doc = await _firestore.collection(collection).doc(userId).get();
      final fcmToken = doc.data()?['fcmToken'] as String?;
      
      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Store push notification request for Cloud Functions to send
        await _firestore.collection('push_notifications').add({
          'token': fcmToken,
          'title': title,
          'body': body,
          'userId': userId,
          'userType': userType,
          'createdAt': FieldValue.serverTimestamp(),
          'sent': false,
        });
      }
    } catch (e) {
      debugPrint('Error sending push to user: $e');
    }
  }

  /// Send push notification to NGO
  Future<void> _sendPushToNgo(String ngoId, String title, String body) async {
    try {
      // Get all FCM tokens for this NGO
      final tokensSnapshot = await _firestore
          .collection('ngo_fcm_tokens')
          .where('ngoId', isEqualTo: ngoId)
          .get();
      
      for (final doc in tokensSnapshot.docs) {
        final fcmToken = doc.data()['fcmToken'] as String?;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _firestore.collection('push_notifications').add({
            'token': fcmToken,
            'title': title,
            'body': body,
            'ngoId': ngoId,
            'createdAt': FieldValue.serverTimestamp(),
            'sent': false,
          });
        }
      }
    } catch (e) {
      debugPrint('Error sending push to NGO: $e');
    }
  }

  /// Send email notification
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      // Store email in Firestore for Cloud Functions to send
      // This is more reliable than sending from client
      await _firestore.collection('email_queue').add({
        'to': to,
        'subject': subject,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
      debugPrint('Email queued for: $to');
    } catch (e) {
      debugPrint('Error queueing email: $e');
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Format date and time for display
  String _formatDateTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(date)} at ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  // ==================== SCHEDULED NOTIFICATIONS ====================

  /// Check and send event reminders (call this periodically)
  Future<void> checkAndSendEventReminders() async {
    try {
      final now = DateTime.now();
      final in24Hours = now.add(const Duration(hours: 24));
      final in1Hour = now.add(const Duration(hours: 1));
      
      // Get events starting in next 24 hours
      final events24h = await _firestore
          .collection('events')
          .where('startDate', isGreaterThan: Timestamp.fromDate(now))
          .where('startDate', isLessThan: Timestamp.fromDate(in24Hours))
          .where('reminder24hSent', isEqualTo: false)
          .get();
      
      for (final doc in events24h.docs) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp).toDate();
        
        await sendEventReminder(
          eventId: doc.id,
          eventName: data['title'] ?? data['name'] ?? 'Event',
          ngoName: data['ngoName'] ?? 'NGO',
          eventDate: startDate,
          hoursUntilEvent: 24,
        );
        
        // Mark as sent
        await doc.reference.update({'reminder24hSent': true});
      }
      
      // Get events starting in next hour
      final events1h = await _firestore
          .collection('events')
          .where('startDate', isGreaterThan: Timestamp.fromDate(now))
          .where('startDate', isLessThan: Timestamp.fromDate(in1Hour))
          .where('reminder1hSent', isEqualTo: false)
          .get();
      
      for (final doc in events1h.docs) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp).toDate();
        
        await sendEventReminder(
          eventId: doc.id,
          eventName: data['title'] ?? data['name'] ?? 'Event',
          ngoName: data['ngoName'] ?? 'NGO',
          eventDate: startDate,
          hoursUntilEvent: 1,
        );
        
        // Mark as sent
        await doc.reference.update({'reminder1hSent': true});
      }
    } catch (e) {
      debugPrint('Error checking event reminders: $e');
    }
  }

  /// Send weekly digest to NGOs (call this weekly)
  Future<void> sendWeeklyDigestToNgos() async {
    try {
      // Get NGOs with weekly digest enabled
      final settingsSnapshot = await _firestore
          .collection('ngo_settings')
          .where('weeklyDigest', isEqualTo: true)
          .get();
      
      for (final doc in settingsSnapshot.docs) {
        final ngoId = doc.id;
        
        // Get NGO details
        final ngoDoc = await _firestore.collection('ngo_registrations').doc(ngoId).get();
        if (!ngoDoc.exists) continue;
        
        final ngoData = ngoDoc.data()!;
        final ngoEmail = ngoData['email'] as String?;
        final ngoName = ngoData['ngoName'] ?? 'NGO';
        
        // Calculate weekly stats
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        
        // Count donations
        final donations = await _firestore
            .collection('donations')
            .where('ngoId', isEqualTo: ngoId)
            .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
            .get();
        
        double totalDonations = 0;
        for (final d in donations.docs) {
          totalDonations += (d.data()['amount'] ?? 0).toDouble();
        }
        
        // Count new volunteers
        final newVolunteers = await _firestore
            .collection('volunteer_registrations')
            .where('ngoId', isEqualTo: ngoId)
            .where('status', isEqualTo: 'approved')
            .where('approvedAt', isGreaterThan: Timestamp.fromDate(weekAgo))
            .get();
        
        // Create notification
        await _createNotification(
          userId: ngoId,
          userType: 'ngo',
          title: 'Weekly Digest',
          message: 'This week: ${donations.docs.length} donations (₹${totalDonations.toStringAsFixed(0)}), ${newVolunteers.docs.length} new volunteers',
          type: NotificationType.weeklyDigest,
          data: {
            'totalDonations': totalDonations,
            'donationCount': donations.docs.length,
            'newVolunteers': newVolunteers.docs.length,
          },
        );
        
        // Send email
        if (ngoEmail != null && ngoEmail.isNotEmpty) {
          await _sendEmail(
            to: ngoEmail,
            subject: 'Weekly Digest - $ngoName',
            body: '''
Dear $ngoName Team,

Here's your weekly summary:

DONATIONS
=========
Total Donations: ${donations.docs.length}
Total Amount: ₹${totalDonations.toStringAsFixed(2)}

VOLUNTEERS
==========
New Volunteers: ${newVolunteers.docs.length}

Keep up the great work!

Best regards,
Connect NGO Team
            ''',
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending weekly digest: $e');
    }
  }
}
