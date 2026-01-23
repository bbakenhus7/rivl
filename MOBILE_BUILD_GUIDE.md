# Mobile App Build Guide for RIVL

This guide covers building iOS and Android apps for RIVL fitness competition app.

## Why Build Mobile Apps?

The **web version** of RIVL has limitations:
- ❌ No access to step counting (HealthKit/Health Connect)
- ❌ No background tracking
- ❌ Limited native features

The **mobile apps** provide:
- ✅ Real step tracking via HealthKit (iOS) and Health Connect (Android)
- ✅ Background tracking
- ✅ Native notifications
- ✅ Better performance
- ✅ App Store distribution

## Prerequisites

### For Both Platforms
- ✅ Flutter SDK installed (already have this)
- ✅ Firebase project configured
- ✅ Code repository access

### For iOS (Requires macOS)
- ✅ macOS computer with Xcode 14+ installed
- ✅ Apple Developer Account ($99/year)
  - Individual or Organization account
  - Sign up at: https://developer.apple.com
- ✅ CocoaPods installed: `sudo gem install cocoapods`

### For Android
- ✅ Android Studio or Android SDK
- ✅ Java JDK 17 installed
- ✅ Google Play Developer Account ($25 one-time)
  - Sign up at: https://play.google.com/console

---

## Part 1: iOS App Build

### Step 1: Set Up Apple Developer Account

1. Go to https://developer.apple.com
2. Enroll in Apple Developer Program ($99/year)
3. Complete enrollment (takes 24-48 hours for approval)
4. Once approved, you can create App IDs and provision profiles

### Step 2: Create App ID in Apple Developer Portal

1. Go to https://developer.apple.com/account
2. Certificates, Identifiers & Profiles → Identifiers
3. Click **+** to create new App ID
4. Select **App IDs** → Continue
5. Fill in:
   - **Description**: RIVL Fitness
   - **Bundle ID**: `com.rivlapp.rivl` (or your own unique ID)
   - **Capabilities**: Check these boxes:
     - ☑ HealthKit
     - ☑ Push Notifications
     - ☑ Sign in with Apple (optional)
6. Click **Continue** → **Register**

### Step 3: Configure iOS Project in Xcode

1. Open Terminal and navigate to project:
   ```bash
   cd /path/to/rivl
   cd ios
   pod install
   open Runner.xcworkspace
   ```

2. In Xcode, select **Runner** project (blue icon at top)

3. Go to **Signing & Capabilities** tab:
   - **Team**: Select your Apple Developer Team
   - **Bundle Identifier**: `com.rivlapp.rivl` (must match App ID)
   - Xcode will automatically generate provisioning profile

4. Add HealthKit capability:
   - Click **+ Capability**
   - Search for **HealthKit**
   - Add it

5. Configure HealthKit (if not auto-configured):
   - Under HealthKit section
   - Check **Clinical Health Records** (optional)
   - Health data types are configured in code

### Step 4: Add Firebase Configuration for iOS

1. In Firebase Console, go to Project Settings
2. Under "Your apps", click **Add app** → iOS
3. Fill in:
   - **iOS bundle ID**: `com.rivlapp.rivl` (same as Xcode)
   - **App nickname**: RIVL iOS
   - **App Store ID**: (leave blank for now)
4. Click **Register app**
5. Download `GoogleService-Info.plist`
6. In Xcode, drag this file into `ios/Runner` folder
   - Make sure "Copy items if needed" is checked
   - Target: Runner
7. Update `/lib/firebase_options.dart` with iOS config from Firebase Console

### Step 5: Build iOS App

#### Option A: Using Script (Easiest)

```bash
cd /path/to/rivl
./scripts/build-ios.sh
```

#### Option B: Manual Build

```bash
# Clean and build
flutter clean
cd ios
pod install
cd ..
flutter build ios --release
```

### Step 6: Create Archive for TestFlight

