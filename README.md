# CarpenterHub

A loyalty/ordering platform for a carpentry materials business: carpenters place orders, earn points, and redeem rewards through a mobile app; staff manage orders, offers, gifts, and leads through a web admin console. Both apps share one Firebase backend.

## Apps

| App | Path | Platform | Tech |
|---|---|---|---|
| **Carpenter App** | [`carpenter_app/`](carpenter_app) | Android (Flutter, iOS/desktop scaffolding present but untested) | Flutter, Firebase Auth + Firestore, Cloudinary |
| **Admin Console** | [`admin_console/`](admin_console) | Web | Flutter Web, Firebase Auth + Firestore, Cloudinary, Firebase Hosting |

### Carpenter App

The carpenter-facing mobile app. Carpenters can:

- Place orders by photo, manual line-item entry, or voice note recording
- Track order status (Submitted → Processing → Fulfilled → Delivered), view invoices, and play back voice notes
- Earn and redeem points (cash payout or a gift catalog)
- Submit customer leads (with map/GPS location) and see points earned per lead
- View today's/weekly offers and a carpenter leaderboard
- Switch the app language (English/Hindi) and adjust font size — both persist across restarts

### Admin Console

The staff-facing web dashboard. Admins can:

- Process orders: enter line items from the physical invoice, generate invoices, manage status, view uploaded photos/voice notes
- Publish/withdraw offers (with optional banner image, PDF, and description)
- Manage the gift catalog and redemption queue (cash + gift requests)
- Manage leads: view remarks/location (with a map link), set status, and configure how many points are awarded for reaching "Qualified" vs "Converted"
- Configure global points/redemption rules
- Broadcast notifications to carpenters and see live carpenter locations on a map

## Architecture

- **Backend**: Firebase (Auth for login, Firestore for all data, Hosting for the admin console). No Cloud Functions — all business logic (points crediting, order numbering, etc.) lives in the Flutter client code, often inside Firestore transactions for atomicity.
- **File uploads**: Cloudinary (not Firebase Storage, which requires the paid Blaze plan). Images use the `auto` upload type; voice notes use `raw` ([why](carpenter_app/lib/services/cloudinary_service.dart) — `auto` classifies audio as a `video` resource, which unsigned upload presets commonly block).
- **State management**: `provider` (a single `ChangeNotifier` per app — `AppState` / `AdminState` — backed by Firestore snapshot listeners).
- **Collections**: `carpenters`, `orders`, `offers`, `gifts`, `giftRedemptions`, `leads`, `notifications`, `pointsLedger`, plus a `config` doc for global rules. See [`firestore.rules`](firestore.rules) for the security model.

## Getting started

### Prerequisites

- Flutter SDK (stable channel, 3.27+ — the app uses `record: ^7.1.0` and modern AGP/Kotlin, which need a recent Flutter)
- Android SDK (for the carpenter app) — platform 36, a recent build-tools version
- A JDK (17 recommended)
- Node.js + the Firebase CLI (`npm install -g firebase-tools`) if you'll deploy the admin console
- **Install everything to a path with no spaces.** A previous setup at a path containing spaces caused real Gradle/Android-SDK dependency-locking failures that needed directory junctions to work around.

### Setup

```sh
git clone https://github.com/nigamkartik96/carpenter.git
cd carpenter

cd carpenter_app && flutter pub get && cd ..
cd admin_console && flutter pub get && cd ..
```

`android/local.properties` under `carpenter_app/` is machine-specific and gitignored — Flutter regenerates it on first build. If `flutter doctor` can't find your Android SDK, point it there once:

```sh
flutter config --android-sdk <path-to-sdk>
```

### Running

```sh
# Carpenter app, on a connected/emulated Android device
cd carpenter_app
flutter run

# Admin console, locally
cd admin_console
flutter run -d chrome
```

### Building

```sh
# Carpenter app debug APK
cd carpenter_app
flutter build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk

# Admin console web build
cd admin_console
flutter build web
```

### Deploying the admin console

```sh
cd admin_console
firebase login        # once per machine
firebase deploy --only hosting
```

Live at **https://carpenterhub-96958.web.app**.

## Firebase & Cloudinary config

`google-services.json` (carpenter app) and `firebase_options.dart` (both apps) are committed — these contain Firebase's client-side API keys, which are not secret (access is controlled by Firestore security rules, not key secrecy), so this is normal practice for Firebase apps.

Cloudinary credentials (cloud name + unsigned upload preset) are hardcoded in each app's `cloudinary_service.dart`, since the unsigned-upload flow is designed not to need a server-side secret.

## Known constraints

- No automated tests beyond the default Flutter widget-test scaffold — this was built iteratively against a live device/browser, not TDD.
- Background location tracking (for field-visit tracking) is foreground-only; a persistent background service is a separate, larger effort.
- iOS/desktop targets exist as Flutter scaffolding but have not been built or tested.
