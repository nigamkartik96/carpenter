import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/cloudinary_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0D1117), Color(0xFF1A1200)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
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
                  child: const Icon(Icons.handyman, color: Colors.white, size: 40),
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
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool busy = false;

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
          TextField(controller: email, decoration: InputDecoration(labelText: app.tr('Email'))),
          const SizedBox(height: 12),
          TextField(controller: password, decoration: InputDecoration(labelText: app.tr('Password')), obscureText: true),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: kDanger, fontSize: 12))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    final result = await app.login(email.text.trim(), password.text);
                    setState(() => busy = false);
                    if (result != 'ok') {
                      setState(() => error = result);
                      return;
                    }
                    if (!context.mounted) return;
                    if (app.isApproved) {
                      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
                    } else {
                      Navigator.pushNamedAndRemoveUntil(context, '/pending', (r) => false);
                    }
                  },
            child: Text(busy ? app.tr('Logging in...') : app.tr('Login')),
          ),
          const SizedBox(height: 8),
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
  final shop = TextEditingController();
  final address = TextEditingController();
  String? error;
  bool busy = false;
  bool uploadingPhoto = false;
  String? photoUrl;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
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
          TextField(controller: mobile, decoration: InputDecoration(labelText: app.tr('Mobile number'), hintText: '98765 43210')),
          const SizedBox(height: 12),
          TextField(controller: email, decoration: InputDecoration(labelText: app.tr('Email'))),
          const SizedBox(height: 12),
          TextField(controller: password, decoration: InputDecoration(labelText: app.tr('Password')), obscureText: true),
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
                    if (name.text.isEmpty || email.text.isEmpty || password.text.isEmpty) {
                      setState(() => error = app.tr('Fill all required fields'));
                      return;
                    }
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    final result = await app.register(
                      name: name.text,
                      mobileNum: mobile.text,
                      email: email.text.trim(),
                      password: password.text,
                      shop: shop.text,
                      addr: address.text,
                      photoUrl: photoUrl,
                    );
                    setState(() => busy = false);
                    if (result != 'ok') {
                      setState(() => error = result);
                      return;
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
              onPressed: () {
                app.startLocationReporting();
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
              },
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
