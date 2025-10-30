#!/bin/bash

# HandyShots - Build Script
# Compiles the app from scratch and creates a standalone .app bundle

set -e

echo "🔨 Starting HandyShots build..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# App details
APP_NAME="HandyShots"
BUNDLE_ID="com.handyshots.app"
VERSION="1.0.0"
MIN_MACOS="13.0"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "📁 Project directory: $PROJECT_DIR"
echo ""

# Step 1: Check prerequisites
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Checking prerequisites..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ Error: This script must be run on macOS${NC}"
    exit 1
fi

# Check for Swift
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Error: Swift is not installed${NC}"
    echo "Please install Xcode from the App Store"
    exit 1
fi

SWIFT_VERSION=$(swift --version | head -n 1)
echo -e "  ${GREEN}✅ Swift found: $SWIFT_VERSION${NC}"

# Check for xcodebuild
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Error: xcodebuild is not installed${NC}"
    echo "Please install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo -e "  ${GREEN}✅ Xcode found: $XCODE_VERSION${NC}"

echo ""

# Step 2: Generate Xcode project
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Generating Xcode project..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$PROJECT_DIR"

# Create Xcode project using swift package
echo "  🔧 Creating Xcode project from Package.swift..."

# Generate Xcode project (works with SPM)
swift package generate-xcodeproj 2>/dev/null || {
    echo "  ℹ️  generate-xcodeproj deprecated, using alternative method..."

    # Alternative: open the package in Xcode which will create workspace
    # For now, we'll build directly with swift build and create .app manually
    echo "  ℹ️  Will build using swift build and create .app bundle manually"
}

echo -e "${GREEN}✅ Project prepared${NC}"
echo ""

# Step 3: Build with Swift
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏗️  Building executable..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Build in release mode
echo "  🔨 Compiling in Release mode..."
swift build -c release --arch arm64 --arch x86_64 || {
    echo -e "${YELLOW}⚠️  Universal build failed, trying single architecture...${NC}"
    swift build -c release
}

# Try multiple possible build output locations
POSSIBLE_PATHS=(
    "$PROJECT_DIR/.build/release/$APP_NAME"
    "$PROJECT_DIR/.build/apple/Products/Release/$APP_NAME"
    "$PROJECT_DIR/.build/arm64-apple-macosx/release/$APP_NAME"
    "$PROJECT_DIR/.build/x86_64-apple-macosx/release/$APP_NAME"
)

EXECUTABLE_PATH=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path" ]; then
        EXECUTABLE_PATH="$path"
        break
    fi
done

# If still not found, try to find it dynamically
if [ -z "$EXECUTABLE_PATH" ] || [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "  🔍 Searching for executable in .build directory..."
    EXECUTABLE_PATH=$(find "$PROJECT_DIR/.build" -name "$APP_NAME" -type f -executable 2>/dev/null | head -n 1)
fi

if [ -z "$EXECUTABLE_PATH" ] || [ ! -f "$EXECUTABLE_PATH" ]; then
    echo -e "${RED}❌ Error: Executable not found after build${NC}"
    echo "Searched in:"
    for path in "${POSSIBLE_PATHS[@]}"; do
        echo "  - $path"
    done
    echo ""
    echo "Build directory structure:"
    ls -R "$PROJECT_DIR/.build" 2>/dev/null | head -50
    exit 1
fi

echo -e "  ${GREEN}✅ Executable built at: $EXECUTABLE_PATH${NC}"
echo ""

# Step 4: Create .app bundle structure
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Creating .app bundle..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

APP_BUNDLE="$PROJECT_DIR/build/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"

# Remove old bundle if exists
if [ -d "$APP_BUNDLE" ]; then
    echo "  🗑️  Removing old bundle..."
    rm -rf "$APP_BUNDLE"
fi

# Create directory structure
echo "  📁 Creating bundle structure..."
mkdir -p "$APP_MACOS"
mkdir -p "$APP_RESOURCES"

# Copy executable
echo "  📋 Copying executable..."
cp "$EXECUTABLE_PATH" "$APP_MACOS/$APP_NAME"
chmod +x "$APP_MACOS/$APP_NAME"

# Copy Info.plist
echo "  📋 Copying Info.plist..."
if [ -f "$PROJECT_DIR/HandyShots/Resources/Info.plist" ]; then
    cp "$PROJECT_DIR/HandyShots/Resources/Info.plist" "$APP_CONTENTS/Info.plist"
else
    echo -e "${YELLOW}⚠️  Info.plist not found, creating basic one...${NC}"
    cat > "$APP_CONTENTS/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF
fi

# Create PkgInfo
echo "  📋 Creating PkgInfo..."
echo -n "APPL????" > "$APP_CONTENTS/PkgInfo"

# Copy resources if any
if [ -d "$PROJECT_DIR/HandyShots/Resources" ]; then
    echo "  📋 Copying resources..."
    find "$PROJECT_DIR/HandyShots/Resources" -type f ! -name "Info.plist" ! -name "*.entitlements" -exec cp {} "$APP_RESOURCES/" \;
fi

echo -e "${GREEN}✅ App bundle created${NC}"
echo ""

# Step 5: Code signing (ad-hoc for local development)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✍️  Code signing..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if entitlements exist
ENTITLEMENTS_PATH="$PROJECT_DIR/HandyShots/Resources/HandyShots.entitlements"

if [ -f "$ENTITLEMENTS_PATH" ]; then
    echo "  🔏 Signing with entitlements..."
    codesign --force --deep --sign - --entitlements "$ENTITLEMENTS_PATH" "$APP_BUNDLE" 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Entitlements signing failed, trying ad-hoc...${NC}"
        codesign --force --deep --sign - "$APP_BUNDLE"
    }
else
    echo "  🔏 Signing with ad-hoc signature..."
    codesign --force --deep --sign - "$APP_BUNDLE"
fi

# Verify signature
echo "  ✅ Verifying signature..."
codesign --verify --verbose "$APP_BUNDLE"

echo -e "${GREEN}✅ App signed successfully${NC}"
echo ""

# Step 6: Build summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✨ Build complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 App bundle location:"
echo -e "   ${BLUE}$APP_BUNDLE${NC}"
echo ""
echo "📊 Bundle information:"
APP_SIZE=$(du -sh "$APP_BUNDLE" | cut -f1)
echo "   Size: $APP_SIZE"
echo "   Version: $VERSION"
echo "   Bundle ID: $BUNDLE_ID"
echo "   Min macOS: $MIN_MACOS"
echo ""
echo "🚀 To run the app:"
echo -e "   ${BLUE}open \"$APP_BUNDLE\"${NC}"
echo ""
echo "   Or double-click the app in Finder:"
echo "   $APP_BUNDLE"
echo ""
echo "📋 To copy to Applications:"
echo -e "   ${BLUE}cp -r \"$APP_BUNDLE\" ~/Applications/${NC}"
echo ""
