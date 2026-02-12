#!/bin/bash
# Build RIVL macOS app

set -e

echo "Building RIVL macOS app..."

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: macOS builds require macOS with Xcode installed"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode not found. Please install Xcode from the App Store"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter not found. Run ./scripts/setup-flutter-mac.sh first"
    exit 1
fi

# Clean previous builds
echo "Cleaning previous build..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Install CocoaPods dependencies
echo "Installing CocoaPods dependencies..."
cd macos
if ! command -v pod &> /dev/null; then
    echo "Installing CocoaPods..."
    sudo gem install cocoapods
fi
pod install
cd ..

# Build macOS app (release mode)
echo "Building macOS app..."
flutter build macos --release

echo ""
echo "macOS build complete!"
echo "Output: build/macos/Build/Products/Release/rivl.app"
echo ""
echo "To run the app:"
echo "  open build/macos/Build/Products/Release/rivl.app"
echo ""
echo "To run in debug mode:"
echo "  flutter run -d macos"
