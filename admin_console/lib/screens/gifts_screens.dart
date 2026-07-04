import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../cloudinary_service.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

const _lowStockThreshold = 5;

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  int _page = 0;
  int _perPage = 25;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final live = app.gifts.where((g) => g.status != 'Withdrawn').toList();
    final past = app.gifts.where((g) => g.status == 'Withdrawn').toList();
    final all = [...live, ...past];

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

    final paged = pageSlice(all, _page, _perPage);

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
        if (all.isEmpty) const EmptyState(icon: Icons.card_giftcard_outlined, message: 'No gifts in the catalog yet'),
        if (all.isNotEmpty) ...[
          PaginationBar(
            total: all.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
          ),
          grid(paged),
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
      appBar: AppBar(title: Text(g.name), automaticallyImplyLeading: false),
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
      child: FormDialog(
        title: 'Add gift',
        subtitle: 'Add a new item to the redemption catalog',
        icon: Icons.card_giftcard_outlined,
        onClose: _close,
        maxWidth: 480,
        maxHeight: 600,
        children: [
          ImagePickerBox(
            imageUrl: imageUrl,
            uploading: uploading,
            onTap: _pickAndUpload,
            hint: 'Click to upload a gift image',
          ),
          const SizedBox(height: spaceMd),
          LabeledField(
            label: 'Gift name',
            error: submitted && name.text.trim().isEmpty ? 'Gift name is required' : null,
            child: TextField(controller: name, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'e.g. Steel measuring tape')),
          ),
          const SizedBox(height: spaceSm),
          LabeledField(
            label: 'Description (optional)',
            child: TextField(controller: description, maxLines: 2, decoration: const InputDecoration(hintText: 'Shown on the gift detail page')),
          ),
          const SizedBox(height: spaceSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Points required',
                  error: submitted && (int.tryParse(points.text) ?? 0) <= 0 ? 'Enter a positive number' : null,
                  child: TextField(controller: points, onChanged: (_) => setState(() {}), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(hintText: '0')),
                ),
              ),
              const SizedBox(width: spaceSm),
              Expanded(
                child: LabeledField(
                  label: 'Stock quantity',
                  error: submitted && (int.tryParse(qty.text) ?? -1) < 0 ? 'Enter a valid quantity' : null,
                  child: TextField(controller: qty, onChanged: (_) => setState(() {}), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(hintText: '0')),
                ),
              ),
            ],
          ),
        ],
        actions: [
          TextButton(onPressed: _close, child: const Text('Cancel')),
          const SizedBox(width: spaceSm),
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
    );
  }
}
