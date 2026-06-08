# NGO App Folder Structure (Professional and Manageable)

This project now follows a **target feature-first architecture** that companies commonly use for medium/large Flutter apps.

## Target Structure

```text
lib/
  app/
    app.dart                     # MaterialApp, routes, app-level providers
    bootstrap.dart               # startup/initialization wiring

  core/                          # shared technical foundation
    config/                      # env, app config, feature flags
    constants/                   # app-wide constants
    network/                     # API clients, interceptors, network helpers
    services/                    # cross-feature services (analytics, crashlytics)
    theme/                       # colors, typography, theming
    utils/                       # utility functions
    widgets/                     # reusable low-level UI widgets

  shared/                        # shared business/UI pieces used by many features
    models/                      # common entities/value objects
    widgets/                     # shared UI widgets

  features/                      # all business modules
    auth/
      data/
      domain/
      presentation/screens/
      presentation/widgets/
    ngo/
      data/
      domain/
      presentation/screens/
      presentation/widgets/
    volunteer/
      data/
      domain/
      presentation/screens/
      presentation/widgets/
    admin/
      data/
      domain/
      presentation/screens/
      presentation/widgets/
    donations/
    campaigns/
    community/
    emergency/
    opportunities/
    notifications/
    home/
    profile/

  l10n/
  main.dart
```

## Why This Is Professional

- Features are isolated, so teams can work in parallel.
- Shared code is explicit (`core` vs `shared`) and easier to govern.
- New modules can be added without creating a huge `screens/` folder.
- Architecture scales to state management, testing, CI/CD, and code ownership.

## Migration Rule (Important)

Use **small, safe batches**:

1. Move one feature at a time.
2. Update imports immediately.
3. Run `flutter analyze` and `flutter test` after each batch.
4. Remove old files only when all references are gone.

Do not perform a massive one-shot move in a large project.

## Suggested Mapping from Current Project

- `lib/screens/ngo/*` -> `lib/features/ngo/presentation/screens/*`
- `lib/screens/volunteer/*` -> `lib/features/volunteer/presentation/screens/*`
- `lib/screens/admin/*` -> `lib/features/admin/presentation/screens/*`
- `lib/screens/login_screen.dart`, `lib/screens/email_verification_screen.dart` -> `lib/features/auth/presentation/screens/*`
- `lib/services/auth_service.dart` -> `lib/features/auth/data/services/*`
- `lib/services/notification_service.dart` -> `lib/features/notifications/data/services/*`
- `lib/services/analytics_service.dart`, `lib/services/crashlytics_service.dart` -> `lib/core/services/*`
- `lib/widgets/*` -> either `lib/shared/widgets/*` or feature widgets based on usage

## Team Conventions

- Keep imports package-based when possible: `package:ngo_app/...`
- Keep each file focused on one responsibility.
- Place feature-specific widgets inside their feature.
- Avoid adding new screens to old `lib/screens/`.
