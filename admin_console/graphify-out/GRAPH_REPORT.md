# Graph Report - admin_console  (2026-07-03)

## Corpus Check
- 27 files · ~19,445 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 535 nodes · 746 edges · 26 communities (23 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `eb1daa33`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_widgets.dart|widgets.dart]]
- [[_COMMUNITY_state.dart|state.dart]]
- [[_COMMUNITY_models.dart|models.dart]]
- [[_COMMUNITY_firebase_service.dart|firebase_service.dart]]
- [[_COMMUNITY_order_detail_screen.dart|order_detail_screen.dart]]
- [[_COMMUNITY_settings_screen.dart|settings_screen.dart]]
- [[_COMMUNITY_offers_screens.dart|offers_screens.dart]]
- [[_COMMUNITY_orders_screens.dart|orders_screens.dart]]
- [[_COMMUNITY_gifts_screens.dart|gifts_screens.dart]]
- [[_COMMUNITY_router.dart|router.dart]]
- [[_COMMUNITY_main.dart|main.dart]]
- [[_COMMUNITY_StatelessWidget|StatelessWidget]]
- [[_COMMUNITY_AdminState|AdminState]]
- [[_COMMUNITY_shell.dart|shell.dart]]
- [[_COMMUNITY_packageproviderprovider.dart|package:provider/provider.dart]]
- [[_COMMUNITY_cloudinary_service.dart|cloudinary_service.dart]]
- [[_COMMUNITY_notifications_screen.dart|notifications_screen.dart]]
- [[_COMMUNITY_manifest.json|manifest.json]]
- [[_COMMUNITY_carpenter_detail_screen.dart|carpenter_detail_screen.dart]]
- [[_COMMUNITY_carpenters_screens.dart|carpenters_screens.dart]]
- [[_COMMUNITY_dashboard_screen.dart|dashboard_screen.dart]]
- [[_COMMUNITY_locations_screen.dart|locations_screen.dart]]
- [[_COMMUNITY_packagefluttermaterial.dart|package:flutter/material.dart]]
- [[_COMMUNITY_admin_console|admin_console]]
- [[_COMMUNITY_CLAUDE|CLAUDE.md]]
- [[_COMMUNITY_StatChip|StatChip]]

## God Nodes (most connected - your core abstractions)
1. `AdminState` - 52 edges
2. `build` - 5 edges
3. `_LoginScreenState` - 4 edges
4. `_AdminRouterProviderState` - 4 edges
5. `_DashboardScreenState` - 4 edges
6. `_NewGiftDialogState` - 4 edges
7. `_LocationsScreenState` - 4 edges
8. `_NotificationsScreenState` - 4 edges
9. `_NewOfferDialogState` - 4 edges
10. `_OrderDetailScreenState` - 4 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/login_screen.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/router.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/screens/carpenters_screens.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/screens/locations_screen.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/screens/notifications_screen.dart → lib/state.dart

## Import Cycles
- None detected.

## Communities (26 total, 3 thin omitted)

### Community 0 - "widgets.dart"
Cohesion: 0.03
Nodes (60): Color, build, buildAdminTheme, cancelLabel, child, children, color, confirmDialog (+52 more)

### Community 1 - "state.dart"
Cohesion: 0.03
Nodes (60): dart:async, firebase_service.dart, addGift, addOffer, adminEmail, approve, broadcastNotification, broadcasts (+52 more)

### Community 2 - "models.dart"
Cohesion: 0.04
Nodes (53): int get, AdminGift, AdminLead, AdminOffer, amount, area, audioUrl, bannerUrl (+45 more)

### Community 3 - "firebase_service.dart"
Cohesion: 0.05
Nodes (39): bool get, FirebaseAuth, FirebaseFirestore, addGift, addOffer, AdminFirebaseService, approveCarpenter, auth (+31 more)

### Community 4 - "order_detail_screen.dart"
Cohesion: 0.06
Nodes (32): AdminOrder, createState, effectiveStatus, fulfilledGateErrors, _headerCard, _horizontal, _initRowsIfNeeded, _invoiceCard (+24 more)

### Community 5 - "settings_screen.dart"
Cohesion: 0.09
Nodes (29): LoginScreen, _LoginScreenState, LocationsScreen, _LocationsScreenState, _CarpenterPicker, _CarpenterPickerState, _NewOfferDialog, _NewOfferDialogState (+21 more)

### Community 6 - "offers_screens.dart"
Cohesion: 0.07
Nodes (28): DateTime, activityFilter, activitySince, allCarpenters, app, bannerUrl, build, category (+20 more)

