import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';


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
    // Status stays as chips -- an admin wants every stage visible at once.
    // Date and sort are single-choice, so they collapse into selects and
    // stop competing with the status row.
    return Wrap(
      spacing: spaceSm,
      runSpacing: spaceSm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusFilterChip(label: 'All statuses', selected: statusFilter == 'All', onTap: () => onStatusFilter('All')),
        for (final s in orderStatuses) StatusFilterChip(label: s, selected: statusFilter == s, onTap: () => onStatusFilter(s)),
        const SizedBox(width: spaceXs),
        FilterSelect<String>(
          value: dateFilter,
          icon: Icons.calendar_today_outlined,
          options: const [('all', 'All dates'), ('today', 'Past day'), ('week', 'Past week')],
          onChanged: onDateFilter,
        ),
        FilterSelect<String>(
          value: sortBy,
          icon: Icons.swap_vert,
          options: const [
            ('newest', 'Newest first'),
            ('oldest', 'Oldest first'),
            ('amountHigh', 'Amount: high to low'),
            ('amountLow', 'Amount: low to high'),
          ],
          onChanged: onSortBy,
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
  int _perPage = 10;

  void _open(BuildContext context, String orderId) => context.push('/orders/$orderId');

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final visible = filterAndSortOrders(app.orders, dateFilter: dateFilter, statusFilter: statusFilter, sortBy: sortBy, search: search.text);

    return ListView(
      children: [
        const Heading('Orders', subtitle: 'Approve orders to credit carpenter points'),
        const SizedBox(height: spaceMd),
        if (app.orders.isNotEmpty) ...[
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
          const SizedBox(height: spaceMd),
        ],
        if (app.orders.isEmpty)
          const EmptyState(icon: Icons.inventory_2_outlined, message: 'No orders yet. They will appear here once a carpenter places one.')
        else if (visible.isEmpty)
          const EmptyState(icon: Icons.filter_alt_off_outlined, message: 'No orders match this filter.')
        else ...[
          PaginationBar(
            total: visible.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
          ),
          ...pageSlice(visible, _page, _perPage).map((o) => _OrderCard(order: o, onTap: () => _open(context, o.id))),
        ],
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, this.onTap});
  final AdminOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pending = order.amount == 0 && order.items.isEmpty;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorderSubtle, width: 0.5))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(color: kBgApp, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.receipt_long_outlined, size: 18, color: kTextSecondary),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.carpenterName, style: kTypeBody.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${order.orderNumber}${order.products.isNotEmpty ? ' · ${order.products.first}' : ''}',
                    style: kTypeMeta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pending ? '' : '₹${order.amount}',
                  style: kTypeFigure.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                StatusBadge(order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
