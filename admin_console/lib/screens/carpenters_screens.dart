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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c.name} · ${c.shop}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(c.mobile, style: const TextStyle(color: kMuted, fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton(onPressed: () => app.approve(c), child: const Text('Approve')),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Reject this carpenter?'),
                                content: Text('${c.name} will not be able to log in. This cannot be undone from here.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
                                ],
                              ),
                            );
                            if (confirmed == true) app.reject(c);
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
                  child: _CarpenterTile(carpenter: c, onTap: () => context.push('/carpenters/${c.id}')),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _CarpenterTile extends StatelessWidget {
  const _CarpenterTile({required this.carpenter, required this.onTap});
  final Carpenter carpenter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: kPrimary.withOpacity(0.12),
                backgroundImage: carpenter.photoUrl != null ? NetworkImage(carpenter.photoUrl!) : null,
                child: carpenter.photoUrl == null
                    ? Text(
                        carpenter.name.isNotEmpty ? carpenter.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 20),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(carpenter.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(carpenter.shop, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 8),
              StatusBadge(carpenter.status),
            ],
          ),
        ),
      ),
    );
  }
}
