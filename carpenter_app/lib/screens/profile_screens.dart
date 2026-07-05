import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/cloudinary_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/mic_button.dart';
import 'qr_scan_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: kCard2,
                child: app.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          app.photoUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(app.initials, style: const TextStyle(fontSize: 20, color: kPrimaryDark, fontWeight: FontWeight.w600)),
                        ),
                      )
                    : Text(app.initials, style: const TextStyle(fontSize: 20, color: kPrimaryDark, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
              Text(app.carpenterName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              StatusBadge('${app.points} pts'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(child: Text(app.shopName, style: const TextStyle(fontSize: 13))),
        SectionCard(child: Text(app.mobile, style: const TextStyle(fontSize: 13))),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(app.tr('Address'), style: TextStyle(color: kMuted, fontSize: 12)), Text(app.address, style: const TextStyle(fontSize: 13))],
          ),
        ),
        SectionCard(
          onTap: () => Navigator.pushNamed(context, '/editProfile'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(app.tr('Edit profile'), style: const TextStyle(fontSize: 13)), const Icon(Icons.chevron_right, color: kMuted)],
          ),
        ),
        SectionCard(
          onTap: () => Navigator.pushNamed(context, '/account'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(app.tr('Bank and UPI details'), style: const TextStyle(fontSize: 13)), const Icon(Icons.chevron_right, color: kMuted)],
          ),
        ),
        const SizedBox(height: 8),
        Text(app.tr('Language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: app.locale.isHindi ? null : OutlinedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: kOnPrimary),
                onPressed: () => app.setLanguage(false),
                // Always shown in Devanagari, not the Latin word "English" --
                // a user who can't read English script would otherwise have
                // no way to tell which button is which.
                child: const Text('अंग्रेज़ी'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: app.locale.isHindi ? OutlinedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: kOnPrimary) : null,
                onPressed: () => app.setLanguage(true),
                child: const Text('हिंदी'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(app.tr('Font size'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(app.tr('Small'), style: const TextStyle(fontSize: 11, color: kMuted)),
            Expanded(
              child: Slider(
                value: app.fontScale,
                min: 0.85,
                max: 1.4,
                divisions: 11,
                label: app.fontScale.toStringAsFixed(2),
                onChanged: (v) => app.setFontScale(v),
              ),
            ),
            Text(app.tr('Extra large'), style: const TextStyle(fontSize: 11, color: kMuted)),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(app.tr('Logout')),
                content: Text(app.tr('Are you sure you want to logout?')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(app.tr('Cancel'))),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text(app.tr('Logout'))),
                ],
              ),
            );
            if (confirmed != true) return;
            await app.logout();
            if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/splash', (r) => false);
          },
          child: Text(app.tr('Logout')),
        ),
      ],
    );
    if (embedded) return body;
    return Scaffold(appBar: AppBar(title: Text(app.tr('Profile'))), body: body);
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool editing = false;
  bool saving = false;
  bool uploadingQr = false;
  late TextEditingController upiId;
  late TextEditingController bankName;
  late TextEditingController accountNumber;
  late TextEditingController ifsc;
  bool _initialized = false;

  Future<void> _changeQr(AppState app) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 70);
    if (picked == null) return;
    setState(() => uploadingQr = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await CloudinaryService.instance.uploadBytes(bytes, picked.name);
      if (url != null) await app.savePayout({'qrUrl': url});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.read<AppState>().tr('QR upload failed')}: $e')));
    } finally {
      if (mounted) setState(() => uploadingQr = false);
    }
  }

  /// Live camera QR scan -- the recommended way to fill in the UPI ID,
  /// since IFSC/account-number-style alphanumeric codes are high-risk for
  /// a non-literate user to read or type correctly (Section 7). Scanning
  /// a UPI QR (e.g. from the carpenter's own bank/UPI app) decodes the ID
  /// directly, no typing required.
  Future<void> _scanQr(AppState app) async {
    final scanned = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const QrScanScreen()));
    if (scanned == null) return;
    final upi = extractUpiId(scanned);
    if (upi == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.tr('Could not read this QR code'))));
      return;
    }
    setState(() {
      editing = true;
      upiId.text = upi;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.tr('QR scanned'))));
  }

  void _initControllersIfNeeded(AppState app) {
    if (_initialized) return;
    upiId = TextEditingController(text: app.upiId);
    bankName = TextEditingController(text: app.bankName);
    accountNumber = TextEditingController(text: app.accountNumber);
    ifsc = TextEditingController(text: app.ifsc);
    _initialized = true;
  }

  Future<void> _save(AppState app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(app.tr('Save bank/UPI details?')),
        content: Text(app.tr('These details are used to send your cash redemption payouts. Make sure they are correct.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(app.tr('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(app.tr('Save'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => saving = true);
    try {
      await app.savePayout({
        'upiId': upiId.text.trim(),
        'bankName': bankName.text.trim(),
        'accountNumber': accountNumber.text.trim(),
        'ifsc': ifsc.text.trim(),
      });
      if (mounted) {
        setState(() => editing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.tr('Account details saved'))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.read<AppState>().tr('Could not save')}: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    _initControllersIfNeeded(app);
    Widget row(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: TextStyle(color: kMuted, fontSize: 13)), Text(b.isEmpty ? app.tr('-- not set --') : b, style: const TextStyle(fontSize: 13))]),
        );
    final hasDetails = app.upiId.isNotEmpty || app.bankName.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('My account'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(app.tr('Where we send your money'), style: TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: app.qrUrl != null ? () => _openFullScreenQr(context, app.qrUrl!) : null,
              child: Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
                child: app.qrUrl != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(app.qrUrl!, fit: BoxFit.contain))
                    : const Icon(Icons.qr_code_2, size: 100, color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              app.qrUrl != null ? app.tr('Scan to pay via UPI · tap to enlarge') : app.tr('Scan to pay via UPI'),
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton.icon(
              onPressed: uploadingQr ? null : () => _changeQr(app),
              icon: uploadingQr
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.qr_code_scanner, size: 16),
              label: Text(app.qrUrl != null ? app.tr('Change QR code') : app.tr('Upload QR code')),
            ),
          ),
          const SizedBox(height: 16),
          if (!editing)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
              child: Column(
                children: [
                  row(app.tr('UPI ID'), app.upiId),
                  row(app.tr('Bank'), app.bankName),
                  row(app.tr('Account'), app.accountNumber),
                  row(app.tr('IFSC'), app.ifsc),
                ],
              ),
            )
          else
            Column(
              children: [
                // Scanning is the recommended path -- typing/reading a UPI ID,
                // account number or IFSC code is high-risk for a non-literate
                // user. Manual entry below stays available as a fallback.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _scanQr(app),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: Text(app.tr('Scan QR code')),
                  ),
                ),
                const SizedBox(height: 12),
                Text(app.tr('Enter details manually instead'), style: TextStyle(color: kMuted, fontSize: 12)),
                const SizedBox(height: 10),
                TextField(controller: upiId, decoration: InputDecoration(labelText: app.tr('UPI ID'), hintText: 'name@bank')),
                const SizedBox(height: 10),
                TextField(controller: bankName, decoration: InputDecoration(labelText: app.tr('Bank'), hintText: 'HDFC Bank', suffixIcon: MicButton(controller: bankName))),
                const SizedBox(height: 10),
                TextField(controller: accountNumber, decoration: InputDecoration(labelText: app.tr('Account'), hintText: 'Account number')),
                const SizedBox(height: 10),
                TextField(controller: ifsc, decoration: InputDecoration(labelText: app.tr('IFSC'), hintText: 'HDFC0001234')),
              ],
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(app.tr('Points balance'), style: const TextStyle(fontSize: 13)), Text('${app.points} pts', style: const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w600))]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/redeemCash'), child: Text(app.tr('Redeem points'))),
          const SizedBox(height: 8),
          if (editing)
            ElevatedButton(
              onPressed: saving ? null : () => _save(app),
              child: Text(saving ? app.tr('Saving...') : app.tr('Save details')),
            )
          else
            OutlinedButton(
              onPressed: () => setState(() => editing = true),
              child: Text(hasDetails ? app.tr('Edit account details') : app.tr('Add account details')),
            ),
        ],
      ),
    );
  }
}

