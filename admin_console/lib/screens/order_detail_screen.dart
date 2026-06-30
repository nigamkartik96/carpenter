import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cloudinary_service.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

// Fixed stage order for the status stepper -- intentionally not the same
// list as orders_screens.dart's `orderStatuses` filter options, since this
// one encodes a strict sequence rather than just "every status that exists".
const _stages = ['Submitted', 'Processing', 'Fulfilled', 'Delivered'];

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

  // Status changes are staged locally until "Save changes" is pressed --
  // clicking "Advance to X" / "Move back to Y" no longer commits
  // immediately, it just sets this and enables the Save button.
  String? pendingStatus;
  List<String> fulfilledGateErrors = [];

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

  /// Section 4.5 -- both conditions checked against the order's already
  /// *persisted* items/invoice (the "Save items" / "Upload invoice"
  /// actions above already commit independently of this status flow),
  /// not the in-progress unsaved row edits.
  List<String> _fulfilledGateErrors(AdminOrder order) {
    final errors = <String>[];
    if (order.items.isEmpty) errors.add('At least one item must be added before fulfilling this order.');
    if (order.invoiceUrl == null) errors.add('Please upload an invoice before marking this order as Fulfilled.');
    return errors;
  }

  Future<void> _saveStatus(BuildContext context, AdminState app, AdminOrder order) async {
    final target = pendingStatus;
    if (target == null || target == order.status) return;

    final fromIndex = _stages.indexOf(order.status);
    final toIndex = _stages.indexOf(target);
    final isForward = toIndex > fromIndex;

    if (target == 'Fulfilled') {
      final errors = _fulfilledGateErrors(order);
      if (errors.isNotEmpty) {
        setState(() => fulfilledGateErrors = errors);
        return;
      }
    }
    setState(() => fulfilledGateErrors = []);

    if (isForward && (target == 'Fulfilled' || target == 'Delivered')) {
      final confirmed = await confirmDialog(
        context,
        title: target == 'Delivered' ? 'Mark as Delivered?' : 'Mark as Fulfilled?',
        message: target == 'Delivered'
            ? 'You are about to mark this order as Delivered. This is the final stage -- no further status changes will be possible. Confirm?'
            : 'You are about to mark this order as Fulfilled. This action cannot be undone. Are you sure?',
        confirmLabel: 'Confirm',
      );
      if (!confirmed) return;
    }

    try {
      await app.setOrderStatus(order, target);
      if (mounted) {
        setState(() => pendingStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $target')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update status: $e')));
    }
  }

  Widget _headerCard(AdminOrder order, BuildContext context) {
    return AppCard(
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
          // Photo orders show the image here; voice/manual orders simply
          // have nothing in its place -- no empty placeholder gap.
          if (order.imageUrl != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showImageLightbox(context, order.imageUrl!),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(order.imageUrl!, height: 160, fit: BoxFit.cover, width: double.infinity)),
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
        ],
      ),
    );
  }

  Widget _lineItemsCard(AdminOrder order, AdminState app, bool itemsLocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubHeading('Line items'),
        const SizedBox(height: 4),
        Text(
          itemsLocked
              ? 'This order is ${order.status} -- points were already credited against this total, so line items are locked.'
              : 'Enter the products and prices from the physical invoice -- the total below feeds point crediting.',
          style: TextStyle(color: itemsLocked ? kWarning : kTextSecondary, fontSize: 12),
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
                  const Text('Total amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text('Rs $_computedTotal', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: kPrimaryDark)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'At ${app.pointRuleAmount} = ${app.pointRulePoints} pt(s), this order earns ${app.pointRuleAmount > 0 ? (_computedTotal ~/ app.pointRuleAmount) * app.pointRulePoints : 0} points once marked Fulfilled.',
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
              if (fulfilledGateErrors.isNotEmpty && order.items.isEmpty) ...[
                const SizedBox(height: 10),
                const Text('At least one item must be added before fulfilling this order.', style: TextStyle(color: kStatusClosed, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: (itemsLocked || savingItems) ? null : () => _saveItems(app, order),
                child: Text(savingItems ? 'Saving...' : 'Save items'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _invoiceCard(AdminOrder order, AdminState app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubHeading('Invoice'),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (order.invoiceUrl != null) ...[
                    const Icon(Icons.file_present_outlined, color: kPrimary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Invoice uploaded', style: TextStyle(fontSize: 13))),
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
              if (fulfilledGateErrors.isNotEmpty && order.invoiceUrl == null) ...[
                const SizedBox(height: 8),
                const Text('Please upload an invoice before marking this order as Fulfilled.', style: TextStyle(color: kStatusClosed, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// The stepper + advance/save/discard action panel. This is the single
  /// most frequent action on the page, so it's surfaced without scrolling
  /// on both layouts -- pinned in the sticky right column on desktop
  /// (Part A), and moved to the very top on mobile (collapsed layout).
  Widget _statusPanel(BuildContext context, AdminState app, AdminOrder order, bool isMobile, {bool sticky = false}) {
    final effectiveStatus = pendingStatus ?? order.status;
    final hasPendingChange = pendingStatus != null && pendingStatus != order.status;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubHeading('Status'),
        const SizedBox(height: 14),
        OrderStatusStepper(effectiveStatus: effectiveStatus, isMobile: isMobile || sticky),
        const SizedBox(height: 16),
        _StatusActions(
          order: order,
          pendingStatus: pendingStatus,
          onStage: (s) => setState(() {
            pendingStatus = s;
            fulfilledGateErrors = [];
          }),
          onDiscard: () => setState(() {
            pendingStatus = null;
            fulfilledGateErrors = [];
          }),
        ),
        if (hasPendingChange) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kAccentPrimary.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: kAccentPrimary),
                const SizedBox(width: 8),
                Expanded(child: Text('Staged change: $pendingStatus -- not saved yet.', style: const TextStyle(fontSize: 12, color: kAccentPrimaryDark))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: hasPendingChange ? () => _saveStatus(context, app, order) : null,
              child: const Text('Save changes'),
            ),
            if (hasPendingChange)
              TextButton(
                onPressed: () => setState(() {
                  pendingStatus = null;
                  fulfilledGateErrors = [];
                }),
                child: const Text('Discard'),
              ),
          ],
        ),
      ],
    );
    return sticky
        ? Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kBgSurface, borderRadius: BorderRadius.circular(kCardRadius), border: Border.all(color: kBorderSubtle)),
            child: content,
          )
        : AppCard(child: content);
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

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isTwoColumn = width >= 1024;
    // Once an order is Fulfilled or Delivered, its price has already been
    // used to credit points -- editing line items after that would let the
    // total silently drift from what was actually charged. Delivered is
    // also fully terminal: status can't move at all from there.
    final itemsLocked = order.status == 'Fulfilled' || order.status == 'Delivered';

    final backLink = BackLink(label: 'Back to Orders', onTap: () => context.go('/orders'));

    Widget body;
    if (isTwoColumn) {
      // Right column isn't itself scrollable -- it sits outside the left
      // column's SingleChildScrollView, so as the admin scrolls through
      // line items it stays pinned in place (the desktop-CSS-"sticky"
      // equivalent for a Flutter Row layout).
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            backLink,
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _headerCard(order, context),
                          const SizedBox(height: 16),
                          _lineItemsCard(order, app, itemsLocked),
                          const SizedBox(height: 16),
                          _invoiceCard(order, app),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 24),
                      child: _statusPanel(context, app, order, isMobile, sticky: true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Single column: status moves to the top so it's visible without
      // scrolling regardless of screen size (Part A, mobile case).
      body = ListView(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        children: [
          backLink,
          const SizedBox(height: 8),
          _statusPanel(context, app, order, isMobile),
          const SizedBox(height: 16),
          _headerCard(order, context),
          const SizedBox(height: 16),
          _lineItemsCard(order, app, itemsLocked),
          const SizedBox(height: 16),
          _invoiceCard(order, app),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber), automaticallyImplyLeading: false),
      body: body,
    );
  }
}

/// The 4-stage horizontal (or vertical, on narrow viewports) progress
/// stepper. Display-only -- it reflects [effectiveStatus] (the order's
/// real status, or a staged-but-unsaved target), nothing here is
/// clickable.
class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({super.key, required this.effectiveStatus, required this.isMobile});
  final String effectiveStatus;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _stages.indexOf(effectiveStatus).clamp(0, _stages.length - 1);
    return isMobile ? _vertical(currentIndex) : _horizontal(currentIndex);
  }

  ({Widget circle, Widget label, Widget subLabel}) _node(int i, int currentIndex) {
    final done = i < currentIndex;
    final current = i == currentIndex;
    final circle = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? kStatusSuccess : Colors.white,
        border: Border.all(color: done ? kStatusSuccess : (current ? kAccentPrimary : kBorderSubtle), width: current ? 3 : 2),
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : current
              ? Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: kAccentPrimary))
              : null,
    );
    final label = Text(_stages[i], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: kTextPrimary));
    final subLabel = Text(
      done ? 'Completed' : (current ? 'In Progress' : 'Pending'),
      style: TextStyle(fontSize: 10, color: done ? kStatusSuccess : (current ? kAccentPrimary : kTextMuted)),
    );
    return (circle: circle, label: label, subLabel: subLabel);
  }

  Widget _horizontal(int currentIndex) {
    final nodes = List.generate(_stages.length, (i) => _node(i, currentIndex));
    return Row(
      children: [
        for (var i = 0; i < nodes.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i == 0) const SizedBox(width: 16),
                    if (i > 0) Expanded(child: Container(height: 2, color: i - 1 < currentIndex ? kStatusSuccess : kBorderSubtle)),
                    nodes[i].circle,
                    if (i < nodes.length - 1) Expanded(child: Container(height: 2, color: i < currentIndex ? kStatusSuccess : kBorderSubtle)),
                    if (i == nodes.length - 1) const SizedBox(width: 16),
                  ],
                ),
                const SizedBox(height: 8),
                nodes[i].label,
                const SizedBox(height: 2),
                nodes[i].subLabel,
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _vertical(int currentIndex) {
    final nodes = List.generate(_stages.length, (i) => _node(i, currentIndex));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < nodes.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  nodes[i].circle,
                  if (i < nodes.length - 1) Container(width: 2, height: 28, color: i < currentIndex ? kStatusSuccess : kBorderSubtle),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [nodes[i].label, nodes[i].subLabel],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// The action row below the stepper -- what's offered depends on the
/// order's *real* status (Section 4.1) and whether a target one is
/// already staged.
class _StatusActions extends StatelessWidget {
  const _StatusActions({required this.order, required this.pendingStatus, required this.onStage, required this.onDiscard});
  final AdminOrder order;
  final String? pendingStatus;
  final ValueChanged<String> onStage;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    if (order.status == 'Delivered') {
      return const Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: kTextMuted),
          SizedBox(width: 8),
          Expanded(child: Text('This order has been delivered and is now closed.', style: TextStyle(color: kTextMuted, fontSize: 13))),
        ],
      );
    }
    if (pendingStatus != null && pendingStatus != order.status) {
      // Already staged -- don't offer more staging buttons until this
      // one is saved or discarded (see the Save/Discard row below it).
      return const SizedBox.shrink();
    }

    final buttons = <Widget>[];
    switch (order.status) {
      case 'Submitted':
        buttons.add(ElevatedButton(onPressed: () => onStage('Processing'), child: const Text('Advance to Processing')));
        break;
      case 'Processing':
        buttons.add(ElevatedButton(onPressed: () => onStage('Fulfilled'), child: const Text('Mark as Fulfilled')));
        break;
      case 'Fulfilled':
        buttons.add(ElevatedButton(onPressed: () => onStage('Delivered'), child: const Text('Mark as Delivered')));
        buttons.add(OutlinedButton(onPressed: () => onStage('Processing'), child: const Text('Move back to Processing')));
        break;
    }
    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
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
