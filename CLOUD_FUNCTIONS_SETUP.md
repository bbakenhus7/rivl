# Cloud Functions Setup Guide

This guide walks you through deploying Cloud Functions for RIVL.

## Prerequisites

Before starting, make sure you have:
- ✅ Completed Firebase setup (see FIREBASE_SETUP_GUIDE.md)
- ✅ Firebase project on Blaze (pay-as-you-go) plan
- ✅ Node.js 18+ installed
- ✅ Stripe account with API keys

## Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

## Step 2: Login to Firebase

```bash
firebase login
```

This will open a browser window for authentication.

## Step 3: Initialize Firebase in Your Project

Navigate to your project directory:

```bash
cd /path/to/rivl
firebase init
```

Select the following options:
- **Features**: Functions, Firestore, Hosting
- **Project**: Select your existing Firebase project
- **Language**: TypeScript
- **TSLint**: No
- **Install dependencies**: Yes

## Step 4: Install Dependencies

```bash
cd functions
npm install
```

This installs:
- `firebase-functions` - Cloud Functions SDK
- `firebase-admin` - Firebase Admin SDK
- `stripe` - Stripe payment processing
- TypeScript and dev dependencies

## Step 5: Configure Stripe Keys

### Get Your Stripe Keys

1. Go to https://dashboard.stripe.com/apikeys
2. Copy your **Secret key** (starts with `sk_test_...` for test mode)
3. Go to https://dashboard.stripe.com/webhooks
4. Click "Add endpoint"
5. URL: `https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/stripeWebhook`
6. Events to listen for:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
7. Copy the **Signing secret** (starts with `whsec_...`)

### Set Environment Variables

```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_SECRET_KEY"
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
```

### Verify Configuration

```bash
firebase functions:config:get
```

You should see:
```json
{
  "stripe": {
    "secret_key": "sk_test_...",
    "webhook_secret": "whsec_..."
  }
}
```

## Step 6: Test Functions Locally (Optional but Recommended)

### Start Firebase Emulators

```bash
cd functions
npm run serve
```

This starts local emulators for:
- Functions: http://localhost:5001
- Firestore: http://localhost:8080

### Test a Function

```bash
# In another terminal
curl -X POST \
  http://localhost:5001/YOUR_PROJECT_ID/us-central1/createChallenge \
  -H 'Content-Type: application/json' \
  -d '{
    "data": {
      "opponentId": "test-user-id",
      "stakeAmount": 10,
      "goalType": "total_steps",
      "duration": "1week"
    }
  }'
```

## Step 7: Deploy Cloud Functions

### Deploy All Functions

```bash
firebase deploy --only functions
```

This takes 2-5 minutes for first deployment.

### Deploy Specific Function

```bash
firebase deploy --only functions:createChallenge
```

### Verify Deployment

After deployment, you'll see URLs like:
```
✔  functions[createChallenge(us-central1)] ... deployed
✔  functions[acceptChallenge(us-central1)] ... deployed
✔  functions[stripeWebhook(us-central1)] ... deployed
...
```

## Step 8: Configure Stripe Webhook

1. Go back to https://dashboard.stripe.com/webhooks
2. Update your webhook endpoint URL to the deployed function:
   ```
   https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/stripeWebhook
   ```
3. Test the webhook by sending a test event

## Step 9: Deploy Firestore Security Rules

```bash
firebase deploy --only firestore:rules
```

## Step 10: Set Up Scheduled Functions

The function `completeChallengeScheduled` runs every hour automatically. No additional setup needed!

## Functions Overview

Your deployed functions:

### Callable Functions (Called from App)

1. **createChallenge**
   - Creates new challenge
   - Creates Stripe Payment Intent
   - Returns client secret for payment

2. **acceptChallenge**
   - Accepts pending challenge
   - Creates opponent's Payment Intent
   - Starts challenge when both paid

3. **manualCompleteChallenge** (for testing)
   - Manually complete a challenge
   - Useful during development

### HTTP Functions

4. **stripeWebhook**
   - Handles Stripe payment confirmations
   - Updates challenge payment status
   - Starts challenge when both participants paid

### Scheduled Functions

5. **completeChallengeScheduled**
   - Runs every hour
   - Finds ended challenges
   - Determines winners
   - Distributes funds

