# Graph Report - admin_console  (2026-08-03)

## Corpus Check
- 35 files · ~32,493 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 849 nodes · 1169 edges · 32 communities (27 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f6b9f5a6`
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
- AdminState
- AdminState
- manifest.json
- package:provider/provider.dart
- package:flutter/material.dart
- _DashedBorderPainter
- build
- feedback_screen.dart
- firebase_options.dart

## God Nodes (most connected - your core abstractions)
1. `AdminState` - 68 edges
2. `build` - 5 edges
3. `_LoginScreenState` - 4 edges
4. `_AdminRouterProviderState` - 4 edges
5. `_CarpenterDetailScreenState` - 4 edges
6. `_CarpentersScreenState` - 4 edges
7. `_CreatorHomeScreenState` - 4 edges
8. `_RecordPaymentDialogState` - 4 edges
9. `_PartyOrderDialogState` - 4 edges
10. `_DashboardScreenState` - 4 edges

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
  lib/screens/leads_screen.dart → lib/state.dart

## Import Cycles
- None detected.

## Communities (32 total, 5 thin omitted)

### Community 0 - "widgets.dart"
Cohesion: 0.02
Nodes (98): Color, actions, build, buildAdminTheme, buttonLabel, cancelLabel, cells, child (+90 more)

### Community 1 - "state.dart"
Cohesion: 0.02
Nodes (100): dart:async, firebase_service.dart, addGift, addOffer, addOrderComment, addPartyOrder, adminEmail, appBuildNumber (+92 more)

### Community 2 - "models.dart"
Cohesion: 0.03
Nodes (79): AdminGift, AdminOffer, amount, approvedAmount, area, at, audioUrl, authorName (+71 more)

### Community 3 - "firebase_service.dart"
Cohesion: 0.04
Nodes (52): bool get, FirebaseAuth, FirebaseFirestore, addGift, addOffer, addOrderComment, addPartyOrder, AdminFirebaseService (+44 more)

### Community 4 - "offers_screens.dart"
Cohesion: 0.06
Nodes (34): DateTime, activityFilter, activitySince, allCarpenters, app, bannerUrl, build, category (+26 more)

### Community 5 - "order_detail_screen.dart"
Cohesion: 0.05
Nodes (40): amountCtrl, _bubble, build, _comments, createState, dispose, effectiveStatus, _field (+32 more)

### Community 6 - "orders_screens.dart"
Cohesion: 0.06
Nodes (31): AdminOrder, build, createState, dateFilter, filterAndSortOrders, list, now, onDateFilter (+23 more)

### Community 7 - "party_orders_screen.dart"
Cohesion: 0.07
Nodes (29): PartyOrder, approveAmt, _approveCard, _approvePrefilled, build, busy, createState, dispose (+21 more)

### Community 8 - "creator_home_screen.dart"
Cohesion: 0.06
Nodes (37): int get, amount, _amt, carpenterId, carpenterName, carpSearch, createState, CreatorHomeScreen (+29 more)

### Community 9 - "router.dart"
Cohesion: 0.08
Nodes (24): GoRouter?, AdminRouterProvider, _AdminRouterProviderState, build, buildAdminRouter, createState, _router, login_screen.dart (+16 more)

### Community 10 - "dashboard_screen.dart"
Cohesion: 0.05
Nodes (41): build, carpenterId, createState, _Detail, label, _leadsTab, _ordersTab, _partyTab (+33 more)

### Community 11 - "gifts_screens.dart"
Cohesion: 0.18
Nodes (11): body, build, createState, NotificationsScreen, _NotificationsScreenState, _page, _perPage, sending (+3 more)

### Community 12 - "main.dart"
Cohesion: 0.17
Nodes (11): firebase_options.dart, _app, build, createState, initializeApp, initState, main, package:cloud_firestore/cloud_firestore.dart (+3 more)

### Community 13 - "StatelessWidget"
Cohesion: 0.10
Nodes (21): _CreatorOrderCard, _PartyStatusChip, OfferDetailScreen, OrderStatusStepper, _StatusActions, AppCard, AudienceBadge, Avatar (+13 more)

### Community 14 - "settings_screen.dart"
Cohesion: 0.07
Nodes (41): AdminConsoleApp, _AdminConsoleAppState, CarpenterDetailScreen, _CarpenterDetailScreenState, DashboardScreen, _DashboardScreenState, _CarpenterPicker, _CarpenterPickerState (+33 more)

### Community 15 - "carpenters_screens.dart"
Cohesion: 0.06
Nodes (32): IconData, Carpenter, build, carpenter, CarpentersScreen, _CarpentersScreenState, _CarpenterTile, createState (+24 more)

### Community 16 - "carpenter_detail_screen.dart"
Cohesion: 0.08
Nodes (25): ../cloudinary_service.dart, build, _close, createState, description, GiftDetailScreen, giftId, GiftsScreen (+17 more)

### Community 17 - "cloudinary_service.dart"
Cohesion: 0.08
Nodes (24): dart:convert, dart:typed_data, CloudinaryService, cloudName, _compressImage, _imageExtensions, instance, _jpegQuality (+16 more)

### Community 19 - "leads_screen.dart"
Cohesion: 0.17
Nodes (12): AdminLead, app, build, createState, lead, _LeadCard, LeadsScreen, _LeadsScreenState (+4 more)

### Community 21 - "redemptions_screen.dart"
Cohesion: 0.18
Nodes (11): Redemption, app, build, createState, _page, _perPage, redemption, _RedemptionCard (+3 more)

### Community 22 - "locations_screen.dart"
Cohesion: 0.18
Nodes (11): build, createState, _defaultCenter, LocationsScreen, _LocationsScreenState, mapController, selected, _int (+3 more)

### Community 23 - "AdminState"
Cohesion: 0.33
Nodes (6): ChangeNotifier, build, build, initState, _send, AdminState

### Community 25 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 26 - "package:provider/provider.dart"
Cohesion: 0.25
Nodes (8): build, createState, email, LoginScreen, _LoginScreenState, password, package:provider/provider.dart, widgets.dart

### Community 27 - "package:flutter/material.dart"
Cohesion: 0.40
Nodes (4): package:admin_console/main.dart, package:flutter/material.dart, package:flutter_test/flutter_test.dart, main

### Community 31 - "feedback_screen.dart"
Cohesion: 0.17
Nodes (12): FeedbackEntry, app, createState, entry, _FeedbackCard, FeedbackScreen, _FeedbackScreenState, _openOnly (+4 more)

### Community 32 - "firebase_options.dart"
Cohesion: 0.29
Nodes (6): currentPlatform, DefaultFirebaseOptions, web, package:firebase_core/firebase_core.dart, static const FirebaseOptions, static FirebaseOptions get

## Knowledge Gaps
- **605 isolated node(s):** `CloudinaryService`, `_imageExtensions`, `_pdfExtensions`, `_maxDimension`, `_jpegQuality` (+600 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AdminState` connect `AdminState` to `state.dart`, `offers_screens.dart`, `order_detail_screen.dart`, `orders_screens.dart`, `party_orders_screen.dart`, `creator_home_screen.dart`, `router.dart`, `dashboard_screen.dart`, `gifts_screens.dart`, `main.dart`, `StatelessWidget`, `settings_screen.dart`, `carpenters_screens.dart`, `carpenter_detail_screen.dart`, `leads_screen.dart`, `redemptions_screen.dart`, `locations_screen.dart`, `package:provider/provider.dart`, `feedback_screen.dart`?**
  _High betweenness centrality (0.182) - this node is a cross-community bridge._
- **Why does `AdminFirebaseService` connect `firebase_service.dart` to `state.dart`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Why does `AdminOrder` connect `orders_screens.dart` to `models.dart`, `order_detail_screen.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **What connects `CloudinaryService`, `_imageExtensions`, `_pdfExtensions` to the rest of the system?**
  _605 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `widgets.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.020202020202020204 - nodes in this community are weakly interconnected._
- **Should `state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.019801980198019802 - nodes in this community are weakly interconnected._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.025 - nodes in this community are weakly interconnected._