# Graph Report - carpenter_app  (2026-07-19)

## Corpus Check
- 58 files · ~35,199 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 789 nodes · 1077 edges · 47 communities (32 shown, 15 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6aca94b3`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_state.dart
- Win32Window
- models.dart
- qr_scan_screen.dart
- theme.dart
- order_screens.dart
- main.dart
- rewards_screens.dart
- firebase_service.dart
- profile_screens.dart
- State
- onboarding_screens.dart
- my_application.cc
- GeneratedPluginRegistrant.swift
- build
- strings.dart
- speech_service.dart
- StatelessWidget
- update_service.dart
- AppState
- wWinMain
- cloudinary_service.dart
- tts_service.dart
- manifest.json
- .application
- RunnerTests.swift
- FlutterMacOS
- RegisterGeneratedPlugins
- MainActivity
- contact_picker.dart
- _OrderHistoryScreenState
- _UploadOrderScreenState
- _VoiceOrderScreenState
- List
- @bank
- String?
- carpenter_app
- CLAUDE.md
- CLAUDE.md
- README.md
- _ManualOrderScreenState
- _OffersScreenState
- _OrderSuccessScreenState

## God Nodes (most connected - your core abstractions)
1. `AppState` - 69 edges
2. `Win32Window` - 22 edges
3. `MessageHandler` - 12 edges
4. `build` - 11 edges
5. `build` - 10 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `MessageHandler` - 9 edges
10. `OnCreate` - 7 edges

## Surprising Connections (you probably didn't know these)
- `_check` --references--> `AppState`  [EXTRACTED]
  lib/main.dart → lib/state/app_state.dart
- `_pickPhoto` --references--> `AppState`  [EXTRACTED]
  lib/screens/onboarding_screens.dart → lib/state/app_state.dart
- `_changeQr` --references--> `AppState`  [EXTRACTED]
  lib/screens/profile_screens.dart → lib/state/app_state.dart
- `_save` --references--> `AppState`  [EXTRACTED]
  lib/screens/profile_screens.dart → lib/state/app_state.dart
- `_pickPhoto` --references--> `AppState`  [EXTRACTED]
  lib/screens/profile_screens.dart → lib/state/app_state.dart

## Import Cycles
- None detected.

## Communities (47 total, 15 thin omitted)

### Community 0 - "app_state.dart"
Cohesion: 0.02
Nodes (84): dart:async, ../l10n/strings.dart, accountNumber, addLead, addOrder, addOrderComment, address, bankName (+76 more)

### Community 1 - "Win32Window"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 2 - "models.dart"
Cohesion: 0.04
Nodes (53): DateTime?, int get, AppNotification, audioUrl, authorName, authorRole, bannerUrl, body (+45 more)

### Community 3 - "qr_scan_screen.dart"
Cohesion: 0.06
Nodes (38): build, contains, _controller, createState, dispose, extractUpiId, _FirstOrNull, _handled (+30 more)

### Community 4 - "theme.dart"
Cohesion: 0.04
Nodes (45): BoxFit, IconData, buildAppTheme, child, color, _defaultPageSizes, errorWidget, fit (+37 more)

### Community 5 - "order_screens.dart"
Cohesion: 0.04
Nodes (50): AudioPlayer?, AudioPlayer get, dart:io, _addRow, audioUrl, _bubble, _comments, createState (+42 more)

### Community 6 - "main.dart"
Cohesion: 0.06
Nodes (32): @pragma, ../firebase_options.dart, android, DefaultFirebaseOptions, web, build, CarpenterHubApp, _check (+24 more)

### Community 7 - "rewards_screens.dart"
Cohesion: 0.06
Nodes (34): Color, double?, color, controller, createState, embedded, error, _giftPage (+26 more)

### Community 8 - "firebase_service.dart"
Cohesion: 0.06
Nodes (34): FirebaseAuth, FirebaseFirestore, addLead, addOrder, addOrderComment, auth, carpenterDoc, currentUser (+26 more)

### Community 9 - "profile_screens.dart"
Cohesion: 0.07
Nodes (31): _openFullScreenImage, accountNumber, AccountScreen, _AccountScreenState, address, bankName, _changeQr, _confirmDiscard (+23 more)

### Community 10 - "State"
Cohesion: 0.16
Nodes (18): AuthGate, _AuthGateState, GiftStoreScreen, _GiftStoreScreenState, LeadNewScreen, _LeadNewScreenState, LeadsScreen, _LeadsScreenState (+10 more)

### Community 11 - "onboarding_screens.dart"
Cohesion: 0.08
Nodes (26): address, build, busy, checking, ConsentScreen, createState, email, error (+18 more)

### Community 12 - "my_application.cc"
Cohesion: 0.10
Nodes (20): FlPluginRegistry, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins(), main() (+12 more)

### Community 13 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.10
Nodes (19): audioplayers_darwin, cloud_firestore, file_selector_macos, firebase_auth, firebase_core, firebase_messaging, firebase_storage, flutter_tts (+11 more)

### Community 14 - "build"
Cohesion: 0.12
Nodes (20): build, build, build, build, Route /account, Route /createOrder, Route /editProfile, Route /gifts (+12 more)

### Community 15 - "strings.dart"
Cohesion: 0.10
Nodes (19): AppLocale, giftRedemption, hiStrings, isHindi, leadBonus, offerLive, order, orderComment (+11 more)

### Community 16 - "speech_service.dart"
Cohesion: 0.13
Nodes (14): bool get, _available, cancel, _ensureInit, _initTried, instance, isListening, listen (+6 more)

### Community 17 - "StatelessWidget"
Cohesion: 0.10
Nodes (26): ChangeNotifier, SplashScreen, CreateOrderScreen, initState, OfferDetailsScreen, OrderDetailsScreen, OrderThumbnail, _pick (+18 more)

### Community 18 - "update_service.dart"
Cohesion: 0.10
Nodes (18): buildNumber, checkForUpdate, downloadUrl, forceUpdate, instance, launchDownload, releaseNotes, showUpdateDialog (+10 more)

### Community 20 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 21 - "cloudinary_service.dart"
Cohesion: 0.18
Nodes (10): dart:convert, dart:typed_data, CloudinaryService, cloudName, instance, uploadBytes, uploadPreset, package:http/http.dart (+2 more)

### Community 22 - "tts_service.dart"
Cohesion: 0.18
Nodes (10): FlutterTts, _configured, _ensureConfigured, instance, speak, stop, _tts, TtsService (+2 more)

### Community 23 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 24 - ".application"
Cohesion: 0.20
Nodes (8): Any, FlutterAppDelegate, AppDelegate, Bool, AppDelegate, Bool, NSApplication, UIApplication

### Community 25 - "RunnerTests.swift"
Cohesion: 0.25
Nodes (5): Flutter, RunnerTests, RunnerTests, UIKit, XCTestCase

### Community 26 - "FlutterMacOS"
Cohesion: 0.47
Nodes (3): Cocoa, FlutterMacOS, XCTest

### Community 27 - "RegisterGeneratedPlugins"
Cohesion: 0.33
Nodes (5): FlutterPluginRegistry, FlutterViewController, RegisterGeneratedPlugins(), MainFlutterWindow, NSWindow

### Community 34 - "List"
Cohesion: 0.20
Nodes (10): createState, DashboardScreen, HomeShell, _HomeShellState, _index, order_screens.dart, package:cached_network_image/cached_network_image.dart, profile_screens.dart (+2 more)

## Knowledge Gaps
- **424 isolated node(s):** `DefaultFirebaseOptions`, `android`, `web`, `hiStrings`, `isHindi` (+419 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppState` connect `StatelessWidget` to `app_state.dart`, `_VoiceOrderScreenState`, `List`, `qr_scan_screen.dart`, `theme.dart`, `order_screens.dart`, `main.dart`, `rewards_screens.dart`, `profile_screens.dart`, `State`, `onboarding_screens.dart`, `build`, `_ManualOrderScreenState`, `_OffersScreenState`, `_OrderSuccessScreenState`, `AppState`, `_OrderHistoryScreenState`, `_UploadOrderScreenState`?**
  _High betweenness centrality (0.171) - this node is a cross-community bridge._
- **Why does `CarpenterOrder` connect `models.dart` to `order_screens.dart`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `FirebaseService` connect `firebase_service.dart` to `app_state.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `DefaultFirebaseOptions`, `android`, `web` to the rest of the system?**
  _424 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.023529411764705882 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._