import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/cloudinary_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final today = app.offers.where((o) => o.category == 'Today').toList();
    final weekly = app.offers.where((o) => o.category == 'Weekly').toList();
    Widget tile(Offer o, Color accent) => SectionCard(
          onTap: () => Navigator.pushNamed(context, '/offerDetails', arguments: o),
          child: Row(
            children: [
              o.bannerUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(o.bannerUrl!, width: 40, height: 40, fit: BoxFit.cover))
                  : Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.local_offer, color: Colors.white, size: 20),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Valid till ${o.validTill}', style: TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Offers'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(app.tr('Today'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kMuted)),
          Text(app.tr('Aaj hi order dene me fayada'), style: const TextStyle(fontSize: 11, color: kPrimary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          ...today.map((o) => tile(o, const Color(0xFFD85A30))),
          const SizedBox(height: 12),
          Text(app.tr('Weekly'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kMuted)),
          Text(app.tr('Is hafte order dene me fayada'), style: const TextStyle(fontSize: 11, color: kPrimary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          ...weekly.map((o) => tile(o, const Color(0xFF534AB7))),
        ],
      ),
    );
  }
}

class OfferDetailsScreen extends StatelessWidget {
  const OfferDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final offer = ModalRoute.of(context)!.settings.arguments as Offer;
    return Scaffold(
      appBar: AppBar(title: Text(offer.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            offer.bannerUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(offer.bannerUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
                  )
                : Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFFD85A30), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.local_offer, color: Colors.white, size: 36),
                  ),
            const SizedBox(height: 16),
            if (offer.description.isNotEmpty) ...[
              Text(offer.description, style: const TextStyle(color: kMuted, fontSize: 13, height: 1.5)),
              const SizedBox(height: 10),
            ],
            Text('Valid till ${offer.validTill}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 20),
            if (offer.pdfUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(offer.pdfUrl!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('View PDF'),
                ),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/createOrder'),
              child: Text(app.tr('Create order now')),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateOrderScreen extends StatelessWidget {
  const CreateOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    Widget opt(IconData icon, String title, String subtitle, String route) => SectionCard(
          onTap: () => Navigator.pushNamed(context, route),
          child: Row(
            children: [
              Icon(icon, color: kPrimary, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.tr(title), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(app.tr(subtitle), style: TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Create order'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            opt(Icons.camera_alt_outlined, 'Upload order image', 'Snap or pick a photo', '/uploadOrder'),
            const SizedBox(height: 4),
            opt(Icons.list_alt_outlined, 'Manual entry', 'Add products and quantities', '/manualOrder'),
            const SizedBox(height: 4),
            opt(Icons.mic_none_outlined, 'Voice note', 'Record your order by voice', '/voiceOrder'),
          ],
        ),
      ),
    );
  }
}

class UploadOrderScreen extends StatefulWidget {
  const UploadOrderScreen({super.key});

  @override
  State<UploadOrderScreen> createState() => _UploadOrderScreenState();
}

class _UploadOrderScreenState extends State<UploadOrderScreen> {
  final remarks = TextEditingController();
  bool uploading = false;
  String? imageUrl;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1440, imageQuality: 85);
    if (picked == null) return;
    setState(() => uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await CloudinaryService.instance.uploadBytes(bytes, picked.name);
      setState(() => imageUrl = url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Upload order image'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(imageUrl!, height: 140, fit: BoxFit.cover)),
              ),
            if (uploading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 6),
                    Text(app.tr('Uploading...'), style: TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: uploading ? null : () => _pick(ImageSource.camera),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(10)),
                      child: Column(children: [const Icon(Icons.camera_alt_outlined, color: kMuted), const SizedBox(height: 6), Text(app.tr('Camera'), style: const TextStyle(fontSize: 12, color: kText))]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: uploading ? null : () => _pick(ImageSource.gallery),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(10)),
                      child: Column(children: [const Icon(Icons.photo_outlined, color: kMuted), const SizedBox(height: 6), Text(app.tr('Gallery'), style: const TextStyle(fontSize: 12, color: kText))]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(controller: remarks, decoration: InputDecoration(labelText: app.tr('Remarks'), hintText: 'e.g. Deliver before Friday')),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => _submitPhotoOrder(context, app),
              child: Text(app.tr('Submit order')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPhotoOrder(BuildContext context, AppState app) async {
    await _submit(
      context,
      app,
      'Photo',
      remarks.text.trim().isEmpty ? 'Order image' : remarks.text.trim(),
      imageUrl: imageUrl,
    );
  }
}

class ManualOrderScreen extends StatefulWidget {
  const ManualOrderScreen({super.key});

  @override
  State<ManualOrderScreen> createState() => _ManualOrderScreenState();
}

class _ManualOrderRow {
  _ManualOrderRow() : product = TextEditingController(), qty = TextEditingController();
  final TextEditingController product;
  final TextEditingController qty;
}

class _ManualOrderScreenState extends State<ManualOrderScreen> {
  final rows = [_ManualOrderRow()];
  bool submitting = false;

  void _addRow() => setState(() => rows.add(_ManualOrderRow()));

  void _removeRow(int i) => setState(() {
        if (rows.length > 1) rows.removeAt(i);
      });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Manual order'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Expanded(flex: 2, child: Text(app.tr('Product'), style: TextStyle(color: kMuted, fontSize: 12))), Expanded(child: Text(app.tr('Qty'), style: TextStyle(color: kMuted, fontSize: 12)))]),
            const SizedBox(height: 6),
            ...List.generate(rows.length, (i) => _editableRow(rows[i], i)),
            const SizedBox(height: 6),
            OutlinedButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: Text(app.tr('Add product'))),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: submitting ? null : () => _submitManual(context, app),
              child: Text(submitting ? app.tr('Submitting...') : app.tr('Submit order')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableRow(_ManualOrderRow row, int i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: row.product,
                decoration: const InputDecoration(hintText: 'e.g. Marine plywood 18mm'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: row.qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Qty'),
              ),
            ),
            IconButton(onPressed: () => _removeRow(i), icon: const Icon(Icons.close, size: 18)),
          ],
        ),
      );

  Future<void> _submitManual(BuildContext context, AppState app) async {
    final items = rows
        .where((r) => r.product.text.trim().isNotEmpty)
        .map((r) => '${r.product.text.trim()} x${r.qty.text.trim().isEmpty ? '1' : r.qty.text.trim()}')
        .join(', ');
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one product')));
      return;
    }
    setState(() => submitting = true);
    await _submit(context, app, 'Manual', items);
    if (mounted) setState(() => submitting = false);
  }
}

class VoiceOrderScreen extends StatefulWidget {
  const VoiceOrderScreen({super.key});

