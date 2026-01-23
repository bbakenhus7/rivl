# Firebase Setup Guide for RIVL

This guide will walk you through setting up Firebase for your RIVL app.

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click **"Add project"**
3. Enter project name: **"rivl-fitness"** (or your preference)
4. Enable Google Analytics (recommended) → Click Continue
5. Choose Analytics account or create new → Click Create Project
6. Wait for project creation (30-60 seconds)

## Step 2: Add Web App to Firebase Project

1. In Firebase Console, click the **Web icon** (`</>`) to add a web app
2. Register app:
   - **App nickname**: "RIVL Web App"
   - ✅ Check **"Also set up Firebase Hosting"**
   - Click **Register app**
3. **IMPORTANT**: Copy the Firebase configuration that appears
4. Click **Continue to console**

## Step 3: Get Your Firebase Configuration

You'll see something like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "rivl-fitness.firebaseapp.com",
  projectId: "rivl-fitness",
  storageBucket: "rivl-fitness.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef1234567890",
  measurementId: "G-XXXXXXXXXX"
};
```

**Save this!** You'll need it in the next steps.

## Step 4: Update Your Flutter App

1. Open the file `/lib/firebase_options.dart` in your project
2. Replace the placeholder values with your actual Firebase config
3. The file should already be set up - just update the values

## Step 5: Enable Authentication Methods

1. In Firebase Console, go to **Build** → **Authentication**
2. Click **Get started**
3. Go to **Sign-in method** tab
4. Enable these providers:

### Email/Password (Required)
- Click **Email/Password**
- Toggle **Enable** to ON
- Click **Save**

### Google Sign-In (Recommended)
- Click **Google**
- Toggle **Enable** to ON
- Enter support email
- Click **Save**

### Apple Sign-In (Optional for iOS)
- Click **Apple**
- Toggle **Enable** to ON
- Follow Apple setup instructions
- Click **Save**

## Step 6: Set Up Firestore Database

1. In Firebase Console, go to **Build** → **Firestore Database**
2. Click **Create database**
3. Choose mode:
   - **Test mode** for development/beta (open access, auto-expires in 30 days)
   - **Production mode** for launch (use the security rules we provide)
4. Choose location: **us-central** or closest to your users
5. Click **Enable**

## Step 7: Apply Security Rules

1. Go to **Firestore Database** → **Rules** tab
2. Replace the default rules with the rules from `/firestore.rules` file in your project
3. Click **Publish**

## Step 8: Enable Firebase Cloud Messaging (for notifications)

1. In Firebase Console, go to **Build** → **Cloud Messaging**
2. If prompted, click **Get started**
3. No additional configuration needed for web

## Step 9: Set Up Firebase Cloud Functions

1. In Firebase Console, go to **Build** → **Functions**
2. Click **Get started**
3. Upgrade to Blaze (pay-as-you-go) plan:
   - Required for external API calls (Stripe)
   - Free tier: 2M invocations/month
   - Very affordable for beta testing

## Step 10: Configure Stripe Extension (Alternative to Custom Functions)

**Option A: Use Stripe Extension (Easier)**
1. In Firebase Console, go to **Extensions**
2. Search for **"Run Payments with Stripe"**
3. Click **Install**
4. Follow setup wizard with your Stripe keys

**Option B: Custom Cloud Functions (More Control)**
- We'll set this up separately with the Cloud Functions code

## Step 11: Set Up Environment Variables

For Cloud Functions, you'll need to set Stripe secret key:

```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_SECRET_KEY_HERE"
```

## Verification Checklist

Before moving forward, verify:

- ✅ Firebase project created
- ✅ Web app added to project
- ✅ Firebase config copied
- ✅ `/lib/firebase_options.dart` updated with real values
- ✅ Email/Password authentication enabled
- ✅ Firestore database created
- ✅ Security rules applied
- ✅ Firebase upgraded to Blaze plan (for Cloud Functions)
- ✅ Stripe keys configured

## Next Steps

1. Update your app code with the new Firebase config
2. Deploy Cloud Functions (see CLOUD_FUNCTIONS_SETUP.md)
3. Test authentication flow
4. Test Firestore read/write
5. Rebuild and deploy your app

## Need Help?

If you encounter issues:
- Check Firebase Console → **Project settings** for your config
- Verify billing is enabled for Cloud Functions
- Check Firestore rules are published
- Ensure authentication methods are enabled

---

**Important Files to Update:**
- `/lib/firebase_options.dart` - Your Firebase config
- `/firestore.rules` - Database security rules
- `/functions/` - Cloud Functions code

Continue to the next guide: **CLOUD_FUNCTIONS_SETUP.md**
