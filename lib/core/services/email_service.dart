import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailService {
  /// Send verification email through Firestore queue with HTML template
  static Future<bool> sendVerificationEmail({
    required String userEmail,
    required String userName,
    required String verificationLink,
  }) async {
    try {
      final htmlBody = _getVerificationEmailHtml(
        userName: userName,
        verificationLink: verificationLink,
      );
      
      await FirebaseFirestore.instance.collection('email_queue').add({
        'to': userEmail,
        'subject': 'Verify your account - Connect & Contribute',
        'html': htmlBody,
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
      
      return true;
    } catch (e) {
      print('Error queuing verification email: $e');
      return false;
    }
  }
  
  /// Send password reset email through Firestore queue with HTML template
  static Future<bool> sendPasswordResetEmail({
    required String userEmail,
    required String userName,
    required String resetLink,
  }) async {
    try {
      final htmlBody = _getPasswordResetEmailHtml(
        userName: userName,
        resetLink: resetLink,
      );
      
      await FirebaseFirestore.instance.collection('email_queue').add({
        'to': userEmail,
        'subject': 'Reset Your Password - Connect & Contribute',
        'html': htmlBody,
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
      
      return true;
    } catch (e) {
      print('Error queuing password reset email: $e');
      return false;
    }
  }
  
  static Future<bool> sendThankYouEmail({
    required String donorEmail,
    required String donorName,
    required double amount,
    required String campaignTitle,
    required String ngoName,
    required DateTime donationDate,
    required String ngoEmail,
  }) async {
    try {
      // Format the date
      final formattedDate = '${donationDate.month}/${donationDate.day}/${donationDate.year}';
      
      // Create email subject
      final subject = Uri.encodeComponent('Thank You for Your Generous Donation - $ngoName');
      
      // Create email body with HTML-like formatting (text version)
      final body = Uri.encodeComponent('''
Dear $donorName,

We are incredibly grateful for your generous donation of ₹${amount.toStringAsFixed(2)} to support our "$campaignTitle" campaign.

Your contribution, made on $formattedDate, has made a world of difference. Because of you, we can continue our mission of providing vital services and support to those in need.

DONATION RECEIPT
Amount: ₹${amount.toStringAsFixed(2)}
Date: $formattedDate
Project: $campaignTitle

Your generosity inspires us to work harder and reach more people. We couldn't do this important work without supporters like you.

Thank you for being a part of our community. Together, we can make a difference.

With heartfelt gratitude,
$ngoName Team

---
This is an automated thank you message. For any queries, please contact us at $ngoEmail

Connect & Contribute - Making a Difference Together
      ''');
      
      // Create mailto URL with both donor and NGO in CC
      final mailtoUrl = 'mailto:$donorEmail?cc=$ngoEmail&subject=$subject&body=$body';
      
      final uri = Uri.parse(mailtoUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      print('Error sending thank you email: $e');
      return false;
    }
  }
  
  static Future<Map<String, dynamic>?> getNgoDetails(String ngoId) async {
    try {
      final ngoDoc = await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .doc(ngoId)
          .get();
      
      if (ngoDoc.exists) {
        return ngoDoc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching NGO details: $e');
      return null;
    }
  }
  
  /// Generate HTML for verification email
  static String _getVerificationEmailHtml({
    required String userName,
    required String verificationLink,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify Your Account</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
    <table role="presentation" style="width: 100%; border-collapse: collapse;">
        <tr>
            <td align="center" style="padding: 40px 0;">
                <table role="presentation" style="width: 600px; max-width: 100%; border-collapse: collapse; background-color: #ffffff; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #0099B8 0%, #00B8A9 100%); border-radius: 12px 12px 0 0;">
                            <div style="background-color: rgba(255,255,255,0.95); width: 80px; height: 80px; border-radius: 50%; margin: 0 auto 16px; display: inline-block; padding: 10px;">
                                <div style="width: 60px; height: 60px; background-color: #0099B8; border-radius: 50%; display: flex; align-items: center; justify-content: center; line-height: 60px; text-align: center;">
                                    <span style="font-size: 32px;">✓</span>
                                </div>
                            </div>
                            <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Connect & Contribute</h1>
                        </td>
                    </tr>
                    
                    <!-- Title -->
                    <tr>
                        <td style="padding: 32px 40px 16px; text-align: center;">
                            <h2 style="color: #1a1a1a; margin: 0; font-size: 24px; font-weight: 600;">Verify your account - Connect & Contribute</h2>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 16px 40px; color: #4a4a4a; font-size: 16px; line-height: 1.6;">
                            <p style="margin: 0 0 16px;">Welcome to the community!</p>
                            <p style="margin: 0 0 24px;">To finish setting up your account, please click the secure link below.</p>
                        </td>
                    </tr>
                    
                    <!-- Button -->
                    <tr>
                        <td style="padding: 0 40px 24px; text-align: center;">
                            <a href="$verificationLink" style="display: inline-block; padding: 14px 40px; background-color: #0099B8; color: #ffffff; text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: 600; box-shadow: 0 2px 4px rgba(0,153,184,0.3);">Verify My Account</a>
                        </td>
                    </tr>
                    
                    <!-- Alternative Link -->
                    <tr>
                        <td style="padding: 0 40px 32px; text-align: center; color: #666666; font-size: 14px;">
                            <p style="margin: 0;">Or copy and paste link:</p>
                            <p style="margin: 8px 0 0; word-break: break-all;">
                                <a href="$verificationLink" style="color: #0099B8; text-decoration: none;">$verificationLink</a>
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer Note -->
                    <tr>
                        <td style="padding: 0 40px 40px; text-align: center; color: #999999; font-size: 13px; line-height: 1.5;">
                            <p style="margin: 0;">If you didn't request this, please ignore this email.</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
    ''';
  }
  
  /// Generate HTML for password reset email
  static String _getPasswordResetEmailHtml({
    required String userName,
    required String resetLink,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Your Password</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
    <table role="presentation" style="width: 100%; border-collapse: collapse;">
        <tr>
            <td align="center" style="padding: 40px 0;">
                <table role="presentation" style="width: 600px; max-width: 100%; border-collapse: collapse; background-color: #ffffff; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #0099B8 0%, #00B8A9 100%); border-radius: 12px 12px 0 0;">
                            <div style="background-color: rgba(255,255,255,0.95); width: 80px; height: 80px; border-radius: 50%; margin: 0 auto 16px; display: inline-block; padding: 10px;">
                                <div style="width: 60px; height: 60px; background-color: #0099B8; border-radius: 50%; display: flex; align-items: center; justify-content: center; line-height: 60px; text-align: center;">
                                    <span style="font-size: 32px;">🔒</span>
                                </div>
                            </div>
                            <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Connect & Contribute</h1>
                        </td>
                    </tr>
                    
                    <!-- Title -->
                    <tr>
                        <td style="padding: 32px 40px 16px; text-align: center;">
                            <h2 style="color: #1a1a1a; margin: 0; font-size: 24px; font-weight: 600;">Reset Your Password - Connect & Contribute</h2>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 16px 40px; color: #4a4a4a; font-size: 16px; line-height: 1.6;">
                            <p style="margin: 0 0 16px;">Hi [Name], we received a request to reset the password for your account. If you request, click the link below to set new one.</p>
                        </td>
                    </tr>
                    
                    <!-- Button -->
                    <tr>
                        <td style="padding: 0 40px 24px; text-align: center;">
                            <a href="$resetLink" style="display: inline-block; padding: 14px 40px; background-color: #495579; color: #ffffff; text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: 600; box-shadow: 0 2px 4px rgba(73,85,121,0.3);">Reset Password</a>
                        </td>
                    </tr>
                    
                    <!-- Alternative Link -->
                    <tr>
                        <td style="padding: 0 40px 32px; text-align: center; color: #666666; font-size: 14px;">
                            <p style="margin: 0;">Or copy and paste link:</p>
                            <p style="margin: 8px 0 0; word-break: break-all;">
                                <a href="$resetLink" style="color: #0099B8; text-decoration: none;">$resetLink</a>
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer Note -->
                    <tr>
                        <td style="padding: 0 40px 40px; text-align: center; color: #999999; font-size: 13px; line-height: 1.5;">
                            <p style="margin: 0;">If you didn't request this, ignore this email. This link valid 24 hours.</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
    ''';
  }
}
