# Graph Report - admin_console  (2026-07-06)

## Corpus Check
- 42 files · ~39,401 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 841 nodes · 1129 edges · 44 communities (34 shown, 10 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `94792c86`
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
- [[_COMMUNITY_leads_screen.dart|leads_screen.dart]]
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
- [[_COMMUNITY_What You Must Do When Invoked|What You Must Do When Invoked]]
- [[_COMMUNITY_creator_home_screen.dart|creator_home_screen.dart]]
- [[_COMMUNITY_party_orders_screen.dart|party_orders_screen.dart]]
- [[_COMMUNITY_graphify reference extra exports and benchmark|graphify reference: extra exports and benchmark]]
- [[_COMMUNITY_graphify reference query, path, explain|graphify reference: query, path, explain]]
- [[_COMMUNITY_graphify reference add a URL and watch a folder|graphify reference: add a URL and watch a folder]]
- [[_COMMUNITY_graphify reference commit hook and native CLAUDE.md integration|graphify reference: commit hook and native CLAUDE.md integration]]
- [[_COMMUNITY_graphify reference incremental update and cluster-only|graphify reference: incremental update and cluster-only]]
- [[_COMMUNITY_graphify reference GitHub clone and cross-repo merge|graphify reference: GitHub clone and cross-repo merge]]
- [[_COMMUNITY_graphify reference transcribe video and audio|graphify reference: transcribe video and audio]]
- [[_COMMUNITY_CLAUDE|CLAUDE.md]]
- [[_COMMUNITY_extraction-spec|extraction-spec.md]]
- [[_COMMUNITY__DashedBorderPainter|_DashedBorderPainter]]
- [[_COMMUNITY__PartyOrderDialogState|_PartyOrderDialogState]]
- [[_COMMUNITY_build|build]]
- [[_COMMUNITY_State|State]]
- [[_COMMUNITY_state.dart|state.dart]]
- [[_COMMUNITY_build|build]]

## God Nodes (most connected - your core abstractions)
1. `AdminState` - 61 edges
2. `What You Must Do When Invoked` - 12 edges
3. `/graphify` - 10 edges
4. `graphify reference: extra exports and benchmark` - 8 edges
5. `build` - 5 edges
6. `graphify reference: query, path, explain` - 5 edges
7. `_LoginScreenState` - 4 edges
8. `_AdminRouterProviderState` - 4 edges
9. `_CarpenterDetailScreenState` - 4 edges
10. `_CarpentersScreenState` - 4 edges

## Surprising Connections (you probably didn't know these)
- `buildAdminRouter` --references--> `AdminState`  [EXTRACTED]
  lib/router.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/router.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/screens/carpenters_screens.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/screens/creator_home_screen.dart → lib/state.dart
- `build` --references--> `AdminState`  [EXTRACTED]
  lib/screens/leads_screen.dart → lib/state.dart

## Import Cycles
- None detected.

## Communities (44 total, 10 thin omitted)

### Community 0 - "widgets.dart"
Cohesion: 0.02
Nodes (95): Color, actions, build, buildAdminTheme, buttonLabel, cancelLabel, cells, child (+87 more)

### Community 1 - "state.dart"
Cohesion: 0.02
Nodes (94): dart:async, firebase_service.dart, addGift, addOffer, addPartyOrder, adminEmail, appBuildNumber, appDownloadUrl (+86 more)

### Community 2 - "models.dart"
Cohesion: 0.03
Nodes (66): int get, AdminGift, AdminOffer, amount, approvedAmount, area, audioUrl, bankName (+58 more)

### Community 3 - "firebase_service.dart"
Cohesion: 0.04
Nodes (48): bool get, FirebaseAuth, FirebaseFirestore, addGift, addOffer, addPartyOrder, AdminFirebaseService, approveCarpenter (+40 more)

### Community 4 - "order_detail_screen.dart"
Cohesion: 0.06
Nodes (33): createState, effectiveStatus, fulfilledGateErrors, _headerCard, _horizontal, _initRowsIfNeeded, _invoiceCard, isMobile (+25 more)

### Community 5 - "settings_screen.dart"
Cohesion: 0.07
Nodes (37): AdminConsoleApp, _AdminConsoleAppState, CarpenterDetailScreen, _CarpenterDetailScreenState, LocationsScreen, _LocationsScreenState, _NewOfferDialog, _NewOfferDialogState (+29 more)

### Community 6 - "offers_screens.dart"
Cohesion: 0.06
Nodes (34): DateTime, activityFilter, activitySince, allCarpenters, app, bannerUrl, build, _CarpenterPicker (+26 more)

### Community 7 - "orders_screens.dart"
Cohesion: 0.07
Nodes (30): AdminOrder, build, createState, dateFilter, filterAndSortOrders, list, now, onDateFilter (+22 more)

### Community 8 - "gifts_screens.dart"
Cohesion: 0.09
Nodes (23): ../cloudinary_service.dart, _close, createState, description, GiftDetailScreen, giftId, GiftsScreen, _GiftsScreenState (+15 more)

### Community 9 - "router.dart"
Cohesion: 0.09
Nodes (23): GoRouter?, AdminRouterProvider, _AdminRouterProviderState, build, buildAdminRouter, createState, _router, login_screen.dart (+15 more)

### Community 10 - "main.dart"
Cohesion: 0.17
Nodes (11): firebase_options.dart, _app, build, createState, initializeApp, initState, main, package:cloud_firestore/cloud_firestore.dart (+3 more)

### Community 11 - "StatelessWidget"
Cohesion: 0.10
Nodes (20): OfferDetailScreen, OrderStatusStepper, _StatusActions, OrderFilterBar, AppCard, AudienceBadge, Avatar, BackLink (+12 more)

### Community 12 - "AdminState"
Cohesion: 0.22
Nodes (11): ChangeNotifier, build, build, build, build, AdminShell, build, AdminState (+3 more)

### Community 13 - "shell.dart"
Cohesion: 0.14
Nodes (13): IconData, child, createState, _hovering, icon, label, location, onTap (+5 more)

### Community 14 - "leads_screen.dart"
Cohesion: 0.15
Nodes (13): AdminLead, app, build, createState, lead, _LeadCard, LeadsScreen, _LeadsScreenState (+5 more)

### Community 15 - "cloudinary_service.dart"
Cohesion: 0.11
Nodes (17): dart:convert, dart:typed_data, CloudinaryService, cloudName, _compressImage, _imageExtensions, instance, _jpegQuality (+9 more)

### Community 16 - "notifications_screen.dart"
Cohesion: 0.18
Nodes (11): body, build, createState, NotificationsScreen, _NotificationsScreenState, _page, _perPage, sending (+3 more)

### Community 17 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 18 - "carpenter_detail_screen.dart"
Cohesion: 0.12
Nodes (16): carpenterId, createState, icon, label, _leadsTab, _MiniStat, _ordersTab, _partyTab (+8 more)

### Community 19 - "carpenters_screens.dart"
Cohesion: 0.11
Nodes (18): Carpenter, build, carpenter, CarpentersScreen, _CarpentersScreenState, _CarpenterTile, createState, dispose (+10 more)

### Community 20 - "dashboard_screen.dart"
Cohesion: 0.09
Nodes (23): createState, DashboardScreen, _DashboardScreenState, dateFilter, _filterPartyOrders, onDateFilter, onSortBy, onStatusFilter (+15 more)

### Community 21 - "locations_screen.dart"
Cohesion: 0.20
Nodes (9): build, createState, _defaultCenter, mapController, selected, _int, models.dart, package:flutter_map/flutter_map.dart (+1 more)

### Community 22 - "package:flutter/material.dart"
Cohesion: 0.40
Nodes (4): package:admin_console/main.dart, package:flutter/material.dart, package:flutter_test/flutter_test.dart, main

### Community 26 - "What You Must Do When Invoked"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 27 - "creator_home_screen.dart"
Cohesion: 0.07
Nodes (27): PartyOrder, amount, build, carpenterId, carpenterName, carpSearch, createState, CreatorHomeScreen (+19 more)

### Community 28 - "party_orders_screen.dart"
Cohesion: 0.07
Nodes (30): approveAmt, _approveCard, _approvePrefilled, build, busy, commissionCtl, createState, dispose (+22 more)

### Community 29 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 30 - "graphify reference: query, path, explain"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 31 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 32 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 33 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

### Community 41 - "State"
Cohesion: 0.18
Nodes (11): Redemption, app, build, createState, _page, _perPage, redemption, _RedemptionCard (+3 more)

### Community 42 - "state.dart"
Cohesion: 0.29
Nodes (7): createState, email, LoginScreen, _LoginScreenState, password, state.dart, widgets.dart

### Community 43 - "build"
Cohesion: 0.29
Nodes (6): currentPlatform, DefaultFirebaseOptions, web, package:firebase_core/firebase_core.dart, static const FirebaseOptions, static FirebaseOptions get

## Knowledge Gaps
- **596 isolated node(s):** `CloudinaryService`, `_imageExtensions`, `_pdfExtensions`, `_maxDimension`, `_jpegQuality` (+591 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AdminState` connect `AdminState` to `state.dart`, `order_detail_screen.dart`, `settings_screen.dart`, `offers_screens.dart`, `orders_screens.dart`, `gifts_screens.dart`, `router.dart`, `main.dart`, `StatelessWidget`, `shell.dart`, `leads_screen.dart`, `notifications_screen.dart`, `carpenter_detail_screen.dart`, `carpenters_screens.dart`, `dashboard_screen.dart`, `locations_screen.dart`, `creator_home_screen.dart`, `party_orders_screen.dart`, `_PartyOrderDialogState`, `build`, `State`, `state.dart`?**
  _High betweenness centrality (0.148) - this node is a cross-community bridge._
- **Why does `AdminFirebaseService` connect `firebase_service.dart` to `state.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `PartyOrder` connect `creator_home_screen.dart` to `models.dart`, `party_orders_screen.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `CloudinaryService`, `_imageExtensions`, `_pdfExtensions` to the rest of the system?**
  _596 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `widgets.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.020833333333333332 - nodes in this community are weakly interconnected._
- **Should `state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.021052631578947368 - nodes in this community are weakly interconnected._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.029850746268656716 - nodes in this community are weakly interconnected._