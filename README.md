# RIVL Flutter App

## 🎯 Overview

This is the complete Flutter version of RIVL - a fitness competition app that works on **both iOS and Android** from a single codebase.

## ✅ Benefits of Flutter Version

| Feature | Flutter | Native iOS (Swift) |
|---------|---------|-------------------|
| Develop on Windows | ✅ Yes | ❌ No |
| Develop on Mac | ✅ Yes | ✅ Yes |
| Build Android | ✅ Yes | ❌ No |
| Build iOS | ✅ Yes (needs Mac for final build) | ✅ Yes |
| Single codebase | ✅ One codebase for both | ❌ Separate codebases |
| Cost | Free | Free |

---

## 🚀 Quick Start (Windows)

### 1. Install Flutter

```bash
# Download Flutter SDK from flutter.dev
# Extract to C:\flutter

# Add to PATH (in Environment Variables)
C:\flutter\bin

# Verify installation
flutter doctor
```

### 2. Install Android Studio

1. Download from [developer.android.com/studio](https://developer.android.com/studio)
2. During install, include "Android SDK" and "Android Virtual Device"
3. Open Android Studio → More Actions → SDK Manager
4. Install Android SDK Command-line Tools

### 3. Install VS Code + Extensions

1. Download VS Code from [code.visualstudio.com](https://code.visualstudio.com)
2. Install extensions:
   - Flutter
   - Dart

### 4. Setup Project

```bash
# Clone or copy this folder
cd rivl-flutter

# Get dependencies
flutter pub get

# Run the app (with Android emulator running)
flutter run
```

---

## 📁 Project Structure

```
rivl-flutter/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   ├── user_model.dart       # User data model
│   │   └── challenge_model.dart  # Challenge data model
│   ├── services/
│   │   ├── firebase_service.dart # All Firebase API calls
│   │   └── health_service.dart   # Step tracking
│   ├── providers/
│   │   ├── auth_provider.dart    # Auth state management
│   │   ├── challenge_provider.dart
│   │   └── health_provider.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── main_screen.dart
│   │   ├── auth/
│   │   ├── home/
│   │   ├── challenges/
│   │   ├── create/
│   │   ├── leaderboard/
│   │   └── profile/
│   ├── widgets/
│   │   ├── challenge_card.dart
│   │   └── steps_card.dart
│   └── utils/
│       └── theme.dart            # Colors, styles
├── pubspec.yaml                  # Dependencies
└── README.md
```

---

## 🔧 Configuration Steps

### 1. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create project "rivl-app"
3. Add Android app:
   - Package name: `com.yourcompany.rivl`
   - Download `google-services.json`
   - Place in `android/app/`
4. Add iOS app (when ready):
   - Bundle ID: `com.yourcompany.rivl`
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`

### 2. Update main.dart

Replace the Stripe key in `lib/main.dart`:

```dart
Stripe.publishableKey = 'pk_test_YOUR_ACTUAL_KEY';
```

### 3. Android Configuration

Edit `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        applicationId "com.yourcompany.rivl"
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### 4. Health Connect Setup (Android)

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Health Connect permissions -->
    <uses-permission android:name="android.permission.health.READ_STEPS"/>
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
    
    <application>
        <!-- Health Connect intent filter -->
        <intent-filter>
            <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE"/>
        </intent-filter>
    </application>
</manifest>
```

---

## 📱 Running the App

### On Android Emulator

```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>

# Run app
flutter run
```

### On Physical Android Device

1. Enable Developer Options on your phone
2. Enable USB Debugging
3. Connect phone via USB
4. Run:
```bash
flutter devices  # Should show your phone
flutter run
```

### On iOS (requires Mac)

```bash
# Open iOS simulator
open -a Simulator

# Run app
flutter run
```

---

## 🏗️ Building for Release

### Android APK (can do on Windows!)

```bash
# Build APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (requires Mac)

```bash
flutter build ios --release

# Then open Xcode to archive and upload
```

---

## 🌐 Building iOS Without a Mac

### Option 1: Codemagic (Recommended)

1. Push code to GitHub
2. Sign up at [codemagic.io](https://codemagic.io)
3. Connect your GitHub repo
4. Codemagic builds iOS on their Mac servers
5. Download the .ipa file

**Free tier**: 500 build minutes/month

### Option 2: GitHub Actions + Mac Runner

Use GitHub Actions with a macOS runner to build iOS.

---

## 🔥 Firebase Backend

The Flutter app uses the **same Firebase backend** as the Swift version. No changes needed!

Deploy the Cloud Functions from `firebase-backend/` folder:

```bash
cd firebase-backend
firebase deploy --only functions
```

---

## 📊 Health Data

### Android: Health Connect

- Google's new unified health platform
- Works on Android 9+
- Users must install Health Connect app

### iOS: HealthKit

- Apple's native health framework
- Works automatically on all iPhones
- Requires Mac to build

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/auth_test.dart
```

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Authentication |
| `cloud_firestore` | Database |
| `firebase_messaging` | Push notifications |
| `provider` | State management |
| `health` | Step tracking (Android Health Connect, iOS HealthKit) |
| `flutter_stripe` | Payment processing |
| `fl_chart` | Charts and graphs |

---

## 🚨 Common Issues

### "Flutter doctor" shows issues

```bash
flutter doctor -v  # Verbose output
flutter doctor --android-licenses  # Accept licenses
```

### Gradle build fails

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Health permissions not working

- Android: Make sure Health Connect app is installed
- Check AndroidManifest.xml has correct permissions

---

## 📞 Next Steps

1. ✅ Install Flutter & Android Studio
2. ✅ Run `flutter pub get`
3. ✅ Set up Firebase project
4. ✅ Add `google-services.json`
5. ✅ Run `flutter run` to test
6. ✅ Build APK for Android
7. ⏳ Use Codemagic to build iOS (when ready)

---

## 💰 Cost Summary

| Item | Cost |
|------|------|
| Flutter | Free |
| Android Studio | Free |
| VS Code | Free |
| Firebase (start) | Free |
| Google Play Store | $25 one-time |
| Codemagic (iOS builds) | Free tier available |
| Apple Developer (for iOS) | $99/year |

**Total to launch on Android: $25**
**Total to launch on both: $124**

---

Good luck with RIVL! 🏆
