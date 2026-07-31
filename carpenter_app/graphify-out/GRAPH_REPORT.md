# Graph Report - carpenter_app  (2026-07-31)

## Corpus Check
- 59 files · ~36,668 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 822 nodes · 1116 edges · 52 communities (37 shown, 15 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `221633d2`
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
- speaker_button.dart
- _VoiceOrderScreenState
- List
- @bank
- String?
- _VoiceNotePlayerState
- List
- carpenter_app
- CLAUDE.md
- CLAUDE.md
- README.md
- _ManualOrderScreenState
- _OffersScreenState
- _OrderSuccessScreenState
- _LeadNewScreenState
- _NotificationsScreenState

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

## Communities (52 total, 15 thin omitted)

### Community 0 - "app_state.dart"
Cohesion: 0.02
Nodes (87): dart:async, ../l10n/strings.dart, accountNumber, addLead, addOrder, addOrderComment, address, bankName (+79 more)

### Community 1 - "Win32Window"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 2 - "models.dart"
Cohesion: 0.04
Nodes (53): DateTime?, int get, AppNotification, audioUrl, authorName, authorRole, bannerUrl, body (+45 more)

### Community 3 - "qr_scan_screen.dart"
Cohesion: 0.17
Nodes (12): build, contains, _controller, createState, dispose, extractUpiId, _handled, _onDetect (+4 more)

### Community 4 - "theme.dart"
Cohesion: 0.04
Nodes (47): BoxFit, Color, _FirstOrNull, buildAppTheme, child, color, _defaultPageSizes, errorWidget (+39 more)

### Community 5 - "order_screens.dart"
Cohesion: 0.04
Nodes (48): AudioPlayer?, AudioPlayer get, dart:io, _addRow, audioUrl, _bubble, _comments, createState (+40 more)

### Community 6 - "main.dart"
Cohesion: 0.10
Nodes (20): AuthGate, _AuthGateState, build, CarpenterHubApp, _check, _checked, _checkForUpdate, createState (+12 more)

### Community 7 - "rewards_screens.dart"
Cohesion: 0.05
Nodes (52): double?, IconData, OrderSuccessScreen, _OrderSuccessScreenState, color, controller, createState, embedded (+44 more)

### Community 8 - "firebase_service.dart"
Cohesion: 0.05
Nodes (36): FirebaseAuth, FirebaseFirestore, addFcmToken, addLead, addOrder, addOrderComment, auth, carpenterDoc (+28 more)

### Community 9 - "profile_screens.dart"
Cohesion: 0.07
Nodes (31): _openFullScreenImage, accountNumber, AccountScreen, _AccountScreenState, address, bankName, _changeQr, _confirmDiscard (+23 more)

### Community 10 - "State"
Cohesion: 0.09
Nodes (21): AndroidFlutterLocalNotificationsPlugin, firebase_service.dart, FirebaseMessaging, FlutterLocalNotificationsPlugin, GlobalKey, _channelId, _channelName, init (+13 more)

### Community 11 - "onboarding_screens.dart"
Cohesion: 0.08
Nodes (27): address, build, busy, checking, createState, email, error, identifier (+19 more)

### Community 12 - "my_application.cc"
Cohesion: 0.10
Nodes (20): FlPluginRegistry, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins(), main() (+12 more)

### Community 13 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.10
Nodes (20): audioplayers_darwin, cloud_firestore, file_selector_macos, firebase_auth, firebase_core, firebase_messaging, firebase_storage, flutter_local_notifications (+12 more)

### Community 14 - "build"
Cohesion: 0.12
Nodes (21): build, build, build, build, _open, Route /account, Route /createOrder, Route /editProfile (+13 more)

### Community 15 - "strings.dart"
Cohesion: 0.10
Nodes (19): AppLocale, giftRedemption, hiStrings, isHindi, leadBonus, offerLive, order, orderComment (+11 more)

### Community 16 - "speech_service.dart"
Cohesion: 0.13
Nodes (14): bool get, _available, cancel, _ensureInit, _initTried, instance, isListening, listen (+6 more)

### Community 17 - "StatelessWidget"
Cohesion: 0.10
Nodes (26): ChangeNotifier, ConsentScreen, CreateOrderScreen, initState, OfferDetailsScreen, OrderDetailsScreen, OrderThumbnail, _pick (+18 more)

### Community 18 - "update_service.dart"
Cohesion: 0.13
Nodes (14): buildNumber, checkForUpdate, downloadUrl, forceUpdate, instance, launchDownload, releaseNotes, showUpdateDialog (+6 more)

### Community 19 - "AppState"
Cohesion: 0.17
Nodes (12): _baseText, build, controller, createState, _listening, MicButton, _MicButtonState, onFinalResult (+4 more)

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

### Community 32 - "speaker_button.dart"
Cohesion: 0.18
Nodes (11): build, createState, size, SpeakerButton, _SpeakerButtonState, _speaking, text, _toggle (+3 more)

### Community 33 - "_VoiceOrderScreenState"
Cohesion: 0.40
Nodes (4): package:carpenter_app/main.dart, package:flutter/material.dart, package:flutter_test/flutter_test.dart, main

### Community 34 - "List"
Cohesion: 0.18
Nodes (11): createState, DashboardScreen, HomeShell, _HomeShellState, _index, order_screens.dart, package:cached_network_image/cached_network_image.dart, package:provider/provider.dart (+3 more)

### Community 42 - "List"
Cohesion: 0.17
Nodes (11): @pragma, ../firebase_options.dart, backgroundLocationCallbackDispatcher, backgroundLocationTaskName, cancelBackgroundLocation, scheduleBackgroundLocation, pushBackgroundHandler, package:cloud_firestore/cloud_firestore.dart (+3 more)

### Community 49 - "_OrderSuccessScreenState"
Cohesion: 0.29
Nodes (6): android, DefaultFirebaseOptions, web, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

## Knowledge Gaps
- **444 isolated node(s):** `DefaultFirebaseOptions`, `android`, `web`, `hiStrings`, `isHindi` (+439 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppState` connect `StatelessWidget` to `app_state.dart`, `qr_scan_screen.dart`, `theme.dart`, `order_screens.dart`, `main.dart`, `rewards_screens.dart`, `profile_screens.dart`, `onboarding_screens.dart`, `build`, `AppState`, `_OrderHistoryScreenState`, `_UploadOrderScreenState`, `speaker_button.dart`, `List`, `_VoiceNotePlayerState`, `_ManualOrderScreenState`, `_OffersScreenState`, `_LeadNewScreenState`, `_NotificationsScreenState`?**
  _High betweenness centrality (0.160) - this node is a cross-community bridge._
- **Why does `CarpenterOrder` connect `models.dart` to `order_screens.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `FirebaseService` connect `firebase_service.dart` to `app_state.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `DefaultFirebaseOptions`, `android`, `web` to the rest of the system?**
  _444 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.022727272727272728 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._