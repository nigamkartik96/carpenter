import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'services/background_location.dart';
import 'services/update_service.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/onboarding_screens.dart';
import 'screens/home_shell.dart';
import 'screens/order_screens.dart';
import 'screens/rewards_screens.dart';
import 'screens/profile_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Workmanager().initialize(backgroundLocationCallbackDispatcher, isInDebugMode: kDebugMode);
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
          '/leadNew': (_) => const LeadNewScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/account': (_) => const AccountScreen(),
          '/editProfile': (_) => const EditProfileScreen(),
        },
        ),
      ),
    );
  }
}

/// Resumes an existing Firebase session on app start instead of always
/// showing the login screen. Shows the splash screen briefly while it
/// checks, then routes to dashboard / pending / login as appropriate.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final app = context.read<AppState>();
    await app.loadPrefs();
    final hasSession = await app.tryResumeSession();
    if (!mounted) return;
    if (hasSession) {
      final target = app.isApproved ? '/dashboard' : '/pending';
      Navigator.of(context).pushNamedAndRemoveUntil(target, (r) => false);
    } else {
      setState(() => _checked = true);
    }
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final update = await UpdateService.instance.checkForUpdate();
    if (update != null && mounted) {
      UpdateService.showUpdateDialog(context, update);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const SplashScreen();
  }
}
