// firebase_options.dart
// Firebase Configuration for RIVL

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web Configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDbtmGqg5yxs3l7S03RaikYK0Zq1y1ySaI',
    authDomain: 'rivl-3bf21.firebaseapp.com',
    projectId: 'rivl-3bf21',
    storageBucket: 'rivl-3bf21.firebasestorage.app',
    messagingSenderId: '868172313930',
    appId: '1:868172313930:web:893cf08d511b7c9ec23db3',
    measurementId: 'G-LGD052GJ5K',
  );

  // iOS Configuration
  // TODO: Add iOS app in Firebase Console and update these values
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDbtmGqg5yxs3l7S03RaikYK0Zq1y1ySaI',
    appId: '1:868172313930:ios:PLACEHOLDER',
    messagingSenderId: '868172313930',
    projectId: 'rivl-3bf21',
    storageBucket: 'rivl-3bf21.firebasestorage.app',
    iosBundleId: 'com.rivl.app',
  );

  // Android Configuration
  // TODO: Add Android app in Firebase Console and update these values
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDbtmGqg5yxs3l7S03RaikYK0Zq1y1ySaI',
    appId: '1:868172313930:android:PLACEHOLDER',
    messagingSenderId: '868172313930',
    projectId: 'rivl-3bf21',
    storageBucket: 'rivl-3bf21.firebasestorage.app',
  );

  // macOS Configuration
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDbtmGqg5yxs3l7S03RaikYK0Zq1y1ySaI',
    appId: '1:868172313930:ios:PLACEHOLDER',
    messagingSenderId: '868172313930',
    projectId: 'rivl-3bf21',
    storageBucket: 'rivl-3bf21.firebasestorage.app',
    iosBundleId: 'com.rivl.app',
  );
}
