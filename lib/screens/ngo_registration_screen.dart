/// NGO Registration Screen
/// 
/// This file re-exports the modular NGO registration screen for backward compatibility.
/// 
/// The registration flow has been refactored into a modular structure:
/// 
/// ```
/// lib/screens/ngo_registration/
/// ├── ngo_registration.dart       # Barrel export file
/// ├── ngo_registration_screen.dart # Main screen widget
/// ├── constants.dart              # Constants and configuration
/// ├── models.dart                 # Data models (DocumentType, DocumentsManager)
/// ├── widgets.dart                # Reusable form widgets
/// └── steps.dart                  # Step content widgets (Step1-5)
/// ```
/// 
/// For new code, prefer importing from the modular structure:
/// ```dart
/// import 'package:ngo_app/screens/ngo_registration/ngo_registration.dart';
/// ```

export 'ngo_registration/ngo_registration_screen.dart';