### Triggered Functions

6. **trackReferral**
   - Triggers on new user creation
   - Credits referrer with bonus
   - Updates referral stats

7. **verifySteps**
   - Triggers on step submission
   - Anti-cheat validation
   - Flags suspicious activity

## Monitoring & Logs

### View Logs

```bash
firebase functions:log
```

### View Specific Function Logs

```bash
firebase functions:log --only createChallenge
```

### Real-time Logs

```bash
firebase functions:log --follow
```

### Firebase Console

Go to: https://console.firebase.google.com
- Functions → Dashboard (see invocations, errors, execution time)
- Functions → Logs (detailed logs with filters)
- Functions → Health (performance metrics)

## Testing Your Functions

### Test Payment Flow

1. Create a test challenge from your app
2. Use Stripe test cards:
   - Success: `4242 4242 4242 4242`
   - Declined: `4000 0000 0000 0002`
   - Requires 3D Secure: `4000 0025 0000 3155`
3. Check Firebase Console logs for function execution
4. Verify challenge status updates in Firestore

### Test Challenge Completion

1. Create a challenge with very short duration (modify code for testing)
2. Add step data for both participants
3. Wait for scheduled function to run (or call `manualCompleteChallenge`)
4. Verify winner determination and fund distribution

## Cost Estimates

Firebase Functions pricing (Blaze plan):

**Free Tier (per month):**
- 2M invocations
- 400,000 GB-sec compute time
- 200,000 GHz-sec CPU time
- 5GB outbound networking

**After Free Tier:**
- $0.40 per million invocations
- $0.0000025 per GB-sec
- $0.0000100 per GHz-sec

**Example Beta Testing (100 users, 500 challenges/month):**
- ~10,000 function invocations
- **Cost: $0** (within free tier)

**Example Production (10,000 users, 50,000 challenges/month):**
- ~1M function invocations
- **Estimated cost: $20-50/month**

Stripe charges 2.9% + $0.30 per transaction.

## Troubleshooting

### "Billing account not configured"
- Upgrade to Blaze plan in Firebase Console
- Go to: Usage and billing → Details & settings → Modify plan

### "Permission denied" errors
- Check Firestore security rules
- Verify authentication is working
- Check function auth context

### "Stripe API key invalid"
- Verify keys are set correctly:
  ```bash
  firebase functions:config:get
  ```
- Make sure you're using the SECRET key (sk_...), not publishable key
- Re-deploy after changing config:
  ```bash
  firebase deploy --only functions
  ```

### Webhook not receiving events
- Check webhook URL matches deployed function URL
- Verify webhook secret is correct
- Check Stripe Dashboard → Webhooks → Your endpoint → Recent deliveries

### Functions timing out
- Increase timeout (max 9 minutes):
  ```typescript
  export const myFunction = functions
    .runWith({ timeoutSeconds: 300 })
    .https.onCall(...)
  ```

## Security Best Practices

1. **Never commit secrets to git**
   - Use `firebase functions:config:set`
   - Or environment variables in production

2. **Validate all inputs**
   - Check amounts, user IDs, etc.
   - The provided code includes validation

3. **Use HTTPS only**
   - Cloud Functions are HTTPS by default

4. **Implement rate limiting**
   - Consider adding rate limits for expensive operations

5. **Monitor for abuse**
   - Check logs regularly
   - Set up alerts for errors/suspicious activity

## Next Steps

After deploying Cloud Functions:

1. ✅ Test payment flow end-to-end
2. ✅ Test challenge creation and completion
3. ✅ Verify notifications are sent
4. ✅ Check leaderboard updates
5. ✅ Monitor function execution in Firebase Console
6. ✅ Set up error alerts
7. ✅ Test referral system

## Production Checklist

Before going live:

- [ ] Switch Stripe to live mode (pk_live_... and sk_live_...)
- [ ] Update webhook to use live mode
- [ ] Set up monitoring and alerts
- [ ] Test all edge cases
- [ ] Implement proper error handling for failed payments
- [ ] Set up payout system for winners
- [ ] Add admin functions for dispute resolution
- [ ] Configure backup and disaster recovery

---

**You're now ready to handle payments and challenge logic in the cloud!**

Need help? Check Firebase Functions documentation:
https://firebase.google.com/docs/functions
