import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models.dart';
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
  String _partyDateFilter = 'all';
  String _partyStatusFilter = 'all';
  String _partySortBy = 'newest';

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
        Container(
          decoration: BoxDecoration(
            color: kBgSurface,
            borderRadius: BorderRadius.circular(kCardRadius),
            border: Border.all(color: kBorderSubtle),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                child: Row(
                  children: [
                    Expanded(child: SubHeading(_showParty ? 'Recent party orders' : 'Recent orders')),
                    TextButton(
                      onPressed: () => context.go(_showParty ? '/party-orders' : '/orders'),
                      child: const Text('View all →', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: kBgApp,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      Expanded(child: _tab('Orders', Icons.inventory_2_outlined, !_showParty, () => setState(() { _showParty = false; _page = 0; }))),
                      const SizedBox(width: 4),
                      Expanded(child: _tab('Party orders', Icons.receipt_long_outlined, _showParty, () => setState(() { _showParty = true; _partyPage = 0; }))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!_showParty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OrderFilterBar(
                    dateFilter: dateFilter,
                    statusFilter: statusFilter,
                    sortBy: sortBy,
                    onDateFilter: (v) => setState(() { dateFilter = v; _page = 0; }),
                    onStatusFilter: (v) => setState(() { statusFilter = v; _page = 0; }),
                    onSortBy: (v) => setState(() { sortBy = v; _page = 0; }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PaginationBar(
                    total: allFiltered.length,
                    page: _page,
                    perPage: _perPage,
                    onPageChanged: (p) => setState(() => _page = p),
                    onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
                  ),
                ),
                if (recent.isEmpty)
                  const Padding(padding: EdgeInsets.only(bottom: 16), child: EmptyState(icon: Icons.inventory_2_outlined, message: 'No orders match this filter')),
                ...recent.map((o) => _orderTile(context, o)),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PartyFilterBar(
                    dateFilter: _partyDateFilter,
                    statusFilter: _partyStatusFilter,
                    sortBy: _partySortBy,
                    onDateFilter: (v) => setState(() { _partyDateFilter = v; _partyPage = 0; }),
                    onStatusFilter: (v) => setState(() { _partyStatusFilter = v; _partyPage = 0; }),
                    onSortBy: (v) => setState(() { _partySortBy = v; _partyPage = 0; }),
                  ),
                ),
                Builder(builder: (context) {
                  final filtered = _filterPartyOrders(app.partyOrders);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: PaginationBar(
                          total: filtered.length,
                          page: _partyPage,
                          perPage: _perPage,
                          onPageChanged: (p) => setState(() => _partyPage = p),
                          onPerPageChanged: (n) => setState(() { _perPage = n; _partyPage = 0; }),
                        ),
                      ),
                      if (filtered.isEmpty)
                        const Padding(padding: EdgeInsets.only(bottom: 16), child: EmptyState(icon: Icons.receipt_long_outlined, message: 'No party orders match this filter')),
                      ...pageSlice(filtered, _partyPage, _perPage).map((o) => _partyTile(context, o)),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tab(String label, IconData icon, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? kBgSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? kAccentPrimary : kTextMuted),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? kTextPrimary : kTextMuted)),
            ],
          ),
        ),
      );

  Widget _orderTile(BuildContext context, AdminOrder o) => InkWell(
        onTap: () => context.push('/orders/${o.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorderSubtle, width: 0.5))),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: kAccentPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.inventory_2_outlined, size: 16, color: kAccentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.carpenterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(o.orderNumber, style: const TextStyle(color: kTextMuted, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  orderAmountText(o, fontSize: 13),
                  const SizedBox(height: 2),
                  StatusBadge(o.status),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _partyTile(BuildContext context, PartyOrder o) {
    final isPending = o.status == 'pending';
    final progress = o.approvedAmount > 0 ? o.paid / o.approvedAmount : 0.0;
    return InkWell(
      onTap: () => context.push('/party-orders/${o.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorderSubtle, width: 0.5))),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF92400E)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.carpenterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Party: ${o.party}', style: const TextStyle(color: kTextMuted, fontSize: 11)),
                  if (!isPending) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 4, backgroundColor: kBorderSubtle, color: progress >= 1.0 ? const Color(0xFF16A34A) : kAccentPrimary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${o.amount}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                PartyStatusChip(status: o.status),
                if (!isPending) ...[
                  const SizedBox(height: 2),
                  Text('+${o.pointsAwarded} pts', style: const TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PartyOrder> _filterPartyOrders(List<PartyOrder> orders) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));

    var list = orders.where((o) {
      if (_partyStatusFilter != 'all' && o.status != _partyStatusFilter) return false;
      if (_partyDateFilter == 'today' && (o.createdAt == null || o.createdAt!.isBefore(startOfDay))) return false;
      if (_partyDateFilter == 'week' && (o.createdAt == null || o.createdAt!.isBefore(startOfWeek))) return false;
      return true;
    }).toList();

    switch (_partySortBy) {
      case 'oldest':
        list.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        break;
      case 'amountHigh':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amountLow':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    }
    return list;
  }
}

class _PartyFilterBar extends StatelessWidget {
  const _PartyFilterBar({
    required this.dateFilter,
    required this.statusFilter,
    required this.sortBy,
    required this.onDateFilter,
    required this.onStatusFilter,
    required this.onSortBy,
  });
  final String dateFilter;
  final String statusFilter;
  final String sortBy;
  final ValueChanged<String> onDateFilter;
  final ValueChanged<String> onStatusFilter;
  final ValueChanged<String> onSortBy;

  static const _statuses = [
    ('all', 'All statuses'),
    ('pending', 'Pending'),
    ('approved', 'Collecting payment'),
    ('completed', 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String value, String current, ValueChanged<String> onSelect) => FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: current == value,
          onSelected: (_) => onSelect(value),
          visualDensity: VisualDensity.compact,
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip('All dates', 'all', dateFilter, onDateFilter),
        chip('Past day', 'today', dateFilter, onDateFilter),
        chip('Past week', 'week', dateFilter, onDateFilter),
        const SizedBox(width: 4),
        for (final (value, label) in _statuses) chip(label, value, statusFilter, onStatusFilter),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: sortBy,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'newest', child: Text('Newest first', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'oldest', child: Text('Oldest first', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'amountHigh', child: Text('Amount: high to low', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'amountLow', child: Text('Amount: low to high', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (v) => onSortBy(v ?? 'newest'),
        ),
      ],
    );
  }
}
