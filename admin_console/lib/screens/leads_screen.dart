import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state.dart';
import '../widgets.dart';

const leadStatuses = ['New', 'Contacted', 'Qualified', 'Converted', 'Closed'];
const leadTerminalStatuses = ['Converted', 'Closed'];

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  int _page = 0;
  int _perPage = 25;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final paged = pageSlice(app.leads, _page, _perPage);
    return ListView(
      children: [
        const Heading('Leads', subtitle: 'Customer leads submitted by carpenters'),
        const SizedBox(height: 16),
        if (app.leads.isEmpty) const EmptyState(icon: Icons.lightbulb_outline, message: 'No leads submitted yet'),
        if (app.leads.isNotEmpty) ...[
          PaginationBar(
            total: app.leads.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
          ),
          ...paged.map((l) => AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.customer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('${l.phone} · By: ${l.carpenter}', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                          if (l.notes.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(l.notes, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (l.pointsAwarded > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('+${l.pointsAwarded} pts', style: const TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    StatusDropdown(
                      value: l.status,
                      options: leadStatuses,
                      enabled: !leadTerminalStatuses.contains(l.status),
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
                    if (l.lat != null && l.lng != null)
                      IconButton(
                        icon: const Icon(Icons.map_outlined, size: 18, color: kAccentPrimary),
                        tooltip: 'View on map',
                        onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${l.lat},${l.lng}'), mode: LaunchMode.externalApplication),
                      ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
