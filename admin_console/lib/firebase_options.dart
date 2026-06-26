// Hand-written Firebase configuration (no flutterfire CLI login available
// in this environment). Web config copied from the Firebase console:
// Project settings > Your apps > CarpenterHub Admin > firebaseConfig.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA1T8o8eX_KJIkOYMANr7LPKw04FQgfODs',
    appId: '1:620857085533:web:adb0692714efe84ac347b4',
    messagingSenderId: '620857085533',
    projectId: 'carpenterhub-96958',
    authDomain: 'carpenterhub-96958.firebaseapp.com',
    storageBucket: 'carpenterhub-96958.firebasestorage.app',
  );
}
