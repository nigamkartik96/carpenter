import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'orders_screens.dart' show orderAmountLabel;
import 'party_orders_screen.dart' show PartyStatusChip;

class CarpenterDetailScreen extends StatefulWidget {
  const CarpenterDetailScreen({super.key, required this.carpenterId});
  final String carpenterId;

  @override
  State<CarpenterDetailScreen> createState() => _CarpenterDetailScreenState();
}

class _CarpenterDetailScreenState extends State<CarpenterDetailScreen> {
  int _tab = 0;

  static const _tabs = [
    (Icons.inventory_2_outlined, 'Orders'),
    (Icons.receipt_long_outlined, 'Party'),
    (Icons.card_giftcard_outlined, 'Gifts'),
    (Icons.lightbulb_outline, 'Leads'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final matches = app.carpenters.where((c) => c.id == widget.carpenterId);
    if (matches.isEmpty) {
      return const Scaffold(body: Center(child: Text('Carpenter not found')));
    }
    final c = matches.first;
    final orders = app.ordersFor(widget.carpenterId);
    final partyOrders = app.partyOrdersFor(widget.carpenterId);
    final redemptions = app.redemptionsFor(widget.carpenterId);
    final leads = app.leadsFor(widget.carpenterId);
    final counts = [orders.length, partyOrders.length, redemptions.length, leads.length];

    return Scaffold(
      appBar: AppBar(title: Text(c.name), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BackLink(label: 'Back to Carpenters', onTap: () => context.go('/carpenters')),
          const SizedBox(height: 8),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Avatar(photoUrl: c.photoUrl, name: c.name, radius: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      Text(c.shop, style: kTypeBody.copyWith(color: kTextSecondary)),
                      const SizedBox(height: 6),
                      Text(c.mobile, style: kTypeBody),
                      Text(c.area, style: const TextStyle(color: kMuted, fontSize: 12)),
                      const SizedBox(height: 10),
                      // Counts read as plain details alongside the name and
                      // phone rather than a separate row of stat tiles --
                      // nothing here is tappable, so tiles overstated them.
                      Wrap(
                        spacing: 18,
                        runSpacing: 6,
                        children: [
                          _Detail(label: 'Points', value: '${c.points}'),
                          _Detail(label: 'Orders', value: '${orders.length}'),
                          _Detail(label: 'Party', value: '${partyOrders.length}'),
                          _Detail(label: 'Redemptions', value: '${redemptions.length}'),
                          _Detail(label: 'Leads', value: '${leads.length}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusBadge(c.status),
                          StatusDropdown(
                            value: c.tier,
                            options: carpenterTiers,
                            onChanged: (v) async {
                              final confirmed = await confirmDialog(context, title: 'Change tier?', message: 'Move ${c.name} to the $v tier?');
                              if (!confirmed) return;
                              app.setTier(c, v);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.name} moved to $v tier')));
                            },
                          ),
                          OutlinedButton.icon(
                            onPressed: () => showPaymentDetailsDialog(context, c),
                            icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                            label: const Text('Payment details'),
                          ),
                          _LocationButton(carpenter: c),
                          if (c.status == 'Pending') ...[
                            ElevatedButton(
                              onPressed: () async {
                                final confirmed = await confirmDialog(context, title: 'Approve carpenter?', message: '${c.name} will be able to log in and start placing orders.');
                                if (confirmed) app.approve(c);
                              },
                              child: const Text('Approve'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                final confirmed = await confirmDialog(context, title: 'Reject this carpenter?', message: '${c.name} will not be able to log in. This cannot be undone from here.', confirmLabel: 'Reject', danger: true);
                                if (confirmed) app.reject(c);
                              },
                              child: const Text('Reject'),
                            ),
                          ],
                          if (!app.isCreator && c.status == 'Approved') ...[
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed = await confirmDialog(context, title: 'Reset PIN?', message: '${c.name} will be required to set a new PIN on their next app launch.');
                                if (!confirmed) return;
                                await app.triggerPinReset(c);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PIN reset triggered for ${c.name}')));
                              },
                              icon: const Icon(Icons.pin, size: 16),
                              label: const Text('Reset PIN'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed = await confirmDialog(context, title: 'Reset password?', message: '${c.name} will be required to set a new password on their next app launch.', danger: true);
                                if (!confirmed) return;
                                await app.triggerPasswordReset(c);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset triggered for ${c.name}')));
                              },
                              icon: const Icon(Icons.password, size: 16),
                              label: const Text('Reset password'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: BorderRadius.circular(kCardRadius),
              border: Border.all(color: kBorderSubtle),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(color: kBgApp, borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        for (var i = 0; i < _tabs.length; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Expanded(child: _tabChip(i, _tabs[i].$1, _tabs[i].$2, counts[i])),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_tab == 0) _ordersTab(context, orders),
                if (_tab == 1) _partyTab(context, partyOrders),
                if (_tab == 2) _redemptionsTab(context, redemptions),
                if (_tab == 3) _leadsTab(context, leads),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(int index, IconData icon, String label, int count) => GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _tab == index ? kBgSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: _tab == index ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: _tab == index ? kAccentPrimary : kTextMuted),
              const SizedBox(height: 2),
              Text('$label ($count)', style: TextStyle(fontSize: 11, fontWeight: _tab == index ? FontWeight.w600 : FontWeight.w400, color: _tab == index ? kTextPrimary : kTextMuted)),
            ],
          ),
        ),
      );

  Widget _ordersTab(BuildContext context, List<AdminOrder> orders) {
    if (orders.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: EmptyState(icon: Icons.inventory_2_outlined, message: 'No orders yet'));
    return Column(
      children: orders.map((o) => _tileBorder(
            InkWell(
              onTap: () => context.push('/orders/${o.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: kAccentPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.inventory_2_outlined, size: 15, color: kAccentPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.orderNumber, style: kTypeBody.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(orderAmountLabel(o), style: TextStyle(fontSize: 12, color: o.amount == 0 && o.items.isEmpty ? kTextMuted : kTextSecondary)),
                        ],
                      ),
                    ),
                    StatusBadge(o.status),
                  ],
                ),
              ),
            ),
          )).toList(),
    );
  }

  Widget _partyTab(BuildContext context, List<PartyOrder> orders) {
    if (orders.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: EmptyState(icon: Icons.receipt_long_outlined, message: 'No party orders yet'));
    return Column(
      children: orders.map((o) {
        final isPending = o.status == 'pending';
        final progress = o.approvedAmount > 0 ? o.paid / o.approvedAmount : 0.0;
        return _tileBorder(
          InkWell(
            onTap: () => context.push('/party-orders/${o.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: kTintAttention, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.receipt_long_outlined, size: 15, color: kInkAttention),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Party: ${o.party}', style: kTypeBody.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        if (!isPending) ...[
                          Text('Paid ₹${o.paid} of ₹${o.approvedAmount} · Remaining ₹${o.remaining}', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 4, backgroundColor: kBorderSubtle, color: progress >= 1.0 ? kStatusSuccess : kAccentPrimary),
                          ),
                        ] else
                          Text('₹${o.amount}', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PartyStatusChip(status: o.status),
                      if (!isPending) ...[
                        const SizedBox(height: 4),
                        Text('+${o.pointsAwarded} pts', style: const TextStyle(color: kStatusSuccess, fontSize: 11, fontWeight: FontWeight.w500)),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text('~${o.maxPoints} pts', style: const TextStyle(color: kTextMuted, fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _redemptionsTab(BuildContext context, List<Redemption> redemptions) {
    if (redemptions.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: EmptyState(icon: Icons.card_giftcard_outlined, message: 'No gift redemptions yet'));
    return Column(
      children: redemptions.map((r) => _tileBorder(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: kTintAudience, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.card_giftcard_outlined, size: 15, color: kAudienceColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.giftName, style: kTypeBody.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${r.points} pts', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  StatusBadge(r.status),
                ],
              ),
            ),
          )).toList(),
    );
  }

  Widget _leadsTab(BuildContext context, List<AdminLead> leads) {
    if (leads.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: EmptyState(icon: Icons.lightbulb_outline, message: 'No leads yet'));
    return Column(
      children: leads.map((l) => _tileBorder(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: kTintSuccess, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.lightbulb_outline, size: 15, color: kInkSuccess),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.customer, style: kTypeBody.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(l.phone, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  StatusBadge(l.status),
                ],
              ),
            ),
          )).toList(),
    );
  }

  Widget _tileBorder(Widget child) => Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorderSubtle, width: 0.5))),
        child: child,
      );
}

