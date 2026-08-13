import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'creator_home_screen.dart' show PartyOrderDialog, RecordPaymentDialog;
import 'party_orders_screen.dart' show PartyStatusChip;

/// Carpenters list for the order-creator role. Shows only approved carpenters
/// in a searchable grid -- no approve/reject, no tier management.
class CreatorCarpentersScreen extends StatefulWidget {
  const CreatorCarpentersScreen({super.key});

  @override
  State<CreatorCarpentersScreen> createState() => _CreatorCarpentersScreenState();
}

class _CreatorCarpentersScreenState extends State<CreatorCarpentersScreen> {
  final search = TextEditingController();
  int _page = 0;
  int _perPage = 25;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final q = search.text.trim().toLowerCase();
    final filtered = app.carpenters.where((c) {
      if (c.status != 'Approved') return false;
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) || c.shop.toLowerCase().contains(q) || c.mobile.contains(q);
    }).toList();
    final paged = pageSlice(filtered, _page, _perPage);

    return ListView(
      children: [
        const Heading('Carpenters', subtitle: 'View carpenters and their party orders'),
        const SizedBox(height: 20),
        if (app.carpenters.isEmpty)
          const EmptyState(icon: Icons.people_outline, message: 'No carpenters yet')
        else ...[
          TextField(
            controller: search,
            onChanged: (_) => setState(() => _page = 0),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search by name, shop or mobile', isDense: true),
          ),
          const SizedBox(height: 10),
          PaginationBar(
            total: filtered.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
          ),
          if (filtered.isEmpty)
            const EmptyState(icon: Icons.filter_alt_off_outlined, message: 'No carpenters match this search')
          else
            LayoutBuilder(builder: (context, constraints) {
              final perRow = (constraints.maxWidth / 200).floor().clamp(2, 6);
              const spacing = 12.0;
              final tileWidth = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final c in paged)
                    SizedBox(
                      width: tileWidth,
                      child: _CreatorCarpenterTile(
                        carpenter: c,
                        partyOrderCount: app.partyOrdersFor(c.id).length,
                        onTap: () => context.push('/carpenters/${c.id}'),
                      ),
                    ),
                ],
              );
            }),
        ],
      ],
    );
  }
}

class _CreatorCarpenterTile extends StatelessWidget {
  const _CreatorCarpenterTile({required this.carpenter, required this.partyOrderCount, required this.onTap});
  final Carpenter carpenter;
  final int partyOrderCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBgSurface,
      borderRadius: BorderRadius.circular(kCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(kCardRadius), border: Border.all(color: kBorderSubtle)),
          child: Column(
            children: [
              Avatar(photoUrl: carpenter.photoUrl, name: carpenter.name, radius: 32),
              const SizedBox(height: 10),
              Text(carpenter.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: kTypeBody.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(carpenter.shop, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, size: 14, color: kAccentPrimary),
                  const SizedBox(width: 4),
                  Text('${carpenter.points} pts', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kAccentPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              Text('$partyOrderCount party order${partyOrderCount == 1 ? '' : 's'}', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextMuted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carpenter detail screen for the order-creator role. Shows only the
/// carpenter's party orders and a button to create a new one.
class CreatorCarpenterDetailScreen extends StatefulWidget {
  const CreatorCarpenterDetailScreen({super.key, required this.carpenterId});
  final String carpenterId;

  @override
  State<CreatorCarpenterDetailScreen> createState() => _CreatorCarpenterDetailScreenState();
}

class _CreatorCarpenterDetailScreenState extends State<CreatorCarpenterDetailScreen> {
  int _page = 0;
  int _perPage = 10;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final matches = app.carpenters.where((c) => c.id == widget.carpenterId);
    if (matches.isEmpty) {
      return const Scaffold(body: Center(child: Text('Carpenter not found')));
    }
    final c = matches.first;
    final partyOrders = app.partyOrdersFor(widget.carpenterId);

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
                      if (c.area.isNotEmpty) Text(c.area, style: const TextStyle(color: kMuted, fontSize: 12)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 18,
                        runSpacing: 6,
                        children: [
                          _Detail(label: 'Points', value: '${c.points}'),
                          _Detail(label: 'Party orders', value: '${partyOrders.length}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: kBgSurface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showDialog(
                context: context,
                builder: (_) => PartyOrderDialog(initialCarpenterId: c.id, initialCarpenterName: c.name),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderSubtle)),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: kAccentPrimary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add, color: kAccentPrimary),
                    ),
                    const SizedBox(width: spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create party order for ${c.name}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                          const Text('Attach a photo or PDF, enter the party and amount', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: kTextMuted),
                  ],
                ),
              ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 16, color: kTextSecondary),
                      const SizedBox(width: 8),
                      Text('Party orders (${partyOrders.length})', style: kTypeBody.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (partyOrders.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: EmptyState(icon: Icons.receipt_long_outlined, message: 'No party orders yet. Create one above.'))
                else ...[
                  PaginationBar(
                    total: partyOrders.length,
                    page: _page,
                    perPage: _perPage,
                    onPageChanged: (p) => setState(() => _page = p),
                    onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
                  ),
                  ...pageSlice(partyOrders, _page, _perPage).map((o) {
                    final isPending = o.status == 'pending';
                    final collecting = o.status == 'approved';
                    final progress = o.approvedAmount > 0 ? o.paid / o.approvedAmount : 0.0;
                    return Container(
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorderSubtle, width: 0.5))),
                      child: InkWell(
                        onTap: o.editable
                            ? () => showDialog(context: context, builder: (_) => PartyOrderDialog(existing: o))
                            : collecting
                                ? () => showDialog(context: context, builder: (_) => RecordPaymentDialog(order: o))
                                : null,
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
                                  if (o.editable) ...[
                                    const SizedBox(height: 4),
                                    const Icon(Icons.edit_outlined, size: 14, color: kTextMuted),
                                  ],
                                  if (collecting) ...[
                                    const SizedBox(height: 4),
                                    const Icon(Icons.payments_outlined, size: 14, color: kAccentPrimary),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
