import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();

  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _keyId = 'ch_login_id';
  static const _keyPw = 'ch_login_pw';

  Future<void> saveCredentials(String identifier, String password) async {
    await _storage.write(key: _keyId, value: identifier);
    await _storage.write(key: _keyPw, value: password);
  }

  Future<(String, String)?> loadCredentials() async {
    final id = await _storage.read(key: _keyId);
    final pw = await _storage.read(key: _keyPw);
    if (id == null || pw == null) return null;
    return (id, pw);
  }

  Future<bool> hasSavedCredentials() async {
    final id = await _storage.read(key: _keyId);
    return id != null;
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyId);
    await _storage.delete(key: _keyPw);
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