1. In Xcode, select target device: **Any iOS Device**
2. Menu: **Product** → **Archive**
3. Wait for archive to complete (5-10 minutes)
4. Organizer window opens automatically
5. Select your archive → Click **Distribute App**
6. Choose **App Store Connect** → **Upload**
7. Follow prompts (use automatic signing)
8. Upload complete! (may take 10-20 minutes)

### Step 7: Set Up TestFlight

1. Go to https://appstoreconnect.apple.com
2. **My Apps** → **+** → **New App**
3. Fill in app information:
   - **Platform**: iOS
   - **Name**: RIVL
   - **Primary Language**: English
   - **Bundle ID**: Select `com.rivlapp.rivl`
   - **SKU**: `rivl-001` (any unique identifier)
4. Click **Create**

5. Go to **TestFlight** tab
6. Under "Internal Testing":
   - Click **+** next to "Internal Group"
   - Add testers (up to 100 internal testers, no review needed)
7. Under "External Testing":
   - For beta with outside testers (requires Apple review)

### Step 8: Invite Testers

1. In TestFlight tab, click your test group
2. Click **Add Testers**
3. Enter email addresses
4. Testers receive email with TestFlight link
5. They install TestFlight app from App Store
6. Open link to install RIVL beta

---

## Part 2: Android App Build

### Step 1: Set Up Google Play Developer Account

1. Go to https://play.google.com/console
2. Create account ($25 one-time fee)
3. Accept Developer Distribution Agreement
4. Pay registration fee
5. Account setup takes 24-48 hours for verification

### Step 2: Create App in Play Console

1. In Play Console, click **Create app**
2. Fill in details:
   - **App name**: RIVL
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
3. Accept declarations
4. Click **Create app**

### Step 3: Configure Android Project

The app is already configured with:
- Package name: `com.rivlapp.rivl`
- Min SDK: 28 (Android 9.0) - required for Health Connect
- Target SDK: 34 (Android 14)
- Health Connect permissions

#### Customize Package Name (Optional)

If you want a different package name:

1. Edit `/android/app/build.gradle.kts`:
   ```kotlin
   namespace = "com.yourcompany.rivl"
   applicationId = "com.yourcompany.rivl"
   ```

2. Edit `/android/app/src/main/AndroidManifest.xml`:
   Update package references if needed

3. Rebuild project

### Step 4: Add Firebase Configuration for Android

1. In Firebase Console, Project Settings
2. Under "Your apps", click **Add app** → Android
3. Fill in:
   - **Android package name**: `com.rivlapp.rivl`
   - **App nickname**: RIVL Android
   - **Debug signing certificate**: (optional for now)
4. Click **Register app**
5. Download `google-services.json`
6. Copy file to `/android/app/google-services.json`
7. Update `/lib/firebase_options.dart` with Android config

### Step 5: Generate Signing Key

For Play Store release, you need to sign your app:

```bash
# Create upload keystore
keytool -genkey -v -keystore ~/rivl-upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias rivl-upload

# You'll be prompted for:
# - Password (save this!)
# - Name, organization, etc.
```

Create `/android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=rivl-upload
storeFile=/Users/you/rivl-upload-key.jks
```

**⚠️ IMPORTANT**: Add `key.properties` to `.gitignore` (already done)

Update `/android/app/build.gradle.kts` to use key (if not already configured):

