import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:ngo_app/core/services/notification_manager.dart';
import 'package:ngo_app/core/services/notification_service.dart';
import 'package:ngo_app/features/donations/domain/models/donation.dart';
import 'package:ngo_app/features/donations/data/repositories/firebase_donation_repository.dart';

class RazorpayService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;

  // Razorpay API key (default test key, production keys fetched from Firestore)
  static const String keyId = 'rzp_test_Rsb9ATnbTWb7WI';

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    _onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  Future<void> openCheckout({
    required double amount,
    required String donorName,
    required String donorEmail,
    required String donorPhone,
    required String campaignTitle,
    String? description,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
  }) async {
    _onSuccess = onSuccess;
    _onFailure = onFailure;

    // Load active key dynamically from Firestore config
    String activeKeyId = keyId;
    try {
      final configDoc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('razorpay')
          .get();
      if (configDoc.exists) {
        activeKeyId = configDoc.data()?['keyId'] ?? keyId;
      }
    } catch (_) {}

    var options = {
      'key': activeKeyId,
      'amount': (amount * 100).toInt(), // Convert to paise
      'name': 'NGO App',
      'description': description ?? 'Donation for $campaignTitle',
      'prefill': {
        'contact': donorPhone,
        'email': donorEmail,
        'name': donorName,
      },
      'theme': {
        'color': '#0099B8',
      },
      'notes': {
        'campaign': campaignTitle,
        'donor_name': donorName,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  Future<void> saveDonationToFirestore({
    required String paymentId,
    required String orderId,
    required String signature,
    required double amount,
    required String donorName,
    required String donorEmail,
    required String donorPhone,
    required String campaignId,
    required String campaignTitle,
    required String campaignType, // 'campaign', 'emergency', 'impact', 'donation_request'
    String? message,
    bool isAnonymous = false,
    String? ngoId, // Add NGO ID
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Get volunteer profile data
      DocumentSnapshot? volunteerDoc;
      String? profileImageUrl;
      String? volunteerId;
      
      if (user != null) {
        volunteerId = user.uid;
        print('💳 Razorpay: Fetching volunteer data for user: $volunteerId');
        volunteerDoc = await FirebaseFirestore.instance
            .collection('volunteers')
            .doc(user.uid)
            .get();
        
        if (volunteerDoc.exists) {
          final volunteerData = volunteerDoc.data() as Map<String, dynamic>?;
          // Check multiple possible field names for profile image
          profileImageUrl = volunteerData?['photoUrl'] ?? 
                           volunteerData?['profileImageUrl'] ?? 
                           volunteerData?['photoURL'] ??
                           user.photoURL;
          print('💳 Razorpay: Profile image URL found: $profileImageUrl');
          print('💳 Razorpay: Volunteer data keys: ${volunteerData?.keys.toList()}');
        } else {
          print('💳 Razorpay: Volunteer document does not exist');
        }
      } else {
        print('💳 Razorpay: No authenticated user found');
      }

      // Get NGO ID from campaign if not provided
      String? finalNgoId = ngoId;
      if (finalNgoId == null) {
        final campaignDoc = await FirebaseFirestore.instance
            .collection(_getCollectionName(campaignType))
            .doc(campaignId)
            .get();
        
        if (campaignDoc.exists) {
          finalNgoId = campaignDoc.data()?['createdBy'] ?? campaignDoc.data()?['ngoId'];
        }
      }

      print('💳 Razorpay: Triggering payment verification Cloud Function');
      final callable = FirebaseFunctions.instance.httpsCallable('verifyAndSaveDonation');
      final result = await callable.call(<String, dynamic>{
        'paymentId': paymentId,
        'orderId': orderId,
        'signature': signature,
        'amount': amount,
        'donorName': donorName,
        'donorEmail': donorEmail,
        'donorPhone': donorPhone,
        'campaignId': campaignId,
        'campaignTitle': campaignTitle,
        'campaignType': campaignType,
        'isAnonymous': isAnonymous,
        'ngoId': finalNgoId,
        'message': message,
      });

      final donationId = result.data['donationId'] as String;
      debugPrint('Donation verified and saved successfully: $donationId');
      
      // Send notifications after successful save
      try {
        final notificationManager = NotificationManager();
        final notificationService = NotificationService();
        
        // Send local notification to donor (volunteer)
        if (volunteerId != null && !isAnonymous) {
          await notificationService.showDonationNotification(
            title: '🎉 Donation Successful!',
            body: 'Your donation of ₹${amount.toStringAsFixed(0)} to "$campaignTitle" was successful. Thank you for making a difference!',
            data: {
              'type': 'donation_success',
              'amount': amount,
              'campaignTitle': campaignTitle,
              'campaignId': campaignId,
              'donationId': donationId,
            },
          );
          
          // Send in-app notification to donor
          await notificationManager.notifyDonationSuccess(
            volunteerId: volunteerId,
            volunteerEmail: donorEmail,
            volunteerName: donorName,
            amount: amount,
            ngoName: 'NGO', // Will be updated from campaign data
            ngoId: finalNgoId ?? '',
            transactionId: paymentId,
            campaignName: campaignTitle,
          );
        }
        
        // Send notification to NGO
        if (finalNgoId != null && finalNgoId.isNotEmpty) {
          // Get NGO details
          final ngoDoc = await FirebaseFirestore.instance
              .collection('ngo_registrations')
              .doc(finalNgoId)
              .get();
          
          if (ngoDoc.exists) {
            final ngoData = ngoDoc.data();
            final ngoName = ngoData?['organizationName'] ?? 'NGO';
            final ngoEmail = ngoData?['email'] ?? '';
            
            final displayDonorName = isAnonymous ? 'Anonymous Donor' : donorName;
            
            // Show immediate local notification to NGO (if app is open)
            await notificationService.showDonationNotification(
              title: '💰 New Donation Received!',
              body: '$displayDonorName donated ₹${amount.toStringAsFixed(0)} to "$campaignTitle"',
              largeIconUrl: isAnonymous ? null : profileImageUrl,  // Show donor's profile image
              data: {
                'type': 'donation_received',
                'donorName': displayDonorName,
                'donorId': volunteerId ?? 'anonymous',
                'amount': amount,
                'campaignTitle': campaignTitle,
                'campaignId': campaignId,
                'donationId': donationId,
                'ngoId': finalNgoId,
                'profileImageUrl': profileImageUrl,
              },
            );
            
            // Send in-app notification and email to NGO
            await notificationManager.notifyDonationReceived(
              ngoId: finalNgoId,
              ngoEmail: ngoEmail,
              ngoName: ngoName,
              donorName: displayDonorName,
              donorId: volunteerId ?? 'anonymous',
              amount: amount,
              transactionId: paymentId,
              campaignName: campaignTitle,
            );
            
            debugPrint('✅ NGO notification sent: $ngoName');
          }
        }
        
        debugPrint('✅ Notifications sent successfully');
      } catch (notifError) {
        debugPrint('⚠️ Error sending notifications: $notifError');
        // Don't throw - notification failure shouldn't fail the donation
      }
    } catch (e) {
      debugPrint('Error saving donation: $e');
      rethrow;
    }
  }

  String _getCollectionName(String campaignType) {
    switch (campaignType) {
      case 'emergency':
        return 'emergency_donations';
      case 'impact':
        return 'impacts';
      case 'donation_request':
        return 'donation_posts';
      case 'campaign':
      default:
        return 'campaigns';
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
