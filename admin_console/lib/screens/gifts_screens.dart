import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../cloudinary_service.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

const _lowStockThreshold = 5;

class GiftsScreen extends StatelessWidget {
  const GiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final live = app.gifts.where((g) => g.status != 'Withdrawn').toList();
    final past = app.gifts.where((g) => g.status == 'Withdrawn').toList();

    Widget grid(List<AdminGift> gifts) => GridView.builder(
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
            mainAxisExtent: 130,
          ),
          itemCount: gifts.length,
          itemBuilder: (context, i) {
            final g = gifts[i];
            return AppCard(
              onTap: () => context.push('/gifts/${g.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  g.imageUrl != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(g.imageUrl!, height: 40, width: 40, fit: BoxFit.cover))
                      : const Icon(Icons.card_giftcard, color: kPrimary, size: 22),
                  const SizedBox(height: 6),
                  Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    '${g.points} pts · ${g.qty} in stock',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: g.qty == 0 ? kStatusClosed : (g.qty < _lowStockThreshold ? kStatusAttention : kTextSecondary),
                      fontWeight: g.qty < _lowStockThreshold ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  if (g.status == 'Withdrawn') ...[const SizedBox(height: 4), const StatusBadge('Withdrawn')] else if (g.qty == 0) ...[
                    const SizedBox(height: 4),
                    const Text('Out of stock', style: TextStyle(color: kStatusClosed, fontSize: 11, fontWeight: FontWeight.w600)),
                  ] else if (g.qty < _lowStockThreshold) ...[
                    const SizedBox(height: 4),
                    const Text('Low stock', style: TextStyle(color: kStatusAttention, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            );
          },
        );

    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Heading('Gift catalog', subtitle: 'Manage redeemable gifts and stock'),
            ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (_) => const _NewGiftDialog()),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add gift'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (live.isEmpty) const EmptyState(icon: Icons.card_giftcard_outlined, message: 'No gifts in the catalog yet'),
        grid(live),
        if (past.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SubHeading('Withdrawn gifts'),
          const SizedBox(height: 10),
          grid(past),
        ],
      ],
    );
  }
}

class GiftDetailScreen extends StatelessWidget {
  const GiftDetailScreen({super.key, required this.giftId});
  final String giftId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final g = app.giftById(giftId);
    if (g == null) return const Scaffold(body: Center(child: Text('Gift not found')));
    return Scaffold(
      appBar: AppBar(title: Text(g.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BackLink(label: 'Back to Gift catalog', onTap: () => context.go('/gifts')),
          const SizedBox(height: 8),
          if (g.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(g.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(g.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              StatusBadge(g.status),
            ],
          ),
          const SizedBox(height: 6),
          Text('${g.points} points · ${g.qty} in stock', style: const TextStyle(color: kMuted, fontSize: 13)),
          if (g.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(g.description, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
          const SizedBox(height: 24),
          if (g.status != 'Withdrawn')
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await confirmDialog(context, title: 'Withdraw this gift?', message: '"${g.name}" will no longer be redeemable by carpenters.', confirmLabel: 'Withdraw', danger: true);
                if (confirmed && context.mounted) {
                  await context.read<AdminState>().withdrawGift(g);
                  if (context.mounted) context.pop();
                }
              },
              style: OutlinedButton.styleFrom(foregroundColor: kDanger, side: const BorderSide(color: kDanger)),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Withdraw gift'),
            ),
        ],
      ),
    );
  }
}

class _NewGiftDialog extends StatefulWidget {
  const _NewGiftDialog();

  @override
  State<_NewGiftDialog> createState() => _NewGiftDialogState();
}

class _NewGiftDialogState extends State<_NewGiftDialog> {
  final name = TextEditingController();
  final description = TextEditingController();
  final points = TextEditingController();
  final qty = TextEditingController();
  bool uploading = false;
  bool saving = false;
  bool submitted = false;
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

  Future<void> _close() async {
    if (name.text.isNotEmpty || points.text.isNotEmpty || qty.text.isNotEmpty || imageUrl != null) {
      final discard = await confirmDialog(context, title: 'Discard this gift?', message: 'You have unsaved changes that will be lost.', confirmLabel: 'Discard');
      if (!discard) return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AdminState>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add gift', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                          onTap: uploading ? null : _pickAndUpload,
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
                            clipBehavior: Clip.antiAlias,
                            child: uploading
                                ? const Center(child: CircularProgressIndicator())
                                : imageUrl != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(imageUrl!, fit: BoxFit.cover),
                                          Positioned(
                                            right: 6,
                                            top: 6,
                                            child: Material(
                                              color: Colors.black54,
                                              shape: const CircleBorder(),
                                              child: IconButton(icon: const Icon(Icons.edit, color: Colors.white, size: 16), onPressed: _pickAndUpload),
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
                                            Text('Tap to add a gift image', style: TextStyle(color: kMuted, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'Gift name',
                          error: submitted && name.text.trim().isEmpty ? 'Gift name is required' : null,
                          child: TextField(controller: name, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'e.g. Steel measuring tape')),
                        ),
                        const SizedBox(height: 10),
                        LabeledField(
                          label: 'Description (optional)',
                          child: TextField(controller: description, maxLines: 2, decoration: const InputDecoration(hintText: 'Shown on the gift detail page')),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: LabeledField(
                                label: 'Points required',
                                error: submitted && (int.tryParse(points.text) ?? 0) <= 0 ? 'Enter a positive number' : null,
                                child: TextField(controller: points, onChanged: (_) => setState(() {}), keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '0')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LabeledField(
                                label: 'Stock quantity',
                                error: submitted && (int.tryParse(qty.text) ?? -1) < 0 ? 'Enter a valid quantity' : null,
                                child: TextField(controller: qty, onChanged: (_) => setState(() {}), keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '0')),
                              ),
                            ),
                          ],
                        ),
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
                              final valid = name.text.trim().isNotEmpty && (int.tryParse(points.text) ?? 0) > 0 && (int.tryParse(qty.text) ?? -1) >= 0;
                              if (!valid) return;
                              setState(() => saving = true);
                              try {
                                await app.addGift(name.text, int.tryParse(points.text) ?? 0, int.tryParse(qty.text) ?? 0, imageUrl: imageUrl, description: description.text.trim());
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                if (mounted) {
                                  setState(() => saving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add gift: $e')));
                                }
                              }
                            },
                      child: Text(saving ? 'Adding...' : 'Add to catalog'),
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
