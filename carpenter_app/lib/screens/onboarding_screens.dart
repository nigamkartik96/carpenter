import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/biometric_service.dart';
import '../services/cloudinary_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'pin_screens.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      // Was a near-black gradient -- kept as a plain Container (not just
      // relying on scaffoldBackgroundColor) so this screen still renders
      // correctly if a dark theme toggle is ever added back later.
      body: Container(
        color: kBg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  // Dark icon, not white -- white-on-kPrimary is too low
                  // contrast (brand orange is tuned for kOnPrimary content).
                  child: const Icon(Icons.handyman, color: kOnPrimary, size: 40),
                ),
                const SizedBox(height: 18),
                const Text('CarpenterHub', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kText)),
                const SizedBox(height: 6),
                Text(app.tr('Order  ·  Earn points  ·  Redeem'), style: TextStyle(color: kMuted, fontSize: 13)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: Text(app.tr('Get started')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final identifier = TextEditingController();
  final password = TextEditingController();
  final pin = TextEditingController();
  String? error;
  bool busy = false;
  bool pinMode = false;

  Future<void> _navigateAfterLogin(BuildContext context, AppState app) async {
    if (!context.mounted) return;
    if (app.isApproved) {
      if (app.needsForceReset) {
        await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => ForceResetScreen(resetPin: app.resetPin, resetPassword: app.resetPassword),
        ));
        if (!context.mounted) return;
      }
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/pending', (r) => false);
    }
  }

  Future<void> _loginWithPassword(AppState app) async {
    setState(() { busy = true; error = null; });
    final result = await app.login(identifier.text.trim(), password.text);
    setState(() => busy = false);
    if (result != 'ok') {
      setState(() => error = app.tr(result));
      return;
    }
    await _navigateAfterLogin(context, app);
  }

  Future<void> _loginWithPin(AppState app) async {
    final id = identifier.text.trim();
    if (id.isEmpty) {
      setState(() => error = app.tr('Enter your mobile number or email'));
      return;
    }
    if (pin.text.length != 4) {
      setState(() => error = app.tr('Enter a valid 4-digit PIN'));
      return;
    }
    final lastId = app.lastUserIdentifier;
    if (lastId == null || !_identifiersMatch(id, lastId)) {
      setState(() => error = app.tr('PIN login is not available for this account'));
      return;
    }
    setState(() { busy = true; error = null; });
    final result = await app.loginWithPin(pin.text);
    setState(() => busy = false);
    if (result != 'ok') {
      setState(() => error = app.tr(result));
      return;
    }
    await _navigateAfterLogin(context, app);
  }

  bool _identifiersMatch(String a, String b) {
    final normA = normalizeMobile(a);
    final normB = normalizeMobile(b);
    if (normA.length >= 10 && normB.length >= 10) return normA == normB;
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Login'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(app.tr('Welcome back'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(app.tr('Login to continue'), style: TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(controller: identifier, decoration: InputDecoration(labelText: app.tr('Mobile number or email'))),
          const SizedBox(height: 12),
          if (pinMode)
            TextField(
              controller: pin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: app.tr('4-digit PIN'),
                counterText: '',
              ),
            )
          else
            TextField(controller: password, decoration: InputDecoration(labelText: app.tr('Password')), obscureText: true),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: kDanger, fontSize: 12))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: busy ? null : () => pinMode ? _loginWithPin(app) : _loginWithPassword(app),
            child: Text(busy ? app.tr('Logging in...') : app.tr('Login')),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => setState(() { pinMode = !pinMode; error = null; }),
              child: Text(pinMode ? app.tr('Use password instead') : app.tr('Use PIN instead')),
            ),
          ),
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: Text(app.tr('Create new account')),
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final pin = TextEditingController();
  final shop = TextEditingController();
  final address = TextEditingController();
  String? error;
  bool busy = false;
  bool uploadingPhoto = false;
  String? photoUrl;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 70);
    if (picked == null) return;
    setState(() => uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await CloudinaryService.instance.uploadBytes(bytes, picked.name);
      setState(() => photoUrl = url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AppState>().tr('Photo uploaded'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.read<AppState>().tr('Photo upload failed')}: $e')));
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Register'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(app.tr('Tell us about your shop'), style: TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(controller: name, decoration: InputDecoration(labelText: app.tr('Full name'), hintText: 'Ramesh Kumar')),
          const SizedBox(height: 12),
          TextField(
            controller: mobile,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: app.tr('Mobile number'),
              hintText: '98765 43210',
              helperText: app.tr('You can log in with this number'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: app.tr('Email (optional)')),
          ),
          const SizedBox(height: 12),
          TextField(controller: password, decoration: InputDecoration(labelText: app.tr('Password')), obscureText: true),
          const SizedBox(height: 12),
          TextField(
            controller: pin,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              labelText: app.tr('4-digit PIN (optional)'),
              hintText: '••••',
              helperText: app.tr('For quick access to your account'),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: shop, decoration: InputDecoration(labelText: app.tr('Shop name'), hintText: 'Kumar Furniture')),
          const SizedBox(height: 12),
          TextField(controller: address, decoration: InputDecoration(labelText: app.tr('Address'), hintText: 'Sector 12, Pune')),
          const SizedBox(height: 12),
          if (photoUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CircleAvatar(radius: 32, backgroundImage: NetworkImage(photoUrl!)),
            ),
          OutlinedButton.icon(
            onPressed: uploadingPhoto ? null : _pickPhoto,
            icon: uploadingPhoto
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.camera_alt_outlined),
            label: Text(photoUrl != null ? app.tr('Change photo') : app.tr('Upload profile photo')),
          ),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: kDanger, fontSize: 12))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: busy
                ? null
                : () async {
                    // Email is optional -- the mobile number is what
                    // identifies a carpenter without one, so it's
                    // required and has to be a usable number.
                    final digits = normalizeMobile(mobile.text);
                    final typedEmail = email.text.trim();
                    if (name.text.trim().isEmpty || digits.isEmpty || password.text.isEmpty) {
                      setState(() => error = app.tr('Fill all required fields'));
                      return;
                    }
                    if (digits.length < 10) {
                      setState(() => error = app.tr('Enter a valid 10-digit mobile number'));
                      return;
                    }
                    if (typedEmail.isNotEmpty && !typedEmail.contains('@')) {
                      setState(() => error = app.tr('Enter a valid email address'));
                      return;
                    }
                    final pinText = pin.text.trim();
                    if (pinText.isNotEmpty && pinText.length != 4) {
                      setState(() => error = app.tr('PIN must be exactly 4 digits'));
                      return;
                    }
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    final result = await app.register(
                      name: name.text,
                      mobileNum: mobile.text,
                      email: typedEmail,
                      password: password.text,
                      shop: shop.text,
                      addr: address.text,
                      photoUrl: photoUrl,
                      pin: pinText.isEmpty ? null : pinText,
                    );
                    setState(() => busy = false);
                    if (result != 'ok') {
                      setState(() => error = app.tr(result));
                      return;
                    }
                    if (!context.mounted) return;
                    final loginId = typedEmail.isNotEmpty ? typedEmail : mobile.text.trim();
                    final bio = BiometricService.instance;
                    final bioSupported = await bio.isDeviceSupported();
                    if (context.mounted && bioSupported) {
                      final enable = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(app.tr('Enable biometric login')),
                          content: Text(app.tr('Use fingerprint or face to log in quickly next time?')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(app.tr('Not now'))),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(app.tr('Enable'))),
                          ],
                        ),
                      );
                      if (enable == true) {
                        await bio.saveCredentials(loginId, password.text);
                      }
                    }
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/pending');
                  },
            child: Text(busy ? app.tr('Registering...') : app.tr('Register')),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(app.tr('Back to login')),
          ),
        ],
      ),
    );
  }
}

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  bool checking = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: kWarning.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.access_time, color: kWarning, size: 34),
              ),
              const SizedBox(height: 18),
              Text(app.tr('Approval pending'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                app.tr('Your account is being reviewed by the admin.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: kMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: checking
                    ? null
                    : () async {
                        setState(() => checking = true);
                        final approved = await app.checkApproval();
                        setState(() => checking = false);
                        if (!context.mounted) return;
                        if (approved) {
                          Navigator.pushNamed(context, '/consent');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(app.tr('Still pending approval'))),
                          );
                        }
                      },
                child: Text(checking ? app.tr('Checking...') : app.tr('Refresh status')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  /// Grants foreground location, then tries to upgrade to "Allow all the
  /// time". Android 11+ refuses to offer that in a dialog, so if it isn't
  /// granted the carpenter is walked to the settings page where it can
  /// be. Without it the hourly background job gets no fix at all and the
  /// admin map freezes on this one position -- which is exactly what was
  /// happening before.
  static Future<void> _grantAndContinue(BuildContext context, AppState app) async {
    final always = await app.requestLocationPermissions();
    app.startLocationReporting();
    if (!context.mounted) return;
    if (!always) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(app.tr('One more step')),
          content: Text(app.tr(
            'To keep sharing your location when the app is closed, open Settings > Permissions > Location and choose "Allow all the time".',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(app.tr('Later')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                app.openLocationSettings();
              },
              child: Text(app.tr('Open settings')),
            ),
          ],
        ),
      );
    }
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Location access'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.tr('Help us track field visits'), style: TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 16),
            const Center(child: Icon(Icons.location_on_outlined, size: 56, color: kPrimary)),
            const SizedBox(height: 16),
            Text(
              app.tr('We use your location while the app is open to show your last known position to the admin team.'),
              style: TextStyle(color: kMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_box_outlined, size: 18, color: kPrimary),
                const SizedBox(width: 8),
                Expanded(child: Text(app.tr('I agree to share my location with the company.'), style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _grantAndContinue(context, app),
              child: Text(app.tr('Allow location access')),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false),
              child: Text(app.tr('Continue without sharing')),
            ),
          ],
        ),
      ),
    );
  }
}
