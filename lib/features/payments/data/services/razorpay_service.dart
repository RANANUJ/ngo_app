import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_manager.dart';
import 'notification_service.dart';

class RazorpayService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;

  // Razorpay API keys
  static const String keyId = 'rzp_test_Rsb9ATnbTWb7WI'; // Test key
  static const String keySecret = 'WspWYiYrBvLOemXCtCh33h5V'; // Test key secret
  // For production: static const String keyId = 'rzp_live_YOUR_KEY_ID';

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

  void openCheckout({
    required double amount,
    required String donorName,
    required String donorEmail,
    required String donorPhone,
    required String campaignTitle,
    String? description,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;

    var options = {
      'key': keyId,
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

      final donationData = {
        // Payment details
        'paymentId': paymentId,
        'orderId': orderId,
        'signature': signature,
        'amount': amount,
        'status': 'success',
        'paymentMethod': 'razorpay',
        
        // Donor details
        'donorName': isAnonymous ? 'Anonymous' : donorName,
        'donorEmail': isAnonymous ? '' : donorEmail,
        'donorPhone': isAnonymous ? '' : donorPhone,
        'donorId': volunteerId,
        'profileImageUrl': isAnonymous ? null : profileImageUrl,
        'isAnonymous': isAnonymous,
        
        // Campaign details
        'campaignId': campaignId,
        'campaignTitle': campaignTitle,
        'campaignType': campaignType,
        'ngoId': finalNgoId,
        
        // Additional info
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      print('💳 Razorpay: Saving donation with profileImageUrl: ${donationData['profileImageUrl']}');
      
      // Save to main donations collection
      final donationRef = await FirebaseFirestore.instance
          .collection('donations')
          .add(donationData);

      // Also save to NGO-specific donations subcollection if NGO ID exists
      if (finalNgoId != null && finalNgoId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('ngos')
            .doc(finalNgoId)
            .collection('received_donations')
            .doc(donationRef.id)
            .set(donationData);
      }

      // Update campaign raised amount
      final campaignRef = FirebaseFirestore.instance
          .collection(_getCollectionName(campaignType))
          .doc(campaignId);
      
      debugPrint('Updating campaign: ${_getCollectionName(campaignType)}/$campaignId');
      debugPrint('Campaign Type: $campaignType');
      debugPrint('Donation Amount: $amount');
      
      final campaignDoc = await campaignRef.get();
      
      if (campaignDoc.exists) {
        final data = campaignDoc.data();
        
        // Determine the correct field name based on campaign type
        String amountField;
        switch (campaignType) {
          case 'donation_request':
            amountField = 'collectedAmount';
            break;
          case 'emergency':
            amountField = 'collectedAmount';
            break;
          case 'impact':
            amountField = 'donationsReceived';
            break;
          case 'campaign':
          default:
            amountField = 'raisedAmount';
            break;
        }
        
        debugPrint('Using field: $amountField');
        final currentRaised = (data?[amountField] ?? 0).toDouble();
        debugPrint('Current raised: $currentRaised');
        debugPrint('New total: ${currentRaised + amount}');
        
        final donorCount = (data?['donorCount'] ?? data?['donorsCount'] ?? 0) as int;
        
        await campaignRef.update({
          amountField: currentRaised + amount,
          'donorCount': donorCount + 1,
          'lastDonationAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('Campaign updated successfully');
      } else {
        debugPrint('WARNING: Campaign document does not exist!');
      }

      debugPrint('Donation saved successfully: ${donationRef.id}');
      
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
              'donationId': donationRef.id,
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
                'donationId': donationRef.id,
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
