import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'state.dart';
import 'widgets.dart';
import 'login_screen.dart';
import 'shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminConsoleApp());
}

class AdminConsoleApp extends StatelessWidget {
  const AdminConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminState(),
      child: MaterialApp(
        title: 'CarpenterHub Admin',
        debugShowCheckedModeBanner: false,
        theme: buildAdminTheme(),
        home: const AdminAuthGate(),
      ),
    );
  }
}

/// Resumes an existing Firebase session instead of always showing the
/// login screen on page reload.
class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    context.read<AdminState>().tryResumeSession().then((_) {
      if (mounted) setState(() => _checked = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Consumer<AdminState>(
      builder: (context, app, _) => app.loggedIn ? const AdminShell() : const LoginScreen(),
    );
  }
}
