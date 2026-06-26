import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

class CarpentersScreen extends StatelessWidget {
  const CarpentersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final pending = app.carpenters.where((c) => c.status == 'Pending').toList();
    return ListView(
      children: [
        const Text('Carpenters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const Text('Approve new sign-ups and manage existing carpenters', style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 20),
        if (pending.isNotEmpty) ...[
          const Text('Pending approval', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          ...pending.map((c) => AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c.name} · ${c.shop}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(c.mobile, style: const TextStyle(color: kMuted, fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton(onPressed: () => app.approve(c), child: const Text('Approve')),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Reject this carpenter?'),
                                content: Text('${c.name} will not be able to log in. This cannot be undone from here.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
                                ],
                              ),
                            );
                            if (confirmed == true) app.reject(c);
                          },
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
        ],
        const Text('All carpenters', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Shop')),
              DataColumn(label: Text('Mobile')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Points')),
              DataColumn(label: Text('Tier')),
            ],
            rows: app.carpenters
                .map((c) => DataRow(cells: [
                      DataCell(Text(c.name)),
                      DataCell(Text(c.shop)),
                      DataCell(Text(c.mobile)),
                      DataCell(StatusBadge(c.status)),
                      DataCell(Text('${c.points}')),
                      DataCell(StatusDropdown(value: c.tier, options: carpenterTiers, onChanged: (v) {
                        app.setTier(c, v);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.name} moved to $v tier')));
                      })),
                    ]))
                .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
