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
  // Replace these values with your actual Firebase config
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY_HERE', // Example: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com', // Example: 'rivl-fitness.firebaseapp.com'
    projectId: 'YOUR_PROJECT_ID', // Example: 'rivl-fitness'
    storageBucket: 'YOUR_PROJECT_ID.appspot.com', // Example: 'rivl-fitness.appspot.com'
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID', // Example: '123456789012'
    appId: 'YOUR_WEB_APP_ID', // Example: '1:123456789012:web:abcdef1234567890'
    measurementId: 'YOUR_MEASUREMENT_ID', // Example: 'G-XXXXXXXXXX'
  );

  // iOS Configuration (for mobile app builds)
  // Get this from Firebase Console → iOS app settings
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.yourcompany.rivl', // Change this to your bundle ID
  );

  // Android Configuration (for mobile app builds)
  // Get this from Firebase Console → Android app settings
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );
}

// VERIFICATION CHECKLIST:
// Before deploying, make sure:
// ✅ All "YOUR_" placeholders are replaced with real values
// ✅ No test/stub/fake values remain
// ✅ apiKey starts with "AIza"
// ✅ projectId matches your Firebase project name
// ✅ You've tested authentication after updating