### Community 7 - "orders_screens.dart"
Cohesion: 0.08
Nodes (26): build, createState, dateFilter, filterAndSortOrders, list, now, onDateFilter, onSortBy (+18 more)

### Community 8 - "gifts_screens.dart"
Cohesion: 0.09
Nodes (22): ../cloudinary_service.dart, build, _close, createState, description, GiftDetailScreen, giftId, GiftsScreen (+14 more)

### Community 9 - "router.dart"
Cohesion: 0.10
Nodes (21): GoRouter?, AdminRouterProvider, _AdminRouterProviderState, build, buildAdminRouter, createState, _router, login_screen.dart (+13 more)

### Community 10 - "main.dart"
Cohesion: 0.11
Nodes (17): firebase_options.dart, currentPlatform, DefaultFirebaseOptions, web, AdminConsoleApp, _AdminConsoleAppState, _app, build (+9 more)

### Community 11 - "StatelessWidget"
Cohesion: 0.12
Nodes (17): OfferDetailScreen, OffersScreen, OrderStatusStepper, _StatusActions, AppCard, AudienceBadge, Avatar, BackLink (+9 more)

### Community 12 - "AdminState"
Cohesion: 0.21
Nodes (12): ChangeNotifier, build, build, build, LeadsScreen, leadStatuses, leadTerminalStatuses, build (+4 more)

### Community 13 - "shell.dart"
Cohesion: 0.15
Nodes (12): AdminShell, build, child, createState, _hovering, icon, label, location (+4 more)

### Community 14 - "package:provider/provider.dart"
Cohesion: 0.20
Nodes (10): build, createState, email, password, build, RedemptionsScreen, redemptionStatuses, package:provider/provider.dart (+2 more)

### Community 15 - "cloudinary_service.dart"
Cohesion: 0.18
Nodes (10): dart:convert, dart:typed_data, CloudinaryService, cloudName, instance, uploadBytes, uploadPreset, package:http/http.dart (+2 more)

### Community 16 - "notifications_screen.dart"
Cohesion: 0.20
Nodes (10): body, build, createState, NotificationsScreen, _NotificationsScreenState, sending, submitted, targetTier (+2 more)

### Community 17 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 18 - "carpenter_detail_screen.dart"
Cohesion: 0.22
Nodes (8): IconData, CarpenterDetailScreen, carpenterId, icon, label, _MiniStat, value, package:url_launcher/url_launcher.dart

### Community 19 - "carpenters_screens.dart"
Cohesion: 0.22
Nodes (8): Carpenter, build, carpenter, CarpentersScreen, _CarpenterTile, onTap, orderCount, VoidCallback

### Community 20 - "dashboard_screen.dart"
Cohesion: 0.25
Nodes (8): createState, DashboardScreen, _DashboardScreenState, dateFilter, sortBy, statusFilter, orders_screens.dart, package:go_router/go_router.dart

### Community 21 - "locations_screen.dart"
Cohesion: 0.22
Nodes (8): build, createState, _defaultCenter, mapController, selected, _int, package:flutter_map/flutter_map.dart, package:latlong2/latlong.dart

### Community 22 - "package:flutter/material.dart"
Cohesion: 0.40
Nodes (4): package:admin_console/main.dart, package:flutter/material.dart, package:flutter_test/flutter_test.dart, main

## Knowledge Gaps
- **358 isolated node(s):** `CloudinaryService`, `instance`, `cloudName`, `uploadPreset`, `uploadBytes` (+353 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AdminState` connect `AdminState` to `state.dart`, `order_detail_screen.dart`, `settings_screen.dart`, `offers_screens.dart`, `orders_screens.dart`, `gifts_screens.dart`, `router.dart`, `main.dart`, `StatelessWidget`, `shell.dart`, `package:provider/provider.dart`, `notifications_screen.dart`, `carpenter_detail_screen.dart`, `carpenters_screens.dart`, `dashboard_screen.dart`, `locations_screen.dart`?**
  _High betweenness centrality (0.198) - this node is a cross-community bridge._
- **Why does `AdminFirebaseService` connect `firebase_service.dart` to `state.dart`?**
  _High betweenness centrality (0.062) - this node is a cross-community bridge._
- **Why does `_double` connect `models.dart` to `state.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `CloudinaryService`, `instance`, `cloudName` to the rest of the system?**
  _358 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `widgets.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03278688524590164 - nodes in this community are weakly interconnected._
- **Should `state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03278688524590164 - nodes in this community are weakly interconnected._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._