void _openFullScreenQr(BuildContext context, String url) {
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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController name;
  late TextEditingController shop;
  late TextEditingController address;
  bool _initialized = false;
  bool saving = false;
  bool uploadingPhoto = false;
  String? photoUrl;

  void _initControllersIfNeeded(AppState app) {
    if (_initialized) return;
    name = TextEditingController(text: app.carpenterName);
    shop = TextEditingController(text: app.shopName);
    address = TextEditingController(text: app.address);
    photoUrl = app.photoUrl;
    _initialized = true;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 70);
    if (picked == null) return;
    setState(() => uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await CloudinaryService.instance.uploadBytes(bytes, picked.name);
      setState(() => photoUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<AppState>().tr("Photo uploaded — tap 'Save changes' below to apply it"))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.read<AppState>().tr('Photo upload failed')}: $e')));
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
    }
  }

  bool _hasUnsavedChanges(AppState app) {
    return name.text.trim() != app.carpenterName ||
        shop.text.trim() != app.shopName ||
        address.text.trim() != app.address ||
        photoUrl != app.photoUrl;
  }

  Future<bool> _confirmDiscard(AppState app) async {
    if (!_hasUnsavedChanges(app)) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(app.tr('Discard changes?')),
        content: Text(app.tr("You have unsaved changes (including any uploaded photo) that will be lost if you don't tap 'Save changes'.")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(app.tr('Keep editing'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(app.tr('Discard'))),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _save(AppState app) async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.tr('Name cannot be empty'))));
      return;
    }
    setState(() => saving = true);
    try {
      await app.updateProfile(name: name.text.trim(), shop: shop.text.trim(), addr: address.text.trim(), photoUrl: photoUrl);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${app.tr('Could not save')}: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    _initControllersIfNeeded(app);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard(app) && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
      appBar: AppBar(title: Text(app.tr('Edit profile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: kCard2,
                  child: photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            photoUrl!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(initialsOf(name.text.isEmpty ? app.carpenterName : name.text), style: const TextStyle(fontSize: 22, color: kPrimaryDark, fontWeight: FontWeight.w600)),
                          ),
                        )
                      : Text(initialsOf(name.text.isEmpty ? app.carpenterName : name.text), style: const TextStyle(fontSize: 22, color: kPrimaryDark, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: uploadingPhoto ? null : _pickPhoto,
                  icon: uploadingPhoto
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.camera_alt_outlined, size: 16),
                  label: Text(photoUrl != null ? app.tr('Change photo') : app.tr('Add photo')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: name, decoration: InputDecoration(labelText: app.tr('Full name'), suffixIcon: MicButton(controller: name))),
          const SizedBox(height: 12),
          TextField(controller: shop, decoration: InputDecoration(labelText: app.tr('Shop name'), suffixIcon: MicButton(controller: shop))),
          const SizedBox(height: 12),
          TextField(controller: address, decoration: InputDecoration(labelText: app.tr('Address'), suffixIcon: MicButton(controller: address))),
          const SizedBox(height: 12),
          SectionCard(child: Text('${app.tr('Mobile number')}: ${app.mobile} (cannot be changed here)', style: TextStyle(color: kMuted, fontSize: 12))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: saving ? null : () => _save(app),
            child: Text(saving ? app.tr('Saving...') : app.tr('Save changes')),
          ),
        ],
      ),
      ),
    );
  }
}
