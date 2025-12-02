# 🌍 NGO Connect - Volunteer & NGO Management Platform

<p align="center">
  <img src="assets/logo.png" alt="NGO Connect Logo" width="150"/>
</p>

<p align="center">
  <strong>Connecting Volunteers with NGOs to Create Social Impact</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.8.1-blue?logo=flutter" alt="Flutter Version"/>
  <img src="https://img.shields.io/badge/Dart-3.0+-blue?logo=dart" alt="Dart Version"/>
  <img src="https://img.shields.io/badge/Firebase-Enabled-orange?logo=firebase" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green" alt="Platform"/>
</p>

---

## 📱 About The App

**NGO Connect** is a comprehensive Flutter-based mobile application designed to bridge the gap between Non-Governmental Organizations (NGOs) and volunteers. The platform facilitates seamless collaboration, donation management, campaign coordination, and community building to maximize social impact.

The app serves two primary user types:
- **NGOs** - Organizations looking to manage volunteers, run campaigns, and receive donations
- **Volunteers** - Individuals wanting to contribute their time, skills, and resources to worthy causes

---

## ✨ Key Features

### 🏢 For NGOs

| Feature | Description |
|---------|-------------|
| **Dashboard** | Comprehensive overview of campaigns, donations, volunteers, and activities |
| **Campaign Management** | Create, edit, and manage fundraising campaigns with goals and timelines |
| **Volunteer Management** | View, approve, and coordinate with registered volunteers |
| **Donation Tracking** | Monitor incoming donations and generate reports |
| **SOS Alerts** | Send emergency alerts to volunteers for urgent needs |
| **Quick Tasks** | Create and assign quick tasks to volunteers |
| **Reports & Analytics** | Generate detailed reports with charts and insights |
| **Marketplace** | Share and request resources from other NGOs |
| **Notifications** | Real-time push notifications for all activities |
| **Public Profile** | Showcase your NGO's work and impact to the world |

### 🙋 For Volunteers

| Feature | Description |
|---------|-------------|
| **Discover NGOs** | Browse and follow verified NGOs |
| **Join Campaigns** | Participate in active campaigns and track progress |
| **Donate** | Make donations via blockchain-enabled secure transactions |
| **Volunteer Opportunities** | Find and apply for volunteering opportunities |
| **Community** | Join communities, participate in discussions, and attend events |
| **Emergency Response** | Respond to SOS alerts from NGOs |
| **Impact Tracking** | View your contribution history and impact stats |
| **Event Calendar** | Keep track of upcoming events and activities |
| **Government Schemes** | Access information about relevant government programs |
| **Ask Experts** | Connect with experts for guidance and support |

### 🌐 Shared Features

- **🔐 Secure Authentication** - Email/password and Google Sign-In
- **📍 Location Services** - Google Maps integration for events and NGO locations
- **📸 Media Support** - Image and video upload capabilities
- **🔔 Push Notifications** - Real-time updates even when app is closed
- **💬 Community Posts** - Share updates, success stories, and engage with others
- **📊 CSR Integration** - Corporate Social Responsibility partnerships
- **🔄 Needs Forecasting** - AI-powered prediction for resource needs

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform mobile development |
| **Dart** | Programming language |
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | Real-time NoSQL database |
| **Firebase Storage** | File and media storage |
| **Firebase Messaging** | Push notifications |
| **Google Maps Flutter** | Maps and location services |
| **FL Chart** | Data visualization |
| **Geolocator** | GPS and location tracking |

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── screens/
│   ├── admin/               # Admin panel screens
│   ├── ngo/                 # NGO-specific screens
│   │   ├── ngo_dashboard_screen.dart
│   │   ├── ngo_home_screen.dart
│   │   ├── ngo_volunteers_screen.dart
│   │   ├── ngo_reports_screen.dart
│   │   └── ...
│   ├── volunteer/           # Volunteer-specific screens
│   │   ├── volunteer_dashboard_screen.dart
│   │   ├── volunteer_opportunities_screen.dart
│   │   ├── volunteer_impacts_screen.dart
│   │   └── ...
│   ├── campaign_*.dart      # Campaign management
│   ├── community_*.dart     # Community features
│   ├── donation_*.dart      # Donation features
│   └── ...
├── services/
│   ├── auth_service.dart           # Authentication logic
│   ├── notification_service.dart   # Push notifications
│   ├── cache_service.dart          # Local caching
│   └── ...
├── utils/                   # Helper utilities
└── widgets/                 # Reusable UI components
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart 3.0 or higher
- Android Studio / VS Code
- Firebase account
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/RANANUJ/ngo_app.git
   cd ngo_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android and iOS apps to your Firebase project
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication, Firestore, Storage, and Cloud Messaging

4. **Configure Google Maps**
   - Get an API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Add the API key to:
     - `android/app/src/main/AndroidManifest.xml`
     - `ios/Runner/AppDelegate.swift`

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 📱 Screenshots

<p align="center">
  <i>Coming Soon</i>
</p>

---

## 🔐 Firebase Security Rules

The app uses comprehensive Firestore security rules to protect user data. See `firestore.rules` for the complete ruleset.

---

## 🔔 Push Notifications

The app supports:
- **Foreground notifications** - Displayed while app is open
- **Background notifications** - Received when app is minimized
- **Terminated state notifications** - Received when app is closed

Notification channels include:
- SOS Alerts (High Priority)
- Donations
- Campaign Updates
- General Notifications

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**RANANUJ**

- GitHub: [@RANANUJ](https://github.com/RANANUJ)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for the robust backend services
- All contributors and supporters of this project

---

<p align="center">
  Made with ❤️ for Social Good
</p>

