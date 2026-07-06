import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
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
