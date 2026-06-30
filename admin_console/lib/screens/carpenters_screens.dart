import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        const Heading('Carpenters', subtitle: 'Approve new sign-ups and manage existing carpenters'),
        const SizedBox(height: 20),
        if (pending.isNotEmpty) ...[
          const SubHeading('Pending approval'),
          const SizedBox(height: 8),
          ...pending.map((c) => AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Avatar(photoUrl: c.photoUrl, name: c.name, radius: 18),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c.name} · ${c.shop}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(c.mobile, style: const TextStyle(color: kMuted, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final confirmed = await confirmDialog(context, title: 'Approve carpenter?', message: '${c.name} will be able to log in and start placing orders.');
                            if (confirmed) app.approve(c);
                          },
                          child: const Text('Approve'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final confirmed = await confirmDialog(context, title: 'Reject this carpenter?', message: '${c.name} will not be able to log in. This cannot be undone from here.', confirmLabel: 'Reject', danger: true);
                            if (confirmed) app.reject(c);
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
        const SubHeading('All carpenters'),
        const SizedBox(height: 10),
        if (app.carpenters.isEmpty) const EmptyState(icon: Icons.people_outline, message: 'No carpenters yet'),
        LayoutBuilder(builder: (context, constraints) {
          final perRow = (constraints.maxWidth / 200).floor().clamp(2, 6);
          final spacing = 12.0;
          final tileWidth = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final c in app.carpenters)
                SizedBox(
                  width: tileWidth,
                  child: _CarpenterTile(carpenter: c, orderCount: app.ordersFor(c.id).length, onTap: () => context.push('/carpenters/${c.id}')),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _CarpenterTile extends StatelessWidget {
  const _CarpenterTile({required this.carpenter, required this.orderCount, required this.onTap});
  final Carpenter carpenter;
  final int orderCount;
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
              Text(carpenter.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(carpenter.shop, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [StatusBadge(carpenter.status), AudienceBadge(carpenter.tier)]),
              const SizedBox(height: 8),
              Text('$orderCount order${orderCount == 1 ? '' : 's'} · ${carpenter.lastSeen}', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextMuted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
