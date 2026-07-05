import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../router.dart';
import '../state.dart';
import '../widgets.dart';
import 'orders_screens.dart';
import 'party_orders_screen.dart' show PartyStatusChip;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String statusFilter = 'All';
  String dateFilter = 'all';
  String sortBy = 'newest';
  int _page = 0;
  int _perPage = 10;
  bool _showParty = false;
  int _partyPage = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final pending = app.carpenters.where((c) => c.status == 'Pending').length;
    final allFiltered = filterAndSortOrders(app.orders, dateFilter: dateFilter, statusFilter: statusFilter, sortBy: sortBy);
    final recent = pageSlice(allFiltered, _page, _perPage);

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
            SubHeading(_showParty ? 'Recent party orders' : 'Recent orders'),
            TextButton(
              onPressed: () => context.go(_showParty ? '/party-orders' : '/orders'),
              child: const Text('View all', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() { _showParty = false; _page = 0; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_showParty ? kAccentPrimary : kBgSurface,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                    border: Border.all(color: !_showParty ? kAccentPrimary : kBorderSubtle),
                  ),
                  alignment: Alignment.center,
                  child: Text('Regular orders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: !_showParty ? Colors.white : kTextSecondary)),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() { _showParty = true; _partyPage = 0; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _showParty ? kAccentPrimary : kBgSurface,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                    border: Border.all(color: _showParty ? kAccentPrimary : kBorderSubtle),
                  ),
                  alignment: Alignment.center,
                  child: Text('Party orders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _showParty ? Colors.white : kTextSecondary)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_showParty) ...[
          OrderFilterBar(
            dateFilter: dateFilter,
            statusFilter: statusFilter,
            sortBy: sortBy,
            onDateFilter: (v) => setState(() { dateFilter = v; _page = 0; }),
            onStatusFilter: (v) => setState(() { statusFilter = v; _page = 0; }),
            onSortBy: (v) => setState(() { sortBy = v; _page = 0; }),
          ),
          PaginationBar(
            total: allFiltered.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
          ),
          if (recent.isEmpty) const EmptyState(icon: Icons.inventory_2_outlined, message: 'No orders match this filter'),
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
                          orderAmountText(o, fontSize: 12),
                        ],
                      ),
                    ),
                    StatusBadge(o.status),
                  ],
                ),
              )),
        ] else ...[
          PaginationBar(
            total: app.partyOrders.length,
            page: _partyPage,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _partyPage = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _partyPage = 0; }),
          ),
          if (app.partyOrders.isEmpty) const EmptyState(icon: Icons.receipt_long_outlined, message: 'No party orders yet'),
          ...pageSlice(app.partyOrders, _partyPage, _perPage).map((o) => AppCard(
                onTap: () => context.push('/party-orders/${o.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${o.carpenterName} · ${o.party}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (o.status != 'pending')
                            Text('Paid ₹${o.paid} of ₹${o.approvedAmount} · +${o.pointsAwarded} pts', style: const TextStyle(color: kTextSecondary, fontSize: 11))
                          else
                            Text('₹${o.amount}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PartyStatusChip(status: o.status),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
