# Services Structure

`lib/services` is now a compatibility layer.

Canonical implementations live in:

- `lib/core/services` for cross-cutting services
- `lib/features/auth/data/services`
- `lib/features/ngo/data/services`
- `lib/features/payments/data/services`
- `lib/features/storage/data/services`

Legacy files under `lib/services/**` re-export canonical files to avoid breaking older imports.

Use package imports with canonical paths for new code.

Example:

```dart
import 'package:ngo_app/core/services/notification_service.dart';
```

Prefer canonical paths in all new files.

