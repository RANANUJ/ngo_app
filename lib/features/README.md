# Features Directory

Each feature should contain:

- `data/`: repositories, DTOs, data sources, API/Firebase adapters
- `domain/`: entities, use-cases, abstractions
- `presentation/screens/`: screens/pages
- `presentation/widgets/`: feature-only widgets

Suggested pattern:

```text
features/<feature_name>/
  data/
  domain/
  presentation/
    screens/
    widgets/
```

Keep feature internals independent from other features. Share reusable pieces via `lib/shared` or `lib/core`.
