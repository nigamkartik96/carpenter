import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Points'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kPrimaryDark, kPrimary], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('Current balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${app.points} pts', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(app.tr('Points activity'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          if (app.ledger.isEmpty) Text(app.tr('No activity yet'), style: TextStyle(color: kMuted, fontSize: 12)),
          ...app.ledger.map(
            (l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.desc, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(l.date, style: TextStyle(color: kMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${l.points >= 0 ? '+' : ''}${l.points}', style: TextStyle(fontWeight: FontWeight.w600, color: l.points >= 0 ? kSuccess : kDanger)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/redeemCash'), child: Text(app.tr('Redeem as cash')))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pushNamed(context, '/gifts'), child: Text(app.tr('Redeem a gift')))),
            ],
          ),
        ],
      ),
    );
  }
}

class RedeemCashScreen extends StatefulWidget {
  const RedeemCashScreen({super.key});

  @override
  State<RedeemCashScreen> createState() => _RedeemCashScreenState();
}

class _RedeemCashScreenState extends State<RedeemCashScreen> {
  final controller = TextEditingController(text: '1000');

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Redeem as cash'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.tr('Convert points to your account'), style: TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
              child: Text(app.trf('Rate: 1 point = 1 rupee. Min {n} pts', app.minRedeemPoints), style: const TextStyle(color: kMuted, fontSize: 12)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: app.tr('Points to redeem')),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.tr('Pays to your account'), style: TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  if (app.bankName.isNotEmpty || app.upiId.isNotEmpty) ...[
                    if (app.bankName.isNotEmpty) Text('${app.bankName}${app.accountNumber.isNotEmpty ? ' ••••${app.accountNumber.substring(app.accountNumber.length > 4 ? app.accountNumber.length - 4 : 0)}' : ''}', style: const TextStyle(fontSize: 13)),
                    if (app.upiId.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('UPI: ${app.upiId}', style: TextStyle(color: kMuted, fontSize: 12))),
                  ] else
                    Text(app.tr('No payout account set up yet'), style: TextStyle(color: kDanger, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (app.bankName.isEmpty && app.upiId.isEmpty)
                  ? null
                  : () async {
                      final amount = int.tryParse(controller.text) ?? 0;
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(app.tr('Confirm redemption')),
                          content: Text(app.trf('Redeem {n} points for cash? This cannot be undone.', amount)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(app.tr('Cancel'))),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(app.tr('Confirm'))),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      final result = await app.redeemCash(amount);
                      if (!context.mounted) return;
                      if (result == 'ok') {
                        Navigator.pushNamed(context, '/redeemCashDone', arguments: amount);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                      }
                    },
              child: Text(app.tr('Confirm redemption')),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pushNamed(context, '/account'), child: Text(app.tr('Change account details'))),
          ],
        ),
      ),
    );
  }
}

class RedeemCashDoneScreen extends StatelessWidget {
  const RedeemCashDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final amount = ModalRoute.of(context)!.settings.arguments as int? ?? 0;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: kSuccess.withOpacity(0.12), shape: BoxShape.circle), child: Icon(Icons.check, color: kSuccess, size: 40)),
            const SizedBox(height: 18),
            Text('$amount on the way', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('$amount points redeemed. Credited within 24 hrs.', style: TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false), child: Text(app.tr('Back to dashboard'))),
          ],
        ),
      ),
    );
  }
}

class GiftStoreScreen extends StatelessWidget {
  const GiftStoreScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(app.tr('Gifts'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), Text('${app.points} pts', style: TextStyle(color: kMuted, fontSize: 12))],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.68 / app.fontScale,
          children: app.gifts.map((g) {
            final outOfStock = g.qty <= 0;
            final notEnoughPoints = app.points < g.points;
            final ok = !outOfStock && !notEnoughPoints;
            final lockedLabel = outOfStock ? app.tr('Out of stock') : (notEnoughPoints ? app.tr('Need ${g.points - app.points} more pts') : app.tr('Locked'));
            return SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  g.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            g.imageUrl!,
                            height: 70,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, color: kPrimary, size: 26),
                          ),
                        )
                      : const Icon(Icons.card_giftcard, color: kPrimary, size: 26),
                  const SizedBox(height: 6),
                  Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${g.points} pts · ${g.qty} left', style: const TextStyle(color: kMuted, fontSize: 11)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ok
                          ? () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(app.tr('Confirm redemption?')),
                                  content: Text('${app.tr('Are you sure you want to redeem this gift?')} (${g.name}, ${g.points} pts)'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(app.tr('Cancel'))),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text(app.tr('Confirm'))),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              final result = await app.redeemGift(g);
                              if (!context.mounted) return;
                              if (result == 'ok') {
                                Navigator.pushNamed(context, '/giftSuccess', arguments: g.name);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                              }
                            }
                          : null,
                      child: Text(ok ? app.tr('Redeem') : lockedLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(app.tr('My gifts'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        if (app.redemptions.isEmpty) Text(app.tr('No gifts redeemed yet'), style: const TextStyle(color: kMuted, fontSize: 12)),
        ...app.redemptions.map(
          (r) => SectionCard(
            onTap: r.status == 'Delivered' ? null : () => _showRedemptionDetail(context, app, r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.giftName, style: const TextStyle(fontSize: 13)), Text(r.date, style: const TextStyle(color: kMuted, fontSize: 11))]),
                StatusBadge(r.status),
              ],
            ),
          ),
        ),
      ],
    );
    if (embedded) return body;
    return Scaffold(appBar: AppBar(title: Text(app.tr('Gifts'))), body: body);
  }
}

