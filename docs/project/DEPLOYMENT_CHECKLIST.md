# Deployment Checklist - Data Export Feature

## Pre-Deployment Steps

### 1. Install Dependencies ✅
```bash
# Flutter dependencies
cd d:\Flutter\flutter dev\projects\ngo_app
flutter pub get

# Firebase Functions dependencies  
cd functions
npm install
```

### 2. Configure Email Settings ⚠️ REQUIRED
You need to set up Gmail credentials for sending emails:

```bash
# Set Gmail account
firebase functions:config:set email.user="your-email@gmail.com"

# Set Gmail app password (NOT your regular password)
firebase functions:config:set email.password="your-app-password"
```

**How to get Gmail App Password:**
1. Go to Google Account settings
2. Enable 2-Factor Authentication
3. Go to Security > App passwords
4. Generate a new app password for "Mail"
5. Copy the 16-character password
6. Use it in the command above

### 3. Verify Firebase Configuration
```bash
# Check current config
firebase functions:config:get

# Should show:
# {
#   "email": {
#     "user": "your-email@gmail.com",
#     "password": "your-app-password"
#   }
# }
```

## Deployment Steps

### 1. Deploy Firebase Cloud Function
```bash
cd d:\Flutter\flutter dev\projects\ngo_app
firebase deploy --only functions:exportUserData
```

Expected output:
```
✔ functions[exportUserData(us-central1)] Successful create operation.
Function URL: https://us-central1-your-project.cloudfunctions.net/exportUserData
```

### 2. Build Flutter App
```bash
flutter clean
flutter pub get
flutter gen-l10n
flutter build apk --release
```

Or for testing:
```bash
flutter run
```

## Testing Checklist

### Functional Tests
- [ ] Login as a volunteer user
- [ ] Navigate to Settings
- [ ] Tap "Download My Data"
- [ ] Verify loading dialog appears
- [ ] Wait for success message (should appear within 10-30 seconds)
- [ ] Check email inbox (including spam folder)
- [ ] Open the PDF attachment
- [ ] Verify PDF contains all 7 sections
- [ ] Check data accuracy

### Error Tests
- [ ] Test without internet connection (should show error)
- [ ] Test with invalid user (should fail gracefully)
- [ ] Test rapid multiple clicks (should prevent duplicate requests)

### PDF Validation
- [ ] Personal information section complete
- [ ] Campaign data shows correctly
- [ ] Donation history with correct amounts
- [ ] Event participation listed
- [ ] CSR applications shown
- [ ] SOS alerts (if any) displayed
- [ ] Settings preferences correct
- [ ] PDF formatting is professional
- [ ] Headers and colors display correctly
- [ ] Footer with security notice present

### Email Validation
- [ ] Email received within 5 minutes
- [ ] Subject line correct: "Your Data Export - Connect NGO"
- [ ] Email HTML template displays correctly
- [ ] PDF attachment present
- [ ] PDF filename format: ConnectNGO_UserData_YYYY-MM-DD.pdf
- [ ] Can download and open PDF from email

## Security Checks

- [ ] Only authenticated users can trigger export
- [ ] User receives only their own data
- [ ] PDF not stored on server permanently
- [ ] Email sent only to registered email address
- [ ] No sensitive data in Cloud Function logs
- [ ] HTTPS used for all communications

## Performance Monitoring

### Check Firebase Console:
1. Go to Firebase Console > Functions
2. Monitor `exportUserData` function:
   - [ ] Invocation count
   - [ ] Error rate (should be 0%)
   - [ ] Execution time (should be < 30s)
   - [ ] Memory usage

### Check Logs:
```bash
firebase functions:log --only exportUserData
```

Look for:
- "Exporting data for user: [userId]"
- "Data export sent to [email]"
- No error messages

## Rollback Plan

If issues occur:

### 1. Disable the Function
```bash
# Delete the function
firebase functions:delete exportUserData
```

### 2. Revert Flutter Changes
```bash
git checkout lib/screens/volunteer/volunteer_settings_screen.dart
```

### 3. Quick Fix (if function fails)
The old placeholder message will still work:
- Shows: "Your data export request has been submitted..."
- No actual export happens
- No errors to user

## Common Issues & Solutions

### Issue: Email not received
**Solutions:**
- Check spam/junk folder
- Verify email configuration: `firebase functions:config:get`
- Check Cloud Function logs for errors
- Verify Gmail app password is correct

### Issue: PDF generation fails
**Solutions:**
- Check if all dependencies installed: `cd functions && npm list pdfkit`
- Verify pdfkit version: should be ^0.15.0
- Check Cloud Function memory allocation (increase if needed)

### Issue: Authentication errors
**Solutions:**
- Verify user is logged in
- Check Firebase Auth configuration
- Ensure Cloud Functions has proper permissions

### Issue: Function timeout
**Solutions:**
- Increase timeout in Firebase Console (default 60s)
- Optimize data queries (already using Promise.all)
- Check if user has excessive data

## Post-Deployment Monitoring

### Week 1:
- [ ] Monitor function invocations daily
- [ ] Check error rates
- [ ] Review user feedback
- [ ] Verify email delivery success rate

### Week 2-4:
- [ ] Weekly monitoring of metrics
- [ ] Review Cloud Function costs
- [ ] Optimize if needed
- [ ] Gather user feedback

## Success Metrics

Track these metrics:
- **Function Success Rate**: Should be > 95%
- **Email Delivery Rate**: Should be > 98%
- **Average Execution Time**: Should be < 30 seconds
- **User Satisfaction**: Positive feedback
- **Error Rate**: < 5%

## Support Documentation

Share with support team:
- [ ] [DATA_EXPORT_GUIDE.md](DATA_EXPORT_GUIDE.md) - Complete user guide
- [ ] [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Technical details
- [ ] This deployment checklist

## Configuration Reference

### Firebase Functions Config:
```json
{
  "email": {
    "user": "connectngo.notifications@gmail.com",
    "password": "your-16-char-app-password"
  }
}
```

### Required Firestore Collections:
- `volunteers` - User profiles
- `campaign_participants` - Campaign data
- `donations` - Donation records
- `event_participants` - Event data
- `csr_volunteer_applications` - CSR applications
- `sos_alerts` - Emergency alerts
- `volunteer_settings` - User settings

### Firebase Functions Permissions:
Ensure Cloud Functions have access to:
- Firestore (read)
- Authentication (verify users)
- Cloud Functions (execute)

## Final Checklist

Before going live:
- [ ] All dependencies installed
- [ ] Email configured with app password
- [ ] Cloud Function deployed successfully
- [ ] Flutter app built and tested
- [ ] All functional tests passed
- [ ] All security checks passed
- [ ] Documentation complete
- [ ] Support team briefed
- [ ] Rollback plan ready
- [ ] Monitoring set up

## Go-Live Command

When ready to deploy:

```bash
# 1. Deploy Cloud Function
firebase deploy --only functions:exportUserData

# 2. Build and release Flutter app
flutter clean
flutter pub get  
flutter build apk --release

# 3. Verify deployment
firebase functions:log --only exportUserData

# 4. Test with real user account
```

---

**Status**: Ready for deployment ✅

**Estimated Deployment Time**: 10-15 minutes

**Risk Level**: Low (feature is isolated, has rollback plan)

**Dependencies**: 
- Firebase Functions
- Gmail account with app password
- Internet connectivity

---

**Deployment Date**: _________________

**Deployed By**: _________________

**Verification**: _________________
