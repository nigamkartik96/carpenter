import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cloudinary_service.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final live = app.offers.where((o) => o.status != 'Withdrawn').toList();
    final past = app.offers.where((o) => o.status == 'Withdrawn').toList();
    final today = live.where((o) => o.category == 'Today').toList();
    final weekly = live.where((o) => o.category == 'Weekly').toList();
    final other = live.where((o) => o.category != 'Today' && o.category != 'Weekly').toList();

    Widget tile(AdminOffer o) => AppCard(
          onTap: () => context.push('/offers/${o.id}'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (o.bannerUrl != null) ...[
                ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(o.bannerUrl!, width: 36, height: 36, fit: BoxFit.cover)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(o.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text('Valid till ${o.validTill}', style: const TextStyle(color: kMuted, fontSize: 12))],
                ),
              ),
              StatusBadge(o.status),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: kMuted),
            ],
          ),
        );

    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Heading('Offers', subtitle: 'Today and weekly promotions'),
            ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (_) => const _NewOfferDialog()),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New offer'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SubHeading('Today'),
        const SizedBox(height: 8),
        if (today.isEmpty) const EmptyState(icon: Icons.local_offer_outlined, message: 'No live offers'),
        ...today.map(tile),
        const SizedBox(height: 12),
        const SubHeading('Weekly'),
        const SizedBox(height: 8),
        if (weekly.isEmpty) const EmptyState(icon: Icons.local_offer_outlined, message: 'No live offers'),
        ...weekly.map(tile),
        if (other.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SubHeading('Other'),
          const SizedBox(height: 8),
          ...other.map(tile),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SubHeading('Past offers'),
          const SizedBox(height: 8),
          ...past.map(tile),
        ],
      ],
    );
  }
}

class OfferDetailScreen extends StatelessWidget {
  const OfferDetailScreen({super.key, required this.offerId});
  final String offerId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final o = app.offerById(offerId);
    if (o == null) return const Scaffold(body: Center(child: Text('Offer not found')));
    return Scaffold(
      appBar: AppBar(title: Text(o.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BackLink(label: 'Back to Offers', onTap: () => context.go('/offers')),
          const SizedBox(height: 8),
          if (o.bannerUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(o.bannerUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              StatusBadge(o.status),
            ],
          ),
          const SizedBox(height: 6),
          Text('${o.category} · Valid till ${o.validTill}', style: const TextStyle(color: kMuted, fontSize: 13)),
          if (o.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(o.description, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
          const SizedBox(height: 16),
          Text(
            o.targetCarpenterIds == null || o.targetCarpenterIds!.isEmpty
                ? 'Sent to: all approved carpenters'
                : 'Sent to: ${o.targetCarpenterIds!.length} selected carpenter(s)',
            style: const TextStyle(color: kMuted, fontSize: 13),
          ),
          if (o.pdfUrl != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(o.pdfUrl!), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('View PDF'),
            ),
          ],
          const SizedBox(height: 24),
          if (o.status != 'Withdrawn')
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await confirmDialog(context, title: 'Withdraw this offer?', message: '"${o.title}" will be removed from the app immediately for all carpenters.', confirmLabel: 'Withdraw', danger: true);
                if (confirmed && context.mounted) {
                  await context.read<AdminState>().withdrawOffer(o);
                  if (context.mounted) context.pop();
                }
              },
              style: OutlinedButton.styleFrom(foregroundColor: kDanger, side: const BorderSide(color: kDanger)),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Withdraw offer'),
            ),
        ],
      ),
    );
  }
}

class _NewOfferDialog extends StatefulWidget {
  const _NewOfferDialog();

  @override
  State<_NewOfferDialog> createState() => _NewOfferDialogState();
}

class _NewOfferDialogState extends State<_NewOfferDialog> {
  final title = TextEditingController();
  final description = TextEditingController();
  String category = 'Today';
  DateTime otherDate = DateTime.now().add(const Duration(days: 1));
  bool uploading = false;
  bool saving = false;
  bool submitted = false;
  String? bannerUrl;
  String? pdfUrl;

