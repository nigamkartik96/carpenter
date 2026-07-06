import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
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
          ...paged.map((r) => _RedemptionCard(redemption: r, app: app)),
        ],
      ],
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  const _RedemptionCard({required this.redemption, required this.app});
  final Redemption redemption;
  final AdminState app;

  @override
  Widget build(BuildContext context) {
    final carpenter = app.carpenterById(redemption.carpenterId);
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
            decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.card_giftcard_outlined, size: 18, color: Color(0xFF7C3AED)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(redemption.carpenterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                    if (carpenter != null)
                      IconButton(
                        icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                        tooltip: 'Payment details',
                        visualDensity: VisualDensity.compact,
                        color: kAccentPrimary,
                        onPressed: () => showPaymentDetailsDialog(context, carpenter),
                      ),
                  ],
                ),
                Text(redemption.giftName, style: const TextStyle(fontSize: 12, color: kTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${redemption.points} pts', style: const TextStyle(fontSize: 12, color: kTextMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(redemption.status),
              const SizedBox(height: 8),
              StatusDropdown(
                value: redemption.status,
                options: redemptionStatuses,
                enabled: redemption.status != 'Delivered',
                onChanged: (v) async {
                  final confirmed = await confirmDialog(context, title: 'Update redemption status?', message: 'Mark ${redemption.carpenterName}\'s redemption of "${redemption.giftName}" as "$v"?');
                  if (!confirmed) return;
                  app.setRedemptionStatus(redemption, v);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${redemption.carpenterName}\'s redemption marked $v')));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
