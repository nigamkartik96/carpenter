import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state.dart';
import 'widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: screenWidth < 392 ? screenWidth - 32 : 360,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.black.withOpacity(0.08))),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(children: [Icon(Icons.handyman, color: kPrimary), SizedBox(width: 8), Text('CarpenterHub admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
                  const SizedBox(height: 4),
                  const Text('Admin accounts are provisioned manually and are not self-service.', style: TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  TextField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                  if (app.loginError != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(app.loginError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: app.busy ? null : () => app.login(email.text.trim(), password.text),
                      child: Text(app.busy ? '...' : 'Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
