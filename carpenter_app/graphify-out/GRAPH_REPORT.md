# Graph Report - carpenter_app  (2026-07-03)

## Corpus Check
- 55 files · ~29,737 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 614 nodes · 825 edges · 32 communities (24 shown, 8 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `eb1daa33`
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

## God Nodes (most connected - your core abstractions)
1. `AppState` - 46 edges
2. `Win32Window` - 22 edges
3. `MessageHandler` - 12 edges
4. `build` - 11 edges
5. `FlutterWindow` - 10 edges
6. `Create` - 10 edges
7. `WndProc` - 10 edges
8. `build` - 9 edges
9. `MessageHandler` - 9 edges
10. `OnCreate` - 7 edges

## Surprising Connections (you probably didn't know these)
- `_check` --references--> `AppState`  [EXTRACTED]
  lib/main.dart → lib/state/app_state.dart
- `build` --references--> `AppState`  [EXTRACTED]
  lib/theme.dart → lib/state/app_state.dart
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `build` --references--> `AppState`  [EXTRACTED]
  lib/screens/home_shell.dart → lib/state/app_state.dart

## Import Cycles
- None detected.

## Communities (32 total, 8 thin omitted)

### Community 0 - "app_state.dart"
Cohesion: 0.03
Nodes (74): bool get, dart:async, ../l10n/strings.dart, accountNumber, addLead, addOrder, address, bankName (+66 more)

### Community 1 - "AppState"
Cohesion: 0.05
Nodes (66): ChangeNotifier, double?, AuthGate, _AuthGateState, DashboardScreen, HomeShell, _HomeShellState, ConsentScreen (+58 more)

### Community 2 - "Win32Window"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 3 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (37): Any, audioplayers_darwin, cloud_firestore, Cocoa, file_selector_macos, firebase_auth, firebase_core, firebase_messaging (+29 more)

### Community 4 - "models.dart"
Cohesion: 0.04
Nodes (47): int get, AppNotification, audioUrl, bannerUrl, body, CarpenterOrder, category, date (+39 more)

### Community 5 - "order_screens.dart"
Cohesion: 0.04
Nodes (45): AudioPlayer?, AudioPlayer get, dart:io, _addRow, audioUrl, createState, detail, dispose (+37 more)

### Community 6 - "main.dart"
Cohesion: 0.07
Nodes (30): @pragma, ../firebase_options.dart, android, DefaultFirebaseOptions, web, build, CarpenterHubApp, _check (+22 more)

### Community 7 - "firebase_service.dart"
Cohesion: 0.06
Nodes (32): FirebaseAuth, FirebaseFirestore, addLead, addOrder, auth, carpenterDoc, currentUser, db (+24 more)

### Community 8 - "theme.dart"
Cohesion: 0.06
Nodes (30): Color, IconData, ActionTile, build, buildAppTheme, child, color, icon (+22 more)

### Community 9 - "my_application.cc"
Cohesion: 0.10
Nodes (20): FlPluginRegistry, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins(), main() (+12 more)

### Community 10 - "profile_screens.dart"
Cohesion: 0.09
Nodes (22): accountNumber, address, bankName, _changeQr, _confirmDiscard, createState, editing, embedded (+14 more)

### Community 11 - "build"
Cohesion: 0.13
Nodes (19): build, build, build, build, Route /account, Route /createOrder, Route /editProfile, Route /gifts (+11 more)

### Community 12 - "onboarding_screens.dart"
Cohesion: 0.12
Nodes (16): address, busy, checking, createState, email, error, mobile, name (+8 more)

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
Nodes (8): createState, _index, order_screens.dart, package:provider/provider.dart, profile_screens.dart, rewards_screens.dart, state/app_state.dart, ../theme.dart

### Community 17 - "strings.dart"
Cohesion: 0.29
Nodes (6): AppLocale, hiStrings, isHindi, tr, trf, Map

### Community 18 - "handle_new_rx_page"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 19 - "package:flutter/material.dart"
Cohesion: 0.40
Nodes (4): package:carpenter_app/main.dart, package:flutter/material.dart, package:flutter_test/flutter_test.dart, main

### Community 20 - "build"
Cohesion: 0.50
Nodes (4): build, Route /consent, Route /login, Route /register

## Knowledge Gaps
- **298 isolated node(s):** `flutter_export_environment.sh script`, `+registerWithRegistry`, `DefaultFirebaseOptions`, `android`, `web` (+293 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppState` connect `AppState` to `app_state.dart`, `order_screens.dart`, `main.dart`, `theme.dart`, `profile_screens.dart`, `build`, `onboarding_screens.dart`, `home_shell.dart`, `build`?**
  _High betweenness centrality (0.167) - this node is a cross-community bridge._
- **Why does `FlutterWindow` connect `Win32Window` to `GeneratedPluginRegistrant.swift`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `FirebaseService` connect `firebase_service.dart` to `app_state.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `flutter_export_environment.sh script`, `+registerWithRegistry` to the rest of the system?**
  _299 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02666666666666667 - nodes in this community are weakly interconnected._
- **Should `AppState` be split into smaller, more focused modules?**
  _Cohesion score 0.05336951605608322 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._