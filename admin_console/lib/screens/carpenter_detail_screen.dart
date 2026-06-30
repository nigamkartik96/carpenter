import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'order_detail_screen.dart';

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
      appBar: AppBar(title: Text(c.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: kPrimary.withOpacity(0.12),
                  backgroundImage: c.photoUrl != null ? NetworkImage(c.photoUrl!) : null,
                  child: c.photoUrl == null ? Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 24)) : null,
                ),
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
                            onChanged: (v) {
                              app.setTier(c, v);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.name} moved to $v tier')));
                            },
                          ),
                          if (c.status == 'Pending') ...[
                            ElevatedButton(onPressed: () => app.approve(c), child: const Text('Approve')),
                            OutlinedButton(onPressed: () => app.reject(c), child: const Text('Reject')),
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
          const SubHeading('Location'),
          const SizedBox(height: 8),
          AppCard(
            child: c.lat != null && c.lng != null
                ? Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: kPrimary),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Last seen: ${c.lastSeen}', style: const TextStyle(fontSize: 13))),
                      TextButton.icon(
                        onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${c.lat},${c.lng}'), mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Open map'),
                      ),
                    ],
                  )
                : const Text('No location reported yet', style: TextStyle(color: kMuted, fontSize: 13)),
          ),
          const SizedBox(height: 16),
          SubHeading('Points: ${c.points}'),
          const SizedBox(height: 16),
          SubHeading('Orders (${orders.length})'),
          const SizedBox(height: 8),
          if (orders.isEmpty) const Text('No orders yet', style: TextStyle(color: kMuted, fontSize: 13)),
          ...orders.map((o) => AppCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${o.orderNumber} · ₹${o.amount}', style: const TextStyle(fontSize: 13))),
                    StatusBadge(o.status),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SubHeading('Gift redemptions (${redemptions.length})'),
          const SizedBox(height: 8),
          if (redemptions.isEmpty) const Text('No redemptions yet', style: TextStyle(color: kMuted, fontSize: 13)),
          ...redemptions.map((r) => AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${r.giftName} · ${r.points} pts', style: const TextStyle(fontSize: 13))),
                    StatusBadge(r.status),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SubHeading('Leads (${leads.length})'),
          const SizedBox(height: 8),
          if (leads.isEmpty) const Text('No leads submitted yet', style: TextStyle(color: kMuted, fontSize: 13)),
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
      ),
    );
  }
}
