# Finders Keepers 🔍

> **A campus lost-and-found application. Find what's lost. Return what's found.**

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-configured-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## About

**Finders Keepers** is a campus-scale lost-and-found platform that connects students and staff who have lost items with those who have found them. It provides a structured, private, and trustworthy way to report, search, claim, and verify ownership of lost campus items.

## Design System: Campus Signal

The app uses a bespoke visual language called **Campus Signal**:

| Token | Color | Usage |
|---|---|---|
| Paper White | `#F7F4EE` | Primary background |
| Ink Black | `#1A1917` | Primary text |
| Signal Lime | `#B8E04A` | Primary accent |
| Graphite | `#6B6860` | Secondary text |
| Alert Orange | `#E8824A` | Warning / Lost status |
| Found Green | `#4A9B6F` | Found status |

Typography: **DM Serif Display** (headings) + **Inter** (interface)

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.22+ / Dart 3.3+ |
| State Management | Riverpod 2.x |
| Navigation | GoRouter 14.x |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Maps | flutter_map + OpenStreetMap |
| Fonts | Google Fonts (Inter, DM Serif Display) |

## Project Structure

```
lib/
├── app/            # App configuration, router, theme
│   └── theme/     # Campus Signal design tokens
├── core/           # Shared widgets, models, constants
│   ├── widgets/   # Reusable CS component library
│   └── models/    # Domain models
└── features/       # Feature modules
    ├── auth/       # Authentication screens
    ├── discovery/  # Home / item discovery
    ├── map/        # Explore / map view
    ├── activity/   # My Activity (reports & claims)
    └── profile/    # Account & settings
```

## Getting Started

### Prerequisites

1. **Flutter SDK 3.22+** — [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Dart SDK 3.3+** (bundled with Flutter)
3. **Android Studio** with Android SDK (API 23+)
4. **Firebase project** (for Phase 2)

### Setup

```bash
# 1. Verify Flutter installation
flutter doctor

# 2. Get dependencies
flutter pub get

# 3. Run the app (with emulator or device connected)
flutter run

# 4. Run tests
flutter test

# 5. Analyze code
flutter analyze
```

### Firebase Setup (Phase 2)

Firebase is configured as an architectural stub in Phase 1. To connect:

1. Create a Firebase project at https://console.firebase.google.com
2. Register your Android app (package name: `com.campustech.finders_keepers`)
3. Download `google-services.json` → place in `android/app/`
4. Download `GoogleService-Info.plist` → place in `ios/Runner/`
5. Run `flutterfire configure` (requires `dart pub global activate flutterfire_cli`)
6. Uncomment Firebase initialization in `lib/main.dart`

## Development Phases

- **Phase 1 (Current):** Foundation, architecture, design system, app shell ✅
- **Phase 2:** Firebase Auth, Firestore data layer, item reports
- **Phase 3:** Map integration, search/filter, item details
- **Phase 4:** Claims flow, verification, approval/rejection
- **Phase 5:** Offline sync, security rules, testing, APK

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

MIT © Campus Tech Team
