import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../cloudinary_service.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

/// Landing screen for the order-creator role. A stripped-down dashboard:
/// just the "Create order" action and this creator's own submitted party
/// orders. Everything else in the console is hidden for this role (see the
/// router redirect and role-aware sidebar).
class CreatorHomeScreen extends StatefulWidget {
  const CreatorHomeScreen({super.key});

  @override
  State<CreatorHomeScreen> createState() => _CreatorHomeScreenState();
}

class _CreatorHomeScreenState extends State<CreatorHomeScreen> {
  int _page = 0;
  int _perPage = 10;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final orders = app.partyOrders;
    return ListView(
      children: [
        const Heading('Create order', subtitle: "Log an order taken from a party on a carpenter's behalf"),
        const SizedBox(height: spaceLg),
        Material(
          color: kBgSurface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => showDialog(context: context, builder: (_) => const _PartyOrderDialog()),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderSubtle)),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: kAccentPrimary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add, color: kAccentPrimary),
                  ),
                  const SizedBox(width: spaceMd),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create order', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                        Text('Attach a photo or PDF, pick the carpenter, enter the amount', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kTextMuted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: spaceXl),
        const SubHeading('Your orders'),
        const SizedBox(height: spaceSm),
        if (orders.isEmpty)
          const EmptyState(icon: Icons.receipt_long_outlined, message: 'No orders yet. Create your first one above.')
        else ...[
          PaginationBar(
            total: orders.length,
            page: _page,
            perPage: _perPage,
            onPageChanged: (p) => setState(() => _page = p),
            onPerPageChanged: (n) => setState(() { _perPage = n; _page = 0; }),
          ),
          ...pageSlice(orders, _page, _perPage).map((o) => _CreatorOrderCard(order: o)),
        ],
      ],
    );
  }
}

class _CreatorOrderCard extends StatelessWidget {
  const _CreatorOrderCard({required this.order});
  final PartyOrder order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return AppCard(
      onTap: o.editable ? () => showDialog(context: context, builder: (_) => _PartyOrderDialog(existing: o)) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.carpenterName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                Text('Party: ${o.party} · ₹${o.amount}', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          _PartyStatusChip(status: o.status),
          if (o.editable) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.edit_outlined, size: 16, color: kTextMuted)),
        ],
      ),
    );
  }
}

/// Party-order status pill. Its own small helper (not the shared StatusBadge)
/// because party-order statuses are lowercase lifecycle states, not the
/// carpenter-order status vocabulary StatusBadge is built around.
class _PartyStatusChip extends StatelessWidget {
  const _PartyStatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late String label;
    switch (status) {
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Completed';
        break;
      case 'approved':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'Collecting payment';
        break;
      default:
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF4338CA);
        label = 'Awaiting approval';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

/// Create/edit form for a party order. Used by the order-creator only.
/// Editing is offered solely for orders still `pending` (the tile that opens
/// this passes no [existing] once approved).
class _PartyOrderDialog extends StatefulWidget {
  const _PartyOrderDialog({this.existing});
  final PartyOrder? existing;

