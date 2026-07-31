import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_service.dart';

/// Android needs a notification channel declared up front; messages that
/// arrive while the app is closed are posted to this one by the Firebase
/// SDK (it's named in AndroidManifest.xml as the default channel), and
/// foreground messages are posted to it by [PushService] by hand.
const _channelId = 'carpenterhub_default';
const _channelName = 'Order & points updates';

/// Set by main.dart so a notification tap can navigate without a
/// BuildContext -- taps are handled from a background isolate callback
/// and from cold start, neither of which has a widget tree to read.
final GlobalKey<NavigatorState> pushNavigatorKey = GlobalKey<NavigatorState>();

/// Runs in its own isolate when a message arrives with the app killed or
/// backgrounded. Messages carry a `notification` block, so Android draws
/// the tray entry itself -- nothing needs doing here, but Firebase
/// requires a registered handler for background delivery to work at all.
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {}

/// Firebase Cloud Messaging wiring: permission, device-token
/// registration, and displaying messages that arrive while the app is
/// open (Android suppresses those, so they're re-posted locally).
///
/// Sending is NOT done from either app -- it needs a service-account key,
/// which would be readable by anyone if it shipped in the admin console.
/// A Cloudflare Worker holds the key and calls FCM; see push-worker/ at
/// the repo root.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) => _openFromPayload(response.payload),
      );

      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Comments on your orders, points credited, offers and redemption updates',
            importance: Importance.high,
          ));

      // Android 13+ and iOS both gate notifications behind a runtime
      // prompt; on older Android this resolves immediately as granted.
      await _messaging.requestPermission();
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // App open: Android delivers the message to the app instead of the
      // tray, so draw it ourselves or the carpenter sees nothing.
      FirebaseMessaging.onMessage.listen(_showForeground);
      // App backgrounded: tapping the tray entry resumes the app here.
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
      // App was killed and launched by the tap.
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _open(initial.data);
    } catch (e) {
      // A carpenter denying the permission prompt, or a device without
      // Play Services, must never stop the app from starting.
      debugPrint('PushService.init failed: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _local.show(
      id: message.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: '${message.data['type'] ?? ''}|${message.data['refId'] ?? ''}',
    );
  }

  void _openFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final parts = payload.split('|');
    _open({'type': parts.first, if (parts.length > 1) 'refId': parts[1]});
  }

  /// Order notifications deep-link to that order; everything else opens
  /// the notification list, which is a safe destination whether or not
  /// the app's Firestore caches have loaded yet.
  void _open(Map<String, dynamic> data) {
    final nav = pushNavigatorKey.currentState;
    if (nav == null) return;
    final refId = '${data['refId'] ?? ''}';
    if (data['type'] == 'order' && refId.isNotEmpty) {
      nav.pushNamed('/orderDetails', arguments: refId);
    } else {
      nav.pushNamed('/notifications');
    }
  }

  /// Stores this device's token on the carpenter's profile so the Worker
  /// knows where to send. Tokens rotate, so the refresh stream is
  /// followed for as long as the session lasts.
  Future<void> registerToken(String carpenterId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await FirebaseService.instance.addFcmToken(carpenterId, token);
      _messaging.onTokenRefresh.listen((t) => FirebaseService.instance.addFcmToken(carpenterId, t));
    } catch (e) {
      debugPrint('PushService.registerToken failed: $e');
    }
  }

  /// Called on logout so the next carpenter to use this handset doesn't
  /// receive the previous one's notifications.
  Future<void> unregisterToken(String carpenterId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await FirebaseService.instance.removeFcmToken(carpenterId, token);
    } catch (e) {
      debugPrint('PushService.unregisterToken failed: $e');
    }
  }
}
