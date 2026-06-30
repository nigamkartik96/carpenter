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
        const Heading('Redemption queue', subtitle: 'Move cash and gift redemption requests through fulfilment'),
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
                            : StatusDropdown(value: r.status, options: redemptionStatuses, onChanged: (v) async {
                                final confirmed = await confirmDialog(context, title: 'Update redemption status?', message: 'Mark ${r.carpenterName}\'s redemption of "${r.giftName}" as "$v"?');
                                if (!confirmed) return;
                                app.setRedemptionStatus(r, v);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r.carpenterName}\'s redemption marked $v')));
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
