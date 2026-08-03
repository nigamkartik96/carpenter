import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

/// Problems carpenters reported from the app's Feedback screen. Each entry
/// can carry typed text, a voice note, a photo, or any combination -- the
/// voice and photo paths exist because a lot of carpenters won't type.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _page = 0;
  int _perPage = 25;
  bool _openOnly = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final all = _openOnly ? app.feedback.where((f) => f.status == 'New').toList() : app.feedback;
    final paged = pageSlice(all, _page, _perPage);
    return ListView(
      children: [
        Heading(
          'Feedback',
          subtitle: app.newFeedbackCount > 0
              ? '${app.newFeedbackCount} unresolved of ${app.feedback.length}'
              : 'Problems reported by carpenters from the app',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            StatusFilterChip(
              label: 'Unresolved only',
              selected: _openOnly,
              onTap: () => setState(() {
                _openOnly = !_openOnly;
                _page = 0;
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (all.isEmpty)
          EmptyState(
            icon: Icons.feedback_outlined,
            message: _openOnly ? 'Nothing unresolved' : 'No feedback submitted yet',
          ),
        if (all.isNotEmpty) ...[
          PaginationBar(
            total: all.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() {
              _perPage = n;
              _page = 0;
            }),
          ),
          ...paged.map((f) => _FeedbackCard(entry: f, app: app)),
        ],
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.entry, required this.app});
  final FeedbackEntry entry;
  final AdminState app;

  String get _when {
    final d = entry.createdAt;
    if (d == null) return '';
    final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '$date ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final resolved = entry.status == 'Resolved';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.carpenterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      [if (entry.mobile.isNotEmpty) entry.mobile, _when].where((s) => s.isNotEmpty).join('  ·  '),
                      style: const TextStyle(color: kMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (resolved ? kStatusSuccess : kWarning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.status,
                  style: TextStyle(
                    color: resolved ? kStatusSuccess : kWarning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (entry.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(entry.text, style: kTypeBody),
          ],
          if (entry.imageUrl != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showImage(context, entry.imageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(entry.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (entry.audioUrl != null)
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(entry.audioUrl!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Play voice note'),
                ),
              if (entry.mobile.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:${entry.mobile}')),
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: const Text('Call'),
                ),
              ElevatedButton(
                onPressed: () => app.setFeedbackStatus(entry, resolved ? 'New' : 'Resolved'),
                child: Text(resolved ? 'Reopen' : 'Mark resolved'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showImage(BuildContext context, String url) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      child: Center(child: InteractiveViewer(child: Image.network(url))),
    ),
  );
}
