# Finders Keepers 🔍

> **A campus lost-and-found application. Find what's lost. Return what's found.**

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Dual--Mode%20Architecture-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Overview

**Finders Keepers** is a production-quality campus lost-and-found mobile platform built with Flutter and Riverpod. It bridges the gap between students and staff who lose items and good Samaritans or campus security officers who find them.

The application features:
- **Campus Signal Design System**: A bespoke editorial visual identity featuring warm ivory paper backgrounds (`#F7F4EE`), near-black ink typography (`#1A1917`), and high-visibility signal lime accents (`#B8E04A`).
- **Dual-Mode Backend Architecture**: Seamless operation in both live Firebase cloud environments (Auth, Firestore, Storage) and offline-first local environments with durable persistence across process restarts.
- **Draft Auto-Save & Interruption Recovery**: Automatically saves in-progress report drafts to disk, prompting users to restore unfinished reports after unexpected app closures or phone calls.
- **Multi-Factor Similarity Engine**: Evaluates title/description token overlap, category matches, geographical zone proximity, and temporal delta to compute percentage match scores and explanations.
- **Secure Ownership Verification**: Private evidence handling, self-claim prevention, role-based security, and an atomic state machine (`active` → `claimed` → `returned`) preventing double-handover.
- **Offline Sync Queue**: Resilient queue managing pending/synced/failed network operations with idempotency keys and bounded exponential backoff.
- **In-App Match Alerts & Deep Linking**: Instant notifications when new found items match reported lost items, routing directly to item details.

---

## Visual Identity: Campus Signal

The app intentionally rejects standard AI-generated dashboard aesthetics and default material themes in favor of an editorial, newspaper-inspired visual language:

| Design Token | Hex Code | Purpose |
|---|---|---|
| **Paper White** | `#F7F4EE` | Calibrated warm paper background |
| **Ink Black** | `#1A1917` | Deep contrast text and dark headers |
| **Signal Lime** | `#B8E04A` | Primary high-visibility accent |
| **Graphite** | `#6B6860` | Secondary muted metadata & timestamps |
| **Alert Orange** | `#E8824A` | Lost status and attention banners |
| **Found Green** | `#4A9B6F` | Found status and confirmed handovers |

**Typography**:
- **Display / Headings**: DM Serif Display — expressive, editorial serif for titles.
- **Interface / Body**: Inter — high-legibility sans-serif for forms, lists, and metadata.

---

## Technology Stack

| Layer | Technology | Details |
|---|---|---|
| **Framework** | Flutter 3.22+ / Dart 3.3+ | Material 3 foundation |
| **State Management** | Riverpod 2.5.1 | Reactive declarative dependency injection |
| **Navigation** | GoRouter 14.2.0 | Declarative URL-like routing & deep linking |
| **Cloud Database** | Cloud Firestore | `items`, `claims`, `users` collections |
| **Authentication** | Firebase Auth | Email/Password, Anonymous guest, campus roles |
| **Cloud Storage** | Firebase Storage | Image uploads with MIME & 5MB size validation |
| **Local Persistence** | SharedPreferences / JSON Cache | Durable offline storage surviving process termination |
| **Maps** | flutter_map 7.0.2 + OpenStreetMap | Interactive campus zones with privacy coordinate jitter |
| **Image Handling** | image_picker 1.1.2 + cached_network_image | Camera and gallery picker with local previews |

---

## Architecture & Codebase Structure

```
lib/
├── app/
│   ├── app.dart                   # FindersKeepersApp root widget
│   ├── router.dart                # GoRouter route declarations & redirect guards
│   └── theme/                     # Campus Signal design system
│       ├── colors.dart            # CSColors palette tokens
│       ├── typography.dart        # CSTypography (DM Serif + Inter)
│       ├── spacing.dart           # CSSpacing padding and radius tokens
│       └── theme.dart             # Material 3 ThemeData overrides
├── core/
│   ├── constants/                 # App constants & route paths
│   ├── models/                    # ItemModel, ItemType, ItemStatus domain models
│   ├── services/
│   │   ├── firebase_service.dart  # Dual-mode runtime configuration detector
│   │   ├── local_cache_service.dart # Durable SharedPreferences persistence & draft store
│   │   ├── sync_queue_service.dart# Offline operation queue with exponential backoff
│   │   ├── similarity_service.dart# Multi-factor token & proximity matching engine
│   │   ├── notification_service.dart # In-app alerts & deep linking service
│   │   ├── storage_service.dart   # Image picker abstraction & local storage
│   │   └── firebase_storage_service.dart # Cloud Storage image uploader
│   └── widgets/                   # Reusable Campus Signal UI components
│       ├── cs_button.dart         # CSPrimaryButton, CSSecondaryButton
│       ├── cs_card.dart           # CSItemCard, CSStatusLabel, CSSectionHeader
│       ├── cs_navbar.dart         # Editorial BottomNavigationBar
│       └── cs_search_bar.dart     # Custom stylized search input
└── features/
    ├── auth/                      # Authentication & Guest login
    │   ├── data/                  # AuthRepository, MockAuthRepository, FirebaseAuthRepository
    │   └── presentation/          # WelcomeScreen, ProfileScreen auth modals
    ├── discovery/                 # Home feed & multi-criteria filtering
    │   └── presentation/          # HomeScreen (category chips, search, notification sheet)
    ├── items/                     # Lost/Found reporting and inspection
    │   ├── data/                  # ItemRepository, MockItemRepository, FirestoreItemRepository
    │   └── presentation/          # ReportItemScreen, ItemDetailScreen
    ├── claims/                    # Ownership verification & handovers
    │   ├── data/                  # ClaimRepository, ClaimModel, FirestoreClaimRepository
    │   └── presentation/          # Claim submission sheet, reporter review interface
    ├── map/                       # Campus exploration
    │   └── presentation/          # ExploreScreen (OpenStreetMap), campus_locations.dart
    └── profile/                   # User account & settings
        └── presentation/          # ProfileScreen, sync status inspector
```

