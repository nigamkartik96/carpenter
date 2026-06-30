import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state.dart';
import '../widgets.dart';

const leadStatuses = ['New', 'Contacted', 'Qualified', 'Converted', 'Closed'];
const leadTerminalStatuses = ['Converted', 'Closed'];

class LeadsScreen extends StatelessWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    return ListView(
      children: [
        const Heading('Leads', subtitle: 'Customer leads submitted by carpenters'),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Carpenter')),
                DataColumn(label: Text('Remarks')),
                DataColumn(label: Text('Location')),
                DataColumn(label: Text('Points')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Update')),
              ],
              rows: app.leads
                  .map((l) => DataRow(cells: [
                        DataCell(Text(l.customer)),
                        DataCell(Text(l.phone)),
                        DataCell(Text(l.carpenter)),
                        DataCell(SizedBox(width: 160, child: Text(l.notes, maxLines: 2, overflow: TextOverflow.ellipsis))),
                        DataCell(
                          l.lat != null && l.lng != null
                              ? TextButton.icon(
                                  onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${l.lat},${l.lng}'), mode: LaunchMode.externalApplication),
                                  icon: const Icon(Icons.map_outlined, size: 14),
                                  label: const Text('Map', style: TextStyle(fontSize: 12)),
                                )
                              : Text(l.location.isEmpty ? '-' : l.location, style: const TextStyle(fontSize: 12)),
                        ),
                        DataCell(Text(l.pointsAwarded > 0 ? '+${l.pointsAwarded}' : '-')),
                        DataCell(StatusBadge(l.status)),
                        DataCell(
                          leadTerminalStatuses.contains(l.status)
                              ? const Text('No further action', style: TextStyle(color: kMuted, fontSize: 12))
                              : StatusDropdown(
                                  value: l.status,
                                  options: leadStatuses,
                                  onChanged: (v) async {
                                    final confirmed = await confirmDialog(context, title: 'Update lead status?', message: 'Move ${l.customer}\'s lead to "$v"?');
                                    if (!confirmed) return;
                                    try {
                                      await app.setLeadStatus(l, v);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update lead: $e')));
                                      }
                                    }
                                  },
                                ),
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

