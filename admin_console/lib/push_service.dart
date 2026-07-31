import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// URL of the Cloudflare Worker that actually sends push notifications
/// (see push-worker/ at the repo root). Paste the URL printed by
/// `npx wrangler deploy` here, e.g.
/// 'https://carpenterhub-push.<your-subdomain>.workers.dev'.
///
/// Left empty, everything still works -- notifications are written to
/// Firestore and show up inside the app as before, just without the
/// phone-level push. So the console can be deployed before the Worker is.
const String kPushWorkerUrl = 'https://carpenterhub-push.nigamkartik962.workers.dev';

/// Asks the Worker to push a notification to one or more carpenters.
///
/// The Worker, not this app, holds the service-account key: it grants
/// full access to the Firebase project and anything shipped in a Flutter
/// web build is readable by whoever opens the site. What's sent from here
/// is the admin's own Firebase ID token, which the Worker verifies and
/// checks against the `admins` collection before sending anything.
class AdminPushService {
  AdminPushService._();
  static final AdminPushService instance = AdminPushService._();

  /// Fire-and-forget by design: the caller has already written the
  /// notification document, which is the source of truth for the app's
  /// in-app list. A Worker that's down, misconfigured or not yet
  /// deployed must never fail the admin's action.
  Future<void> notify({
    required List<String> carpenterIds,
    required String title,
    required String body,
    String? type,
    String? refId,
  }) async {
    if (kPushWorkerUrl.isEmpty || carpenterIds.isEmpty) return;
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;
      final res = await http
          .post(
            Uri.parse(kPushWorkerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
              'carpenterIds': carpenterIds,
              'title': title,
              'body': body,
              if (type != null) 'type': type,
              if (refId != null) 'refId': refId,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        debugPrint('push failed (${res.statusCode}): ${res.body}');
      }
    } catch (e) {
      debugPrint('push failed: $e');
    }
  }
}
