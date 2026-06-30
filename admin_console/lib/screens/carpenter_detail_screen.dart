import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'orders_screens.dart' show orderAmountLabel;

/// Full profile for one carpenter: contact info, last known location, and
/// every related record (orders, gift redemptions, leads) so an admin
/// doesn't have to cross-reference four separate screens by name.
class CarpenterDetailScreen extends StatelessWidget {
  const CarpenterDetailScreen({super.key, required this.carpenterId});
  final String carpenterId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final matches = app.carpenters.where((c) => c.id == carpenterId);
    if (matches.isEmpty) {
      return const Scaffold(body: Center(child: Text('Carpenter not found')));
    }
    final c = matches.first;
    final orders = app.ordersFor(carpenterId);
    final redemptions = app.redemptionsFor(carpenterId);
    final leads = app.leadsFor(carpenterId);

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
                      Text(c.shop, style: const TextStyle(color: kMuted, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(c.mobile, style: const TextStyle(fontSize: 13)),
                      Text(c.area, style: const TextStyle(color: kMuted, fontSize: 12)),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // One compact stat row instead of four near-identical sparse
          // blocks -- sections below only expand if they have content.
          Row(
            children: [
              Expanded(child: _MiniStat(icon: Icons.workspace_premium_outlined, label: 'Points', value: '${c.points}')),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(icon: Icons.inventory_2_outlined, label: 'Orders', value: '${orders.length}')),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(icon: Icons.card_giftcard_outlined, label: 'Redemptions', value: '${redemptions.length}')),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(icon: Icons.lightbulb_outline, label: 'Leads', value: '${leads.length}')),
            ],
          ),
          const SizedBox(height: 16),
          const SubHeading('Location'),
          const SizedBox(height: 8),
          if (c.lat != null && c.lng != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${c.lat},${c.lng}'), mode: LaunchMode.externalApplication),
                child: AbsorbPointer(
                  child: SizedBox(
                    height: 220,
                    child: FlutterMap(
                      options: MapOptions(initialCenter: LatLng(c.lat!, c.lng!), initialZoom: 14),
                      children: [
                        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.carpenterhub.admin_console'),
                        MarkerLayer(markers: [
                          Marker(
                            point: LatLng(c.lat!, c.lng!),
                            width: 32,
                            height: 32,
                            child: const Icon(Icons.location_on, color: kPrimaryDark, size: 32),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              onTap: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${c.lat},${c.lng}'), mode: LaunchMode.externalApplication),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Last seen: ${c.lastSeen}', style: const TextStyle(fontSize: 13))),
                  const Icon(Icons.open_in_new, size: 16, color: kMuted),
                  const SizedBox(width: 6),
                  const Text('Open map', style: TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
            ),
          ] else
            const EmptyState(icon: Icons.location_off_outlined, message: 'No location reported yet'),
          if (orders.isNotEmpty) ...[
            const SizedBox(height: 20),
            SubHeading('Orders (${orders.length})'),
            const SizedBox(height: 8),
            ...orders.map((o) => AppCard(
                  onTap: () => context.push('/orders/${o.id}'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 13, color: kTextPrimary),
                            children: [
                              TextSpan(text: '${o.orderNumber} · '),
                              TextSpan(
                                text: orderAmountLabel(o),
                                style: TextStyle(color: o.amount == 0 && o.items.isEmpty ? kTextMuted : kTextPrimary, fontStyle: o.amount == 0 && o.items.isEmpty ? FontStyle.italic : FontStyle.normal),
                              ),
                            ],
                          ),
                        ),
                      ),
                      StatusBadge(o.status),
                    ],
                  ),
                )),
          ],
          if (redemptions.isNotEmpty) ...[
            const SizedBox(height: 20),
            SubHeading('Gift redemptions (${redemptions.length})'),
            const SizedBox(height: 8),
            ...redemptions.map((r) => AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${r.giftName} · ${r.points} pts', style: const TextStyle(fontSize: 13))),
                      StatusBadge(r.status),
                    ],
                  ),
                )),
          ],
          if (leads.isNotEmpty) ...[
            const SizedBox(height: 20),
            SubHeading('Leads (${leads.length})'),
            const SizedBox(height: 8),
            ...leads.map((l) => AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${l.customer} · ${l.phone}', style: const TextStyle(fontSize: 13))),
                      StatusBadge(l.status),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: kBgSurface, borderRadius: BorderRadius.circular(kCardRadius), border: Border.all(color: kBorderSubtle)),
      child: Column(
        children: [
          Icon(icon, size: 18, color: kAccentPrimary),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: const TextStyle(color: kTextMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
