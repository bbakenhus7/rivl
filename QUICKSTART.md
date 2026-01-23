# 🚀 RIVL Quick Start Guide

Everything is set up and ready! Here's how to get your app deployed in the next hour.

## ✅ What's Already Done

All infrastructure and code is complete:

- ✅ **Firebase configuration template** - `/lib/firebase_options.dart`
- ✅ **Firestore security rules** - `firestore.rules`
- ✅ **Cloud Functions** (7 functions) - `functions/src/index.ts`
- ✅ **TypeScript compiled successfully** - `functions/lib/`
- ✅ **All dependencies installed** - `functions/node_modules/`
- ✅ **Firebase CLI installed** - Ready to deploy
- ✅ **Web app built** - `docs/` folder for GitHub Pages
- ✅ **Mobile configs** - iOS & Android permissions set
- ✅ **Build scripts** - Automated build tools
- ✅ **Setup automation** - `scripts/setup.sh`
- ✅ **Validation script** - `scripts/validate.sh`

## 🎯 Quick Start (60 minutes)

### Option 1: Automated Setup (Recommended)

Run the automated setup script:

```bash
cd /home/user/rivl
./scripts/setup.sh
```

This interactive script will:
1. Guide you through Firebase project connection
2. Collect your Firebase and Stripe credentials
3. Update all configuration files
4. Deploy everything automatically

### Option 2: Manual Setup

#### Step 1: Firebase Project (10 min)

1. Go to https://console.firebase.google.com
2. Create new project: "rivl-fitness"
3. Add web app to project
4. Copy the Firebase config
5. Update `/lib/firebase_options.dart` with your values

#### Step 2: Enable Firebase Services (5 min)

In Firebase Console:
1. **Authentication** → Enable Email/Password
2. **Firestore** → Create database (test mode)
3. **Upgrade to Blaze plan** (pay-as-you-go, required for Cloud Functions)

#### Step 3: Stripe Setup (5 min)

1. Sign up at https://dashboard.stripe.com
2. Get test publishable key (`pk_test_...`)
3. Get test secret key (`sk_test_...`)
4. Update `/lib/main.dart` line 32 with publishable key

#### Step 4: Deploy Backend (15 min)

```bash
# Login to Firebase
firebase login

# Set Stripe secret for Cloud Functions
firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY"

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions
```

#### Step 5: Build & Deploy Web App (10 min)

```bash
# Build web app
./scripts/build-web.sh

# Commit and push
git add docs/ lib/
git commit -m "Deploy production configuration"
git push origin main
```

#### Step 6: Set Up Stripe Webhook (5 min)

1. Go to https://dashboard.stripe.com/webhooks
2. Add endpoint: `https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/stripeWebhook`
3. Select events: `payment_intent.succeeded`, `payment_intent.payment_failed`
4. Copy webhook secret (`whsec_...`)
5. Run: `firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET"`
6. Redeploy: `firebase deploy --only functions`

#### Step 7: Test Everything (10 min)

1. Visit https://YOUR_USERNAME.github.io/rivl/
2. Create account
3. Create test challenge
4. Use Stripe test card: `4242 4242 4242 4242`
5. Verify payment and challenge creation

---

## 📱 Mobile Apps (Optional - 4-8 hours)

For real step tracking, build iOS and Android apps:

### iOS

```bash
./scripts/build-ios.sh
```

Then follow `MOBILE_BUILD_GUIDE.md` Part 1 for Xcode setup and TestFlight.

### Android

```bash
./scripts/build-android.sh
```

Then follow `MOBILE_BUILD_GUIDE.md` Part 2 for Play Console setup.

---

## 🔍 Verify Your Setup

Run the validation script to check everything:

```bash
./scripts/validate.sh
```

This checks:
- ✅ Firebase configuration
- ✅ Stripe keys
- ✅ Cloud Functions build
- ✅ Dependencies
- ✅ Mobile permissions
- ✅ Web build

---

## 🛠️ Available Scripts

All scripts are in `/scripts/`:

```bash
# Automated setup (interactive)
./scripts/setup.sh

# Validate configuration
./scripts/validate.sh

# Build web app
./scripts/build-web.sh

# Build iOS app (macOS only)
./scripts/build-ios.sh

# Build Android app
./scripts/build-android.sh
```

---

## 📚 Documentation

Detailed guides in your project:

| File | Purpose |
|------|---------|
| `QUICKSTART.md` | This file - fastest path to deployment |
| `SETUP_COMPLETE.md` | Complete overview of what's been set up |
| `FIREBASE_SETUP_GUIDE.md` | Detailed Firebase setup |
| `CLOUD_FUNCTIONS_SETUP.md` | Cloud Functions deployment |
| `MOBILE_BUILD_GUIDE.md` | iOS & Android builds |
| `BETA_TESTING_CHECKLIST.md` | Pre-launch checklist |

---

## 🎯 What's Next?

After deployment:

1. **Test thoroughly** with multiple users
2. **Add Privacy Policy & Terms** (legally required)
3. **Invite beta testers** (start with 10-20 people)
4. **Monitor Firebase logs** for errors
5. **Iterate based on feedback**

---

## 💡 Pro Tips

### For Fastest Deployment

Run the automated setup:
```bash
./scripts/setup.sh
```

It will guide you through everything step-by-step!

### For Testing Locally

Start Firebase emulators:
```bash
firebase emulators:start
```

This runs Functions, Firestore, and Hosting locally for testing.

### For Monitoring

Watch Cloud Functions logs in real-time:
```bash
firebase functions:log --follow
```

---

## 🆘 Troubleshooting

### "Firebase config has placeholders"
- You need to replace `YOUR_API_KEY_HERE` etc. in `/lib/firebase_options.dart`
- Get values from Firebase Console → Project Settings

### "Stripe key not updated"
- Replace `pk_test_FAKE_...` in `/lib/main.dart` with your real test key
- Get from https://dashboard.stripe.com/test/apikeys

### "Cloud Functions deployment failed"
- Make sure you're on Blaze plan (required for external API calls)
- Check `firebase functions:config:get` shows your Stripe key
- Try `cd functions && npm run build` first

### "Web app shows 404"
- Make sure GitHub Pages is set to serve from `/docs` folder
- Check Settings → Pages in your repository
- Wait 1-2 minutes after pushing for deployment

---

## 🎉 You're Ready!

Everything is set up. Just add your credentials and deploy!

**Estimated time to live app: 60 minutes**

Good luck! 🚀
