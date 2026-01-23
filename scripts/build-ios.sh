#!/bin/bash
# Build RIVL iOS app for TestFlight/App Store

set -e

echo "🍎 Building RIVL iOS app..."

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: iOS builds require macOS with Xcode installed"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode not found. Please install Xcode from App Store"
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous build..."
flutter clean
cd ios
rm -rf build
pod repo update
pod install
cd ..

# Build iOS app (release mode)
echo "🔨 Building iOS app..."
flutter build ios --release

echo "✅ iOS build complete!"
echo ""
echo "Next steps for TestFlight:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select 'Runner' project → 'Signing & Capabilities'"
echo "3. Set your Team and Bundle Identifier"
echo "4. Product → Archive"
echo "5. Distribute App → App Store Connect"
echo "6. Upload to TestFlight"
echo ""
echo "Or build IPA directly:"
echo "flutter build ipa --release"