/// Opens the carpenter's last reported position in Google Maps.
///
/// Deliberately a button rather than the inline 220px map that used to sit
/// further down this page: the position is worth checking now and then, not
/// worth a permanent third of the screen.
///
/// Disabled when the app has never reported a fix, with the reason in the
/// tooltip -- opening Maps on a null pair would land on (0, 0) in the Gulf
/// of Guinea and look like real data.
class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.carpenter});
  final Carpenter carpenter;

  @override
  Widget build(BuildContext context) {
    final c = carpenter;
    final hasFix = c.lat != null && c.lng != null;
    return Tooltip(
      message: hasFix
          ? 'Last seen ${c.lastSeen} · opens Google Maps in a new tab'
          : 'No location reported yet. The carpenter app reports a position while it is open.',
      child: OutlinedButton.icon(
        onPressed: hasFix
            ? () => launchUrl(
                  Uri.parse('https://www.google.com/maps/search/?api=1&query=${c.lat},${c.lng}'),
                  mode: LaunchMode.externalApplication,
                )
            : null,
        icon: const Icon(Icons.location_on_outlined, size: 16),
        label: const Text('Location'),
      ),
    );
  }
}

/// One "Label 123" pair in the header card's detail line.
class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label ', style: const TextStyle(color: kTextMuted, fontSize: 12)),
          TextSpan(text: value, style: kTypeBody.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
