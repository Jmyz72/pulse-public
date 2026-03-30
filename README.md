# Pulse

Pulse is a Flutter co-living coordination app built with Clean Architecture and BLoC. This public copy is intended as a portfolio/code-sample version of the project.

## Public Repo Note

This repository has been sanitized for public release.

- Live Firebase configuration, deployment files, Cloud Functions, and rules are intentionally removed.
- Real API keys, project IDs, deep-link hosts, and platform service files are replaced with placeholders.
- The codebase is preserved to show feature design, app structure, and business logic.

Because the private backend integration is omitted, this copy is not intended to be run as-is.

## What The App Covers

- Authentication and onboarding flows
- Group chat and shared-room coordination
- Expense tracking and bill splitting
- Grocery, chores, and living tools
- Timetable and friend visibility controls
- Location, notifications, and profile settings

## Architecture

Pulse follows Clean Architecture with BLoC:

```text
lib/
├── core/
├── features/
│   └── <feature>/
│       ├── domain/
│       ├── data/
│       └── presentation/
└── shared/
```

Key choices:

- `presentation -> domain -> data` dependency flow
- Use cases for business rules
- BLoC for orchestration and state transitions
- Repository contracts in the domain layer
- Feature-first module structure

## Tech Stack

- Flutter / Dart
- flutter_bloc
- get_it
- dartz
- Firebase-oriented data layer abstractions
- Google Maps and OCR/AI integrations behind app services

## Repository Scope

The public copy focuses on:

- Code organization
- Feature architecture
- State management patterns
- Domain and data layer separation
- Test structure

Backend credentials and production infrastructure are intentionally excluded.

## Related Docs

- [FEATURES.md](/Users/jimmyhew/Documents/pulse-public/FEATURES.md)
- [ARCHITECTURE.md](/Users/jimmyhew/Documents/pulse-public/ARCHITECTURE.md)
- [TESTING.md](/Users/jimmyhew/Documents/pulse-public/TESTING.md)
