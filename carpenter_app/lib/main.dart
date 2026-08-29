import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'services/background_location.dart';
import 'services/biometric_service.dart';
import 'services/navigation.dart';
import 'services/push_service.dart';
import 'services/update_service.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/feedback_screen.dart';
import 'screens/onboarding_screens.dart';
import 'screens/home_shell.dart';
import 'screens/order_screens.dart';
import 'screens/pin_screens.dart';
import 'screens/rewards_screens.dart';
import 'screens/profile_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await Workmanager().initialize(backgroundLocationCallbackDispatcher, isInDebugMode: kDebugMode);
  // Must be registered before runApp, and outside PushService, so
  // Firebase can find it when a message wakes a killed app.
  FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);
  await PushService.instance.init();
  runApp(const CarpenterHubApp());
}

class CarpenterHubApp extends StatelessWidget {
  const CarpenterHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, app, _) => MaterialApp(
        title: 'CarpenterHub',
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // Carpenter-adjustable text scale (Profile > font size) applies
        // app-wide via this builder rather than per-screen, so it's
        // consistent everywhere without touching every Text widget.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(app.fontScale)),
          child: child!,
        ),
        home: const AuthGate(),
        routes: {
          '/auth': (_) => const AuthGate(),
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/pending': (_) => const PendingScreen(),
          '/consent': (_) => const ConsentScreen(),
          '/dashboard': (_) => const HomeShell(),
          '/offers': (_) => const OffersScreen(),
          '/offerDetails': (_) => const OfferDetailsScreen(),
          '/createOrder': (_) => const CreateOrderScreen(),
          '/uploadOrder': (_) => const UploadOrderScreen(),
          '/manualOrder': (_) => const ManualOrderScreen(),
          '/voiceOrder': (_) => const VoiceOrderScreen(),
          '/orderSuccess': (_) => const OrderSuccessScreen(),
          '/orderHistory': (_) => const OrderHistoryScreen(),
          '/orderDetails': (_) => const OrderDetailsScreen(),
          '/points': (_) => const PointsScreen(),
          '/redeem': (_) => const RedeemScreen(),
          '/redeemCash': (_) => const RedeemCashScreen(),
          '/redeemCashDone': (_) => const RedeemCashDoneScreen(),
          '/gifts': (_) => const GiftStoreScreen(),
          '/giftSuccess': (_) => const GiftSuccessScreen(),
          '/leads': (_) => const LeadsScreen(),
          '/feedback': (_) => const FeedbackScreen(),
          '/leadNew': (_) => const LeadNewScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/account': (_) => const AccountScreen(),
          '/editProfile': (_) => const EditProfileScreen(),
          '/setupPin': (_) => const SetupPinScreen(),
          '/changePin': (_) => const ChangePinScreen(),
        },
        ),
      ),
    );
  }
}

/// Resumes an existing Firebase session on app start instead of always
/// showing the login screen. Shows the splash screen briefly while it
/// checks, then routes to dashboard / pending / biometric / login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

enum _AuthResult { loading, splash, returningUser, fallback }

class _AuthGateState extends State<AuthGate> {
  _AuthResult _state = _AuthResult.loading;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _navigateAfterAuth(AppState app) async {
    if (!app.isApproved) {
      Navigator.of(context).pushNamedAndRemoveUntil('/pending', (r) => false);
      return;
    }
    if (app.needsForceReset) {
      await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => ForceResetScreen(resetPin: app.resetPin, resetPassword: app.resetPassword),
      ));
    }
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
    }
  }

  Future<void> _check() async {
    final app = context.read<AppState>();
    await app.loadPrefs();
    final hasSession = await app.tryResumeSession();
    if (!mounted) return;
    if (hasSession) {
      await _navigateAfterAuth(app);
    } else {
      await app.loadLastUser();
      final hasCreds = await BiometricService.instance.hasSavedCredentials();
      if (!mounted) return;
      if (app.lastUserName != null && hasCreds) {
        setState(() => _state = _AuthResult.returningUser);
      } else {
        setState(() => _state = _AuthResult.splash);
      }
    }
    _checkForUpdate();
  }

  Future<void> _handleUseAccount() async {
    setState(() { _busy = true; _error = null; });
    final app = context.read<AppState>();
    final bio = BiometricService.instance;
    final supported = await bio.isDeviceSupported();
    if (!mounted) return;
    if (supported) {
      final ok = await bio.authenticate(app.tr('Verify your identity to log in'));
      if (!mounted) return;
      if (ok) {
        final creds = await bio.loadCredentials();
        if (creds != null && mounted) {
          final result = await app.login(creds.$1, creds.$2);
          if (!mounted) return;
          if (result == 'ok') {
            await _navigateAfterAuth(app);
            return;
          }
        }
      }
    }
    if (mounted) setState(() { _busy = false; _state = _AuthResult.fallback; });
  }

  void _handleOtherAccount() {
    context.read<AppState>().clearLastUser();
    Navigator.pushNamed(context, '/login');
  }

  Future<void> _handlePinFallback() async {
    final app = context.read<AppState>();
    if (!app.lastUserPinSet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(app.tr('PIN is not set up. Use password to log in.'))),
        );
      }
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinLoginScreen()),
    );
    if (result == true && mounted) {
      await _navigateAfterAuth(app);
    }
  }

  void _handlePasswordFallback() {
    Navigator.pushNamed(context, '/login');
  }

  Future<void> _checkForUpdate() => UpdateService.promptIfAvailable();

  @override
  Widget build(BuildContext context) {
    if (_state == _AuthResult.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_state == _AuthResult.splash) return const SplashScreen();

    final app = context.watch<AppState>();

    if (_state == _AuthResult.fallback) {
      return Scaffold(
        body: Container(
          color: kBg,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, color: kPrimary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(app.tr('Choose login method'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
                  const SizedBox(height: 6),
                  Text(
                    '${app.tr('Logging in as')} ${app.lastUserName}',
                    style: const TextStyle(color: kMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _state = _AuthResult.returningUser);
                        _handleUseAccount();
                      },
                      icon: const Icon(Icons.fingerprint),
                      label: Text(app.tr('Try biometric again')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (app.lastUserPinSet)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _handlePinFallback,
                        icon: const Icon(Icons.pin),
                        label: Text(app.tr('Use PIN')),
                      ),
                    ),
                  if (app.lastUserPinSet) const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handlePasswordFallback,
                      icon: const Icon(Icons.password),
                      label: Text(app.tr('Use password')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // returningUser state
    return Scaffold(
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
                    boxShadow: [BoxShadow(color: kPrimary.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.person, color: kOnPrimary, size: 40),
                ),
                const SizedBox(height: 18),
                Text(app.tr('Welcome back'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kText)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${app.tr('Last logged in')} — ${app.lastUserName}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kText),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _handleUseAccount,
                          child: _busy
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kOnPrimary))
                              : Text(app.tr('Use this account')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _handleOtherAccount,
                    child: Text(app.tr('Log in with another account')),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
