# Custom Email Templates Setup Guide

## Overview
This guide explains how to set up beautiful HTML email templates for verification and password reset emails in your Connect & Contribute app.

## What You Get
- ✅ Styled verification emails with app branding
- ✅ Styled password reset emails with app branding
- ✅ Professional design matching your app UI
- ✅ Mobile-responsive email templates
- ✅ Automatic email sending via Firebase Cloud Functions

## Quick Start

### Option 1: Using Firebase Cloud Functions (Recommended)

#### Step 1: Install Firebase Tools
```bash
npm install -g firebase-tools
```

#### Step 2: Login to Firebase
```bash
firebase login
```

#### Step 3: Initialize Functions
```bash
cd ngo_app
firebase init functions
```
- Select JavaScript or TypeScript
- Install dependencies when prompted

#### Step 4: Install Required Packages
```bash
cd functions
npm install nodemailer
```

#### Step 5: Configure Email Service
Edit `functions/index.js` and replace the email configuration:

```javascript
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com',
    pass: 'your-app-password'  // Use App Password for Gmail
  }
});
```

**For Gmail:**
1. Go to Google Account settings
2. Enable 2-Factor Authentication
3. Generate an App Password
4. Use that password in the code above

**For SendGrid, Mailgun, or other services:**
```javascript
const transporter = nodemailer.createTransporter({
  host: 'smtp.sendgrid.net',
  port: 587,
  auth: {
    user: 'apikey',
    pass: 'your-sendgrid-api-key'
  }
});
```

#### Step 6: Copy Email Template Functions
Copy the code from `functions/emailTemplates.js` to `functions/index.js`

#### Step 7: Deploy to Firebase
```bash
firebase deploy --only functions
```

### Option 2: Using Firestore Email Queue (Already Implemented!)

The app already queues emails in Firestore. The Cloud Function watches for new emails and sends them automatically.

**Current Implementation:**
- When user signs up → Email added to `email_queue` collection
- When password reset → Email added to `email_queue` collection
- Cloud Function processes queue → Sends styled HTML emails

## Email Templates

### 1. Verification Email
- **Title**: "Verify your account - Connect & Contribute"
- **Design**: Turquoise gradient header with checkmark icon
- **Button**: "Verify My Account" (turquoise)
- **Includes**: Copy-paste link as alternative

### 2. Password Reset Email
- **Title**: "Reset Your Password - Connect & Contribute"
- **Design**: Turquoise gradient header with lock icon
- **Button**: "Reset Password" (dark blue/purple)
- **Includes**: Copy-paste link, 24-hour validity note

## Testing

### Test Verification Email
1. Register a new user in the app
2. Check Firestore `email_queue` collection
3. Verify email document has `html` field with styled content
4. Check your email inbox

### Test Password Reset Email
1. Go to login screen
2. Click "Forgot Password"
3. Enter email and submit
4. Check Firestore `email_queue` collection
5. Check your email inbox

## Customization

### Change App Logo
Update the logo URL in the email templates:
```dart
// In email_service.dart
static const String appLogoUrl = 'https://your-domain.com/logo.png';
```

### Change Colors
Edit the HTML templates in `email_service.dart`:
- Primary color: `#0099B8` (turquoise)
- Button colors: `#0099B8` (verify), `#495579` (reset)
- Gradient: `linear-gradient(135deg, #0099B8 0%, #00B8A9 100%)`

### Add More Content
Modify the HTML in `_getVerificationEmailHtml()` and `_getPasswordResetEmailHtml()` methods.

## Troubleshooting

### Emails Not Sending
1. **Check Cloud Functions logs:**
   ```bash
   firebase functions:log
   ```

2. **Verify email queue:**
   - Go to Firestore console
   - Check `email_queue` collection
   - Look for `sent: false` documents

3. **Check SMTP credentials:**
   - Ensure App Password is correct
   - Check if 2FA is enabled for Gmail
   - Try different email service if needed

### Emails in Spam
1. Set up SPF and DKIM records for your domain
2. Use a verified sender email
3. Consider using SendGrid or similar service
4. Ask recipients to whitelist your email

## Production Checklist

- [ ] Cloud Functions deployed
- [ ] Email service configured (Gmail/SendGrid)
- [ ] App Password/API Key set up
- [ ] Test verification email working
- [ ] Test password reset email working
- [ ] Emails not going to spam
- [ ] Email templates look good on mobile
- [ ] Email templates look good on desktop
- [ ] All links working correctly

## Support

For issues or questions:
1. Check Firebase Functions logs
2. Check Firestore `email_queue` collection
3. Verify SMTP configuration
4. Test with different email providers

## Current Status

✅ Email templates created in Flutter app
✅ HTML templates designed matching your UI
✅ Firestore email queue implemented
✅ Email service methods ready
⏳ Cloud Functions need to be deployed
⏳ SMTP service needs configuration

**Next Step**: Deploy Cloud Functions with your email service credentials!
