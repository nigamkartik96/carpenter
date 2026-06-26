import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cloudinary_service.dart';
import '../state.dart';
import '../widgets.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  final name = TextEditingController();
  final points = TextEditingController();
  final qty = TextEditingController();
  bool showForm = false;
  bool uploading = false;
  String? imageUrl;

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      final file = result?.files.single;
      if (file?.bytes == null) return;
      setState(() => uploading = true);
      final url = await CloudinaryService.instance.uploadBytes(file!.bytes!, file.name);
      setState(() => imageUrl = url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    return ListView(
      children: [
        const Text('Gift catalog', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const Text('Manage redeemable gifts and stock', style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            if (showForm && (name.text.isNotEmpty || points.text.isNotEmpty || qty.text.isNotEmpty || imageUrl != null)) {
              final discard = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Discard this gift?'),
                  content: const Text('You have unsaved changes that will be lost.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
                  ],
                ),
              );
              if (discard != true) return;
              name.clear();
              points.clear();
              qty.clear();
              imageUrl = null;
            }
            setState(() => showForm = !showForm);
          },
          child: const Text('+ Add gift'),
        ),
        if (showForm)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: uploading ? null : _pickAndUpload,
                      icon: const Icon(Icons.image_outlined, size: 16),
                      label: Text(imageUrl != null ? 'Image uploaded' : 'Add gift image'),
                    ),
                    if (uploading) const Padding(padding: EdgeInsets.only(left: 10), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  Widget field(TextEditingController c, String label) {
                    final tf = TextField(controller: c, decoration: InputDecoration(labelText: label));
                    return isNarrow ? SizedBox(width: double.infinity, child: tf) : Expanded(child: tf);
                  }

                  final addButton = ElevatedButton(
                    onPressed: () {
                      if (name.text.isEmpty) return;
                      app.addGift(name.text, int.tryParse(points.text) ?? 0, int.tryParse(qty.text) ?? 0, imageUrl: imageUrl);
                      name.clear();
                      points.clear();
                      qty.clear();
                      setState(() {
                        showForm = false;
                        imageUrl = null;
                      });
                    },
                    child: const Text('Add to catalog'),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        field(name, 'Gift name'),
                        const SizedBox(height: 8),
                        field(points, 'Points required'),
                        const SizedBox(height: 8),
                        field(qty, 'Stock quantity'),
                        const SizedBox(height: 12),
                        addButton,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      field(name, 'Gift name'),
                      const SizedBox(width: 8),
                      field(points, 'Points required'),
                      const SizedBox(width: 8),
                      field(qty, 'Stock quantity'),
                      const SizedBox(width: 12),
                      addButton,
                    ],
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // A fixed crossAxisCount (was 4) squeezed cards down to ~80px
          // wide on phones, and the fixed aspect ratio made them too
          // short for their content -- both together threw a RenderFlex
          // overflow error on mobile. maxCrossAxisExtent + a fixed
          // mainAxisExtent auto-adjusts columns per screen width and
          // guarantees enough height regardless of text length.
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 120,
          ),
          itemCount: app.gifts.length,
          itemBuilder: (context, i) {
            final g = app.gifts[i];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  g.imageUrl != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(g.imageUrl!, height: 40, width: 40, fit: BoxFit.cover))
                      : const Icon(Icons.card_giftcard, color: kPrimary, size: 22),
                  const SizedBox(height: 6),
                  Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${g.points} pts · ${g.qty} in stock', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
