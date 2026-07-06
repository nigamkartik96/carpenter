import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
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
          ...paged.map((l) => _LeadCard(lead: l, app: app)),
        ],
      ],
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead, required this.app});
  final AdminLead lead;
  final AdminState app;

  @override
  Widget build(BuildContext context) {
    final isTerminal = leadTerminalStatuses.contains(lead.status);
    return Container(
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
            child: const Icon(Icons.person_outline, size: 18, color: kTextSecondary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lead.customer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(lead.phone, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                if (lead.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(lead.notes, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Referred by ', style: const TextStyle(color: kTextMuted, fontSize: 11)),
                    Text(lead.carpenter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    if (lead.lat != null && lead.lng != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${lead.lat},${lead.lng}'), mode: LaunchMode.externalApplication),
                        child: const Icon(Icons.map_outlined, size: 14, color: kAccentPrimary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              lead.pointsAwarded > 0
                  ? Text('+${lead.pointsAwarded}', style: const TextStyle(color: Color(0xFF16A34A), fontSize: 14, fontWeight: FontWeight.w600))
                  : Text('0', style: const TextStyle(color: kTextMuted, fontSize: 14)),
              const SizedBox(height: 6),
              StatusDropdown(
                value: lead.status,
                options: leadStatuses,
                enabled: !isTerminal,
                onChanged: (v) async {
                  final confirmed = await confirmDialog(context, title: 'Update lead status?', message: 'Move ${lead.customer}\'s lead to "$v"?');
                  if (!confirmed) return;
                  try {
                    await app.setLeadStatus(lead, v);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update lead: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
