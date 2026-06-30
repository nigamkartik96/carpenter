import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final title = TextEditingController();
  final body = TextEditingController();
  String targetTier = 'All';
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    return ListView(
      children: [
        const Heading('Notification center', subtitle: 'Broadcast updates to carpenters'),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: body, decoration: const InputDecoration(labelText: 'Message'), maxLines: 2),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: targetTier,
                decoration: const InputDecoration(labelText: 'Send to'),
                items: ['All', ...carpenterTiers].map((t) => DropdownMenuItem(value: t, child: Text(t == 'All' ? 'All approved carpenters' : '$t tier only'))).toList(),
                onChanged: (v) => setState(() => targetTier = v ?? 'All'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        if (title.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title before sending')));
                          return;
                        }
                        setState(() => sending = true);
                        try {
                          await app.broadcastNotification(title.text, body.text, targetTier);
                          title.clear();
                          body.clear();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent')));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
                        } finally {
                          if (mounted) setState(() => sending = false);
                        }
                      },
                child: Text(sending ? 'Sending...' : 'Send notification'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SubHeading('Recently sent'),
        const SizedBox(height: 8),
        if (app.broadcasts.isEmpty) const Text('No notifications sent yet', style: TextStyle(color: kMuted, fontSize: 13)),
        ...app.broadcasts.map((b) => AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (b.body.isNotEmpty && b.body != b.title) Text(b.body, style: const TextStyle(color: kMuted, fontSize: 12)),
                        Text(b.date, style: const TextStyle(color: kMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  pill(b.tier),
                ],
              ),
            )),
      ],
    );
  }
}

Widget pill(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: kPrimaryDark, fontSize: 11, fontWeight: FontWeight.w600)),
    );
