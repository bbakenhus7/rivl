# 🚀 RIVL Beta Testing Checklist

Complete these steps before launching your beta test.

---

## ✅ Phase 1: Essential Setup (REQUIRED)

### 1. Firebase Configuration ⚠️ **CRITICAL**

**Current Status**: Using stub/fake credentials

**What to do**:
1. Create a Firebase project at https://console.firebase.google.com
2. Click "Add app" → Web app
3. Register your app with name "RIVL"
4. Copy the Firebase configuration
5. Replace `/lib/firebase_options_stub.dart` with real credentials:

```dart
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR-ACTUAL-API-KEY',
    authDomain: 'your-project.firebaseapp.com',
    projectId: 'your-project-id',
    storageBucket: 'your-project.appspot.com',
    messagingSenderId: 'YOUR-MESSAGING-ID',
    appId: 'YOUR-APP-ID',
    measurementId: 'YOUR-MEASUREMENT-ID',
  );
}
```

6. **Enable Authentication**:
   - Go to Firebase Console → Authentication → Sign-in method
   - Enable: Email/Password ✓
   - Enable: Google (optional) ✓
   - Enable: Apple (optional) ✓

7. **Set up Firestore Database**:
   - Go to Firestore Database → Create database
   - Start in **test mode** for beta (or production mode with rules below)
   - Location: Choose closest to your users

