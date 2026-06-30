import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // clean /orders/abc123 URLs instead of /#/orders/abc123
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminConsoleApp());
}

class AdminConsoleApp extends StatefulWidget {
  const AdminConsoleApp({super.key});

  @override
  State<AdminConsoleApp> createState() => _AdminConsoleAppState();
}

class _AdminConsoleAppState extends State<AdminConsoleApp> {
  late final AdminState _app;

  @override
  void initState() {
    super.initState();
    _app = AdminState();
    _app.tryResumeSession();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _app,
      child: const AdminRouterProvider(),
    );
  }
}
