import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Full-screen live QR scanner. Pops with the raw decoded string (a UPI
/// deep link, in the account-setup flow) once a code is found, or with
/// null if the carpenter backs out.
///
/// This is the "scan instead of type" alternative to the IFSC/account
/// number fields flagged in Section 7 as high-risk for a non-literate
/// user: pointing the camera at a UPI QR is a single tap, no reading or
/// typing an alphanumeric code required.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    _handled = true;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Scan QR code'))),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(border: Border.all(color: kPrimary, width: 3), borderRadius: BorderRadius.circular(16)),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Text(
              app.tr('Scan a UPI QR code'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 8, color: Colors.black)]),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// UPI QR codes encode a `upi://pay?pa=<upi-id>&pn=<name>&...` deep link.
/// Extracts the payee address (`pa`), which is the UPI ID -- falls back to
/// the raw scanned text if it doesn't look like a UPI link, in case the
/// carpenter's QR is a plain UPI-ID text code instead.
String? extractUpiId(String scanned) {
  try {
    final uri = Uri.parse(scanned);
    final pa = uri.queryParameters['pa'];
    if (pa != null && pa.isNotEmpty) return pa;
  } catch (_) {
    // Not a URI at all -- fall through to the raw-text case below.
  }
  return scanned.contains('@') ? scanned : null;
}
