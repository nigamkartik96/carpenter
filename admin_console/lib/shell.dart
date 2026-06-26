import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state.dart';
import 'widgets.dart';
import 'screens/dashboard_screen.dart';
import 'screens/carpenters_screens.dart';
import 'screens/locations_screen.dart';
import 'screens/orders_screens.dart';
import 'screens/offers_screens.dart';
import 'screens/gifts_screens.dart';
import 'screens/redemptions_screen.dart';
import 'screens/leads_screen.dart';
import 'screens/notifications_screen.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  static const items = [
    ('Dashboard', Icons.dashboard_outlined),
    ('Carpenters', Icons.people_outline),
    ('Locations', Icons.map_outlined),
    ('Orders', Icons.inventory_2_outlined),
    ('Offers', Icons.local_offer_outlined),
    ('Gift catalog', Icons.card_giftcard_outlined),
    ('Redemptions', Icons.assignment_outlined),
    ('Leads', Icons.lightbulb_outline),
    ('Notifications', Icons.notifications_outlined),
  ];

  Widget _sidebarContent(BuildContext context, AdminState app, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 24, 18, 16),
          child: Row(
            children: [
              Icon(Icons.handyman, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('CarpenterHub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        ...List.generate(items.length, (i) {
          final selected = i == index;
          return Material(
            color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
            child: ListTile(
              onTap: () {
                app.goToScreen(i);
                // On mobile this sidebar lives inside a Drawer -- close it
                // after navigating, otherwise the drawer stays open over
                // the newly selected page. Safe no-op on the desktop
                // layout, where there's no drawer route to pop.
                Navigator.maybePop(context);
              },
              leading: Icon(items[i].$2, color: Colors.white70, size: 18),
              title: Text(items[i].$1, style: const TextStyle(color: Colors.white, fontSize: 13)),
              dense: true,
            ),
          );
        }),
        const Spacer(),
        if (app.adminEmail != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Text(app.adminEmail!, style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
          ),
        Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: () => app.logout(),
            leading: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            dense: true,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final index = app.screenIndex;
    final pages = const [
      DashboardScreen(),
      CarpentersScreen(),
      LocationsScreen(),
      OrdersScreen(),
      OffersScreen(),
      GiftsScreen(),
      RedemptionsScreen(),
      LeadsScreen(),
      NotificationsScreen(),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 800;
      final contentPadding = isMobile ? 12.0 : 24.0;

      final body = Column(
        children: [
          if (app.lastError != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(app.lastError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                  GestureDetector(onTap: app.clearError, child: const Icon(Icons.close, size: 16, color: Colors.red)),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(contentPadding),
              child: pages[index],
            ),
          ),
        ],
      );

      if (isMobile) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1F1A16),
            title: Text(items[index].$1, style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          drawer: Drawer(
            backgroundColor: const Color(0xFF1F1A16),
            child: SafeArea(child: _sidebarContent(context, app, index)),
          ),
          body: body,
        );
      }

      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 220,
              color: const Color(0xFF1F1A16),
              child: _sidebarContent(context, app, index),
            ),
            Expanded(child: body),
          ],
        ),
      );
    });
  }
}
