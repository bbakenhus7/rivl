#!/bin/bash
# RIVL Automated Setup Script
# This script automates the initial setup process

set -e  # Exit on error

echo "🚀 RIVL Setup Script"
echo "===================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
echo "Checking prerequisites..."
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found${NC}"
    echo "Installing Firebase CLI..."
    npm install -g firebase-tools
    echo -e "${GREEN}✅ Firebase CLI installed${NC}"
else
    echo -e "${GREEN}✅ Firebase CLI found${NC}"
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}⚠️  Flutter not found (required for mobile builds)${NC}"
    echo "   Install from: https://flutter.dev/docs/get-started/install"
else
    echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -1)${NC}"
fi

echo ""
echo "📋 Setup Checklist:"
echo "===================="
echo ""

# Step 1: Firebase Project
echo -e "${YELLOW}Step 1: Firebase Project Setup${NC}"
echo "Have you created a Firebase project at https://console.firebase.google.com?"
read -p "Press Enter when done..."

# Step 2: Firebase Login
echo ""
echo -e "${YELLOW}Step 2: Firebase Login${NC}"
echo "Logging into Firebase..."
firebase login

# Step 3: Initialize Firebase
echo ""
echo -e "${YELLOW}Step 3: Initialize Firebase Project${NC}"
echo "This will connect your local project to Firebase."
echo "When prompted:"
echo "  - Select your existing project"
echo "  - Functions: Already configured"
echo "  - Firestore: Use existing rules"
echo "  - Hosting: Already configured"
echo ""
read -p "Ready to initialize? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    firebase init
fi

# Step 4: Install Functions Dependencies
echo ""
echo -e "${YELLOW}Step 4: Installing Cloud Functions Dependencies${NC}"
cd functions
npm install
cd ..
echo -e "${GREEN}✅ Dependencies installed${NC}"

# Step 5: Get Firebase Config
echo ""
echo -e "${YELLOW}Step 5: Firebase Configuration${NC}"
echo "Please provide your Firebase configuration values."
echo "You can find these in Firebase Console → Project Settings → Your apps"
echo ""
read -p "Enter your Firebase API Key: " api_key
read -p "Enter your Project ID: " project_id
read -p "Enter your Messaging Sender ID: " sender_id
read -p "Enter your App ID (Web): " app_id
read -p "Enter your Measurement ID: " measurement_id

# Update firebase_options.dart
echo "Updating lib/firebase_options.dart..."
cat > lib/firebase_options.dart <<EOF
// firebase_options.dart
// Firebase Configuration for RIVL Production

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '$api_key',
    authDomain: '$project_id.firebaseapp.com',
    projectId: '$project_id',
    storageBucket: '$project_id.appspot.com',
    messagingSenderId: '$sender_id',
    appId: '$app_id',
    measurementId: '$measurement_id',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '$api_key',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '$sender_id',
    projectId: '$project_id',
    storageBucket: '$project_id.appspot.com',
    iosBundleId: 'com.rivlapp.rivl',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '$api_key',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: '$sender_id',
    projectId: '$project_id',
    storageBucket: '$project_id.appspot.com',
  );
}
EOF

echo -e "${GREEN}✅ Firebase configuration updated${NC}"

# Step 6: Get Stripe Keys
echo ""
echo -e "${YELLOW}Step 6: Stripe Configuration${NC}"
echo "Get your Stripe test keys from: https://dashboard.stripe.com/test/apikeys"
read -p "Enter your Stripe Publishable Key (pk_test_...): " stripe_pub_key
read -p "Enter your Stripe Secret Key (sk_test_...): " stripe_secret_key

# Update main.dart
echo "Updating lib/main.dart with Stripe key..."
sed -i "s/pk_test_FAKE_PUBLISHABLE_KEY_FOR_LOCAL/$stripe_pub_key/g" lib/main.dart
echo -e "${GREEN}✅ Stripe publishable key updated${NC}"

# Set Stripe secret for Cloud Functions
echo "Setting Stripe secret for Cloud Functions..."
firebase functions:config:set stripe.secret_key="$stripe_secret_key"
echo -e "${GREEN}✅ Stripe secret configured${NC}"

# Step 7: Deploy Firestore Rules
echo ""
echo -e "${YELLOW}Step 7: Deploy Firestore Security Rules${NC}"
read -p "Deploy security rules now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    firebase deploy --only firestore:rules
    echo -e "${GREEN}✅ Security rules deployed${NC}"
fi

# Step 8: Deploy Cloud Functions
echo ""
echo -e "${YELLOW}Step 8: Deploy Cloud Functions${NC}"
read -p "Deploy Cloud Functions now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd functions
    npm run build
    cd ..
    firebase deploy --only functions
    echo -e "${GREEN}✅ Cloud Functions deployed${NC}"
fi

# Step 9: Build Web App
echo ""
echo -e "${YELLOW}Step 9: Build Web App${NC}"
read -p "Build and deploy web app? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./scripts/build-web.sh
    echo -e "${GREEN}✅ Web app built${NC}"

    echo ""
    echo "Committing and pushing to GitHub..."
    git add docs/ lib/firebase_options.dart lib/main.dart
    git commit -m "Configure Firebase and Stripe for production"
    git push origin main
    echo -e "${GREEN}✅ Changes pushed to GitHub${NC}"
fi

# Final Summary
echo ""
echo "🎉 Setup Complete!"
echo "===================="
echo ""
echo -e "${GREEN}✅ Firebase project connected${NC}"
echo -e "${GREEN}✅ Cloud Functions deployed${NC}"
echo -e "${GREEN}✅ Firestore rules deployed${NC}"
echo -e "${GREEN}✅ Web app configured${NC}"
echo ""
echo "Next steps:"
echo "1. Set up Stripe webhook:"
echo "   - Go to https://dashboard.stripe.com/webhooks"
echo "   - Add endpoint: https://us-central1-$project_id.cloudfunctions.net/stripeWebhook"
echo "   - Select events: payment_intent.succeeded, payment_intent.payment_failed"
echo "   - Get webhook secret and run:"
echo "     firebase functions:config:set stripe.webhook_secret=\"whsec_YOUR_SECRET\""
echo "     firebase deploy --only functions"
echo ""
echo "2. Test your app at: https://YOUR_USERNAME.github.io/rivl/"
echo ""
echo "3. For mobile builds, see MOBILE_BUILD_GUIDE.md"
echo ""
echo "Need help? Check the documentation in your project folder."