---

## Key Technical Subsystems

### 1. Dual-Mode Architecture (Cloud & Durable Local Persistence)
Finders Keepers operates seamlessly in two distinct environments without requiring mock data fabrications:
- **Cloud Mode**: When `google-services.json` is installed, the app dynamically connects to real Firebase Auth, Cloud Firestore, and Firebase Storage.
- **Durable Local Mode**: When unconfigured or offline, the app switches to `MockItemRepository`, `MockClaimRepository`, and `LocalCacheService`. Reports, claims, user sessions, and sync operations are written to disk via `SharedPreferences`. Process death and cold restarts preserve all reported items and submitted claims.

### 2. Draft Auto-Save & Recovery
- Users filling out reports have their form state (`ItemType`, category, zone, title, description, specific location, photo path) continuously auto-saved to disk.
- When opening `ReportItemScreen`, any unfinished draft prompts the user with an editorial restore banner ("Unsaved Report Draft: Restore or Discard").
- Submitting a report or explicitly discarding it atomically purges the cached draft.

### 3. Multi-Factor Similarity & Matching Engine
A deterministic scoring service compares reported lost items against found items:
- **Category Match (35% weight)**: Exact category equality.
- **Keyword / Token Overlap (35% weight)**: Tokenizes title and description, filters campus stop words, and evaluates Jaccard similarity.
- **Location Proximity (15% weight)**: Compares coordinate distance (<200m = 1.0) or zone label token overlap.
- **Temporal Proximity (15% weight)**: Highest score for items reported within 48 hours, scaling down over 7 days.
- **Transparent Explanation**: Produces human-readable rationale (e.g., `Same category (Electronics) • Keywords match: "airpods, case" • Nearby location • Reported within 48h`).

### 4. Secure Ownership Verification & Handover State Machine
- **Private Evidence Protection**: Verification evidence (e.g., serial numbers, wallpaper descriptions) is strictly separated from the public feed.
- **Self-Claim Prevention**: Users cannot submit ownership claims on items they reported themselves.
- **Role-Based Review**: The original finder, campus staff, and security admins can inspect submitted evidence and click **Approve & Hand Over** or **Reject**.
- **Atomic Handover**: Approving a claim transitions the item state to `returned`, preventing double-returns or subsequent unauthorized claims.

### 5. Offline Sync Queue
- Network operations are enqueued with unique idempotency keys (e.g., `item_rep_123456789`).
- Status tracks `pending`, `synced`, or `failed`.
- Failed requests compute bounded exponential backoff (`2 * 2^retryCount` seconds up to 128s).

---

## Security & Rules

### Firestore Security Rules (`firestore.rules`)
```javascript
// Strict ownership, evidence privacy, and role checks
match /claims/{claimId} {
  // Only claimant, item reporter, or campus admin can view evidence
  allow read: if isAuthenticated() && (
    resource.data.claimantUid == request.auth.uid ||
    getItem(resource.data.itemId).reportedByUid == request.auth.uid ||
    isAdmin()
  );
  // Claimants cannot claim items they reported themselves
  allow create: if isAuthenticated() &&
    request.resource.data.claimantUid == request.auth.uid &&
    getItem(request.resource.data.itemId).reportedByUid != request.auth.uid &&
    request.resource.data.status == 'pending';
  // Only finder or admin can approve/reject claims
  allow update: if isAuthenticated() && (
    getItem(resource.data.itemId).reportedByUid == request.auth.uid || isAdmin()
  );
}
```

### Storage Security Rules (`storage.rules`)
- Restricts uploaded photos to image MIME types (`image/*`).
- Enforces a 5MB maximum file size limit.
- Separates public item images from private claim evidence.

### Cloud Functions Architecture (`functions/`)
- `onItemCreated`: Triggered when an item is created; computes similarity against opposite items and dispatches in-app match alerts.
- `onClaimStatusUpdated`: Triggered on claim decision; notifies the claimant and transitions item status to `returned`.
- `submitClaimSecure`: Secure callable function validating claimant authorization.

---

## Automated Testing Suite

The repository includes a comprehensive automated test suite with **54 passing tests** and **0 analyzer issues**:

| Test File | Test Suite | Tests |
|---|---|---|
| `test/theme_test.dart` | Campus Signal Design Tokens & Typography | 10 passed |
| `test/navigation_test.dart` | GoRouter Navigation & Shell Switching | 26 passed |
| `test/phase2_features_test.dart` | Auth, Models, UI Components & Form Validation | 9 passed |
| `test/phase3_features_test.dart` | Local Storage, Sync Queue, Similarity Engine, Lifecycle & Alerts | 9 passed |
| **Total** | **All automated tests** | **54 passed** |

Run tests:
```bash
flutter analyze
flutter test
```

---

## Setup & Running

### 1. Prerequisites
- Flutter SDK 3.22+
- Android Studio / Android SDK (API 34+)

### 2. Run Locally
```bash
# Get dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Build debug APK
flutter build apk --debug
```

### 3. Connecting Live Firebase (Optional)
To switch from Durable Local Mode to Live Firebase Cloud Mode:
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com).
2. Register an Android application with package name `com.campustech.finders_keepers`.
3. Download `google-services.json` and place it in `android/app/`.
4. Run `flutterfire configure`.
5. Deploy security rules: `firebase deploy --only firestore:rules,storage`.
6. Deploy Cloud Functions: `cd functions && npm install && firebase deploy --only functions`.

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
