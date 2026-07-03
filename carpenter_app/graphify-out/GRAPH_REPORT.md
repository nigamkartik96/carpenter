# Graph Report - carpenter_app  (2026-07-03)

## Corpus Check
- 72 files · ~44,012 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 774 nodes · 1030 edges · 50 communities (37 shown, 13 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f14876a3`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_app_state.dart|app_state.dart]]
- [[_COMMUNITY_AppState|AppState]]
- [[_COMMUNITY_Win32Window|Win32Window]]
- [[_COMMUNITY_GeneratedPluginRegistrant.swift|GeneratedPluginRegistrant.swift]]
- [[_COMMUNITY_models.dart|models.dart]]
- [[_COMMUNITY_order_screens.dart|order_screens.dart]]
- [[_COMMUNITY_main.dart|main.dart]]
- [[_COMMUNITY_firebase_service.dart|firebase_service.dart]]
- [[_COMMUNITY_theme.dart|theme.dart]]
- [[_COMMUNITY_my_application.cc|my_application.cc]]
- [[_COMMUNITY_profile_screens.dart|profile_screens.dart]]
- [[_COMMUNITY_build|build]]
- [[_COMMUNITY_onboarding_screens.dart|onboarding_screens.dart]]
- [[_COMMUNITY_wWinMain|wWinMain]]
- [[_COMMUNITY_cloudinary_service.dart|cloudinary_service.dart]]
- [[_COMMUNITY_manifest.json|manifest.json]]
- [[_COMMUNITY_home_shell.dart|home_shell.dart]]
- [[_COMMUNITY_strings.dart|strings.dart]]
- [[_COMMUNITY_handle_new_rx_page|handle_new_rx_page]]
- [[_COMMUNITY_packagefluttermaterial.dart|package:flutter/material.dart]]
- [[_COMMUNITY_build|build]]
- [[_COMMUNITY_MainActivity|MainActivity]]
- [[_COMMUNITY_carpenter_app|carpenter_app]]
- [[_COMMUNITY_CLAUDE|CLAUDE.md]]
- [[_COMMUNITY_flutter_export_environment.sh|flutter_export_environment.sh]]
- [[_COMMUNITY_README|README.md]]
- [[_COMMUNITY_flutter_export_environment.sh|flutter_export_environment.sh]]
- [[_COMMUNITY_@bank|@bank]]
- [[_COMMUNITY_String|String?]]
- [[_COMMUNITY_What You Must Do When Invoked|What You Must Do When Invoked]]
- [[_COMMUNITY_rewards_screens.dart|rewards_screens.dart]]
- [[_COMMUNITY_AppState|AppState]]
- [[_COMMUNITY_speech_service.dart|speech_service.dart]]
- [[_COMMUNITY_mic_button.dart|mic_button.dart]]
- [[_COMMUNITY_tts_service.dart|tts_service.dart]]
- [[_COMMUNITY_qr_scan_screen.dart|qr_scan_screen.dart]]
- [[_COMMUNITY_graphify reference extra exports and benchmark|graphify reference: extra exports and benchmark]]
- [[_COMMUNITY_speaker_button.dart|speaker_button.dart]]
- [[_COMMUNITY_graphify reference query, path, explain|graphify reference: query, path, explain]]
- [[_COMMUNITY_graphify reference add a URL and watch a folder|graphify reference: add a URL and watch a folder]]
- [[_COMMUNITY_graphify reference commit hook and native CLAUDE.md integration|graphify reference: commit hook and native CLAUDE.md integration]]
- [[_COMMUNITY_graphify reference incremental update and cluster-only|graphify reference: incremental update and cluster-only]]
- [[_COMMUNITY_graphify reference GitHub clone and cross-repo merge|graphify reference: GitHub clone and cross-repo merge]]
- [[_COMMUNITY_graphify reference transcribe video and audio|graphify reference: transcribe video and audio]]
- [[_COMMUNITY_contact_picker.dart|contact_picker.dart]]
- [[_COMMUNITY_CLAUDE|CLAUDE.md]]
- [[_COMMUNITY_extraction-spec|extraction-spec.md]]

## God Nodes (most connected - your core abstractions)
1. `AppState` - 66 edges
2. `Win32Window` - 22 edges
3. `MessageHandler` - 12 edges
4. `What You Must Do When Invoked` - 12 edges
5. `build` - 11 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `/graphify` - 10 edges
10. `build` - 9 edges

## Surprising Connections (you probably didn't know these)
- `_check` --references--> `AppState`  [EXTRACTED]
  lib/main.dart → lib/state/app_state.dart
- `_pickPhoto` --references--> `AppState`  [EXTRACTED]
  lib/screens/onboarding_screens.dart → lib/state/app_state.dart
- `initState` --references--> `AppState`  [EXTRACTED]
  lib/screens/order_screens.dart → lib/state/app_state.dart
- `_changeQr` --references--> `AppState`  [EXTRACTED]
  lib/screens/profile_screens.dart → lib/state/app_state.dart
- `_save` --references--> `AppState`  [EXTRACTED]
  lib/screens/profile_screens.dart → lib/state/app_state.dart

## Import Cycles
- None detected.

## Communities (50 total, 13 thin omitted)

### Community 0 - "app_state.dart"
Cohesion: 0.03
Nodes (74): dart:async, ../l10n/strings.dart, accountNumber, addLead, addOrder, address, bankName, carpenterName (+66 more)

### Community 1 - "AppState"
Cohesion: 0.11
Nodes (26): AuthGate, _AuthGateState, HomeShell, _HomeShellState, ManualOrderScreen, _ManualOrderScreenState, OrderSuccessScreen, _OrderSuccessScreenState (+18 more)

### Community 2 - "Win32Window"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 3 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (41): Any, audioplayers_darwin, cloud_firestore, Cocoa, file_selector_macos, firebase_auth, firebase_core, firebase_messaging (+33 more)

### Community 4 - "models.dart"
Cohesion: 0.04
Nodes (48): int get, AppNotification, audioUrl, bannerUrl, body, CarpenterOrder, category, date (+40 more)

### Community 5 - "order_screens.dart"
Cohesion: 0.05
Nodes (41): AudioPlayer?, AudioPlayer get, dart:io, _addRow, audioUrl, createState, detail, dispose (+33 more)

### Community 6 - "main.dart"
Cohesion: 0.07
Nodes (30): @pragma, ../firebase_options.dart, android, DefaultFirebaseOptions, web, build, CarpenterHubApp, _check (+22 more)

### Community 7 - "firebase_service.dart"
Cohesion: 0.06
Nodes (32): FirebaseAuth, FirebaseFirestore, addLead, addOrder, auth, carpenterDoc, currentUser, db (+24 more)

### Community 8 - "theme.dart"
Cohesion: 0.06
Nodes (31): Color, IconData, ActionTile, build, buildAppTheme, child, color, icon (+23 more)

### Community 9 - "my_application.cc"
Cohesion: 0.10
Nodes (20): FlPluginRegistry, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins(), main() (+12 more)

### Community 10 - "profile_screens.dart"
Cohesion: 0.07
Nodes (31): _openFullScreenImage, accountNumber, AccountScreen, _AccountScreenState, address, bankName, _changeQr, _confirmDiscard (+23 more)

### Community 11 - "build"
Cohesion: 0.13
Nodes (19): build, build, build, build, Route /account, Route /createOrder, Route /editProfile, Route /gifts (+11 more)

### Community 12 - "onboarding_screens.dart"
Cohesion: 0.10
Nodes (21): address, busy, checking, createState, email, error, LoginScreen, _LoginScreenState (+13 more)

### Community 13 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 14 - "cloudinary_service.dart"
Cohesion: 0.18
Nodes (10): dart:convert, dart:typed_data, CloudinaryService, cloudName, instance, uploadBytes, uploadPreset, package:http/http.dart (+2 more)

### Community 15 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 16 - "home_shell.dart"
Cohesion: 0.22
Nodes (8): createState, _index, order_screens.dart, package:provider/provider.dart, profile_screens.dart, rewards_screens.dart, ../state/app_state.dart, ../widgets/speaker_button.dart

### Community 17 - "strings.dart"
Cohesion: 0.11
Nodes (18): AppLocale, giftRedemption, hiStrings, isHindi, leadBonus, offerLive, order, pointsForLead (+10 more)

### Community 18 - "handle_new_rx_page"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 19 - "package:flutter/material.dart"
Cohesion: 0.40
Nodes (4): package:carpenter_app/main.dart, package:flutter/material.dart, package:flutter_test/flutter_test.dart, main

### Community 20 - "build"
Cohesion: 0.50
Nodes (4): build, Route /consent, Route /login, Route /register

### Community 32 - "What You Must Do When Invoked"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 33 - "rewards_screens.dart"
Cohesion: 0.08
Nodes (24): double?, controller, createState, embedded, error, id, initState, lat (+16 more)

### Community 34 - "AppState"
Cohesion: 0.13
Nodes (24): ChangeNotifier, DashboardScreen, ConsentScreen, SplashScreen, CreateOrderScreen, OfferDetailsScreen, OffersScreen, OrderDetailsScreen (+16 more)

### Community 35 - "speech_service.dart"
Cohesion: 0.13
Nodes (14): bool get, _available, cancel, _ensureInit, _initTried, instance, isListening, listen (+6 more)

### Community 36 - "mic_button.dart"
Cohesion: 0.17
Nodes (12): _baseText, build, controller, createState, _listening, MicButton, _MicButtonState, onFinalResult (+4 more)

### Community 37 - "tts_service.dart"
Cohesion: 0.18
Nodes (10): FlutterTts, _configured, _ensureConfigured, instance, speak, stop, _tts, TtsService (+2 more)

### Community 38 - "qr_scan_screen.dart"
Cohesion: 0.18
Nodes (10): build, contains, _controller, createState, dispose, extractUpiId, _handled, _onDetect (+2 more)

### Community 39 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 40 - "speaker_button.dart"
Cohesion: 0.22
Nodes (8): build, createState, size, _speaking, text, _toggle, ../services/tts_service.dart, ../theme.dart

### Community 41 - "graphify reference: query, path, explain"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 42 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 43 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 44 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

## Knowledge Gaps
- **389 isolated node(s):** `flutter_export_environment.sh script`, `+registerWithRegistry`, `DefaultFirebaseOptions`, `android`, `web` (+384 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppState` connect `AppState` to `app_state.dart`, `AppState`, `rewards_screens.dart`, `mic_button.dart`, `order_screens.dart`, `main.dart`, `qr_scan_screen.dart`, `theme.dart`, `speaker_button.dart`, `profile_screens.dart`, `build`, `onboarding_screens.dart`, `home_shell.dart`, `build`?**
  _High betweenness centrality (0.149) - this node is a cross-community bridge._
- **Why does `CarpenterOrder` connect `models.dart` to `order_screens.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `FirebaseService` connect `firebase_service.dart` to `app_state.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `flutter_export_environment.sh script`, `+registerWithRegistry` to the rest of the system?**
  _390 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02666666666666667 - nodes in this community are weakly interconnected._
- **Should `AppState` be split into smaller, more focused modules?**
  _Cohesion score 0.11076923076923077 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._