#!/bin/bash
# RIVL Configuration Validation Script
# Checks that all required setup is complete

echo "🔍 RIVL Configuration Validator"
echo "==============================="
echo ""

ERRORS=0
WARNINGS=0

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Firebase Config
echo "Checking Firebase Configuration..."
if grep -q "YOUR_API_KEY_HERE" lib/firebase_options.dart; then
    echo -e "${RED}❌ Firebase config not updated (still has placeholders)${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ Firebase config looks good${NC}"
fi

# Check Stripe Key
echo "Checking Stripe Configuration..."
if grep -q "FAKE_PUBLISHABLE_KEY" lib/main.dart; then
    echo -e "${RED}❌ Stripe key not updated (still using fake key)${NC}"
    ERRORS=$((ERRORS + 1))
elif grep -q "pk_test_" lib/main.dart; then
    echo -e "${GREEN}✅ Stripe test key configured${NC}"
elif grep -q "pk_live_" lib/main.dart; then
    echo -e "${YELLOW}⚠️  Using Stripe LIVE key (make sure this is intentional)${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${RED}❌ Stripe key format not recognized${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Cloud Functions Build
echo "Checking Cloud Functions..."
if [ -d "functions/lib" ]; then
    echo -e "${GREEN}✅ Cloud Functions compiled${NC}"
else
    echo -e "${YELLOW}⚠️  Cloud Functions not compiled yet${NC}"
    echo "   Run: cd functions && npm run build"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Dependencies
echo "Checking Dependencies..."
if [ -d "functions/node_modules" ]; then
    echo -e "${GREEN}✅ Cloud Functions dependencies installed${NC}"
else
    echo -e "${RED}❌ Cloud Functions dependencies missing${NC}"
    echo "   Run: cd functions && npm install"
    ERRORS=$((ERRORS + 1))
fi

# Check Firebase CLI
echo "Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    echo -e "${GREEN}✅ Firebase CLI installed${NC}"
else
    echo -e "${RED}❌ Firebase CLI not found${NC}"
    echo "   Install: npm install -g firebase-tools"
    ERRORS=$((ERRORS + 1))
fi

# Check Flutter
echo "Checking Flutter..."
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✅ Flutter installed${NC}"
else
    echo -e "${YELLOW}⚠️  Flutter not found (needed for mobile builds)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Web Build
echo "Checking Web Build..."
if [ -d "docs" ] && [ -f "docs/index.html" ]; then
    # Check if it has the correct base href
    if grep -q 'base href="/rivl/"' docs/index.html; then
        echo -e "${GREEN}✅ Web build exists with correct base href${NC}"
    else
        echo -e "${YELLOW}⚠️  Web build exists but base href might be wrong${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  Web build not found${NC}"
    echo "   Run: ./scripts/build-web.sh"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Firestore Rules
echo "Checking Firestore Rules..."
if [ -f "firestore.rules" ]; then
    echo -e "${GREEN}✅ Firestore rules file exists${NC}"
else
    echo -e "${RED}❌ Firestore rules file missing${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Firebase Config File
echo "Checking Firebase Config..."
if [ -f "firebase.json" ]; then
    echo -e "${GREEN}✅ firebase.json exists${NC}"
else
    echo -e "${RED}❌ firebase.json missing${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Mobile Configs
echo "Checking Mobile Configurations..."
if grep -q "NSHealthShareUsageDescription" ios/Runner/Info.plist; then
    echo -e "${GREEN}✅ iOS HealthKit permissions configured${NC}"
else
    echo -e "${YELLOW}⚠️  iOS HealthKit permissions might not be configured${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

if grep -q "health.READ_STEPS" android/app/src/main/AndroidManifest.xml; then
    echo -e "${GREEN}✅ Android Health Connect permissions configured${NC}"
else
    echo -e "${YELLOW}⚠️  Android Health Connect permissions might not be configured${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Summary
echo ""
echo "=============================="
echo "Validation Summary"
echo "=============================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 Perfect! Everything looks good!${NC}"
    echo ""
    echo "You're ready to deploy:"
    echo "1. Deploy Firestore rules: firebase deploy --only firestore:rules"
    echo "2. Deploy Cloud Functions: firebase deploy --only functions"
    echo "3. Test your app!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found${NC}"
    echo "Review the warnings above. The app should still work."
    exit 0
else
    echo -e "${RED}❌ $ERRORS error(s) found${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found${NC}"
    fi
    echo ""
    echo "Please fix the errors above before deploying."
    exit 1
fi
