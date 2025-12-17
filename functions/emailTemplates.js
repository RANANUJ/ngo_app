/**
 * Firebase Cloud Functions for Custom Email Templates
 * 
 * This file contains the Cloud Functions needed to send custom HTML emails
 * for verification and password reset.
 * 
 * To deploy:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login: firebase login
 * 3. Init functions: firebase init functions
 * 4. Copy this code to functions/index.js
 * 5. Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure your email service (e.g., Gmail, SendGrid, etc.)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com',  // Replace with your email
    pass: 'your-app-password'       // Use App Password for Gmail
  }
});

/**
 * Send custom verification email when user signs up
 */
exports.sendVerificationEmail = functions.auth.user().onCreate(async (user) => {
  const email = user.email;
  const displayName = user.displayName || 'User';
  
  // Generate verification link (you may need to use Firebase Admin SDK)
  const link = await admin.auth().generateEmailVerificationLink(email);
  
  const htmlBody = getVerificationEmailHtml(displayName, link);
  
  const mailOptions = {
    from: '"Connect & Contribute" <your-email@gmail.com>',
    to: email,
    subject: 'Verify your account - Connect & Contribute',
    html: htmlBody
  };
  
  try {
    await transporter.sendMail(mailOptions);
    console.log('Verification email sent to:', email);
  } catch (error) {
    console.error('Error sending verification email:', error);
  }
});

/**
 * Process email queue from Firestore
 * This watches the email_queue collection and sends emails
 */
exports.processEmailQueue = functions.firestore
  .document('email_queue/{emailId}')
  .onCreate(async (snap, context) => {
    const emailData = snap.data();
    
    if (emailData.sent) {
      return null; // Already sent
    }
    
    const mailOptions = {
      from: '"Connect & Contribute" <your-email@gmail.com>',
      to: emailData.to,
      subject: emailData.subject,
      html: emailData.html || emailData.body,
      text: emailData.body
    };
    
    try {
      await transporter.sendMail(mailOptions);
      console.log('Email sent to:', emailData.to);
      
      // Mark as sent
      await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
    } catch (error) {
      console.error('Error sending email:', error);
      await snap.ref.update({ error: error.message });
    }
  });

/**
 * Process push notifications from Firestore
 */
exports.processPushNotifications = functions.firestore
  .document('push_notifications/{notifId}')
  .onCreate(async (snap, context) => {
    const notifData = snap.data();
    
    if (notifData.sent) {
      return null;
    }
    
    const message = {
      notification: {
        title: notifData.title,
        body: notifData.body
      },
      token: notifData.token,
      data: notifData.data || {}
    };
    
    try {
      await admin.messaging().send(message);
      console.log('Push notification sent');
      await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
    } catch (error) {
      console.error('Error sending push notification:', error);
      await snap.ref.update({ error: error.message });
    }
  });

// HTML Email Templates
function getVerificationEmailHtml(userName, verificationLink) {
  return `
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
                    <tr>
                        <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #0099B8 0%, #00B8A9 100%); border-radius: 12px 12px 0 0;">
                            <div style="background-color: rgba(255,255,255,0.95); width: 80px; height: 80px; border-radius: 50%; margin: 0 auto 16px; display: inline-block; padding: 10px;">
                                <div style="width: 60px; height: 60px; background-color: #0099B8; border-radius: 50%; text-align: center; line-height: 60px;">
                                    <span style="font-size: 32px; color: white;">✓</span>
                                </div>
                            </div>
                            <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Connect & Contribute</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 32px 40px 16px; text-align: center;">
                            <h2 style="color: #1a1a1a; margin: 0; font-size: 24px; font-weight: 600;">Verify your account - Connect & Contribute</h2>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 16px 40px; color: #4a4a4a; font-size: 16px; line-height: 1.6;">
                            <p style="margin: 0 0 16px;">Welcome to the community!</p>
                            <p style="margin: 0 0 24px;">To finish setting up your account, please click the secure link below.</p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 0 40px 24px; text-align: center;">
                            <a href="${verificationLink}" style="display: inline-block; padding: 14px 40px; background-color: #0099B8; color: #ffffff; text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: 600; box-shadow: 0 2px 4px rgba(0,153,184,0.3);">Verify My Account</a>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 0 40px 32px; text-align: center; color: #666666; font-size: 14px;">
                            <p style="margin: 0;">Or copy and paste link:</p>
                            <p style="margin: 8px 0 0; word-break: break-all;">
                                <a href="${verificationLink}" style="color: #0099B8; text-decoration: none;">${verificationLink}</a>
                            </p>
                        </td>
                    </tr>
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
  `;
}

function getPasswordResetEmailHtml(userName, resetLink) {
  return `
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
                    <tr>
                        <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #0099B8 0%, #00B8A9 100%); border-radius: 12px 12px 0 0;">
                            <div style="background-color: rgba(255,255,255,0.95); width: 80px; height: 80px; border-radius: 50%; margin: 0 auto 16px; display: inline-block; padding: 10px;">
                                <div style="width: 60px; height: 60px; background-color: #0099B8; border-radius: 50%; text-align: center; line-height: 60px;">
                                    <span style="font-size: 32px; color: white;">🔒</span>
                                </div>
                            </div>
                            <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Connect & Contribute</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 32px 40px 16px; text-align: center;">
                            <h2 style="color: #1a1a1a; margin: 0; font-size: 24px; font-weight: 600;">Reset Your Password - Connect & Contribute</h2>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 16px 40px; color: #4a4a4a; font-size: 16px; line-height: 1.6;">
                            <p style="margin: 0 0 16px;">Hi ${userName}, we received a request to reset the password for your account. If you request, click the link below to set new one.</p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 0 40px 24px; text-align: center;">
                            <a href="${resetLink}" style="display: inline-block; padding: 14px 40px; background-color: #495579; color: #ffffff; text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: 600; box-shadow: 0 2px 4px rgba(73,85,121,0.3);">Reset Password</a>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 0 40px 32px; text-align: center; color: #666666; font-size: 14px;">
                            <p style="margin: 0;">Or copy and paste link:</p>
                            <p style="margin: 8px 0 0; word-break: break-all;">
                                <a href="${resetLink}" style="color: #0099B8; text-decoration: none;">${resetLink}</a>
                            </p>
                        </td>
                    </tr>
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
  `;
}
