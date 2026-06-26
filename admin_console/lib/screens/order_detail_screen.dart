import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cloudinary_service.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'orders_screens.dart' show orderStatuses;

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _ItemRow {
  _ItemRow({String name = '', String qty = '1', String unitCost = '0'})
      : name = TextEditingController(text: name),
        qty = TextEditingController(text: qty),
        unitCost = TextEditingController(text: unitCost);
  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController unitCost;
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<_ItemRow>? rows;
  bool savingItems = false;
  bool uploadingInvoice = false;

  void _initRowsIfNeeded(AdminOrder order) {
    if (rows != null) return;
    rows = order.items.isEmpty
        ? [_ItemRow()]
        : order.items.map((i) => _ItemRow(name: i.name, qty: '${i.qty}', unitCost: '${i.unitCost}')).toList();
  }

  int get _computedTotal {
    int total = 0;
    for (final r in rows ?? []) {
      final qty = int.tryParse(r.qty.text) ?? 0;
      final cost = int.tryParse(r.unitCost.text) ?? 0;
      total += qty * cost;
    }
    return total;
  }

  Future<void> _saveItems(AdminState app, AdminOrder order) async {
    setState(() => savingItems = true);
    try {
      final items = (rows ?? [])
          .where((r) => r.name.text.trim().isNotEmpty)
          .map((r) => OrderItem(
                name: r.name.text.trim(),
                qty: int.tryParse(r.qty.text) ?? 0,
                unitCost: int.tryParse(r.unitCost.text) ?? 0,
              ))
          .toList();
      await app.setOrderItems(order, items);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Items saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => savingItems = false);
    }
  }

  Future<void> _uploadInvoice(AdminState app, AdminOrder order) async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      final file = result?.files.single;
      if (file?.bytes == null) return;
      setState(() => uploadingInvoice = true);
      final url = await CloudinaryService.instance.uploadBytes(file!.bytes!, file.name);
      if (url != null) await app.setOrderInvoice(order, url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => uploadingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final matches = app.orders.where((o) => o.id == widget.orderId);
    final order = matches.isEmpty ? null : matches.first;
    if (order == null) {
      return Scaffold(appBar: AppBar(title: const Text('Order')), body: const Center(child: Text('Order not found')));
    }
    _initRowsIfNeeded(order);

    final isMobile = MediaQuery.of(context).size.width < 700;
    // Once an order is Fulfilled or Delivered, its price has already been
    // used to credit points -- editing line items after that would let the
    // total silently drift from what was actually charged. Delivered is
    // also fully terminal: status can't move at all from there.
    final itemsLocked = order.status == 'Fulfilled' || order.status == 'Delivered';
    final statusLocked = order.status == 'Delivered';

    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber)),
      body: ListView(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.carpenterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${order.type} order', style: const TextStyle(color: kMuted, fontSize: 12)),
                if (order.detail.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(order.detail, style: const TextStyle(fontSize: 13)),
                ],
                if (order.imageUrl != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showImageLightbox(context, order.imageUrl!),
                    child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(order.imageUrl!, height: 160, fit: BoxFit.cover)),
                  ),
                ],
                if (order.audioUrl != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.mic_none, size: 18, color: kPrimary),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Voice note', style: TextStyle(fontSize: 13))),
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(order.audioUrl!), mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Play'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(children: [const Text('Status: ', style: TextStyle(fontSize: 13)), StatusBadge(order.status)]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Line items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(
            itemsLocked
                ? 'This order is ${order.status} -- points were already credited against this total, so line items are locked.'
                : 'Enter the products and prices from the physical invoice -- the total below feeds point crediting.',
            style: TextStyle(color: itemsLocked ? kWarning : kMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(flex: 3, child: Text('Product', style: TextStyle(color: kMuted, fontSize: 12))),
                    Expanded(child: Text('Qty', style: TextStyle(color: kMuted, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Unit cost (Rs)', style: TextStyle(color: kMuted, fontSize: 12))),
                    SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 6),
                ...List.generate(rows!.length, (i) {
                  final r = rows![i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: TextField(controller: r.name, enabled: !itemsLocked, onChanged: (_) => setState(() {}))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: r.qty, enabled: !itemsLocked, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: TextField(controller: r.unitCost, enabled: !itemsLocked, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                        SizedBox(
                          width: 36,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: (!itemsLocked && rows!.length > 1) ? () => setState(() => rows!.removeAt(i)) : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: itemsLocked ? null : () => setState(() => rows!.add(_ItemRow())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add line'),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Rs $_computedTotal', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: kPrimaryDark)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'At ${app.pointRuleAmount} = ${app.pointRulePoints} pt(s), this order earns ${app.pointRuleAmount > 0 ? (_computedTotal ~/ app.pointRuleAmount) * app.pointRulePoints : 0} points once marked Fulfilled.',
                  style: const TextStyle(color: kMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: (itemsLocked || savingItems) ? null : () => _saveItems(app, order),
                  child: Text(savingItems ? 'Saving...' : 'Save items'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Invoice', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                if (order.invoiceUrl != null) ...[
                  const Icon(Icons.file_present_outlined, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Invoice uploaded', style: const TextStyle(fontSize: 13))),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(order.invoiceUrl!), mode: LaunchMode.externalApplication),
                    child: const Text('View'),
                  ),
                  const SizedBox(width: 8),
                ] else
                  const Expanded(child: Text('No invoice uploaded yet', style: TextStyle(color: kMuted, fontSize: 13))),
                OutlinedButton.icon(
                  onPressed: uploadingInvoice ? null : () => _uploadInvoice(app, order),
                  icon: uploadingInvoice
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file, size: 16),
                  label: Text(order.invoiceUrl != null ? 'Replace' : 'Upload invoice'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                const Text('Order status:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 10),
                if (statusLocked)
                  StatusBadge(order.status)
                else
                  StatusDropdown(value: order.status, options: orderStatuses, onChanged: (v) {
                    app.setOrderStatus(order, v);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $v')));
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen image viewer -- tap the order photo to expand, tap the X
/// or anywhere outside the image to close.
void _showImageLightbox(BuildContext context, String url) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: () {}, // swallow taps on the image itself
              child: InteractiveViewer(child: Image.network(url)),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}
