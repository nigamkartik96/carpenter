import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

String _money(int n) => '₹${n.toString()}';

/// Admin list of party orders logged by the order-creator role. Tapping one
/// opens the review screen where the admin approves the amount, records
/// payments (which credit the carpenter points), and completes the order.
class PartyOrdersScreen extends StatefulWidget {
  const PartyOrdersScreen({super.key});

  @override
  State<PartyOrdersScreen> createState() => _PartyOrdersScreenState();
}

class _PartyOrdersScreenState extends State<PartyOrdersScreen> {
  final search = TextEditingController();
  String statusFilter = 'all';
  int _page = 0;
  int _perPage = 10;

  // Admin-facing labels for the status filter chips, mirroring PartyStatusChip.
  static const _statusFilters = [
    ('all', 'All'),
    ('pending', 'Pending'),
    ('approved', 'Collecting payment'),
    ('completed', 'Completed'),
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final orders = app.partyOrders;
    final pending = orders.where((o) => o.status == 'pending').length;

    final q = search.text.trim().toLowerCase();
    final visible = orders.where((o) {
      if (statusFilter != 'all' && o.status != statusFilter) return false;
      if (q.isEmpty) return true;
      return o.carpenterName.toLowerCase().contains(q) || o.party.toLowerCase().contains(q);
    }).toList();

    return ListView(
      children: [
        Heading('Party orders', subtitle: pending > 0 ? '$pending awaiting your approval' : "Orders logged on carpenters' behalf"),
        const SizedBox(height: spaceMd),
        if (orders.isNotEmpty) ...[
          TextField(
            controller: search,
            onChanged: (_) => setState(() => _page = 0),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search by carpenter or party', isDense: true),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, label) in _statusFilters)
                FilterChip(
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  selected: statusFilter == value,
                  onSelected: (_) => setState(() { statusFilter = value; _page = 0; }),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: spaceMd),
        ],
        if (orders.isEmpty)
          const EmptyState(icon: Icons.receipt_long_outlined, message: 'No party orders yet. They will appear here once a creator logs one.')
        else if (visible.isEmpty)
          const EmptyState(icon: Icons.filter_alt_off_outlined, message: 'No party orders match this filter.')
        else ...[
          PaginationBar(
            total: visible.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
          ),
          ...pageSlice(visible, _page, _perPage).map((o) => _PartyOrderCard(order: o, onTap: () => context.go('/party-orders/${o.id}'))),
        ],
      ],
    );
  }
}

/// Party-order status pill (admin-facing wording). Kept alongside the
/// creator's own chip rather than shared, so each side can word the states
/// for its own audience.
class PartyStatusChip extends StatelessWidget {
  const PartyStatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late String label;
    switch (status) {
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Completed';
        break;
      case 'approved':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'Collecting payment';
        break;
      default:
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF4338CA);
        label = 'Pending';
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _PartyOrderCard extends StatelessWidget {
  const _PartyOrderCard({required this.order, this.onTap});
  final PartyOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPending = order.status == 'pending';
    final progress = order.approvedAmount > 0 ? order.paid / order.approvedAmount : 0.0;
    final amount = order.approvedAmount > 0 ? order.approvedAmount : order.amount;

    return InkWell(
      onTap: onTap,
      child: Container(
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
              child: const Icon(Icons.receipt_long_outlined, size: 18, color: kTextSecondary),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.carpenterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Party: ${order.party}', style: const TextStyle(fontSize: 12, color: kTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (!isPending) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: kBorderSubtle,
                        color: progress >= 1.0 ? const Color(0xFF16A34A) : kAccentPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_money(amount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                PartyStatusChip(status: order.status),
                const SizedBox(height: 4),
                Text('+${order.pointsAwarded} pts', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PartyOrderDetailScreen extends StatefulWidget {
  const PartyOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<PartyOrderDetailScreen> createState() => _PartyOrderDetailScreenState();
}

class _PartyOrderDetailScreenState extends State<PartyOrderDetailScreen> {
  final approveAmt = TextEditingController();
  final commissionCtl = TextEditingController(text: '10');
  final payAmt = TextEditingController();
  bool busy = false;
  bool _approvePrefilled = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final o = app.partyOrderById(widget.orderId);
    if (o == null) {
      return ListView(children: [
        BackLink(label: 'Back to party orders', onTap: () => context.go('/party-orders')),
        const SizedBox(height: spaceLg),
        const EmptyState(icon: Icons.search_off, message: 'This order no longer exists.'),
      ]);
    }
    if (!_approvePrefilled) {
      approveAmt.text = (o.approvedAmount > 0 ? o.approvedAmount : o.amount).toString();
      commissionCtl.text = o.commissionPercent.toString();
      _approvePrefilled = true;
    }

    return ListView(
      children: [
        BackLink(label: 'Back to party orders', onTap: () => context.go('/party-orders')),
        const SizedBox(height: spaceMd),
        Row(
          children: [
            Expanded(child: Heading(o.carpenterName, subtitle: 'Party: ${o.party}')),
            PartyStatusChip(status: o.status),
          ],
        ),
        const SizedBox(height: spaceLg),
        FormCard(
          title: 'Order details',
          children: [
            _kv('Carpenter', o.carpenterName),
            _kv('Party', o.party),
            _kv('Amount entered', _money(o.amount)),
            _kv('Date', o.createdAt != null ? _fmt(o.createdAt!) : '-'),
            if (o.fileUrl != null)
              if (o.fileType == 'pdf')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(o.fileUrl!), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('View attached PDF'),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Attached photo', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                      const SizedBox(height: 6),
                      // Tap the inline preview to open the full-resolution image.
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse(o.fileUrl!), mode: LaunchMode.externalApplication),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            o.fileUrl!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) => progress == null
                                ? child
                                : Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    color: kBgApp,
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  ),
                            errorBuilder: (context, error, stack) => Container(
                              height: 200,
                              alignment: Alignment.center,
                              color: kBgApp,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image_outlined, size: 18, color: kTextMuted),
                                  SizedBox(width: 6),
                                  Text('Could not load photo', style: TextStyle(fontSize: 12, color: kTextMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
        const SizedBox(height: spaceMd),
        if (o.status == 'pending') _approveCard(app, o) else _paymentCard(app, o),
      ],
    );
  }

  Widget _approveCard(AdminState app, PartyOrder o) => FormCard(
        title: 'Approve order',
        children: [
          LabeledField(
            label: 'Approved order amount',
            child: TextField(controller: approveAmt, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(prefixText: '₹ ')),
          ),
          const SizedBox(height: spaceMd),
          LabeledField(
            label: 'Commission %',
            child: TextField(controller: commissionCtl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(suffixText: '%', hintText: '10')),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Text('Percentage of each payment credited as points to the carpenter', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
          ),
          Builder(builder: (_) {
            final amt = int.tryParse(approveAmt.text) ?? o.amount;
            final commission = (int.tryParse(commissionCtl.text) ?? 10).clamp(0, 100);
            final expectedPoints = (amt * commission) ~/ 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Max points if fully paid: +$expectedPoints pts (${commission}% of ${_money(amt)})', style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w500)),
            );
          }),
          ElevatedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final amt = int.tryParse(approveAmt.text) ?? o.amount;
                    final commission = (int.tryParse(commissionCtl.text) ?? 10).clamp(0, 100);
                    setState(() => busy = true);
                    try {
                      await app.approvePartyOrder(o, amt, commissionPercent: commission);
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve amount'),
          ),
        ],
      );

  Widget _paymentCard(AdminState app, PartyOrder o) {
    final completed = o.status == 'completed';
    return FormCard(
      title: 'Payments',
      children: [
        Row(
          children: [
            _stat('Approved', _money(o.approvedAmount)),
            const SizedBox(width: 8),
            _stat('Paid so far', _money(o.paid)),
            const SizedBox(width: 8),
            _stat('Remaining', _money(o.remaining)),
          ],
        ),
        const SizedBox(height: spaceSm),
        _kv('Commission', '${o.commissionPercent}%'),
        _kv('Points (${o.commissionPercent}% of received ${_money(o.paid)})', '${(o.paid * o.commissionPercent) ~/ 100} pts'),
        _kv('Points credited to ${o.carpenterName.split(' ').first}', '+${o.pointsAwarded} pts'),
        if (o.payments.isNotEmpty) ...[
          const SizedBox(height: spaceSm),
          const Text('Recorded payments', style: TextStyle(fontSize: 12, color: kTextSecondary)),
          const SizedBox(height: 4),
          ...o.payments.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${_money(p.amount)} received', style: const TextStyle(fontSize: 13)), Text('+${p.points} pts', style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A)))]),
              )),
        ],
        if (!completed) ...[
          const Divider(height: 24, color: kBorderSubtle),
          LabeledField(
            label: 'Record payment received from party',
            child: Row(
              children: [
                Expanded(child: TextField(controller: payAmt, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(hintText: '10000', prefixText: '₹ '))),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => setState(() => payAmt.text = o.remaining.toString()),
                  child: const Text('Fill remaining', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Text('Commission: ${o.commissionPercent}% of payment added as points · max ${_money(o.remaining)}', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        final amt = int.tryParse(payAmt.text) ?? 0;
                        if (amt <= 0) return;
                        if (amt > o.remaining) {
                          await infoDialog(context, title: 'Amount too high', message: 'Payment of ${_money(amt)} exceeds the remaining balance of ${_money(o.remaining)}. Please enter an amount up to ${_money(o.remaining)}.');
                          return;
                        }
                        final settlesOrder = amt >= o.remaining;
                        final thisPoints = (amt * o.commissionPercent) ~/ 100;
                        final totalCollected = o.paid + amt;
                        final totalPoints = o.pointsAwarded + thisPoints;
                        setState(() => busy = true);
                        try {
                          await app.recordPartyPayment(o, amt);
                          payAmt.clear();
                          if (settlesOrder) {
                            await app.completePartyOrder(o);
                            if (mounted) {
                              await infoDialog(
                                context,
                                title: 'Order completed',
                                message: "${o.party}'s order is fully paid. ${_money(totalCollected)} collected and +$totalPoints pts awarded to ${o.carpenterName.split(' ').first}.",
                              );
                            }
                          }
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
                icon: const Icon(Icons.payments_outlined, size: 16),
                label: const Text('Record payment'),
              ),
              const SizedBox(width: spaceSm),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await confirmDialog(context, title: 'Complete this order?', message: 'No more payments can be recorded after completing. ${_money(o.paid)} collected, +${o.pointsAwarded} pts awarded.', confirmLabel: 'Complete');
                        if (!ok) return;
                        setState(() => busy = true);
                        try {
                          await app.completePartyOrder(o);
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Complete order'),
              ),
            ],
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PartyStatusChip(status: 'completed'),
          ),
      ],
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: kBgApp, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(k, style: const TextStyle(color: kTextSecondary, fontSize: 13)), Text(v, style: const TextStyle(fontSize: 13))]),
      );

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
