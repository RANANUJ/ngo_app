# NGO Connect App – Functional Documentation

## 1. App Overview
NGO Connect is a Flutter-based platform connecting NGOs, volunteers, and administrators. It streamlines campaign management, volunteer coordination, donations, analytics, and community engagement, maximizing social impact.

**User Types:**
- **NGO**: Manage campaigns, volunteers, donations, and public profile.
- **Volunteer**: Discover NGOs, join campaigns, donate, track impact, and participate in events.
- **Admin**: Oversee NGO registrations, approve/reject applications, and maintain platform integrity.

---

## 2. Features by User Type

### A. NGO Side
- **Dashboard**: Overview of campaigns, donations, volunteers, and activities.
- **Campaign Management**: Create, edit, and manage fundraising campaigns with goals and timelines.
- **Volunteer Management**: View, approve, and coordinate with registered volunteers.
- **Donation Tracking**: Monitor incoming donations and generate reports.
- **SOS Alerts**: Send emergency alerts to volunteers for urgent needs.
- **Quick Tasks**: Assign short-term tasks to volunteers.
- **Reports & Analytics**: Generate detailed reports with charts and insights.
- **Marketplace**: Share/request resources with other NGOs.
- **Notifications**: Real-time push notifications for all activities.
- **Public Profile**: Showcase NGO’s work and impact.

### B. Volunteer Side
- **Discover NGOs**: Browse and follow verified NGOs.
- **Join Campaigns**: Participate in active campaigns and track progress.
- **Donate**: Make secure donations (Razorpay integration).
- **Volunteer Opportunities**: Find and apply for volunteering roles.
- **Community**: Join discussions, share stories, and attend events.
- **Emergency Response**: Respond to SOS alerts from NGOs.
- **Impact Tracking**: View contribution history and stats.
- **Event Calendar**: Track upcoming events and activities.
- **Government Schemes**: Access info about relevant programs.
- **Ask Experts**: Connect with experts for guidance.

### C. Admin Side
- **Dashboard**: View and filter NGO registrations (All, Pending, Approved, Rejected).
- **NGO Verification**: Review details, documents, and approve/reject NGOs.
- **Statistics**: View stats on total, pending, approved, and rejected NGOs.
- **Document Verification**: View and verify uploaded documents.

---

## 3. Shared Features
- **Authentication**: Email/password and Google Sign-In (Firebase Auth).
- **Location Services**: Google Maps for events and NGO locations.
- **Media Support**: Image/video upload (Firebase Storage).
- **Push Notifications**: Real-time updates (Firebase Cloud Messaging).
- **Community Posts**: Share updates and engage with others.
- **CSR Integration**: Corporate Social Responsibility partnerships.
- **Needs Forecasting**: AI-powered resource prediction.

---

## 4. How Major Functions Work

### Authentication
- **Tech**: Firebase Auth
- **How**: Users register/login via email/password or Google. Auth state is managed globally.

### Campaign Management
- **Tech**: Firestore, Flutter UI
- **How**: NGOs create/edit campaigns. Data is stored in Firestore. Volunteers can join campaigns, tracked by participant records.

### Volunteer Management
- **Tech**: Firestore, Cloud Functions
- **How**: NGOs view volunteer applications, approve/reject, and manage lists. Cloud Functions send notifications on status changes.

### Donation Tracking
- **Tech**: Razorpay, Firestore
- **How**: Volunteers donate via Razorpay. Transactions are logged in Firestore. NGOs see donation history and analytics.

### SOS Alerts
- **Tech**: Firestore, Push Notifications
- **How**: NGOs send emergency alerts. Volunteers receive push notifications and can respond.

### Reports & Analytics
- **Tech**: Firestore, Flutter charts
- **How**: Data is aggregated and visualized for NGOs and volunteers.

### Marketplace
- **Tech**: Firestore
- **How**: NGOs post resource needs or offers. Other NGOs can respond.

### Notifications
- **Tech**: Firebase Cloud Messaging
- **How**: Real-time push notifications for all user types.

### Public Profile
- **Tech**: Firestore, Flutter UI
- **How**: NGOs manage a public profile page with achievements, mission, and impact.

---

## 5. Project Structure (lib/)
- **main.dart**: App entry point
- **firebase_options.dart**: Firebase config
- **screens/**: UI screens for admin, ngo, volunteer
- **services/**: Business logic (auth, notifications, cache)
- **utils/**: Helper utilities
- **widgets/**: Reusable UI components

---

## 6. Technologies Used
- **Flutter**: Cross-platform UI
- **Firebase**: Auth, Firestore, Storage, Cloud Functions, Messaging
- **Razorpay**: Payment gateway
- **Google Maps**: Location services
- **Other**: fl_chart, image_picker, audioplayers, vibration, etc.

---

## 7. How to Add/Extend Functionality
- **NGO**: Add new campaign types, analytics, or resource sharing features by extending Firestore models and UI screens.
- **Volunteer**: Add new engagement modules (e.g., skill-based volunteering) by creating new screens and Firestore collections.
- **Admin**: Add new verification steps or analytics by updating admin screens and Cloud Functions.
- **General**: Add new features by creating new screens in `lib/screens/`, updating Firestore structure, and integrating with services in `lib/services/`.

---

## 8. How Each Technology Works
- **Flutter**: Builds the UI for Android, iOS, web, and desktop from a single codebase.
- **Firebase Auth**: Handles user authentication and session management.
- **Firestore**: Stores all app data in real-time, scalable NoSQL database.
- **Firebase Storage**: Stores user-uploaded images and documents.
- **Cloud Functions**: Backend logic for notifications, data validation, and automation.
- **Firebase Messaging**: Sends push notifications to users.
- **Razorpay**: Processes secure payments and donations.
- **Google Maps**: Displays locations and events on maps.

---

## 9. Security & Best Practices
- All sensitive data is secured via Firebase rules.
- User authentication is required for all actions.
- Data validation is enforced both client-side and server-side.

---

## 10. Contribution & Extension
- Follow modular structure for new features.
- Use services for business logic.
- Write reusable widgets for UI consistency.
- Update documentation for any new modules.

---

For more details, refer to the in-code documentation and README.md.
