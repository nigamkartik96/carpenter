# Graph Report - admin_console  (2026-07-19)

## Corpus Check
- 33 files · ~29,875 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 801 nodes · 1104 edges · 33 communities (27 shown, 6 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6aca94b3`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- widgets.dart
- state.dart
- models.dart
- firebase_service.dart
- offers_screens.dart
- order_detail_screen.dart
- orders_screens.dart
- party_orders_screen.dart
- creator_home_screen.dart
- router.dart
- dashboard_screen.dart
- gifts_screens.dart
- main.dart
- StatelessWidget
- settings_screen.dart
- carpenters_screens.dart
- carpenter_detail_screen.dart
- cloudinary_service.dart
- State
- leads_screen.dart
- shell.dart
- redemptions_screen.dart
- locations_screen.dart
- notifications_screen.dart
- AdminState
- manifest.json
- package:provider/provider.dart
- package:flutter/material.dart
- _DashedBorderPainter
- build
- StatChip
- State
- build

## God Nodes (most connected - your core abstractions)
1. `AdminState` - 64 edges
2. `build` - 5 edges
3. `_LoginScreenState` - 4 edges
4. `_AdminRouterProviderState` - 4 edges
5. `_CarpenterDetailScreenState` - 4 edges
6. `_CarpentersScreenState` - 4 edges
7. `_CreatorHomeScreenState` - 4 edges
8. `_PartyOrderDialogState` - 4 edges
9. `_DashboardScreenState` - 4 edges
10. `_GiftsScreenState` - 4 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/login_screen.dart → lib/state.dart
- `buildAdminRouter` --references--> `AdminState`  [EXTRACTED]
  lib/router.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/router.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/screens/carpenters_screens.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/screens/creator_home_screen.dart → lib/state.dart

## Import Cycles
- None detected.

## Communities (33 total, 6 thin omitted)

### Community 0 - "widgets.dart"
Cohesion: 0.02
Nodes (95): Color, actions, build, buildAdminTheme, buttonLabel, cancelLabel, cells, child (+87 more)

### Community 1 - "state.dart"
Cohesion: 0.02
Nodes (96): dart:async, firebase_service.dart, addGift, addOffer, addOrderComment, addPartyOrder, adminEmail, appBuildNumber (+88 more)

### Community 2 - "models.dart"
Cohesion: 0.03
Nodes (71): int get, AdminGift, AdminOffer, amount, approvedAmount, area, audioUrl, authorName (+63 more)

### Community 3 - "firebase_service.dart"
Cohesion: 0.04
Nodes (50): bool get, FirebaseAuth, FirebaseFirestore, addGift, addOffer, addOrderComment, addPartyOrder, AdminFirebaseService (+42 more)

### Community 4 - "offers_screens.dart"
Cohesion: 0.07
Nodes (28): DateTime, activityFilter, activitySince, allCarpenters, app, bannerUrl, category, _close (+20 more)

### Community 5 - "order_detail_screen.dart"
Cohesion: 0.05
Nodes (42): _bubble, _comments, _CommentsCard, _CommentsCardState, createState, dispose, effectiveStatus, _fmtWhen (+34 more)

### Community 6 - "orders_screens.dart"
Cohesion: 0.07
Nodes (30): AdminOrder, build, createState, dateFilter, filterAndSortOrders, list, now, onDateFilter (+22 more)

### Community 7 - "party_orders_screen.dart"
Cohesion: 0.07
Nodes (30): approveAmt, _approveCard, _approvePrefilled, build, busy, commissionCtl, createState, dispose (+22 more)

### Community 8 - "creator_home_screen.dart"
Cohesion: 0.07
Nodes (29): PartyOrder, amount, build, carpenterId, carpenterName, carpSearch, createState, CreatorHomeScreen (+21 more)

### Community 9 - "router.dart"
Cohesion: 0.09
Nodes (23): GoRouter?, AdminRouterProvider, _AdminRouterProviderState, build, buildAdminRouter, createState, _router, login_screen.dart (+15 more)

### Community 10 - "dashboard_screen.dart"
Cohesion: 0.09
Nodes (23): createState, DashboardScreen, _DashboardScreenState, dateFilter, _filterPartyOrders, onDateFilter, onSortBy, onStatusFilter (+15 more)

### Community 11 - "gifts_screens.dart"
Cohesion: 0.08
Nodes (25): ../cloudinary_service.dart, build, _close, createState, description, GiftDetailScreen, giftId, GiftsScreen (+17 more)

### Community 12 - "main.dart"
Cohesion: 0.11
Nodes (18): firebase_options.dart, currentPlatform, DefaultFirebaseOptions, web, AdminConsoleApp, _AdminConsoleAppState, _app, build (+10 more)

### Community 13 - "StatelessWidget"
Cohesion: 0.10
Nodes (20): OfferDetailScreen, OrderStatusStepper, _StatusActions, OrderFilterBar, AppCard, AudienceBadge, Avatar, BackLink (+12 more)

### Community 14 - "settings_screen.dart"
Cohesion: 0.11
Nodes (19): amount, app, build, buildNumber, converted, createState, didUpdateWidget, downloadUrl (+11 more)

### Community 15 - "carpenters_screens.dart"
Cohesion: 0.06
Nodes (35): IconData, Carpenter, build, carpenter, CarpentersScreen, _CarpentersScreenState, _CarpenterTile, createState (+27 more)

### Community 16 - "carpenter_detail_screen.dart"
Cohesion: 0.11
Nodes (18): CarpenterDetailScreen, _CarpenterDetailScreenState, carpenterId, createState, icon, label, _leadsTab, _MiniStat (+10 more)

### Community 17 - "cloudinary_service.dart"
Cohesion: 0.11
Nodes (17): dart:convert, dart:typed_data, CloudinaryService, cloudName, _compressImage, _imageExtensions, instance, _jpegQuality (+9 more)

### Community 19 - "leads_screen.dart"
Cohesion: 0.15
Nodes (13): AdminLead, app, build, createState, lead, _LeadCard, LeadsScreen, _LeadsScreenState (+5 more)

### Community 21 - "redemptions_screen.dart"
Cohesion: 0.18
Nodes (11): Redemption, app, createState, _page, _perPage, redemption, _RedemptionCard, RedemptionsScreen (+3 more)

### Community 22 - "locations_screen.dart"
Cohesion: 0.20
Nodes (10): createState, _defaultCenter, LocationsScreen, _LocationsScreenState, mapController, selected, _int, package:flutter_map/flutter_map.dart (+2 more)

### Community 23 - "notifications_screen.dart"
Cohesion: 0.18
Nodes (11): body, build, createState, NotificationsScreen, _NotificationsScreenState, _page, _perPage, sending (+3 more)

### Community 24 - "AdminState"
Cohesion: 0.20
Nodes (12): ChangeNotifier, build, build, build, build, initState, _send, build (+4 more)

### Community 25 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 26 - "package:provider/provider.dart"
Cohesion: 0.25
Nodes (8): build, createState, email, LoginScreen, _LoginScreenState, password, package:provider/provider.dart, state.dart

### Community 27 - "package:flutter/material.dart"
Cohesion: 0.40
Nodes (4): package:admin_console/main.dart, package:flutter/material.dart, package:flutter_test/flutter_test.dart, main

### Community 31 - "State"
Cohesion: 0.20
Nodes (14): _CarpenterPicker, _CarpenterPickerState, _NewOfferDialog, _NewOfferDialogState, OffersScreen, _OffersScreenState, _AppVersionForm, _AppVersionFormState (+6 more)

## Knowledge Gaps
- **570 isolated node(s):** `CloudinaryService`, `_imageExtensions`, `_pdfExtensions`, `_maxDimension`, `_jpegQuality` (+565 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AdminState` connect `AdminState` to `state.dart`, `offers_screens.dart`, `order_detail_screen.dart`, `orders_screens.dart`, `party_orders_screen.dart`, `creator_home_screen.dart`, `router.dart`, `dashboard_screen.dart`, `gifts_screens.dart`, `main.dart`, `StatelessWidget`, `settings_screen.dart`, `carpenters_screens.dart`, `carpenter_detail_screen.dart`, `leads_screen.dart`, `redemptions_screen.dart`, `locations_screen.dart`, `notifications_screen.dart`, `package:provider/provider.dart`, `State`, `build`?**
  _High betweenness centrality (0.173) - this node is a cross-community bridge._
- **Why does `AdminFirebaseService` connect `firebase_service.dart` to `state.dart`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `AdminOrder` connect `orders_screens.dart` to `models.dart`, `order_detail_screen.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **What connects `CloudinaryService`, `_imageExtensions`, `_pdfExtensions` to the rest of the system?**
  _570 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `widgets.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.020833333333333332 - nodes in this community are weakly interconnected._
- **Should `state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.020618556701030927 - nodes in this community are weakly interconnected._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.027777777777777776 - nodes in this community are weakly interconnected._