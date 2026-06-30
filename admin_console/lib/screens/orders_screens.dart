import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../widgets.dart';
import 'order_detail_screen.dart';

// Must match every status string the carpenter app actually writes
// ('Submitted' is the initial status on order creation) -- DropdownButton
// throws a hard assertion error if its current value isn't in this list,
// which crashes the whole screen.
const orderStatuses = ['Submitted', 'Processing', 'Fulfilled', 'Delivered'];

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final search = TextEditingController();
  String statusFilter = 'All';

  void _open(BuildContext context, String orderId) => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final q = search.text.trim().toLowerCase();
    final visible = app.orders.where((o) {
      if (statusFilter != 'All' && o.status != statusFilter) return false;
      if (q.isEmpty) return true;
      return o.orderNumber.toLowerCase().contains(q) || o.carpenterName.toLowerCase().contains(q);
    }).toList();

    return ListView(
      children: [
        const Heading('Orders', subtitle: 'Approve orders to credit carpenter points'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text('Earning rule: ${app.pointRuleAmount} spent = ${app.pointRulePoints} point(s)', style: const TextStyle(color: kMuted, fontSize: 12)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search by order number or carpenter', isDense: true),
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: statusFilter,
              underline: const SizedBox(),
              items: ['All', ...orderStatuses].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => statusFilter = v ?? 'All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Tap a row, or the eye icon, to open the order', style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Order')),
              DataColumn(label: Text('Carpenter')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('')),
            ],
            rows: visible
                .map((o) => DataRow(
                      // Status changes happen on the order detail screen now --
                      // a second "Quick update" dropdown here duplicated that
                      // control and let an admin change status without first
                      // reviewing/entering line items, bypassing the points logic.
                      onSelectChanged: (_) => _open(context, o.id),
                      cells: [
                        DataCell(Text('${o.orderNumber} · ${o.products.isNotEmpty ? o.products.first : ''}')),
                        DataCell(Text(o.carpenterName)),
                        DataCell(Text('₹${o.amount}')),
                        DataCell(StatusBadge(o.status)),
                        DataCell(IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), tooltip: 'View order', onPressed: () => _open(context, o.id))),
                      ],
                    ))
                .toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SubHeading('Points rules'),
        const SizedBox(height: 10),
        _PointsRuleForm(app: app),
      ],
    );
  }
}

class _PointsRuleForm extends StatefulWidget {
  const _PointsRuleForm({required this.app});
  final AdminState app;

  @override
  State<_PointsRuleForm> createState() => _PointsRuleFormState();
}

class _PointsRuleFormState extends State<_PointsRuleForm> {
  late final amount = TextEditingController(text: '${widget.app.pointRuleAmount}');
  late final points = TextEditingController(text: '${widget.app.pointRulePoints}');
  late final minRedeem = TextEditingController(text: '${widget.app.minRedeemPoints}');

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(width: 120, child: TextField(controller: points, decoration: const InputDecoration(labelText: 'Points'))),
          const Text('per ₹'),
          SizedBox(width: 120, child: TextField(controller: amount, decoration: const InputDecoration(labelText: 'Amount spent'))),
          SizedBox(width: 160, child: TextField(controller: minRedeem, decoration: const InputDecoration(labelText: 'Min points to redeem'))),
          ElevatedButton(
            onPressed: () => widget.app.setPointRule(
              int.tryParse(amount.text) ?? 100,
              int.tryParse(points.text) ?? 1,
              int.tryParse(minRedeem.text) ?? 500,
            ),
            child: const Text('Save rule'),
          ),
        ],
      ),
    );
  }
}
