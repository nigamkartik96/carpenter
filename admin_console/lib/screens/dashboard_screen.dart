import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../router.dart';
import '../state.dart';
import '../widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final pending = app.carpenters.where((c) => c.status == 'Pending').length;
    return ListView(
      children: [
        const Heading('Dashboard', subtitle: 'Overview of the platform'),
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
          final isNarrow = constraints.maxWidth < 700;
          final perRow = isNarrow ? 2 : 4;
          final spacing = 10.0;
          final tileWidth = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (var i = 1; i < adminSections.length; i++)
                SizedBox(
                  width: tileWidth,
                  child: Kpi(label: adminSections[i].$2, value: 'Open', icon: adminSections[i].$3, onTap: () => context.go(adminSections[i].$1)),
                ),
            ],
          );
        }),
        const SizedBox(height: 24),
        const SubHeading('Recent orders'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
            columns: const [
              DataColumn(label: Text('Order')),
              DataColumn(label: Text('Carpenter')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Status')),
            ],
            rows: app.orders
                .map((o) => DataRow(cells: [
                      DataCell(Text(o.orderNumber)),
                      DataCell(Text(o.carpenterName)),
                      DataCell(Text('${o.amount}')),
                      DataCell(StatusBadge(o.status)),
                    ]))
                .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
