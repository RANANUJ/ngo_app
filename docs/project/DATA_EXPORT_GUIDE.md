# Data Export Feature - User Guide

## Overview
The "Download My Data" feature allows users to export all their personal data from the Connect NGO platform in a structured PDF format, which is then sent to their registered email address.

## Features

### What's Included in the PDF?
The exported PDF contains a comprehensive summary of all user data:

1. **Personal Information**
   - Name, Email, Phone
   - Date of Birth, Gender
   - Address, City, State, PIN Code
   - Occupation, Skills, Interests
   - Languages Known, Bio
   - Registration Date, Profile Visibility

2. **Campaign Participation**
   - List of all campaigns joined
   - Status and role in each campaign
   - Hours contributed
   - Join dates

3. **Donation History**
   - Complete donation records
   - Total amount donated
   - NGO and campaign details
   - Payment methods and transaction IDs
   - Donation dates and status

4. **Event Participation**
   - All events participated in
   - Registration and attendance status
   - Event dates

5. **CSR Opportunities**
   - Applications submitted
   - Company names and opportunity details
   - Application status
   - Skills offered

6. **SOS Alerts**
   - Emergency alerts created
   - Alert type, description, location
   - Status and timestamps

7. **Settings & Preferences**
   - Notification settings
   - Privacy settings
   - Communication preferences

## How to Use

### For Users:
1. Open the Connect NGO app
2. Navigate to **Settings** from your profile
3. Scroll to the **Account** section
4. Tap on **"Download My Data"**
5. A loading indicator will appear while your data is being prepared
6. You'll receive a confirmation message when the export is ready
7. Check your registered email for the PDF attachment

### Email Delivery:
- The PDF will be sent to your registered email address
- Subject: "Your Data Export - Connect NGO"
- File name format: `ConnectNGO_UserData_YYYY-MM-DD.pdf`
- The email includes a summary of what's included in the PDF

## Technical Implementation

### Frontend (Flutter)
- Uses Firebase Cloud Functions to trigger the data export
- Shows a loading dialog while processing
- Displays success/error messages via SnackBar

### Backend (Firebase Cloud Functions)
- **Function Name**: `exportUserData`
- **Trigger**: HTTPS Callable Function
- **Authentication**: Required (user must be logged in)

### Data Collection Process:
1. Fetches user profile from `volunteers` collection
2. Retrieves campaign participation from `campaign_participants`
3. Fetches donations from `donations` collection
4. Gets event data from `event_participants`
5. Retrieves CSR applications from `csr_volunteer_applications`
6. Fetches SOS alerts from `sos_alerts`
7. Gets user settings from `volunteer_settings`

### PDF Generation:
- Uses **PDFKit** library for PDF creation
- Structured format with sections and subsections
- Color-coded headers and dividers
- Professional layout with Connect NGO branding

### Email Sending:
- Uses **Nodemailer** with Gmail SMTP
- HTML email template
- PDF attached as file
- Secure and encrypted transmission

## Security & Privacy

### Data Protection:
- Only authenticated users can request their own data
- User ID is verified through Firebase Authentication
- No cross-user data access possible

### Email Security:
- Email sent only to the registered email address
- Contains warning about sensitive information
- Advises secure storage of the PDF

### Temporary Storage:
- PDF is created in a temporary directory
- Automatically deleted after email is sent
- No permanent storage of exported files on server

## Error Handling

### Common Errors:

1. **User Not Authenticated**
   - Error: "User must be authenticated"
   - Solution: User needs to log in again

2. **Profile Not Found**
   - Error: "Volunteer profile not found"
   - Solution: Ensure user has completed registration

3. **Email Sending Failed**
   - Error: "Failed to send email"
   - Solution: Check email configuration or try again later

4. **Network Issues**
   - Error: "Network request failed"
   - Solution: Check internet connection and retry

### User Feedback:
- Loading dialog during processing (prevents multiple requests)
- Success message with confirmation
- Detailed error messages for troubleshooting

## Configuration Required

### Firebase Functions Config:
```bash
firebase functions:config:set email.user="your-email@gmail.com"
firebase functions:config:set email.password="your-app-password"
```

### Gmail Setup:
1. Enable 2-Factor Authentication on Gmail
2. Generate an App Password
3. Use this app password in Firebase Functions config

### Deployment:
```bash
cd functions
npm install
firebase deploy --only functions:exportUserData
```

## Testing

### Test the Feature:
1. Create a test user account
2. Add some test data (campaigns, donations, etc.)
3. Request data export from Settings
4. Verify email receipt
5. Check PDF content for accuracy

### Verify PDF Content:
- ✓ All sections present
- ✓ Data accurately reflected
- ✓ Formatting correct
- ✓ No sensitive data leaks
- ✓ Professional appearance

## Maintenance

### Regular Checks:
- Monitor Cloud Function logs for errors
- Verify email delivery rates
- Check PDF generation success rate
- Review user feedback

### Updates:
- Add new data sections as features are added
- Update PDF template for improved formatting
- Enhance email template as needed

## Support

### User Support:
If users don't receive their email within 5 minutes:
1. Check spam/junk folder
2. Verify registered email address
3. Try the export again
4. Contact support@connectngo.com

### Technical Support:
For errors or issues:
- Check Firebase Functions logs
- Verify email configuration
- Check Firestore permissions
- Review Cloud Function quotas

## Future Enhancements

### Planned Features:
- [ ] Multiple format support (JSON, CSV)
- [ ] Scheduled automatic exports
- [ ] Data export history
- [ ] Selective data export (choose specific sections)
- [ ] Export compression for large datasets

## Compliance

### GDPR Compliance:
- Users have right to access their data ✓
- Data portability in machine-readable format ✓
- Secure data transmission ✓
- Data minimization (only user's own data) ✓

### Data Retention:
- PDFs not stored on server (created and deleted immediately)
- Email records may be retained per email service provider policy
- Users responsible for downloaded PDF storage
