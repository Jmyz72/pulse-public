# Pulse

Pulse is a Flutter co-living coordination app for shared households. It brings messaging, expenses, groceries, chores, timetable visibility, events, notifications, and roommate presence into one mobile app.

This repository is the public version of the project. The application code, feature modules, and architecture are included here; secrets and platform credentials are not. You can run the app locally by wiring it to your own Firebase project and API keys.

## Highlights

- Authentication, onboarding, and profile flows
- Group chat with rich message cards and admin controls
- Expense tracking, bill splitting, and receipt scanning
- Grocery, chores, and living tools for shared spaces
- Timetable sharing, nearby visibility, and event planning
- Push notifications, location-aware features, and settings management

## Tech Stack

- Flutter and Dart
- `flutter_bloc` for state management
- Clean Architecture with feature-first modules
- Firebase Auth, Firestore, Storage, Functions, and Messaging
- Google Maps, OCR, and AI-assisted receipt parsing
- `get_it`, `dartz`, `dio`, `shared_preferences`, and `flutter_secure_storage`

## Architecture

Pulse follows a feature-first Clean Architecture layout:

```text
lib/
├── core/
├── features/
│   └── <feature>/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/
```

Core design choices:

- `presentation -> domain -> data` dependency flow
- repository interfaces in the domain layer
- use cases for business logic boundaries
- BLoC-driven state orchestration
- shared services and widgets isolated under `core/` and `shared/`

## Getting Started

### Prerequisites

- Flutter SDK with a working Android Studio and/or Xcode setup
- A Firebase project for Auth, Firestore, Storage, Functions, and Messaging
- FlutterFire CLI if you want to regenerate Firebase configuration
- Google Maps and Gemini-compatible API access for the location and AI-assisted flows

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

This public repo does not ship real Firebase credentials.

- Replace the placeholder values in [lib/firebase_options.dart](/Users/jimmyhew/Documents/pulse-public/lib/firebase_options.dart), or regenerate the file with `flutterfire configure`
- Add your platform service files:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- If you use email-link auth or deep links, update the placeholder hosts in [android/app/src/main/AndroidManifest.xml](/Users/jimmyhew/Documents/pulse-public/android/app/src/main/AndroidManifest.xml)

### 3. Configure external API keys

This repo includes placeholder values for public release.

- Update [lib/core/config/api_keys.dart](/Users/jimmyhew/Documents/pulse-public/lib/core/config/api_keys.dart) with your own keys
- Replace the Android Maps key placeholder in [android/app/src/main/AndroidManifest.xml](/Users/jimmyhew/Documents/pulse-public/android/app/src/main/AndroidManifest.xml)
- Review [ios/Runner/Info.plist](/Users/jimmyhew/Documents/pulse-public/ios/Runner/Info.plist) and platform identifiers if you are connecting the app to your own services

### 4. Run the app

```bash
flutter run
```

The current public configuration is set up for mobile targets. Web, macOS, Windows, and Linux are not configured in [lib/firebase_options.dart](/Users/jimmyhew/Documents/pulse-public/lib/firebase_options.dart).

## Project Structure

- [lib/main.dart](/Users/jimmyhew/Documents/pulse-public/lib/main.dart): app bootstrap, Firebase initialization, notification wiring
- [lib/app.dart](/Users/jimmyhew/Documents/pulse-public/lib/app.dart): top-level app composition, routing, and BLoC providers
- [lib/injection_container.dart](/Users/jimmyhew/Documents/pulse-public/lib/injection_container.dart): dependency registration
- [lib/features](/Users/jimmyhew/Documents/pulse-public/lib/features): feature modules grouped by `data`, `domain`, and `presentation`

## Testing

Run the test suite with:

```bash
flutter test
```

Testing approach and conventions are documented in [TESTING.md](/Users/jimmyhew/Documents/pulse-public/TESTING.md).

## Additional Documentation

- [FEATURES.md](/Users/jimmyhew/Documents/pulse-public/FEATURES.md)
- [ARCHITECTURE.md](/Users/jimmyhew/Documents/pulse-public/ARCHITECTURE.md)
- [TESTING.md](/Users/jimmyhew/Documents/pulse-public/TESTING.md)
