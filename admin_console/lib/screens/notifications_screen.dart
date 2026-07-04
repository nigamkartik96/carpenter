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
  bool submitted = false;
  int _page = 0;
  int _perPage = 10;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    return ListView(
      children: [
        const Heading('Notification center', subtitle: 'Broadcast updates to carpenters'),
        const SizedBox(height: 16),
        FormCard(
          title: 'New broadcast',
          children: [
            LabeledField(
              label: 'Title',
              error: submitted && title.text.trim().isEmpty ? 'Title is required' : null,
              child: TextField(controller: title, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'e.g. New offer this week')),
            ),
            const SizedBox(height: spaceMd),
            LabeledField(
              label: 'Message (optional)',
              child: TextField(controller: body, maxLines: 2, decoration: const InputDecoration(hintText: 'Shown below the title in the notification')),
            ),
            const SizedBox(height: spaceMd),
            LabeledField(
              label: 'Send to',
              child: DropdownButtonFormField<String>(
                initialValue: targetTier,
                items: ['All', ...carpenterTiers].map((t) => DropdownMenuItem(value: t, child: Text(t == 'All' ? 'All approved carpenters' : '$t tier only'))).toList(),
                onChanged: (v) => setState(() => targetTier = v ?? 'All'),
              ),
            ),
            const SizedBox(height: spaceLg),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      setState(() => submitted = true);
                      if (title.text.trim().isEmpty) return;
                      setState(() => sending = true);
                      try {
                        await app.broadcastNotification(title.text, body.text, targetTier);
                        title.clear();
                        body.clear();
                        setState(() => submitted = false);
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
        const SizedBox(height: 20),
        const SubHeading('Recently sent'),
        const SizedBox(height: 8),
        if (app.broadcasts.isEmpty) const EmptyState(icon: Icons.notifications_outlined, message: 'No notifications sent yet'),
        if (app.broadcasts.isNotEmpty)
          PaginationBar(
            total: app.broadcasts.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
          ),
        ...pageSlice(app.broadcasts, _page, _perPage).map((b) => AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (b.body.isNotEmpty && b.body != b.title) Text(b.body, style: const TextStyle(color: kMuted, fontSize: 12)),
                        Text(b.date, style: const TextStyle(color: kTextMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  AudienceBadge(b.tier),
                ],
              ),
            )),
      ],
    );
  }
}
