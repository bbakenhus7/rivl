#!/bin/bash
# Build RIVL Android app for Google Play

set -e

echo "🤖 Building RIVL Android app..."

# Clean previous builds
echo "🧹 Cleaning previous build..."
flutter clean
cd android
./gradlew clean
cd ..

# Build Android APK (for testing)
echo "🔨 Building Android APK..."
flutter build apk --release

echo "✅ APK build complete!"
echo "📁 Output: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "For Google Play Console (App Bundle):"
echo "flutter build appbundle --release"
echo "📁 Output: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "Next steps for Google Play:"
echo "1. Go to https://play.google.com/console"
echo "2. Create new app or select existing"
echo "3. Create internal test track"
echo "4. Upload app-release.aab"
echo "5. Add testers by email"
echo "6. Share test link with testers"