  @override
  State<VoiceOrderScreen> createState() => _VoiceOrderScreenState();
}

class _VoiceOrderScreenState extends State<VoiceOrderScreen> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final remarks = TextEditingController();
  bool recording = false;
  bool playing = false;
  bool uploading = false;
  bool submitting = false;
  String? localPath;
  String? audioUrl;
  String? error;

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      if (!await _recorder.hasPermission()) {
        setState(() => error = 'Microphone permission denied');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() {
        recording = true;
        localPath = null;
        audioUrl = null;
        error = null;
      });
    } catch (e) {
      // A real mic/codec failure shouldn't crash the screen -- surface it
      // as an inline error instead.
      setState(() => error = 'Could not start recording: $e');
    }
  }

  Future<void> _stop() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        recording = false;
        localPath = path;
      });
      if (path != null) await _upload(path);
    } catch (e) {
      setState(() {
        recording = false;
        error = 'Recording failed: $e';
      });
    }
  }

  Future<void> _upload(String path) async {
    setState(() => uploading = true);
    try {
      final bytes = await File(path).readAsBytes();
      final url = await CloudinaryService.instance.uploadBytes(bytes, 'voice_order.m4a', resourceType: 'raw');
      setState(() => audioUrl = url);
    } catch (e) {
      setState(() => error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _togglePlay() async {
    if (localPath == null) return;
    if (playing) {
      await _player.stop();
      setState(() => playing = false);
      return;
    }
    await _player.play(DeviceFileSource(localPath!));
    setState(() => playing = true);
    _player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hasRecording = localPath != null;
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Voice order'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(app.tr('Tap the mic and describe your order'), style: const TextStyle(color: kMuted, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: recording ? _stop : _start,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: (recording ? kDanger : kPrimary).withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(recording ? Icons.stop : Icons.mic_none, color: recording ? kDanger : kPrimary, size: 42),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              recording ? app.tr('Recording... tap to stop') : (hasRecording ? app.tr('Recording saved') : app.tr('Not recording')),
              style: TextStyle(color: recording ? kDanger : kMuted, fontSize: 12),
            ),
            if (hasRecording) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _togglePlay,
                icon: Icon(playing ? Icons.stop : Icons.play_arrow, size: 16),
                label: Text(playing ? app.tr('Stop') : app.tr('Play voice note')),
              ),
              if (uploading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
            ],
            if (error != null) ...[
              Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: kDanger, fontSize: 12))),
              if (hasRecording && audioUrl == null && !uploading)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton(onPressed: () => _upload(localPath!), child: Text(app.tr('Retry upload'))),
                ),
            ],
            const SizedBox(height: 14),
            TextField(controller: remarks, decoration: InputDecoration(labelText: app.tr('Remarks (optional)'))),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: (!hasRecording || uploading || submitting || audioUrl == null)
                  ? null
                  : () async {
                      setState(() => submitting = true);
                      await _submit(
                        context,
                        app,
                        'Voice',
                        remarks.text.trim().isEmpty ? 'Voice order' : remarks.text.trim(),
                        audioUrl: audioUrl,
                      );
                      if (mounted) setState(() => submitting = false);
                    },
              child: Text(submitting ? app.tr('Submitting...') : app.tr('Stop and submit')),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: hasRecording ? () => setState(() { localPath = null; audioUrl = null; }) : null,
              child: Text(app.tr('Re-record')),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _submit(BuildContext context, AppState app, String type, String detail, {String? imageUrl, String? audioUrl}) async {
  try {
    await app.addOrder(CarpenterOrder(id: '', type: type, detail: detail, status: 'Submitted', date: 'Today'), imageUrl: imageUrl, audioUrl: audioUrl);
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/orderSuccess', (r) => r.settings.name == '/dashboard');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit order: $e')));
    }
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: kSuccess.withOpacity(0.12), shape: BoxShape.circle), child: Icon(Icons.check, color: kSuccess, size: 40)),
            const SizedBox(height: 18),
            Text(app.tr('Order submitted'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(app.tr('Order is now pending review. You will earn points once approved.'), textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false), child: Text(app.tr('Back to dashboard'))),
          ],
        ),
      ),
    );
  }
}

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final body = app.orders.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 40, color: kMuted),
                  const SizedBox(height: 10),
                  Text(app.tr('No orders yet'), style: TextStyle(color: kMuted, fontSize: 13)),
                ],
              ),
            ),
          )
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: app.orders.length,
      itemBuilder: (context, i) {
        final o = app.orders[i];
        return SectionCard(
          onTap: () => Navigator.pushNamed(context, '/orderDetails', arguments: o.id),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(o.date, style: TextStyle(color: kMuted, fontSize: 11)),
                  ],
                ),
              ),
              StatusBadge(o.status),
            ],
          ),
        );
      },
    );
    if (embedded) return body;
    return Scaffold(appBar: AppBar(title: Text(app.tr('Order history'))), body: body);
  }
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final args = ModalRoute.of(context)?.settings.arguments;
    final orderId = args is String ? args : (args is CarpenterOrder ? args.id : null);
    CarpenterOrder? order;
    for (final o in app.orders) {
      if (o.id == orderId) {
        order = o;
        break;
      }
    }
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(app.tr('Order history'))),
        body: Center(child: Text(app.tr('No orders yet'), style: TextStyle(color: kMuted, fontSize: 13))),
      );
    }
    final o = order;
    const steps = ['Submitted', 'Processing', 'Fulfilled', 'Delivered'];
    List<Widget> children;
    try {
      final idx = steps.indexOf(o.status).clamp(0, steps.length - 1);
      children = [
        if (o.imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _openFullScreenImage(context, o.imageUrl!),
              child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(o.imageUrl!, height: 160, fit: BoxFit.cover, width: double.infinity)),
            ),
          ),
        Text(_orderDetailLabel(app, o.detail), style: const TextStyle(fontSize: 14)),
        Text(o.date, style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 14),
        if (o.points > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(app.tr('Points to earn'), style: const TextStyle(fontSize: 13)), Text('+${o.points} pts', style: const TextStyle(color: kSuccess, fontWeight: FontWeight.w600))],
            ),
          ),
        if (o.items.isNotEmpty) ...[
          Text(app.tr('Products'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          ...o.items.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${i.name} x${i.qty}', style: const TextStyle(fontSize: 13)),
                    Text('₹${i.total}', style: TextStyle(fontSize: 13, color: kMuted)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (o.audioUrl != null) ...[
          _VoiceNotePlayer(url: o.audioUrl!),
          const SizedBox(height: 16),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(app.tr('No voice note for this order'), style: TextStyle(color: kMuted, fontSize: 12)),
          ),
        if (o.invoiceUrl != null) ...[
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(o.invoiceUrl!), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: Text(app.tr('Download invoice')),
          ),
          const SizedBox(height: 16),
        ],
        Text(app.tr('Status timeline'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        ...List.generate(steps.length, (i) {
          final done = i <= idx;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [Icon(done ? Icons.check_circle : Icons.circle_outlined, size: 18, color: done ? kPrimary : kMuted), const SizedBox(width: 8), Text(app.tr(steps[i]), style: TextStyle(fontSize: 13, color: done ? kText : kMuted))]),
          );
        }),
      ];
    } catch (e) {
      children = [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text('Could not display this order: $e', style: const TextStyle(color: kDanger, fontSize: 13)),
        ),
      ];
    }
    return Scaffold(
      appBar: AppBar(title: Text(o.orderNumber)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}

/// 'Order image' / 'Voice order' are stored verbatim as the order's [detail]
/// when the carpenter leaves no remarks; translate just those known
/// placeholders, leaving any free-text remarks the carpenter typed alone.
String _orderDetailLabel(AppState app, String detail) {
  if (detail == 'Order image' || detail == 'Voice order') return app.tr(detail);
  return detail;
}

void _openFullScreenImage(BuildContext context, String url) {
  Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    ),
  ));
}