8. **Security Rules** (Important!):
   - Go to Firestore → Rules
   - Add these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // Challenges - participants can read/write
    match /challenges/{challengeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid in resource.data.participantIds;
    }
  }
}
```

9. **Rebuild and redeploy**:
```bash
flutter build web --base-href /rivl/
cp -r build/web/* docs/
git add docs/
git commit -m "Update Firebase configuration for production"
git push
```

---

### 2. Stripe Payment Configuration ⚠️ **CRITICAL**

**Current Status**: Using fake test key

**What to do**:
1. Create account at https://dashboard.stripe.com/register
2. Complete account verification
3. Get your **Publishable Key** (starts with `pk_test_...` for testing)
4. Update `/lib/main.dart` line 32:

```dart
Stripe.publishableKey = 'pk_test_YOUR_ACTUAL_PUBLISHABLE_KEY';
```

5. **Set up products** (for challenge stakes):
   - In Stripe Dashboard → Products
   - Create products for: $5, $10, $15, $20, $25, $50 stakes
   - Note the price IDs

6. **Important**: For beta, use **test mode** keys only!
   - Test keys start with `pk_test_...`
   - Real keys start with `pk_live_...`

7. **Rebuild and redeploy** after updating

---

### 3. Health Data Limitations ⚠️ **IMPORTANT**

**Issue**: The app uses the `health` package which **only works on mobile (iOS/Android)**, not on web.

**Your options**:

**Option A: Web Beta with Mock Data**
- Beta testers will see placeholder step counts
- Good for testing UI/UX, challenges, payments
- Not good for real fitness competition

**Option B: Build Mobile Apps**
- Build iOS and Android apps using Flutter
- Use TestFlight (iOS) or Google Play Beta (Android)
- Full functionality including step tracking
- Recommended for real beta test

**To build mobile apps**:
```bash
# iOS (requires Mac with Xcode)
flutter build ios
# Then upload to TestFlight via Xcode

# Android
flutter build apk --release
# Upload to Google Play Console for beta testing
```

---

## ✅ Phase 2: Legal & Compliance

### 4. Privacy Policy & Terms of Service ⚠️ **LEGALLY REQUIRED**

You're collecting personal data and processing payments. You **must** have:

**What to create**:
1. **Privacy Policy** covering:
   - Data collection (email, name, step data, payment info)
   - How data is used
   - Third-party services (Firebase, Stripe, HealthKit/Health Connect)
   - User rights (GDPR/CCPA compliance)
   - Data retention and deletion

2. **Terms of Service** covering:
   - Challenge rules and disputes
   - Payment terms and refunds
   - User conduct
   - Liability limitations
   - Age requirements (18+ or with parental consent)

**Tools to help**:
- Termly.io (free generator)
- iubenda.com (paid, more comprehensive)
- Hire a lawyer (recommended for real launch)

**Add to app**:
1. Create pages in `/lib/screens/legal/`
2. Link from login/signup screens
3. Require acceptance before account creation

---

## ✅ Phase 3: Features & Testing

### 5. Test All Core Features

**Authentication**:
- [ ] Sign up with email/password
- [ ] Sign in with email/password
- [ ] Sign in with Google
- [ ] Sign in with Apple
- [ ] Password reset
- [ ] Email verification (optional but recommended)

**User Profile**:
- [ ] View profile
- [ ] Edit profile
- [ ] Upload profile picture (not implemented yet)
- [ ] View stats (wins, losses, earnings)
- [ ] Referral code generation and sharing

**Challenges**:
- [ ] Create challenge
- [ ] Send challenge invite
- [ ] Accept challenge
- [ ] Decline challenge
- [ ] View active challenges
- [ ] View challenge details
- [ ] Complete challenge
- [ ] Dispute handling

**Payments**:
- [ ] Connect Stripe for challenge stakes
- [ ] Process payment for joining challenge
- [ ] Receive winnings
- [ ] View transaction history

**Leaderboard**:
- [ ] View global leaderboard
- [ ] Sort by wins/earnings
- [ ] View other user profiles

### 6. Missing Features to Implement

**Critical for Beta**:
- [ ] **Email verification** (prevent fake accounts)
- [ ] **Payment processing** (Stripe integration needs backend)
- [ ] **Dispute resolution system**
- [ ] **Step verification** (anti-cheat)
- [ ] **Notifications** (challenge invites, results)

**Nice to Have**:
- [ ] Profile pictures
- [ ] In-app messaging
- [ ] Push notifications
- [ ] Social sharing
- [ ] Activity feed

---

## ✅ Phase 4: Backend Setup

### 7. Cloud Functions (Recommended)

Your app needs backend logic for:
- Processing payments
- Verifying step data
- Calculating winners
- Handling disputes
- Sending notifications

**Set up Firebase Cloud Functions**:
```bash
npm install -g firebase-tools
firebase init functions
```

**Key functions needed**:
- `createChallenge` - Handle payment and create challenge
- `completeChallenge` - Determine winner and distribute funds
- `verifySteps` - Anti-cheat validation
- `handleDispute` - Dispute resolution

---

## ✅ Phase 5: Testing & Launch Prep

### 8. Testing Checklist

**Before Beta**:
- [ ] Test on multiple browsers (Chrome, Safari, Firefox, Edge)
- [ ] Test on mobile browsers
- [ ] Test all user flows end-to-end
- [ ] Test with real test payments (Stripe test mode)
- [ ] Test error handling (bad inputs, network errors)
- [ ] Load test with multiple users
- [ ] Security test (SQL injection, XSS, auth bypass)

### 9. Beta Testing Plan

**Prepare**:
- [ ] Create beta tester signup form
- [ ] Prepare onboarding email/guide
- [ ] Set up feedback collection (Google Forms, Typeform)
- [ ] Create beta testing Discord/Slack for support
- [ ] Define success metrics (user engagement, challenges created, etc.)

**Beta Group Size**:
- Start small: 10-20 users
- Expand gradually: 50-100 users
- Monitor closely for issues

**Duration**:
- Minimum 2-4 weeks
- Fix critical bugs quickly
- Gather feedback continuously

---

## ✅ Phase 6: Monitoring & Analytics

### 10. Set Up Monitoring

**Firebase Analytics** (already integrated):
- Track user signups
- Track challenge creation
- Track payment conversion
- Track retention

**Error Tracking**:
- Set up Sentry or Firebase Crashlytics
- Monitor for runtime errors
- Track API failures

**Performance**:
- Monitor page load times
- Track API response times
- Monitor Firestore read/write costs

---

## 🚨 Critical Blockers for Beta

These **MUST** be done before any beta testing:

1. ✅ Real Firebase setup (not stub)
2. ✅ Real Stripe setup (test mode)
3. ✅ Privacy Policy & Terms
4. ✅ Security rules in Firestore
5. ✅ Backend for payment processing
6. ✅ Decision: Web-only (mock data) or Mobile apps (real steps)

---

## 📋 Quick Start Guide (Minimum Viable Beta)

If you want to launch quickly with minimal features:

**Week 1: Setup**
- [ ] Firebase setup with real credentials
- [ ] Firestore security rules
- [ ] Privacy policy & terms (use generator)
- [ ] Test authentication flows

**Week 2: Backend**
- [ ] Set up Cloud Functions for payment processing
- [ ] Implement basic challenge flow
- [ ] Test end-to-end with test payments

**Week 3: Testing**
- [ ] Internal testing with 3-5 people
- [ ] Fix critical bugs
- [ ] Prepare beta tester documentation

**Week 4: Launch Beta**
- [ ] Invite 10-20 beta testers
- [ ] Monitor closely
- [ ] Gather feedback
- [ ] Iterate quickly

---

## 💡 Recommendations

**For Web Beta**:
- Focus on UI/UX feedback
- Use mock step data or manual entry
- Test payment flows thoroughly
- Build mobile apps for "real" beta

**For Mobile Beta**:
- Build iOS and Android apps
- Use TestFlight and Google Play Beta
- Real step tracking via HealthKit/Health Connect
- More complex but better testing

**My Suggestion**:
Start with **web beta** to test core features and UI, then build **mobile apps** for real fitness competition testing.

---

## Need Help?

Stuck on any of these steps? Let me know and I can help you implement:
- Firebase setup
- Stripe integration
- Cloud Functions
- Mobile app builds
- Security rules
- Or anything else!

Good luck with your beta! 🚀
