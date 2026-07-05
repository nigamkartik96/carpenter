import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../widgets.dart';

const redemptionStatuses = ['Ordered', 'In store', 'Delivered'];

class RedemptionsScreen extends StatefulWidget {
  const RedemptionsScreen({super.key});

  @override
  State<RedemptionsScreen> createState() => _RedemptionsScreenState();
}

class _RedemptionsScreenState extends State<RedemptionsScreen> {
  int _page = 0;
  int _perPage = 25;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final paged = pageSlice(app.redemptions, _page, _perPage);
    return ListView(
      children: [
        const Heading('Redemption queue', subtitle: 'Move cash and gift redemption requests through fulfilment'),
        const SizedBox(height: 16),
        if (app.redemptions.isEmpty) const EmptyState(icon: Icons.assignment_outlined, message: 'No redemptions yet'),
        if (app.redemptions.isNotEmpty) ...[
          PaginationBar(
            total: app.redemptions.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
          ),
          ...paged.map((r) => AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.carpenterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(r.giftName, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${r.points} pts', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 10),
                    StatusDropdown(
                      value: r.status,
                      options: redemptionStatuses,
                      enabled: r.status != 'Delivered',
                      onChanged: (v) async {
                        final confirmed = await confirmDialog(context, title: 'Update redemption status?', message: 'Mark ${r.carpenterName}\'s redemption of "${r.giftName}" as "$v"?');
                        if (!confirmed) return;
                        app.setRedemptionStatus(r, v);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r.carpenterName}\'s redemption marked $v')));
                      },
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
