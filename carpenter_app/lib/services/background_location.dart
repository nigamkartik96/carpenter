import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import '../firebase_options.dart';

const String backgroundLocationTaskName = 'carpenterhub.backgroundLocation';

/// Runs in a separate background isolate (no access to the running app's
/// state), so it re-initializes Firebase from scratch and reads whichever
/// account is currently signed in via the persisted Firebase Auth session.
@pragma('vm:entry-point')
void backgroundLocationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return true; // not logged in -- nothing to report

      if (!await Geolocator.isLocationServiceEnabled()) return true;
      // Must be `always`, not `whileInUse`: this isolate runs with the app
      // closed, and Android 10+ hands back nothing at all for a
      // foreground-only grant. Checking for it explicitly (rather than
      // just "not denied") is the difference between failing loudly in
      // the log and failing invisibly, which is how this went unnoticed.
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) {
        debugPrint('bg location: need "Allow all the time", have $permission');
        return true;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 30),
          ),
        );
      } catch (e) {
        debugPrint('bg location: live fix failed ($e), trying last known');
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return true;

      await FirebaseFirestore.instance.collection('carpenters').doc(uid).update({
        'location': {'lat': pos.latitude, 'lng': pos.longitude},
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Best-effort, same as the foreground reporter -- a flaky GPS fix or
      // a transient network error here shouldn't retry-storm or crash.
      debugPrint('bg location: $e');
    }
    return true;
  });
}

/// Registers the ~hourly periodic job. Safe to call repeatedly (e.g. on
/// every login) -- `existingWorkPolicy: keep` no-ops if it's already
/// scheduled. Android's WorkManager enforces a 15-minute minimum interval;
/// 60 here is "as close to hourly as the OS allows", not a guarantee --
/// Doze mode and OEM battery managers can delay or skip runs.
Future<void> scheduleBackgroundLocation() async {
  await Workmanager().registerPeriodicTask(
    backgroundLocationTaskName,
    backgroundLocationTaskName,
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

Future<void> cancelBackgroundLocation() => Workmanager().cancelByUniqueName(backgroundLocationTaskName);
