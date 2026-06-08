# App Architecture Guide

This directory has been prepared for a feature-first structure used in production teams.

## Rules

- New code goes inside `lib/features`, `lib/core`, and `lib/shared`.
- Avoid adding new files to legacy folders (`lib/screens`, `lib/services`, `lib/widgets`, `lib/utils`) unless required for hotfixes.
- Migrate existing code gradually by feature.

## Entry Points

- `lib/main.dart`: runtime entry point
- `lib/app/`: app composition layer (recommended place for app-level wiring)

See `docs/architecture/FOLDER_STRUCTURE.md` for full details and migration mapping.
