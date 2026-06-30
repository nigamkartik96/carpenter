import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../router.dart';
import '../state.dart';
import '../widgets.dart';
import 'orders_screens.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String statusFilter = 'All';
  String dateFilter = 'all';
  String sortBy = 'newest';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final pending = app.carpenters.where((c) => c.status == 'Pending').length;
    final recent = filterAndSortOrders(app.orders, dateFilter: dateFilter, statusFilter: statusFilter, sortBy: sortBy).take(10).toList();

    return ListView(
      children: [
        const Heading('Dashboard'),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          // Below ~700px, 4 Expanded KPI cards in a Row squeeze too
          // narrow to read -- wrap into a 2-per-row grid instead.
          final isNarrow = constraints.maxWidth < 700;
          final cardWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : double.infinity;
          final cards = [
            Kpi(label: 'Approved carpenters', value: '${app.carpenters.where((c) => c.status == 'Approved').length}', icon: Icons.people_outline, onTap: () => context.go('/carpenters')),
            Kpi(label: 'Pending approvals', value: '$pending', icon: Icons.person_search_outlined, onTap: () => context.go('/carpenters')),
            Kpi(label: 'Total orders', value: '${app.orders.length}', icon: Icons.inventory_2_outlined, onTap: () => context.go('/orders')),
            Kpi(label: 'Gift redemptions', value: '${app.redemptions.length}', icon: Icons.card_giftcard_outlined, onTap: () => context.go('/redemptions')),
          ];
          if (!isNarrow) {
            return Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: cards[i]),
                ],
              ],
            );
          }
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final c in cards) SizedBox(width: cardWidth, child: c)],
          );
        }),
        const SizedBox(height: 24),
        const SubHeading('Quick links'),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final perRow = (constraints.maxWidth / 130).floor().clamp(3, 9);
          const spacing = 10.0;
          final tileWidth = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (var i = 1; i < adminSections.length; i++)
                SizedBox(
                  width: tileWidth,
                  child: LinkTile(label: adminSections[i].$2, icon: adminSections[i].$3, onTap: () => context.go(adminSections[i].$1)),
                ),
            ],
          );
        }),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SubHeading('Recent orders'),
            TextButton(onPressed: () => context.go('/orders'), child: const Text('View all', style: TextStyle(fontSize: 12))),
          ],
        ),
        const SizedBox(height: 8),
        OrderFilterBar(
          dateFilter: dateFilter,
          statusFilter: statusFilter,
          sortBy: sortBy,
          onDateFilter: (v) => setState(() => dateFilter = v),
          onStatusFilter: (v) => setState(() => statusFilter = v),
          onSortBy: (v) => setState(() => sortBy = v),
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty) const Text('No orders match this filter', style: TextStyle(color: kMuted, fontSize: 13)),
        ...recent.map((o) => AppCard(
              onTap: () => context.push('/orders/${o.id}'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${o.orderNumber} · ${o.carpenterName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('₹${o.amount}', style: const TextStyle(color: kMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  StatusBadge(o.status),
                ],
              ),
            )),
      ],
    );
  }
}
