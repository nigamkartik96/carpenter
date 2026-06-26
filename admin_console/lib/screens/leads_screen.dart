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
        const Text('Leads', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const Text('Customer leads submitted by carpenters', style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 16),
        _LeadPointsRuleForm(app: app),
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

class _LeadPointsRuleForm extends StatefulWidget {
  const _LeadPointsRuleForm({required this.app});
  final AdminState app;

  @override
  State<_LeadPointsRuleForm> createState() => _LeadPointsRuleFormState();
}

class _LeadPointsRuleFormState extends State<_LeadPointsRuleForm> {
  // leadPointsQualified/Converted load asynchronously from Firestore, so
  // this widget can build before they arrive. Initializing the controllers
  // just once at first build risked showing a stale "0" and admins
  // re-saving that over a real rule -- so keep them in sync until the
  // admin actually starts typing.
  late final qualified = TextEditingController(text: '${widget.app.leadPointsQualified}');
  late final converted = TextEditingController(text: '${widget.app.leadPointsConverted}');
  bool _edited = false;

  @override
  void didUpdateWidget(_LeadPointsRuleForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_edited) {
      qualified.text = '${widget.app.leadPointsQualified}';
      converted.text = '${widget.app.leadPointsConverted}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          const Text('Award on:', style: TextStyle(fontSize: 13)),
          SizedBox(
            width: 140,
            child: TextField(
              controller: qualified,
              keyboardType: TextInputType.number,
              onChanged: (_) => _edited = true,
              decoration: const InputDecoration(labelText: 'Qualified -> pts'),
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: converted,
              keyboardType: TextInputType.number,
              onChanged: (_) => _edited = true,
              decoration: const InputDecoration(labelText: 'Converted -> pts'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _edited = false;
              widget.app.setLeadPointsRule(
                qualifiedPoints: int.tryParse(qualified.text) ?? 0,
                convertedPoints: int.tryParse(converted.text) ?? 0,
              );
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lead points rule saved')));
            },
            child: const Text('Save rule'),
          ),
        ],
      ),
    );
  }
}
