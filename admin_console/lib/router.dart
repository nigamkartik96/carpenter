import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'shell.dart';
import 'state.dart';
import 'widgets.dart';
import 'screens/dashboard_screen.dart';
import 'screens/carpenters_screens.dart';
import 'screens/carpenter_detail_screen.dart';
import 'screens/locations_screen.dart';
import 'screens/orders_screens.dart';
import 'screens/order_detail_screen.dart';
import 'screens/offers_screens.dart';
import 'screens/gifts_screens.dart';
import 'screens/redemptions_screen.dart';
import 'screens/leads_screen.dart';
import 'screens/notifications_screen.dart';

/// Every top-level sidebar destination, in the same order the sidebar
/// renders them -- path, title, and icon together so AdminShell doesn't
/// need a separate index to look any of that up.
const List<(String, String, IconData)> adminSections = [
  ('/', 'Dashboard', Icons.dashboard_outlined),
  ('/carpenters', 'Carpenters', Icons.people_outline),
  ('/locations', 'Locations', Icons.map_outlined),
  ('/orders', 'Orders', Icons.inventory_2_outlined),
  ('/offers', 'Offers', Icons.local_offer_outlined),
  ('/gifts', 'Gift catalog', Icons.card_giftcard_outlined),
  ('/redemptions', 'Redemptions', Icons.assignment_outlined),
  ('/leads', 'Leads', Icons.lightbulb_outline),
  ('/notifications', 'Notifications', Icons.notifications_outlined),
];

GoRouter buildAdminRouter(AdminState app) {
  return GoRouter(
    refreshListenable: app,
    initialLocation: '/splash',
    redirect: (context, state) {
      // Wait for tryResumeSession() (called from main.dart) to finish
      // before committing to /login vs the dashboard, otherwise a logged-in
      // admin reloading the page would flash the login screen first.
      if (!app.sessionChecked) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }
      if (state.matchedLocation == '/splash') return app.loggedIn ? '/' : '/login';
      final loggedIn = app.loggedIn;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(
            path: '/carpenters',
            builder: (context, state) => const CarpentersScreen(),
            routes: [
              GoRoute(path: ':id', builder: (context, state) => CarpenterDetailScreen(carpenterId: state.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: '/locations', builder: (context, state) => const LocationsScreen()),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
            routes: [
              GoRoute(path: ':id', builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: '/offers', builder: (context, state) => const OffersScreen()),
          GoRoute(path: '/gifts', builder: (context, state) => const GiftsScreen()),
          GoRoute(path: '/redemptions', builder: (context, state) => const RedemptionsScreen()),
          GoRoute(path: '/leads', builder: (context, state) => const LeadsScreen()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
        ],
      ),
    ],
  );
}

/// Builds the router once, watching [AdminState] so login/logout (which
/// changes `loggedIn`) re-evaluates the redirect above.
class AdminRouterProvider extends StatefulWidget {
  const AdminRouterProvider({super.key});

  @override
  State<AdminRouterProvider> createState() => _AdminRouterProviderState();
}

class _AdminRouterProviderState extends State<AdminRouterProvider> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    _router ??= buildAdminRouter(app);
    return MaterialApp.router(
      title: 'CarpenterHub Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAdminTheme(),
      routerConfig: _router,
    );
  }
}
