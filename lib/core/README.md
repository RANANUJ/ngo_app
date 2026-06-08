# Core Directory

`lib/core` contains technical building blocks reused across the app.

- `config/`: app config and environment setup
- `constants/`: app-wide constants
- `network/`: clients and request helpers
- `services/`: cross-feature services (analytics, crashlytics, notifications infra)
- `theme/`: ThemeData, color and typography system
- `utils/`: generic helper utilities
- `widgets/`: low-level reusable UI components

Do not place feature business logic in `core`.