/// Plays a Cloudinary-hosted voice-note recording in place, for order
/// detail screens (and could be reused by the admin side if it ever
/// gets a Flutter-native player instead of a plain link).
class _VoiceNotePlayer extends StatefulWidget {
  const _VoiceNotePlayer({required this.url});
  final String url;

  @override
  State<_VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<_VoiceNotePlayer> {
  // Created lazily on first tap, not eagerly on mount: constructing an
  // AudioPlayer touches a native platform channel, and on some devices
  // that hung/failed silently (no Dart exception, no Android crash log)
  // just from the order-detail screen rendering, blanking the whole page.
  AudioPlayer? _playerOrNull;
  bool playing = false;
  String? error;

  AudioPlayer get _player => _playerOrNull ??= AudioPlayer();

  @override
  void dispose() {
    _playerOrNull?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (playing) {
      await _player.stop();
      setState(() => playing = false);
      return;
    }
    try {
      setState(() => error = null);
      await _player.play(UrlSource(widget.url));
      setState(() => playing = true);
      _player.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => playing = false);
      });
    } catch (e) {
      setState(() {
        playing = false;
        error = 'Could not play recording: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_none, color: kPrimary, size: 20),
              const SizedBox(width: 10),
              Text(app.tr('Voice note'), style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          // Kept out of the Row above: an OutlinedButton sitting next to an
          // Expanded sibling hit a layout assertion ("BoxConstraints forces
          // an infinite width") on this Flutter version -- giving it its
          // own row sidesteps that entirely.
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _toggle,
              icon: Icon(playing ? Icons.stop : Icons.play_arrow, size: 16),
              label: Text(playing ? app.tr('Stop') : app.tr('Play voice note')),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: const TextStyle(color: kDanger, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
