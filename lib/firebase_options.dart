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

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // For web deployment
    return web;
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
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY', // Get from Firebase Console → Android app
    appId: 'YOUR_ANDROID_APP_ID', // Get from Firebase Console → Android app
    messagingSenderId: '868172313930',
    projectId: 'rivl-3bf21',
    storageBucket: 'rivl-3bf21.firebasestorage.app',
  );
}

// VERIFICATION CHECKLIST:
// Before deploying, make sure:
// ✅ All "YOUR_" placeholders are replaced with real values
// ✅ No test/stub/fake values remain
// ✅ apiKey starts with "AIza"
// ✅ projectId matches your Firebase project name
// ✅ You've tested authentication after updating
