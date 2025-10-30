#!/bin/bash

# HandyShots - Complete Clean Script
# Removes all build artifacts, caches, and previous installations

set -e

echo "🧹 Starting complete cleanup..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# App details
APP_NAME="HandyShots"
BUNDLE_ID="com.handyshots.app"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "📁 Project directory: $PROJECT_DIR"
echo ""

# Step 1: Remove build artifacts
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Removing build artifacts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Swift Package Manager build folder
if [ -d "$PROJECT_DIR/.build" ]; then
    echo "  🗑️  Removing .build/"
    rm -rf "$PROJECT_DIR/.build"
fi

# Xcode DerivedData
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
if [ -d "$DERIVED_DATA" ]; then
    echo "  🗑️  Removing DerivedData for $APP_NAME..."
    find "$DERIVED_DATA" -maxdepth 1 -name "*$APP_NAME*" -exec rm -rf {} \; 2>/dev/null || true
fi

# Generated Xcode project
if [ -d "$PROJECT_DIR/$APP_NAME.xcodeproj" ]; then
    echo "  🗑️  Removing generated Xcode project"
    rm -rf "$PROJECT_DIR/$APP_NAME.xcodeproj"
fi

if [ -d "$PROJECT_DIR/$APP_NAME.xcworkspace" ]; then
    echo "  🗑️  Removing Xcode workspace"
    rm -rf "$PROJECT_DIR/$APP_NAME.xcworkspace"
fi

# Previous app bundle in project
if [ -d "$PROJECT_DIR/$APP_NAME.app" ]; then
    echo "  🗑️  Removing previous app bundle in project"
    rm -rf "$PROJECT_DIR/$APP_NAME.app"
fi

# Build output directory
if [ -d "$PROJECT_DIR/build" ]; then
    echo "  🗑️  Removing build/"
    rm -rf "$PROJECT_DIR/build"
fi

echo -e "${GREEN}✅ Build artifacts cleaned${NC}"
echo ""

# Step 2: Remove installed app from Applications
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗂️  Removing installed applications..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check common installation locations
APP_LOCATIONS=(
    "$HOME/Applications/$APP_NAME.app"
    "/Applications/$APP_NAME.app"
    "$HOME/Desktop/$APP_NAME.app"
)

for app_path in "${APP_LOCATIONS[@]}"; do
    if [ -d "$app_path" ]; then
        echo "  🗑️  Removing $app_path"
        rm -rf "$app_path"
    fi
done

# Kill running instances
if pgrep -x "$APP_NAME" > /dev/null; then
    echo "  ⏹️  Killing running $APP_NAME instances..."
    killall "$APP_NAME" 2>/dev/null || true
    sleep 1
fi

echo -e "${GREEN}✅ Installed applications removed${NC}"
echo ""

# Step 3: Reset UserDefaults
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 Resetting UserDefaults..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PLIST_PATH="$HOME/Library/Preferences/${BUNDLE_ID}.plist"

if [ -f "$PLIST_PATH" ]; then
    echo "  🗑️  Removing $PLIST_PATH"
    rm -f "$PLIST_PATH"
else
    echo "  ℹ️  No UserDefaults found"
fi

# Also reset using defaults command
defaults delete "$BUNDLE_ID" 2>/dev/null || true

echo -e "${GREEN}✅ UserDefaults reset${NC}"
echo ""

# Step 4: Reset app permissions (TCC database)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Resetting app permissions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Reset TCC permissions for the app
echo "  ℹ️  Resetting TCC (Transparency, Consent, and Control) database..."

# TCC database location
TCC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"

if [ -f "$TCC_DB" ]; then
    # Try to remove entries for our app (requires Full Disk Access in some macOS versions)
    sqlite3 "$TCC_DB" "DELETE FROM access WHERE client='$BUNDLE_ID';" 2>/dev/null || true
    echo "  ✅ TCC entries removed (if any existed)"
else
    echo "  ℹ️  TCC database not found or not accessible"
fi

# Reset file system permissions
echo "  ℹ️  Note: You may need to manually reset 'Files and Folders' permissions in"
echo "           System Settings → Privacy & Security if the app had special access"

echo -e "${GREEN}✅ Permissions reset${NC}"
echo ""

# Step 5: Clear Xcode caches
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗄️  Clearing Xcode caches..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Module cache
MODULE_CACHE="$HOME/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
if [ -d "$MODULE_CACHE" ]; then
    echo "  🗑️  Removing module cache"
    rm -rf "$MODULE_CACHE"
fi

# Archive
ARCHIVES="$HOME/Library/Developer/Xcode/Archives"
if [ -d "$ARCHIVES" ]; then
    echo "  🗑️  Removing archives for $APP_NAME"
    find "$ARCHIVES" -name "*$APP_NAME*" -exec rm -rf {} \; 2>/dev/null || true
fi

echo -e "${GREEN}✅ Xcode caches cleared${NC}"
echo ""

# Step 6: Clear Swift Package Manager caches
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Clearing Swift Package Manager caches..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SPM_CACHE="$HOME/Library/Caches/org.swift.swiftpm"
if [ -d "$SPM_CACHE" ]; then
    echo "  🗑️  Removing SPM cache"
    rm -rf "$SPM_CACHE"
fi

echo -e "${GREEN}✅ SPM caches cleared${NC}"
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✨ Cleanup complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The following has been cleaned:"
echo "  ✅ All build artifacts"
echo "  ✅ Xcode DerivedData and caches"
echo "  ✅ Installed app bundles"
echo "  ✅ UserDefaults and preferences"
echo "  ✅ App permissions (TCC)"
echo "  ✅ Swift Package Manager caches"
echo ""
echo "The app will start completely fresh on next build!"
echo ""
