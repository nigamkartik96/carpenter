import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'state.dart';
import 'widgets.dart';

/// Persistent sidebar/app-bar chrome around whichever section is
/// currently routed -- [child] is supplied by go_router's ShellRoute, and
/// [location] is the current URL path so the sidebar can highlight the
/// active item and detail routes (e.g. /orders/abc123) still show
/// "Orders" as selected.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  int get _selectedIndex {
    final i = adminSections.indexWhere((s) => s.$1 != '/' && location.startsWith(s.$1));
    if (i != -1) return i;
    return location == '/' ? 0 : -1;
  }

  Widget _sidebarContent(BuildContext context, AdminState app, int index) {
    // Grouped into Dashboard (standalone) / Operations (day-to-day field
    // work) / Engagement (carpenter-facing programs) / Settings
    // (standalone, bottom) -- purely a visual grouping, indices and
    // routes are untouched.
    const operations = [1, 2, 3]; // Carpenters, Locations, Orders
    const engagement = [4, 5, 6, 7, 8]; // Offers, Gifts, Redemptions, Leads, Notifications

    Widget groupLabel(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
          child: Text(text.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        );

    Widget item(int i) => _SidebarItem(
          icon: adminSections[i].$3,
          label: adminSections[i].$2,
          selected: i == index,
          onTap: () {
            context.go(adminSections[i].$1);
            // On mobile this sidebar lives inside a Drawer -- close it
            // after navigating, otherwise the drawer stays open over
            // the newly selected page. Safe no-op on the desktop
            // layout, where there's no drawer route to pop.
            Navigator.maybePop(context);
          },
        );

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
        item(0),
        groupLabel('Operations'),
        for (final i in operations) item(i),
        groupLabel('Engagement'),
        for (final i in engagement) item(i),
        const Spacer(),
        const Divider(color: Colors.white12, height: 1),
        item(9), // Settings
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
    final index = _selectedIndex;
    final title = index >= 0 ? adminSections[index].$2 : 'CarpenterHub Admin';

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
              child: child,
            ),
          ),
        ],
      );

      if (isMobile) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kBgSidebar,
            title: Text(title, style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          drawer: Drawer(
            backgroundColor: kBgSidebar,
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
              color: kBgSidebar,
              child: _sidebarContent(context, app, index),
            ),
            Expanded(child: body),
          ],
        ),
      );
    });
  }
}

/// A single sidebar nav row with a distinct selected state (filled
/// background + left accent bar + bold text, not just a faint tint) and a
/// hover state on desktop.
class _SidebarItem extends StatefulWidget {
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected ? Colors.white.withOpacity(0.12) : (_hovering ? Colors.white.withOpacity(0.06) : Colors.transparent);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: bg,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: widget.selected ? kAccentPrimary : Colors.transparent, width: 3))),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.selected ? Colors.white : Colors.white70, size: 18),
                const SizedBox(width: 12),
                Text(widget.label, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
