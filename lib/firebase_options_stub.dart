// firebase_options_stub.dart
// Development stub for FirebaseOptions to allow running the app locally on web.

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  // Minimal web options with placeholder values. Replace with real values for production.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'FAKE_API_KEY_FOR_LOCAL_DEV',
    authDomain: 'fake-project.firebaseapp.com',
    projectId: 'fake-project-id',
    storageBucket: 'fake-project.appspot.com',
    messagingSenderId: '000000000000',
    appId: '1:000000000000:web:000000000000000',
    measurementId: 'G-FAKEMEASURE',
  );
}