```kotlin
// Load keystore
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### Step 6: Build Android App

#### Option A: Using Script (Easiest)

```bash
cd /path/to/rivl
./scripts/build-android.sh
```

#### Option B: Manual Build

For testing (APK):
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

For Play Store (App Bundle - required):
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Step 7: Upload to Play Console for Beta Testing

1. In Play Console, go to your app
2. Left sidebar: **Testing** → **Internal testing**
3. Click **Create new release**
4. Upload `app-release.aab`
5. Fill in release notes (what's new)
6. Click **Review release**
7. Click **Start rollout to Internal testing**

### Step 8: Add Beta Testers

1. In Internal testing, go to **Testers** tab
2. Create email list:
   - Click **Create email list**
   - Add tester emails
3. Save
4. Share the opt-in link with testers
5. Testers click link → Accept invite → Download from Play Store

---

## Part 3: Testing Mobile Apps

### iOS Testing Checklist

- [ ] Authentication works (email, Google, Apple)
- [ ] HealthKit permission requested
- [ ] Step data syncs from Health app
- [ ] Create challenge flow works
- [ ] Payment processing works (use Stripe test cards)
- [ ] Challenge completion determines winner correctly
- [ ] Notifications appear
- [ ] Leaderboard updates
- [ ] Profile updates
- [ ] Referral system works

### Android Testing Checklist

- [ ] Authentication works
- [ ] Health Connect permission requested
- [ ] Step data syncs from Health Connect/Google Fit
- [ ] All challenge flows work
- [ ] Payment processing works
- [ ] Notifications appear
- [ ] All features match iOS

### Test Cards for Stripe

- **Success**: `4242 4242 4242 4242`
- **Declined**: `4000 0000 0000 0002`
- **Insufficient funds**: `4000 0000 0000 9995`
- **3D Secure**: `4000 0025 0000 3155`

Use any future expiry date and any 3-digit CVC.

---

## Part 4: Production Release

### iOS App Store Release

1. In App Store Connect, go to your app
2. Fill in all required metadata:
   - App name
   - Subtitle
   - Description
   - Keywords
   - Screenshots (required for all sizes)
   - App icon
   - Privacy policy URL
   - Support URL
3. Age rating questionnaire
4. App Review Information
5. Submit for review
6. Apple review takes 1-7 days
7. Once approved, you can release to App Store

### Android Play Store Release

1. Complete all sections in Play Console:
   - App content (declarations)
   - Store listing (description, screenshots)
   - Store settings (category, tags)
   - Countries/regions
   - Pricing
2. Create production release (same as internal testing)
3. Upload signed AAB
4. Submit for review
5. Google review takes 1-7 days
6. Once approved, app goes live

---

## Cost Summary

### Development Costs
- **Apple Developer Program**: $99/year
- **Google Play Developer**: $25 one-time
- **Total**: $124 first year, $99/year after

### Distribution Costs
- **Stripe**: 2.9% + $0.30 per transaction
- **Firebase**: Free tier covers beta, ~$20-50/month for production
- **Total operational**: ~$50-100/month for 10,000 users

---

## Quick Reference Commands

```bash
# Web
./scripts/build-web.sh

# iOS (macOS only)
./scripts/build-ios.sh

# Android
./scripts/build-android.sh

# Check Flutter doctor
flutter doctor

# Clean build
flutter clean

# Run on connected device
flutter run --release

# View logs
flutter logs
```

---

## Troubleshooting

### iOS Issues

**"No provisioning profile found"**
- Check Team is selected in Xcode
- Verify Bundle ID matches App ID in Developer Portal
- Xcode → Preferences → Accounts → Download Manual Profiles

**"HealthKit not found"**
- Add HealthKit capability in Xcode
- Check Info.plist has NSHealthShareUsageDescription

**Archive fails**
- Clean build folder: Xcode → Product → Clean Build Folder
- Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Run `pod install` again

### Android Issues

**"Gradle build failed"**
- Update Android Gradle Plugin
- Sync project: Android Studio → File → Sync Project with Gradle Files
- Invalidate caches: File → Invalidate Caches / Restart

**"Health Connect not working"**
- Ensure minSdk is 28 or higher
- Check permissions in AndroidManifest.xml
- Install Health Connect app from Play Store on test device

**"Signing error"**
- Verify key.properties path is correct
- Check keystore passwords are correct
- Make sure keystore file exists

---

## Next Steps

After building mobile apps:

1. ✅ Test thoroughly with real devices
2. ✅ Get feedback from beta testers
3. ✅ Fix bugs and iterate
4. ✅ Complete App Store/Play Store metadata
5. ✅ Submit for review
6. ✅ Launch! 🚀

Good luck with your mobile app builds!