Future<void> _showRedemptionDetail(BuildContext context, AppState app, GiftRedemption r) async {
  final markDelivered = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(r.giftName),
      content: Text('${app.tr('Delivery status')}: ${r.status}\n${r.points} pts · ${r.date}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(app.tr('Cancel'))),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(app.tr('I received this'))),
      ],
    ),
  );
  if (markDelivered != true) return;
  try {
    await app.markRedemptionDelivered(r.id);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.tr('Mark as delivered'))));
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update: $e')));
  }
}

class GiftSuccessScreen extends StatelessWidget {
  const GiftSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final name = ModalRoute.of(context)!.settings.arguments as String? ?? '';
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: kSuccess.withOpacity(0.12), shape: BoxShape.circle), child: Icon(Icons.card_giftcard, color: kSuccess, size: 38)),
            const SizedBox(height: 18),
            Text(app.tr('Gift redeemed'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('$name. We will notify you on each update.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false), child: Text(app.tr('Back to dashboard'))),
          ],
        ),
      ),
    );
  }
}

class LeadsScreen extends StatelessWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Suggestions'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/leadNew'), child: Text('+ ${app.tr('Submit lead')}')),
          const SizedBox(height: 16),
          Text(app.tr('Your leads'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          if (app.leads.isEmpty) Text(app.tr('No leads submitted yet'), style: TextStyle(color: kMuted, fontSize: 12)),
          ...app.leads.map(
            (l) => SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (l.notes.isNotEmpty) Text(l.notes, style: const TextStyle(color: kMuted, fontSize: 12)),
                        if (l.location.isNotEmpty) Text('📍 ${l.location}', style: const TextStyle(color: kMuted, fontSize: 11)),
                        if (l.pointsAwarded > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${app.tr('Points earned')}: +${l.pointsAwarded}', style: const TextStyle(color: kSuccess, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(l.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeadNewScreen extends StatefulWidget {
  const LeadNewScreen({super.key});

  @override
  State<LeadNewScreen> createState() => _LeadNewScreenState();
}

class _LeadNewScreenState extends State<LeadNewScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final location = TextEditingController();
  final notes = TextEditingController();
  String? error;
  bool submitting = false;
  bool locating = false;
  double? lat;
  double? lng;

  Future<void> _useCurrentLocation() async {
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => error = 'Location services are off');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => error = 'Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      setState(() {
        lat = pos.latitude;
        lng = pos.longitude;
        location.text = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        error = null;
      });
    } catch (e) {
      setState(() => error = 'Could not get location: $e');
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Suggest a lead'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(app.tr('Refer someone who needs work done'), style: const TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 14),
          TextField(controller: name, decoration: InputDecoration(labelText: app.tr('Name'))),
          const SizedBox(height: 10),
          TextField(controller: phone, decoration: InputDecoration(labelText: app.tr('Phone number'))),
          const SizedBox(height: 10),
          TextField(controller: location, decoration: InputDecoration(labelText: app.tr('Location (optional)'))),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: locating ? null : _useCurrentLocation,
              icon: locating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, size: 16),
              label: Text(app.tr('Use current location')),
            ),
          ),
          const SizedBox(height: 10),
          TextField(controller: notes, decoration: InputDecoration(labelText: app.tr('Remarks')), maxLines: 2),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: kDanger, fontSize: 12))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: submitting
                ? null
                : () async {
                    if (name.text.trim().isEmpty || phone.text.trim().isEmpty) {
                      setState(() => error = app.tr('Name and phone number are required'));
                      return;
                    }
                    setState(() {
                      error = null;
                      submitting = true;
                    });
                    try {
                      await app.addLead(Lead(name: name.text, phone: phone.text, location: location.text, notes: notes.text, lat: lat, lng: lng));
                      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
                    } catch (e) {
                      if (mounted) setState(() => error = 'Could not submit lead: $e');
                    } finally {
                      if (mounted) setState(() => submitting = false);
                    }
                  },
            child: Text(submitting ? app.tr('Submitting...') : app.tr('Submit lead')),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark unread notifications as read once the carpenter actually views
    // this screen, so the bell badge clears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().markNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Notifications'))),
      body: app.notifications.isEmpty
          ? Center(child: Text(app.tr('No notifications yet'), style: TextStyle(color: kMuted, fontSize: 13)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: app.notifications.length,
        itemBuilder: (context, i) {
          final n = app.notifications[i];
          final linkedOffer = n.type == 'offer' ? app.offers.where((o) => o.id == n.refId) : const Iterable<Offer>.empty();
          final offer = linkedOffer.isEmpty ? null : linkedOffer.first;
          return SectionCard(
            onTap: offer == null ? null : () => Navigator.pushNamed(context, '/offerDetails', arguments: offer),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined, color: n.read ? kMuted : kPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(n.body, style: TextStyle(color: kMuted, fontSize: 12)),
                      Text(n.time, style: TextStyle(color: kMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
