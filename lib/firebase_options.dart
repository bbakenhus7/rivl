// firebase_options.dart
// Firebase Configuration for RIVL Production
//
// INSTRUCTIONS:
// 1. Go to https://console.firebase.google.com
// 2. Select your RIVL project
// 3. Click the gear icon → Project settings
// 4. Scroll down to "Your apps" section
// 5. Click on your web app
// 6. Copy the config values and paste them below
// 7. Replace ALL the placeholder values marked with "YOUR_"

import 'package:firebase_core/firebase_core.dart';
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
        return ios; // Use iOS config for macOS
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
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCXQDZkfBBRBmQYxzLY8rNcw6SbPwlgwXc',
    appId: '1:868172313930:ios:fd29333adb591bf2c23db3',
    messagingSenderId: '868172313930',
    projectId: 'rivl-3bf21',
    storageBucket: 'rivl-3bf21.firebasestorage.app',
    iosBundleId: 'com.rivl.fitness',
  );

  // Android Configuration (for mobile app builds)
  // TODO: Add Android app in Firebase Console and update apiKey/appId
  static FirebaseOptions get android {
    const apiKey = String.fromEnvironment('ANDROID_FIREBASE_API_KEY',
        defaultValue: 'YOUR_ANDROID_API_KEY');
    const appId = String.fromEnvironment('ANDROID_FIREBASE_APP_ID',
        defaultValue: 'YOUR_ANDROID_APP_ID');
    if (apiKey.startsWith('YOUR_') || appId.startsWith('YOUR_')) {
      throw UnsupportedError(
        'Android Firebase options are not configured. '
        'Add your Android app in Firebase Console and update firebase_options.dart.',
      );
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: '868172313930',
      projectId: 'rivl-3bf21',
      storageBucket: 'rivl-3bf21.firebasestorage.app',
    );
  }
}

// VERIFICATION CHECKLIST:
// Before deploying, make sure:
// ✅ All "YOUR_" placeholders are replaced with real values
// ✅ No test/stub/fake values remain
// ✅ apiKey starts with "AIza"
// ✅ projectId matches your Firebase project name
// ✅ You've tested authentication after updating
