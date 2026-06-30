import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cloudinary_service.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  String category = 'Today';
  DateTime otherDate = DateTime.now().add(const Duration(days: 1));
  bool showForm = false;
  bool uploading = false;
  String? bannerUrl;
  String? pdfUrl;

  // Carpenter targeting for the offer being composed.
  bool allCarpenters = true;
  final Set<String> selectedIds = {};
  DateTime? activitySince;
  // 'none' = no activity filter applied to the picker list below;
  // 'active'/'inactive' filters by whether the carpenter has an order
  // on/after [activitySince].
  String activityFilter = 'none';
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
        return _fmt(now.add(const Duration(days: 1)));
      case 'Weekly':
        return _fmt(now.add(const Duration(days: 7)));
      default:
        return _fmt(otherDate);
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final today = app.offers.where((o) => o.category == 'Today').toList();
    final weekly = app.offers.where((o) => o.category == 'Weekly').toList();
    final other = app.offers.where((o) => o.category != 'Today' && o.category != 'Weekly').toList();
    Widget tile(AdminOffer o) => AppCard(
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
              if (o.pdfUrl != null)
                IconButton(
                  tooltip: 'View PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  onPressed: () => launchUrl(Uri.parse(o.pdfUrl!), mode: LaunchMode.externalApplication),
                ),
              const StatusBadge('Live'),
              IconButton(
                tooltip: 'Withdraw offer',
                icon: const Icon(Icons.delete_outline, size: 18, color: kDanger),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Withdraw this offer?'),
                      content: Text('"${o.title}" will be removed from the app immediately for all carpenters.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Withdraw')),
                      ],
                    ),
                  );
                  if (confirmed == true) app.withdrawOffer(o);
                },
              ),
            ],
          ),
        );
    return ListView(
      children: [
        const Heading('Offers', subtitle: 'Today and weekly promotions'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            if (showForm && (title.text.isNotEmpty || description.text.isNotEmpty || bannerUrl != null || pdfUrl != null)) {
              final discard = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Discard this offer?'),
                  content: const Text('You have unsaved changes that will be lost.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
                  ],
                ),
              );
              if (discard != true) return;
              title.clear();
              description.clear();
              bannerUrl = null;
              pdfUrl = null;
            }
            setState(() => showForm = !showForm);
          },
          child: const Text('+ New offer'),
        ),
        if (showForm)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 10),
                TextField(controller: description, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 2),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: uploading ? null : () => _pickAndUpload(isPdf: false),
                      icon: const Icon(Icons.image_outlined, size: 16),
                      label: Text(bannerUrl != null ? 'Banner uploaded' : 'Add banner image'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: uploading ? null : () => _pickAndUpload(isPdf: true),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: Text(pdfUrl != null ? 'PDF uploaded' : 'Add PDF'),
                    ),
                    if (uploading) const Padding(padding: EdgeInsets.only(left: 10), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                  ],
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
                                child: Text(_fmt(otherDate)),
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
                if (!allCarpenters) _CarpenterPicker(app: app, screen: this),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (title.text.isEmpty) return;
                    app.addOffer(
                      title.text,
                      category,
                      _computedValidTill,
                      description: description.text.trim(),
                      bannerUrl: bannerUrl,
                      pdfUrl: pdfUrl,
                      targetCarpenterIds: allCarpenters ? null : selectedIds.toList(),
                    );
                    title.clear();
                    description.clear();
                    setState(() {
                      showForm = false;
                      bannerUrl = null;
                      pdfUrl = null;
                      allCarpenters = true;
                      selectedIds.clear();
                    });
                  },
                  child: const Text('Publish offer'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        const Text('Today', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kMuted)),
        const SizedBox(height: 8),
        ...today.map(tile),
        const SizedBox(height: 12),
        const Text('Weekly', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kMuted)),
        const SizedBox(height: 8),
        ...weekly.map(tile),
        if (other.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Other', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kMuted)),
          const SizedBox(height: 8),
          ...other.map(tile),
        ],
      ],
    );
  }
}

/// Lets the admin narrow the "send to" list by recent order activity (a
/// date + active/inactive toggle) and sort it by last order date or total
/// order amount, then check off specific carpenters.
class _CarpenterPicker extends StatefulWidget {
  const _CarpenterPicker({required this.app, required this.screen});
  final AdminState app;
  final _OffersScreenState screen;

  @override
  State<_CarpenterPicker> createState() => _CarpenterPickerState();
}

class _CarpenterPickerState extends State<_CarpenterPicker> {
  @override
  Widget build(BuildContext context) {
    final s = widget.screen;
    var list = widget.app.carpenters.where((c) => c.status == 'Approved').toList();

    if (s.activityFilter != 'none' && s.activitySince != null) {
      list = list.where((c) {
        final last = widget.app.lastOrderDate(c.id);
        final hasRecentOrder = last != null && !last.isBefore(s.activitySince!);
        return s.activityFilter == 'active' ? hasRecentOrder : !hasRecentOrder;
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
                  DropdownMenuItem(value: 'active', child: Text('Active since...', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive since...', style: TextStyle(fontSize: 13))),
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
                  label: Text(s.activitySince == null ? 'Pick date' : _fmt(s.activitySince!), style: const TextStyle(fontSize: 12)),
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
            constraints: const BoxConstraints(maxHeight: 260),
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
                          'Last order: ${last != null ? _fmt(last) : '-'} · Total: ₹$total',
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
