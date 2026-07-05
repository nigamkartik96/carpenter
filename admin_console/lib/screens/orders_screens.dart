import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'party_orders_screen.dart' show PartyStatusChip;

// Must match every status string the carpenter app actually writes
// ('Submitted' is the initial status on order creation) -- DropdownButton
// throws a hard assertion error if its current value isn't in this list,
// which crashes the whole screen.
const orderStatuses = ['Submitted', 'Processing', 'Fulfilled', 'Delivered'];

/// Shared so the Dashboard's "Recent orders" can reuse exactly the same
/// filter/sort logic as the full Orders list.
List<AdminOrder> filterAndSortOrders(
  List<AdminOrder> orders, {
  required String dateFilter,
  required String statusFilter,
  required String sortBy,
  String search = '',
}) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
  final q = search.trim().toLowerCase();

  var list = orders.where((o) {
    if (statusFilter != 'All' && o.status != statusFilter) return false;
    if (dateFilter == 'today' && (o.createdAt == null || o.createdAt!.isBefore(startOfDay))) return false;
    if (dateFilter == 'week' && (o.createdAt == null || o.createdAt!.isBefore(startOfWeek))) return false;
    if (q.isNotEmpty && !o.orderNumber.toLowerCase().contains(q) && !o.carpenterName.toLowerCase().contains(q)) return false;
    return true;
  }).toList();

  switch (sortBy) {
    case 'oldest':
      list.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      break;
    case 'amountHigh':
      list.sort((a, b) => b.amount.compareTo(a.amount));
      break;
    case 'amountLow':
      list.sort((a, b) => a.amount.compareTo(b.amount));
      break;
    default: // newest
      list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }
  return list;
}

/// Most orders show ₹0 until an admin enters line items on the order
/// detail screen (price isn't known up front for photo/voice orders) --
/// a bare "₹0" reads as broken data, so distinguish "genuinely not priced
/// yet" from an actual zero-amount order.
String orderAmountLabel(AdminOrder o) => (o.amount == 0 && o.items.isEmpty) ? 'Pending pricing' : '₹${o.amount}';

Widget orderAmountText(AdminOrder o, {double fontSize = 13}) {
  final pending = o.amount == 0 && o.items.isEmpty;
  return Text(
    orderAmountLabel(o),
    style: TextStyle(fontSize: fontSize, color: pending ? kTextMuted : kTextPrimary, fontStyle: pending ? FontStyle.italic : FontStyle.normal),
  );
}

/// The filter-chip + sort-dropdown row, shared between the Orders list and
/// the Dashboard's "Recent orders" section.
class OrderFilterBar extends StatelessWidget {
  const OrderFilterBar({
    super.key,
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
        chip('All statuses', 'All', statusFilter, onStatusFilter),
        for (final s in orderStatuses) chip(s, s, statusFilter, onStatusFilter),
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

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final search = TextEditingController();
  String statusFilter = 'All';
  String dateFilter = 'all';
  String sortBy = 'newest';
  int _page = 0;
  int _perPage = 25;
  bool _showParty = false;
  String _partyStatusFilter = 'all';
  String _partySearch = '';
  int _partyPage = 0;

  void _open(BuildContext context, String orderId) => context.push('/orders/$orderId');

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();

    return ListView(
      children: [
        const Heading('Orders', subtitle: 'Approve orders to credit carpenter points'),
        const SizedBox(height: 12),
        _buildToggle(),
        const SizedBox(height: 16),
        if (_showParty) _buildPartyOrders(app) else _buildRegularOrders(app),
      ],
    );
  }

  Widget _buildToggle() => Row(
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
      );

  Widget _buildRegularOrders(AdminState app) {
    final visible = filterAndSortOrders(app.orders, dateFilter: dateFilter, statusFilter: statusFilter, sortBy: sortBy, search: search.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: kBgSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorderSubtle)),
          child: Text('Earning rule: ${app.pointRuleAmount} spent = ${app.pointRulePoints} point(s)', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: search,
          onChanged: (_) => setState(() => _page = 0),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search by order number or carpenter', isDense: true),
        ),
        const SizedBox(height: 10),
        OrderFilterBar(
          dateFilter: dateFilter,
          statusFilter: statusFilter,
          sortBy: sortBy,
          onDateFilter: (v) => setState(() { dateFilter = v; _page = 0; }),
          onStatusFilter: (v) => setState(() { statusFilter = v; _page = 0; }),
          onSortBy: (v) => setState(() { sortBy = v; _page = 0; }),
        ),
        const SizedBox(height: 8),
        if (visible.isEmpty) const EmptyState(icon: Icons.inventory_2_outlined, message: 'No orders match this filter'),
        if (visible.isNotEmpty) ...[
          PaginationBar(
            total: visible.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
          ),
          ...pageSlice(visible, _page, _perPage).map((o) => AppCard(
                onTap: () => _open(context, o.id),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.carpenterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('${o.orderNumber}${o.products.isNotEmpty ? ' · ${o.products.first}' : ''}', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    orderAmountText(o, fontSize: 13),
                    const SizedBox(width: 10),
                    StatusBadge(o.status),
                    const Icon(Icons.chevron_right, color: kTextMuted, size: 18),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  static const _partyFilters = [
    ('all', 'All'),
    ('pending', 'Pending'),
    ('approved', 'Collecting payment'),
    ('completed', 'Completed'),
  ];

  Widget _buildPartyOrders(AdminState app) {
    final q = _partySearch.trim().toLowerCase();
    final visible = app.partyOrders.where((o) {
      if (_partyStatusFilter != 'all' && o.status != _partyStatusFilter) return false;
      if (q.isEmpty) return true;
      return o.carpenterName.toLowerCase().contains(q) || o.party.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => setState(() { _partySearch = v; _partyPage = 0; }),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search by carpenter or party', isDense: true),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in _partyFilters)
              FilterChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: _partyStatusFilter == value,
                onSelected: (_) => setState(() { _partyStatusFilter = value; _partyPage = 0; }),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const EmptyState(icon: Icons.receipt_long_outlined, message: 'No party orders match this filter')
        else ...[
          PaginationBar(
            total: visible.length,
            page: _partyPage,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _partyPage = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _partyPage = 0; }),
          ),
          ...pageSlice(visible, _partyPage, _perPage).map((o) {
            final isPending = o.status == 'pending';
            final progress = o.approvedAmount > 0 ? o.paid / o.approvedAmount : 0.0;
            return AppCard(
                onTap: () => context.go('/party-orders/${o.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.carpenterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Party: ${o.party}', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                          if (!isPending) ...[
                            const SizedBox(height: 2),
                            Text('Paid ₹${o.paid} of ₹${o.approvedAmount} · +${o.pointsAwarded} pts', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 4, backgroundColor: kBorderSubtle, color: progress >= 1.0 ? const Color(0xFF16A34A) : kAccentPrimary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('₹${o.approvedAmount > 0 ? o.approvedAmount : o.amount}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 10),
                    PartyStatusChip(status: o.status),
                    const Icon(Icons.chevron_right, color: kTextMuted, size: 18),
                  ],
                ),
              );
          }),
        ],
      ],
    );
  }
}
