#!/bin/bash
# Set up Flutter development environment on macOS for RIVL

set -e

echo "RIVL Flutter Mac Setup"
echo "======================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script must be run on macOS${NC}"
    exit 1
fi

# Step 1: Check Xcode
echo -e "${YELLOW}Step 1: Checking Xcode...${NC}"
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Xcode not found. Please install Xcode from the App Store first.${NC}"
    exit 1
fi
xcode_version=$(xcodebuild -version | head -1)
echo -e "${GREEN}Found: $xcode_version${NC}"

# Accept Xcode license if needed
sudo xcodebuild -license accept 2>/dev/null || true

# Run first launch if needed
sudo xcodebuild -runFirstLaunch 2>/dev/null || true

# Step 2: Install Homebrew (if not installed)
echo ""
echo -e "${YELLOW}Step 2: Checking Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo -e "${GREEN}Homebrew installed${NC}"
else
    echo -e "${GREEN}Homebrew already installed${NC}"
fi

# Step 3: Install Flutter
echo ""
echo -e "${YELLOW}Step 3: Checking Flutter...${NC}"
if ! command -v flutter &> /dev/null; then
    echo "Installing Flutter via Homebrew..."
    brew install --cask flutter
    echo -e "${GREEN}Flutter installed${NC}"
else
    flutter_version=$(flutter --version | head -1)
    echo -e "${GREEN}Found: $flutter_version${NC}"
fi

# Step 4: Install CocoaPods
echo ""
echo -e "${YELLOW}Step 4: Checking CocoaPods...${NC}"
if ! command -v pod &> /dev/null; then
    echo "Installing CocoaPods..."
    sudo gem install cocoapods
    echo -e "${GREEN}CocoaPods installed${NC}"
else
    pod_version=$(pod --version)
    echo -e "${GREEN}Found: CocoaPods $pod_version${NC}"
fi

# Step 5: Flutter doctor
echo ""
echo -e "${YELLOW}Step 5: Running Flutter doctor...${NC}"
flutter doctor

# Step 6: Get project dependencies
echo ""
echo -e "${YELLOW}Step 6: Getting project dependencies...${NC}"
flutter pub get

# Step 7: Install macOS CocoaPods
echo ""
echo -e "${YELLOW}Step 7: Installing macOS CocoaPods dependencies...${NC}"
cd macos
pod install
cd ..

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo "======================"
echo ""
echo "You can now run the app with:"
echo "  flutter run -d macos          # Debug mode"
echo "  ./scripts/build-macos.sh      # Release build"
echo ""
echo "Open in Xcode:"
echo "  open macos/Runner.xcworkspace"
echo ""
