# NGO Connect App – Technologies and Integration

## 1. Flutter
- **Purpose:** Cross-platform UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
- **Integration:** All UI screens, widgets, and navigation are built using Flutter. State management and UI logic are handled in Dart files under `lib/`.

## 2. Firebase
### a. Firebase Authentication
- **Purpose:** Secure user authentication (email/password, Google Sign-In).
- **Integration:** Used for login, registration, and session management for all user types. Auth state is checked globally to control access.

### b. Cloud Firestore
- **Purpose:** Real-time NoSQL database for storing app data.
- **Integration:** Stores user profiles, campaigns, donations, events, notifications, and more. All CRUD operations for app data are performed via Firestore.

### c. Firebase Storage
- **Purpose:** Store and serve user-uploaded files (images, documents).
- **Integration:** Used for uploading NGO documents, profile images, campaign media, etc. Accessed via the `firebase_storage` package.

### d. Firebase Cloud Messaging (FCM)
- **Purpose:** Send push notifications to users.
- **Integration:** Used for real-time alerts (e.g., SOS, campaign updates, approvals). Integrated via the `firebase_messaging` package and custom notification service.

### e. Firebase Cloud Functions
- **Purpose:** Serverless backend logic (automation, notifications, validation).
- **Integration:** Handles automated notifications, data validation, and backend workflows (e.g., notify NGO on volunteer application).

## 3. Razorpay
- **Purpose:** Secure payment gateway for processing donations.
- **Integration:** Used in donation flows for volunteers. Payment status and transaction details are stored in Firestore.

## 4. Google Maps
- **Purpose:** Location services and map display.
- **Integration:** Used to show event and NGO locations, and for geolocation features in campaigns and events.

## 5. Other Packages
- **fl_chart:** For analytics and data visualization (charts, graphs).
- **image_picker:** For selecting and uploading images from device.
- **audioplayers:** For playing alert sounds (e.g., SOS feature).
- **vibration:** For haptic feedback on alerts.

## 6. Project Structure and Integration
- **lib/screens/**: Contains all UI screens, organized by user type and feature.
- **lib/services/**: Contains business logic and integrations (auth, notifications, cache, etc.).
- **lib/utils/**: Helper functions and utilities.
- **lib/widgets/**: Reusable UI components.

## 7. How Technologies Work Together
- **User Flow:**
  - User authenticates via Firebase Auth.
  - Data is read/written to Firestore and Storage as needed.
  - UI updates in real-time using Firestore streams.
  - Notifications are sent via FCM and Cloud Functions.
  - Payments are processed via Razorpay and logged in Firestore.
  - Maps and location data are displayed using Google Maps.

## 8. Security
- All data access is protected by Firebase Security Rules.
- Sensitive operations (e.g., document verification, donations) require authentication.
- Cloud Functions enforce server-side validation and automation.

---

This document provides a concise overview of the technologies used in NGO Connect and how they are integrated to deliver a seamless, secure, and scalable experience for NGOs, volunteers, and admins.