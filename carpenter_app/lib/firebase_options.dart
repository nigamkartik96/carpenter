// Hand-written Firebase configuration (no flutterfire CLI login available
// in this environment). Values copied from the Firebase console:
// - Android: Project settings > Your apps > carpenter_app > google-services.json
// - Web: Project settings > Your apps > CarpenterHub Admin > firebaseConfig
// Regenerate with `flutterfire configure` if you ever get CLI login working.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXTZchUs-s91F5f_oDvIYRaKHIODwfTxI',
    appId: '1:620857085533:android:ed97926cb8319c82c347b4',
    messagingSenderId: '620857085533',
    projectId: 'carpenterhub-96958',
    storageBucket: 'carpenterhub-96958.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA1T8o8eX_KJIkOYMANr7LPKw04FQgfODs',
    appId: '1:620857085533:web:adb0692714efe84ac347b4',
    messagingSenderId: '620857085533',
    projectId: 'carpenterhub-96958',
    authDomain: 'carpenterhub-96958.firebaseapp.com',
    storageBucket: 'carpenterhub-96958.firebasestorage.app',
  );
}
