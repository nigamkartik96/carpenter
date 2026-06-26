import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../widgets.dart';

const redemptionStatuses = ['Ordered', 'In store', 'Delivered'];

class RedemptionsScreen extends StatelessWidget {
  const RedemptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    return ListView(
      children: [
        const Text('Redemption queue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const Text('Move cash and gift redemption requests through fulfilment', style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
            columns: const [
              DataColumn(label: Text('Carpenter')),
              DataColumn(label: Text('Gift')),
              DataColumn(label: Text('Points')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Update')),
            ],
            rows: app.redemptions
                .map((r) => DataRow(cells: [
                      DataCell(Text(r.carpenterName)),
                      DataCell(Text(r.giftName)),
                      DataCell(Text('${r.points}')),
                      DataCell(StatusBadge(r.status)),
                      DataCell(
                        r.status == 'Delivered'
                            ? const Text('No further action', style: TextStyle(color: kMuted, fontSize: 12))
                            : StatusDropdown(value: r.status, options: redemptionStatuses, onChanged: (v) {
                                app.setRedemptionStatus(r, v);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r.carpenterName}\'s redemption marked $v')));
                              }),
                      ),
                    ]))
                .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
