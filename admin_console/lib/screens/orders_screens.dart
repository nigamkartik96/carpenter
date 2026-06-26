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

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    return ListView(
      children: [
        const Text('Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const Text('Approve orders to credit carpenter points', style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text('Earning rule: ${app.pointRuleAmount} spent = ${app.pointRulePoints} point(s)', style: const TextStyle(color: kMuted, fontSize: 12)),
        ),
        const SizedBox(height: 16),
        const Text('Tap a row to open the order, enter line items and an invoice', style: TextStyle(color: kMuted, fontSize: 12)),
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
            ],
            rows: app.orders
                .map((o) => DataRow(
                      // Status changes happen on the order detail screen now --
                      // a second "Quick update" dropdown here duplicated that
                      // control and let an admin change status without first
                      // reviewing/entering line items, bypassing the points logic.
                      onSelectChanged: (_) => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id))),
                      cells: [
                        DataCell(Text('${o.orderNumber} · ${o.products.isNotEmpty ? o.products.first : ''}')),
                        DataCell(Text(o.carpenterName)),
                        DataCell(Text('₹${o.amount}')),
                        DataCell(StatusBadge(o.status)),
                      ],
                    ))
                .toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Points rules', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
