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
        const Text('Offers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const Text('Today and weekly promotions', style: TextStyle(color: kMuted, fontSize: 13)),
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
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (title.text.isEmpty) return;
                    app.addOffer(title.text, category, _computedValidTill, description: description.text.trim(), bannerUrl: bannerUrl, pdfUrl: pdfUrl);
                    title.clear();
                    description.clear();
                    setState(() {
                      showForm = false;
                      bannerUrl = null;
                      pdfUrl = null;
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