  bool allCarpenters = true;
  final Set<String> selectedIds = {};
  DateTime? activitySince;
  String activityFilter = 'none'; // 'none' | 'ordered' | 'notOrdered'
  String sortBy = 'name'; // 'name' | 'lastOrder' | 'totalAmount'

  Future<void> _pickActivitySince() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: activitySince ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => activitySince = picked);
  }

  Future<void> _pickAndUpload({required bool isPdf}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: isPdf ? FileType.custom : FileType.image,
        allowedExtensions: isPdf ? ['pdf'] : null,
        withData: true,
      );
      final file = result?.files.single;
      if (file?.bytes == null) return;
      setState(() => uploading = true);
      final url = await CloudinaryService.instance.uploadBytes(file!.bytes!, file.name);
      setState(() {
        if (isPdf) {
          pdfUrl = url;
        } else {
          bannerUrl = url;
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  String get _computedValidTill {
    final now = DateTime.now();
    switch (category) {
      case 'Today':
        return fmtDate(now.add(const Duration(days: 1)));
      case 'Weekly':
        return fmtDate(now.add(const Duration(days: 7)));
      default:
        return fmtDate(otherDate);
    }
  }

  Future<void> _pickOtherDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: otherDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => otherDate = picked);
  }

  Future<void> _close() async {
    if (title.text.isNotEmpty || description.text.isNotEmpty || bannerUrl != null || pdfUrl != null) {
      final discard = await confirmDialog(context, title: 'Discard this offer?', message: 'You have unsaved changes that will be lost.', confirmLabel: 'Discard');
      if (!discard) return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New offer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    IconButton(icon: const Icon(Icons.close), onPressed: _close),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: uploading ? null : () => _pickAndUpload(isPdf: false),
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
                            clipBehavior: Clip.antiAlias,
                            child: uploading
                                ? const Center(child: CircularProgressIndicator())
                                : bannerUrl != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(bannerUrl!, fit: BoxFit.cover),
                                          Positioned(
                                            right: 6,
                                            top: 6,
                                            child: Material(
                                              color: Colors.black54,
                                              shape: const CircleBorder(),
                                              child: IconButton(icon: const Icon(Icons.edit, color: Colors.white, size: 16), onPressed: () => _pickAndUpload(isPdf: false)),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.image_outlined, color: kMuted, size: 28),
                                            SizedBox(height: 6),
                                            Text('Tap to add a banner image', style: TextStyle(color: kMuted, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'Title',
                          error: submitted && title.text.trim().isEmpty ? 'Title is required' : null,
                          child: TextField(controller: title, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'e.g. आज का ऑफ़र')),
                        ),
                        const SizedBox(height: 10),
                        LabeledField(
                          label: 'Description (optional)',
                          child: TextField(controller: description, maxLines: 2, decoration: const InputDecoration(hintText: 'Shown on the offer detail page')),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: uploading ? null : () => _pickAndUpload(isPdf: true),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                          label: Text(pdfUrl != null ? 'PDF uploaded' : 'Add PDF (optional)'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: category,
                                items: const [
                                  DropdownMenuItem(value: 'Today', child: Text('Today')),
                                  DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (v) => setState(() => category = v ?? 'Today'),
                                decoration: const InputDecoration(labelText: 'Category'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: category == 'Other'
                                  ? InkWell(
                                      onTap: _pickOtherDate,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(labelText: 'Valid till'),
                                        child: Text(fmtDate(otherDate)),
                                      ),
                                    )
                                  : InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Valid till (auto)'),
                                      child: Text(_computedValidTill),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const SubHeading('Send to'),
                        const SizedBox(height: 6),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          value: allCarpenters,
                          title: const Text('All approved carpenters', style: TextStyle(fontSize: 13)),
                          onChanged: (v) => setState(() => allCarpenters = v ?? true),
                        ),
                        if (!allCarpenters) _CarpenterPicker(app: app, dialog: this),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _close, child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setState(() => submitted = true);
                              if (title.text.trim().isEmpty) return;
                              setState(() => saving = true);
                              try {
                                await app.addOffer(
                                  title.text,
                                  category,
                                  _computedValidTill,
                                  description: description.text.trim(),
                                  bannerUrl: bannerUrl,
                                  pdfUrl: pdfUrl,
                                  targetCarpenterIds: allCarpenters ? null : selectedIds.toList(),
                                );
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                if (mounted) {
                                  setState(() => saving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not publish offer: $e')));
                                }
                              }
                            },
                      child: Text(saving ? 'Publishing...' : 'Publish offer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets the admin narrow the "send to" list by recent order activity (a
/// date + ordered/not-ordered toggle, since "activity" for a carpenter is
/// defined by their order history) and sort it by last order date or total
/// order amount, then check off specific carpenters.
class _CarpenterPicker extends StatefulWidget {
  const _CarpenterPicker({required this.app, required this.dialog});
  final AdminState app;
  final _NewOfferDialogState dialog;

  @override
  State<_CarpenterPicker> createState() => _CarpenterPickerState();
}

class _CarpenterPickerState extends State<_CarpenterPicker> {
  @override
  Widget build(BuildContext context) {
    final s = widget.dialog;
    var list = widget.app.carpenters.where((c) => c.status == 'Approved').toList();

    if (s.activityFilter != 'none' && s.activitySince != null) {
      list = list.where((c) {
        final last = widget.app.lastOrderDate(c.id);
        final hasRecentOrder = last != null && !last.isBefore(s.activitySince!);
        return s.activityFilter == 'ordered' ? hasRecentOrder : !hasRecentOrder;
      }).toList();
    }

    switch (s.sortBy) {
      case 'lastOrder':
        list.sort((a, b) {
          final da = widget.app.lastOrderDate(a.id);
          final db = widget.app.lastOrderDate(b.id);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
        break;
      case 'totalAmount':
        list.sort((a, b) => widget.app.totalOrderAmount(b.id).compareTo(widget.app.totalOrderAmount(a.id)));
        break;
      default:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String>(
                value: s.activityFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('No activity filter', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'ordered', child: Text('Ordered since...', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'notOrdered', child: Text('Not ordered since...', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (v) => setState(() => s.activityFilter = v ?? 'none'),
              ),
              if (s.activityFilter != 'none')
                OutlinedButton.icon(
                  onPressed: () async {
                    await s._pickActivitySince();
                    setState(() {});
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 14),
                  label: Text(s.activitySince == null ? 'Pick date' : fmtDate(s.activitySince!), style: const TextStyle(fontSize: 12)),
                ),
              const Text('Sort by', style: TextStyle(fontSize: 13, color: kMuted)),
              DropdownButton<String>(
                value: s.sortBy,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Name', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'lastOrder', child: Text('Last order date', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'totalAmount', child: Text('Total order amount', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (v) => setState(() => s.sortBy = v ?? 'name'),
              ),
              TextButton(onPressed: () => setState(() => s.selectedIds.addAll(list.map((c) => c.id))), child: const Text('Select all shown', style: TextStyle(fontSize: 12))),
              TextButton(onPressed: () => setState(s.selectedIds.clear), child: const Text('Clear', style: TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 6),
          Text('${s.selectedIds.length} selected', style: const TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: list.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No carpenters match this filter', style: TextStyle(color: kMuted, fontSize: 13)))
                : ListView(
                    shrinkWrap: true,
                    children: list.map((c) {
                      final last = widget.app.lastOrderDate(c.id);
                      final total = widget.app.totalOrderAmount(c.id);
                      return CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: s.selectedIds.contains(c.id),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            s.selectedIds.add(c.id);
                          } else {
                            s.selectedIds.remove(c.id);
                          }
                        }),
                        title: Text(c.name, style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          'Last order: ${last != null ? fmtDate(last) : '-'} · Total: ₹$total',
                          style: const TextStyle(fontSize: 11, color: kMuted),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