  @override
  State<_PartyOrderDialog> createState() => _PartyOrderDialogState();
}

class _PartyOrderDialogState extends State<_PartyOrderDialog> {
  final party = TextEditingController();
  final amount = TextEditingController();
  final carpSearch = TextEditingController();
  String? carpenterId;
  String carpenterName = '';
  bool uploading = false;
  bool saving = false;
  bool submitted = false;
  bool _showCarpList = false;
  String? fileUrl;
  String? fileType;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      party.text = e.party;
      amount.text = e.amount.toString();
      carpenterId = e.carpenterId;
      carpenterName = e.carpenterName;
      carpSearch.text = e.carpenterName;
      fileUrl = e.fileUrl;
      fileType = e.fileType;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], withData: true);
      final file = result?.files.single;
      if (file?.bytes == null) return;
      setState(() => uploading = true);
      final url = await CloudinaryService.instance.uploadBytes(file!.bytes!, file.name);
      setState(() {
        fileUrl = url;
        fileType = file.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'image';
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _submit(AdminState app) async {
    setState(() => submitted = true);
    final amt = int.tryParse(amount.text) ?? 0;
    if (carpenterId == null || party.text.trim().isEmpty || amt <= 0) return;
    setState(() => saving = true);
    try {
      if (widget.existing == null) {
        await app.addPartyOrder(carpenterId: carpenterId!, carpenterName: carpenterName, party: party.text.trim(), amount: amt, fileUrl: fileUrl, fileType: fileType);
      } else {
        await app.updatePartyOrder(widget.existing!.id, carpenterId: carpenterId!, carpenterName: carpenterName, party: party.text.trim(), amount: amt, fileUrl: fileUrl, fileType: fileType);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save order: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final q = carpSearch.text.trim().toLowerCase();
    final matches = app.carpenters.where((c) => c.name.toLowerCase().contains(q)).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final editing = widget.existing != null;
    return FormDialog(
      title: editing ? 'Edit order' : 'New order',
      subtitle: editing ? 'Update this order before the admin approves it' : 'Log an order taken from a party',
      icon: Icons.receipt_long_outlined,
      onClose: () => Navigator.pop(context),
      children: [
        _fileField(),
        const SizedBox(height: spaceMd),
        LabeledField(
          label: 'Carpenter',
          error: submitted && carpenterId == null ? 'Pick a carpenter' : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: carpSearch,
                onTap: () => setState(() => _showCarpList = true),
                onChanged: (_) => setState(() {
                  _showCarpList = true;
                  carpenterId = null;
                }),
                decoration: const InputDecoration(hintText: 'Search carpenter by name', prefixIcon: Icon(Icons.search, size: 18)),
              ),
              if (_showCarpList && carpenterId == null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(border: Border.all(color: kBorderSubtle), borderRadius: BorderRadius.circular(8)),
                  child: matches.isEmpty
                      ? const Padding(padding: EdgeInsets.all(12), child: Text('No match', style: TextStyle(color: kTextMuted, fontSize: 13)))
                      : ListView(
                          shrinkWrap: true,
                          children: matches.map((c) => InkWell(
                                onTap: () => setState(() {
                                  carpenterId = c.id;
                                  carpenterName = c.name;
                                  carpSearch.text = c.name;
                                  _showCarpList = false;
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  child: Text(c.name, style: const TextStyle(fontSize: 13)),
                                ),
                              )).toList(),
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(height: spaceMd),
        LabeledField(
          label: 'Party name (who the order is for)',
          error: submitted && party.text.trim().isEmpty ? 'Party name is required' : null,
          child: TextField(controller: party, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Sharma Furniture Works')),
        ),
        const SizedBox(height: spaceMd),
        LabeledField(
          label: 'Order amount',
          error: submitted && (int.tryParse(amount.text) ?? 0) <= 0 ? 'Enter a valid amount' : null,
          child: TextField(controller: amount, onChanged: (_) => setState(() {}), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(hintText: '24000', prefixText: '₹ ')),
        ),
        const SizedBox(height: spaceMd),
        LabeledField(
          label: 'Order date',
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(border: Border.all(color: kBorderSubtle), borderRadius: BorderRadius.circular(8), color: kBgApp),
            child: const Row(children: [Icon(Icons.calendar_today_outlined, size: 15, color: kTextSecondary), SizedBox(width: 8), Text('Tracked automatically on submit', style: TextStyle(color: kTextSecondary, fontSize: 13))]),
          ),
        ),
      ],
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        const SizedBox(width: spaceSm),
        ElevatedButton(onPressed: saving ? null : () => _submit(app), child: Text(saving ? 'Saving...' : (editing ? 'Save changes' : 'Create order'))),
      ],
    );
  }

  Widget _fileField() {
    if (fileUrl != null && fileType == 'image') {
      return LabeledField(label: 'Photo or PDF', child: ImagePickerBox(imageUrl: fileUrl, uploading: uploading, onTap: _pickFile, hint: 'Click to upload photo or PDF'));
    }
    if (fileUrl != null && fileType == 'pdf') {
      return LabeledField(
        label: 'Photo or PDF',
        child: InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: Border.all(color: kBorderSubtle), borderRadius: BorderRadius.circular(kCardRadius), color: kBgApp),
            child: const Row(children: [Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFB91C1C)), SizedBox(width: 10), Expanded(child: Text('PDF attached · tap to replace', style: TextStyle(fontSize: 13))), Icon(Icons.edit_outlined, size: 16, color: kTextMuted)]),
          ),
        ),
      );
    }
    return LabeledField(label: 'Photo or PDF (optional)', child: ImagePickerBox(imageUrl: null, uploading: uploading, onTap: _pickFile, hint: 'Click to upload photo or PDF'));
  }
}
