#!/bin/bash

# HandyShots - Fresh Build Script
# Complete clean + build from scratch pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Banner
clear
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                ║${NC}"
echo -e "${CYAN}║           ${MAGENTA}📷  HandyShots MVP  📷${CYAN}              ║${NC}"
echo -e "${CYAN}║                                                ║${NC}"
echo -e "${CYAN}║           Fresh Build Pipeline                 ║${NC}"
echo -e "${CYAN}║                                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This script will:${NC}"
echo "  1. 🧹 Remove ALL build artifacts and caches"
echo "  2. 🗑️  Delete any previously installed app"
echo "  3. 💾 Reset all UserDefaults and preferences"
echo "  4. 🔐 Clear app permissions (TCC database)"
echo "  5. 🏗️  Compile the app from scratch"
echo "  6. 📦 Create a standalone .app bundle"
echo "  7. ✍️  Code sign the application"
echo ""
echo -e "${RED}⚠️  WARNING: This will completely reset the app!${NC}"
echo ""

# Ask for confirmation
read -p "Do you want to continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Aborted by user${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}🚀 Starting fresh build pipeline...${NC}"
echo ""

# Timestamp start
START_TIME=$(date +%s)

# Step 1: Run clean script
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}        STEP 1/2: CLEANUP & RESET                      ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

if [ -f "$SCRIPT_DIR/clean.sh" ]; then
    bash "$SCRIPT_DIR/clean.sh"
else
    echo -e "${RED}❌ Error: clean.sh not found${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}⏸️  Cleanup complete. Waiting 2 seconds before build...${NC}"
sleep 2

# Step 2: Run build script
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}        STEP 2/2: BUILD APPLICATION                    ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

if [ -f "$SCRIPT_DIR/build.sh" ]; then
    bash "$SCRIPT_DIR/build.sh"
else
    echo -e "${RED}❌ Error: build.sh not found${NC}"
    exit 1
fi

# Timestamp end
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Success banner
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                ║${NC}"
echo -e "${GREEN}║            ✨  BUILD SUCCESSFUL!  ✨            ║${NC}"
echo -e "${GREEN}║                                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}⏱️  Total time: ${DURATION} seconds${NC}"
echo ""

# Final instructions
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
APP_BUNDLE="$PROJECT_DIR/build/HandyShots.app"

if [ -d "$APP_BUNDLE" ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}    📱 Your app is ready to launch!${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}📦 App location:${NC}"
    echo "   $APP_BUNDLE"
    echo ""
    echo -e "${GREEN}🚀 To run the app NOW:${NC}"
    echo -e "   ${BLUE}open \"$APP_BUNDLE\"${NC}"
    echo ""
    echo -e "${GREEN}📂 Or open in Finder:${NC}"
    echo -e "   ${BLUE}open \"$PROJECT_DIR/build\"${NC}"
    echo ""
    echo -e "${GREEN}📋 To install in Applications:${NC}"
    echo -e "   ${BLUE}cp -r \"$APP_BUNDLE\" ~/Applications/${NC}"
    echo ""
    echo -e "${YELLOW}💡 TIP: You can now double-click the .app to launch it!${NC}"
    echo ""

    # Ask if user wants to open the app now
    echo ""
    read -p "Do you want to launch the app now? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${GREEN}🚀 Launching HandyShots...${NC}"
        open "$APP_BUNDLE"
        echo ""
        echo -e "${CYAN}✨ Look for the camera icon 📷 in your menu bar!${NC}"
        echo ""
    fi
else
    echo -e "${RED}❌ Error: App bundle not found at expected location${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}    ✅ Fresh build pipeline completed!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
