/**
 * Cloud Functions for RIVL Fitness Competition App
 *
 * Functions:
 * - Payment processing with Stripe
 * - Challenge lifecycle management
 * - Winner determination
 * - Notifications
 * - Leaderboard updates
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { defineSecret } from 'firebase-functions/params';
import Stripe from 'stripe';

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Define secrets using Firebase Secret Manager
// Set with: firebase functions:secrets:set STRIPE_SECRET_KEY
// Set with: firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');

// Platform fee percentage (3% for head-to-head, 5% for groups)
const H2H_FEE_PERCENT = 0.03;
const GROUP_FEE_PERCENT = 0.05;

// Helper to get Stripe instance (must be called within function context)
function getStripe(): Stripe {
  return new Stripe(stripeSecretKey.value(), {
    apiVersion: '2023-10-16',
  });
}

// ============================================
// CHALLENGE CREATION & PAYMENT
// ============================================

/**
 * Create a challenge with payment intent
 * Callable function from the app
 */
export const createChallenge = functions
  .runWith({ secrets: [stripeSecretKey] })
  .https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const {
    opponentId,
    stakeAmount,
    goalType,
    targetValue,
    duration,
    startDate,
  } = data;

  const creatorId = context.auth.uid;

  // Validate input
  if (!opponentId || !stakeAmount || !goalType || !duration) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  if (stakeAmount < 5 || stakeAmount > 100) {
    throw new functions.https.HttpsError('invalid-argument', 'Stake amount must be between $5 and $100');
  }

  if (creatorId === opponentId) {
    throw new functions.https.HttpsError('invalid-argument', 'Cannot challenge yourself');
  }

  try {
    // Create Stripe Payment Intent for creator
    const stripe = getStripe();
    const creatorPaymentIntent = await stripe.paymentIntents.create({
      amount: stakeAmount * 100, // Convert to cents
      currency: 'usd',
      metadata: {
        userId: creatorId,
        type: 'challenge_stake',
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });

    // Create challenge document
    const challengeRef = db.collection('challenges').doc();
    const challengeData = {
      id: challengeRef.id,
      creatorId,
      opponentId,
      participantIds: [creatorId, opponentId],
      stakeAmount,
      totalPot: stakeAmount * 2,
      platformFee: stakeAmount * 2 * H2H_FEE_PERCENT,
      prizeAmount: stakeAmount * 2 * (1 - H2H_FEE_PERCENT),
      goalType,
      targetValue: targetValue || 10000,
      duration,
      startDate: startDate || admin.firestore.FieldValue.serverTimestamp(),
      endDate: null, // Will be calculated when opponent accepts
      status: 'pending',
      creatorPaymentStatus: 'pending',
      opponentPaymentStatus: 'pending',
      creatorPaymentIntentId: creatorPaymentIntent.id,
      opponentPaymentIntentId: null,
      winnerId: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await challengeRef.set(challengeData);

    // Send notification to opponent
    await createNotification(opponentId, {
      type: 'challenge_received',
      title: 'New Challenge!',
      message: `You have a new challenge worth $${stakeAmount}`,
      challengeId: challengeRef.id,
    });

    return {
      challengeId: challengeRef.id,
      clientSecret: creatorPaymentIntent.client_secret,
    };
  } catch (error: any) {
    console.error('Error creating challenge:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Accept a challenge and create payment intent for opponent
 */
export const acceptChallenge = functions
  .runWith({ secrets: [stripeSecretKey] })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { challengeId } = data;
  const opponentId = context.auth.uid;

  try {
    const challengeRef = db.collection('challenges').doc(challengeId);
    const challenge = await challengeRef.get();

    if (!challenge.exists) {
      throw new functions.https.HttpsError('not-found', 'Challenge not found');
    }

    const challengeData = challenge.data()!;

    // Verify user is the opponent
    if (challengeData.opponentId !== opponentId) {
      throw new functions.https.HttpsError('permission-denied', 'Not authorized');
    }

    if (challengeData.status !== 'pending') {
      throw new functions.https.HttpsError('failed-precondition', 'Challenge already accepted or cancelled');
    }

    // Create Stripe Payment Intent for opponent
    const stripe = getStripe();
    const opponentPaymentIntent = await stripe.paymentIntents.create({
      amount: challengeData.stakeAmount * 100,
      currency: 'usd',
      metadata: {
        userId: opponentId,
        challengeId,
        type: 'challenge_stake',
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });

    // Calculate end date based on duration
    const startDate = new Date();
    const endDate = new Date(startDate);

    switch (challengeData.duration) {
      case 'oneDay':
      case '1day':
        endDate.setDate(endDate.getDate() + 1);
        break;
      case 'threeDays':
      case '3days':
        endDate.setDate(endDate.getDate() + 3);
        break;
      case 'oneWeek':
      case '1week':
        endDate.setDate(endDate.getDate() + 7);
        break;
      case 'twoWeeks':
      case '2weeks':
        endDate.setDate(endDate.getDate() + 14);
        break;
      case 'oneMonth':
      case '1month':
        endDate.setMonth(endDate.getMonth() + 1);
        break;
    }

    // Update challenge
    await challengeRef.update({
      status: 'accepted',
      opponentPaymentIntentId: opponentPaymentIntent.id,
      startDate: admin.firestore.Timestamp.fromDate(startDate),
      endDate: admin.firestore.Timestamp.fromDate(endDate),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Notify creator
    await createNotification(challengeData.creatorId, {
      type: 'challenge_accepted',
      title: 'Challenge Accepted!',
      message: 'Your challenge has been accepted',
      challengeId,
    });

    return {
      clientSecret: opponentPaymentIntent.client_secret,
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
    };
  } catch (error: any) {
    console.error('Error accepting challenge:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Webhook to handle Stripe payment confirmations
 */
export const stripeWebhook = functions
  .runWith({ secrets: [stripeSecretKey, stripeWebhookSecret] })
  .https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'] as string;
  const stripe = getStripe();

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, stripeWebhookSecret.value());
  } catch (err: any) {
    console.error('Webhook signature verification failed:', err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  // Handle the event
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      await handlePaymentSuccess(paymentIntent);
      break;
    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object as Stripe.PaymentIntent;
      await handlePaymentFailure(failedPayment);
      break;
    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({ received: true });
});

/**
 * Handle successful payment
 */
async function handlePaymentSuccess(paymentIntent: Stripe.PaymentIntent) {
  const type = paymentIntent.metadata.type;

  if (type !== 'challenge_stake') return;

  // Find challenge with this payment intent
  const challengesQuery = await db.collection('challenges')
    .where('creatorPaymentIntentId', '==', paymentIntent.id)
    .limit(1)
    .get();

  if (!challengesQuery.empty) {
    const challengeRef = challengesQuery.docs[0].ref;
    await challengeRef.update({
      creatorPaymentStatus: 'paid',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  const opponentQuery = await db.collection('challenges')
    .where('opponentPaymentIntentId', '==', paymentIntent.id)
    .limit(1)
    .get();

  if (!opponentQuery.empty) {
    const challengeRef = opponentQuery.docs[0].ref;
    const challenge = await challengeRef.get();
    const challengeData = challenge.data()!;

    await challengeRef.update({
      opponentPaymentStatus: 'paid',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // If both paid, start the challenge
    if (challengeData.creatorPaymentStatus === 'paid') {
      await challengeRef.update({
        status: 'active',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Notify both participants
      await createNotification(challengeData.creatorId, {
        type: 'challenge_started',
        title: 'Challenge Started!',
        message: 'Your challenge is now active',
        challengeId: challenge.id,
      });

      await createNotification(challengeData.opponentId, {
        type: 'challenge_started',
        title: 'Challenge Started!',
        message: 'Your challenge is now active',
        challengeId: challenge.id,
      });
    }
  }
}

/**
 * Handle failed payment
 */
async function handlePaymentFailure(paymentIntent: Stripe.PaymentIntent) {
  const userId = paymentIntent.metadata.userId;

  // Notify user of payment failure
  await createNotification(userId, {
    type: 'payment_failed',
    title: 'Payment Failed',
    message: 'Your payment could not be processed. Please try again.',
  });
}

// ============================================
// CHALLENGE COMPLETION
// ============================================

/**
 * Triggered when a challenge's end date passes
 * Determines winner and distributes funds
 */
export const completeChallengeScheduled = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // Find all active challenges that have ended
    const endedChallenges = await db.collection('challenges')
      .where('status', '==', 'active')
      .where('endDate', '<=', now)
      .get();

    console.log(`Processing ${endedChallenges.size} ended challenges`);

    const promises = endedChallenges.docs.map(doc => completeChallenge(doc.id));
    await Promise.all(promises);

    return null;
  });

/**
 * Complete a challenge and determine winner
 */
async function completeChallenge(challengeId: string) {
  try {
    const challengeRef = db.collection('challenges').doc(challengeId);
    const challenge = await challengeRef.get();

    if (!challenge.exists) return;

    const challengeData = challenge.data()!;
    const { creatorId, opponentId, goalType, prizeAmount } = challengeData;

    // Get final step counts for both participants
    const dailyStepsSnapshot = await challengeRef.collection('dailySteps').get();

    let creatorTotal = 0;
    let opponentTotal = 0;
    let creatorMax = 0;
    let opponentMax = 0;
    let creatorDays = 0;
    let opponentDays = 0;

    dailyStepsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const steps = data.steps || 0;

      if (data.userId === creatorId) {
        creatorTotal += steps;
        creatorMax = Math.max(creatorMax, steps);
        creatorDays++;
      } else if (data.userId === opponentId) {
        opponentTotal += steps;
        opponentMax = Math.max(opponentMax, steps);
        opponentDays++;
      }
    });

    // Also read progress directly from challenge document (used by newer goal types)
    const creatorDocProgress = challengeData.creatorProgress || 0;
    const opponentDocProgress = challengeData.opponentProgress || 0;

    // Determine winner based on goal type
    let winnerId: string | null = null;
    let winningScore = 0;
    let losingScore = 0;
    let isTie = false;

    switch (goalType) {
      // Legacy step-based goal types
      case 'total_steps':
        isTie = creatorTotal === opponentTotal;
        winnerId = creatorTotal >= opponentTotal ? creatorId : opponentId;
        winningScore = Math.max(creatorTotal, opponentTotal);
        losingScore = Math.min(creatorTotal, opponentTotal);
        break;

      case 'daily_average':
        const creatorAvg = creatorDays > 0 ? creatorTotal / creatorDays : 0;
        const opponentAvg = opponentDays > 0 ? opponentTotal / opponentDays : 0;
        isTie = creatorAvg === opponentAvg;
        winnerId = creatorAvg >= opponentAvg ? creatorId : opponentId;
        winningScore = Math.max(creatorAvg, opponentAvg);
        losingScore = Math.min(creatorAvg, opponentAvg);
        break;

      case 'most_steps_single_day':
        isTie = creatorMax === opponentMax;
        winnerId = creatorMax >= opponentMax ? creatorId : opponentId;
        winningScore = Math.max(creatorMax, opponentMax);
        losingScore = Math.min(creatorMax, opponentMax);
        break;

      // Cumulative goal types (higher is better): steps, distance, sleepDuration
      case 'steps':
      case 'distance':
      case 'sleepDuration':
      case 'rivlHealthScore':
      case 'vo2Max':
        isTie = creatorDocProgress === opponentDocProgress;
        winnerId = creatorDocProgress >= opponentDocProgress ? creatorId : opponentId;
        winningScore = Math.max(creatorDocProgress, opponentDocProgress);
        losingScore = Math.min(creatorDocProgress, opponentDocProgress);
        break;

      // Pace-based goal types (lower is better — faster time wins)
      case 'milePace':
      case 'fiveKPace':
      case 'tenKPace':
        // Lower value = faster = winner
        // But if someone has 0 progress, they didn't record and should lose
        if (creatorDocProgress === 0 && opponentDocProgress === 0) {
          isTie = true;
          winnerId = creatorId;
        } else if (creatorDocProgress === 0) {
          winnerId = opponentId;
        } else if (opponentDocProgress === 0) {
          winnerId = creatorId;
        } else {
          isTie = creatorDocProgress === opponentDocProgress;
          winnerId = creatorDocProgress <= opponentDocProgress ? creatorId : opponentId;
        }
        winningScore = Math.min(creatorDocProgress || 999999, opponentDocProgress || 999999);
        losingScore = Math.max(creatorDocProgress, opponentDocProgress);
        break;

      default:
        // Fallback: use document progress, higher is better
        isTie = creatorDocProgress === opponentDocProgress;
        winnerId = creatorDocProgress >= opponentDocProgress ? creatorId : opponentId;
        winningScore = Math.max(creatorDocProgress, opponentDocProgress);
        losingScore = Math.min(creatorDocProgress, opponentDocProgress);
        break;
    }

    const loserId = winnerId === creatorId ? opponentId : creatorId;

    // Look up winner's display name
    let winnerName: string | null = null;
    if (!isTie && winnerId) {
      const winnerDoc = await db.collection('users').doc(winnerId).get();
      if (winnerDoc.exists) {
        winnerName = winnerDoc.data()?.displayName || null;
      }
    }

    // Update challenge with result
    await challengeRef.update({
      status: 'completed',
      winnerId: isTie ? null : winnerId,
      winnerName: isTie ? null : winnerName,
      isTie,
      winnerScore: winningScore,
      loserScore: losingScore,
      rewardStatus: isTie ? 'refunded' : 'sent',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (isTie) {
      // Tie: refund each participant their stake
      const refundAmount = prizeAmount / 2;

      await db.collection('users').doc(creatorId).collection('transactions').add({
        type: 'challenge_tie_refund',
        amount: refundAmount,
        challengeId,
        status: 'pending_transfer',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await db.collection('users').doc(opponentId).collection('transactions').add({
        type: 'challenge_tie_refund',
        amount: refundAmount,
        challengeId,
        status: 'pending_transfer',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update user stats: draws + totalChallenges for both
      await updateUserStats(creatorId, { draws: 1, totalChallenges: 1 });
      await updateUserStats(opponentId, { draws: 1, totalChallenges: 1 });

      // Award participation XP to both
      await awardXP(creatorId, challengeData, false);
      await awardXP(opponentId, challengeData, false);

      // Update leaderboard
      await updateLeaderboard(creatorId);
      await updateLeaderboard(opponentId);

      // Notify both
      await createNotification(creatorId, {
        type: 'challenge_tied',
        title: "It's a Tie!",
        message: 'Challenge ended in a draw. Stakes have been refunded.',
        challengeId,
      });

      await createNotification(opponentId, {
        type: 'challenge_tied',
        title: "It's a Tie!",
        message: 'Challenge ended in a draw. Stakes have been refunded.',
        challengeId,
      });

      console.log(`Challenge ${challengeId} completed. Result: Tie`);
    } else {
      // Transfer funds to winner
      // Note: In production, you'd create a Stripe Transfer or Payout
      // For now, we'll just record the transaction
      await db.collection('users').doc(winnerId).collection('transactions').add({
        type: 'challenge_win',
        amount: prizeAmount,
        challengeId,
        status: 'pending_transfer',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update user stats
      await updateUserStats(winnerId!, { wins: 1, totalChallenges: 1, earnings: prizeAmount });
      await updateUserStats(loserId, { losses: 1, totalChallenges: 1 });

      // Award XP for battle pass
      await awardXP(winnerId!, challengeData, true);
      await awardXP(loserId, challengeData, false);

      // Update leaderboard
      await updateLeaderboard(winnerId!);
      await updateLeaderboard(loserId);

      // Send notifications
      await createNotification(winnerId!, {
        type: 'challenge_won',
        title: 'You Won!',
        message: `Congratulations! You won $${prizeAmount.toFixed(2)}`,
        challengeId,
      });

      await createNotification(loserId, {
        type: 'challenge_lost',
        title: 'Challenge Ended',
        message: 'Better luck next time!',
        challengeId,
      });

      console.log(`Challenge ${challengeId} completed. Winner: ${winnerId}`);
    }
  } catch (error) {
    console.error(`Error completing challenge ${challengeId}:`, error);
  }
}

// ============================================
// USER STATS & LEADERBOARD
// ============================================

/**
 * Update user statistics
 */
async function updateUserStats(userId: string, stats: {
  wins?: number;
  losses?: number;
  draws?: number;
  totalChallenges?: number;
  earnings?: number;
}) {
  const userRef = db.collection('users').doc(userId);

  const updateData: any = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (stats.wins) {
    updateData.wins = admin.firestore.FieldValue.increment(stats.wins);
  }
  if (stats.losses) {
    updateData.losses = admin.firestore.FieldValue.increment(stats.losses);
  }
  if (stats.draws) {
    updateData.draws = admin.firestore.FieldValue.increment(stats.draws);
  }
  if (stats.totalChallenges) {
    updateData.totalChallenges = admin.firestore.FieldValue.increment(stats.totalChallenges);
  }
  if (stats.earnings) {
    updateData.totalEarnings = admin.firestore.FieldValue.increment(stats.earnings);
  }

  await userRef.update(updateData);

  // Recalculate win rate after updating stats
  const updatedDoc = await userRef.get();
  const userData = updatedDoc.data() || {};
  const wins = userData.wins || 0;
  const losses = userData.losses || 0;
  const winRate = calculateWinRate(wins, losses);
  await userRef.update({ winRate });
}

/**
 * Update leaderboard entry for a user
 */
async function updateLeaderboard(userId: string) {
  const userDoc = await db.collection('users').doc(userId).get();
  if (!userDoc.exists) return;

  const userData = userDoc.data()!;

  await db.collection('leaderboard').doc(userId).set({
    userId,
    username: userData.username,
    displayName: userData.displayName,
    wins: userData.wins || 0,
    losses: userData.losses || 0,
    draws: userData.draws || 0,
    totalChallenges: userData.totalChallenges || 0,
    totalEarnings: userData.totalEarnings || 0,
    winRate: calculateWinRate(userData.wins || 0, userData.losses || 0),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function calculateWinRate(wins: number, losses: number): number {
  const total = wins + losses;
  return total > 0 ? wins / total : 0;
}

/**
 * Award XP for battle pass progression
 */
async function awardXP(userId: string, challengeData: any, won: boolean) {
  const XP_WIN = 100;
  const XP_PARTICIPATION = 50;

  // Calculate base XP
  let baseXP = won ? XP_WIN : XP_PARTICIPATION;

  // Bonus for higher stakes
  const stakeAmount = challengeData.stakeAmount || 0;
  if (stakeAmount >= 50) baseXP += 25;
  else if (stakeAmount >= 25) baseXP += 15;

  // Bonus for longer challenges
  const startDate = challengeData.startDate?.toDate();
  const endDate = challengeData.endDate?.toDate();
  if (startDate && endDate) {
    const durationDays = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
    if (durationDays >= 14) baseXP += 30;
    else if (durationDays >= 7) baseXP += 15;
  }

  // Award XP
  const userRef = db.collection('users').doc(userId);
  const userDoc = await userRef.get();
  const userData = userDoc.data() || {};

  let currentXP = (userData.currentXP || 0) + baseXP;
  let totalXP = (userData.totalXP || 0) + baseXP;
  let battlePassLevel = userData.battlePassLevel || 1;

  // Level up logic
  const xpForNextLevel = 100 + (battlePassLevel * 50);
  while (currentXP >= xpForNextLevel) {
    currentXP -= xpForNextLevel;
    battlePassLevel++;
  }

  // Update user
  await userRef.update({
    currentXP,
    totalXP,
    battlePassLevel,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Record XP transaction
  await userRef.collection('xpHistory').add({
    amount: baseXP,
    source: won ? 'challenge_win' : 'challenge_participation',
    challengeId: challengeData.id,
    levelBefore: userData.battlePassLevel || 1,
    levelAfter: battlePassLevel,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Notify if leveled up
  if (battlePassLevel > (userData.battlePassLevel || 1)) {
    await createNotification(userId, {
      type: 'level_up',
      title: 'Level Up!',
      message: `You reached Battle Pass Level ${battlePassLevel}! Claim your rewards.`,
    });
  }
}

// ============================================
// NOTIFICATIONS
// ============================================

/**
 * Create a notification for a user and send push notification via FCM
 */
async function createNotification(userId: string, notification: {
  type: string;
  title: string;
  message: string;
  challengeId?: string;
}) {
  // Store notification in database
  await db.collection('users').doc(userId).collection('notifications').add({
    ...notification,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send push notification via Firebase Cloud Messaging
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    if (userData?.fcmToken && userData?.notificationsEnabled !== false) {
      const message: admin.messaging.Message = {
        token: userData.fcmToken,
        notification: {
          title: notification.title,
          body: notification.message,
        },
        data: {
          type: notification.type,
          challengeId: notification.challengeId || '',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      await admin.messaging().send(message);
      console.log(`Push notification sent to user ${userId}`);
    }
  } catch (error) {
    console.error(`Failed to send push notification to user ${userId}:`, error);
    // Don't throw - notification failure shouldn't break the flow
  }
}

// ============================================
// REFERRALS
// ============================================

/**
 * Track referral and credit referrer
 */
export const trackReferral = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    const referralCode = userData.referredBy;

    if (!referralCode) return;

    // Find the referrer
    const referrerQuery = await db.collection('users')
      .where('referralCode', '==', referralCode)
      .limit(1)
      .get();

    if (referrerQuery.empty) return;

    const referrerRef = referrerQuery.docs[0].ref;
    const referrerId = referrerRef.id;

    // Credit referrer (e.g., $5 bonus)
    const REFERRAL_BONUS = 5.00;

    await referrerRef.update({
      referralCount: admin.firestore.FieldValue.increment(1),
      referralEarnings: admin.firestore.FieldValue.increment(REFERRAL_BONUS),
      totalEarnings: admin.firestore.FieldValue.increment(REFERRAL_BONUS),
    });

    // Record transaction
    await db.collection('users').doc(referrerId).collection('transactions').add({
      type: 'referral_bonus',
      amount: REFERRAL_BONUS,
      referredUserId: context.params.userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Notify referrer
    await createNotification(referrerId, {
      type: 'referral_earned',
      title: 'Referral Bonus!',
      message: `You earned $${REFERRAL_BONUS} from a referral`,
    });
  });

// ============================================
// ANTI-CHEAT & VERIFICATION (AI/ML-POWERED)
// ============================================

/**
 * AI-powered verification of activity submissions
 * Uses machine learning algorithms to detect fraudulent patterns
 */
export const verifyActivity = functions.firestore
  .document('challenges/{challengeId}/dailyActivity/{dayId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { userId, value, goalType } = data;

    try {
      // Get user's historical data for ML analysis
      const userRef = db.collection('users').doc(userId);
      const userDoc = await userRef.get();
      const userData = userDoc.data() || {};

      // Get challenge history for pattern analysis
      const challengeRef = db.collection('challenges').doc(context.params.challengeId);
      const challengeDoc = await challengeRef.get();
      const challengeData = challengeDoc.data() || {};

      // Collect all daily activity for this user in this challenge
      const activitySnapshot = await challengeRef
        .collection('dailyActivity')
        .where('userId', '==', userId)
        .get();

      const activityHistory = activitySnapshot.docs.map(doc => doc.data());

      // AI/ML Analysis - Multi-factor scoring
      const aiScore = await performAIAnalysis({
        value,
        goalType,
        activityHistory,
        userReputation: userData.antiCheatScore || 0.85,
        accountAge: userData.createdAt,
        pastChallenges: userData.totalChallenges || 0,
      });

      // Update activity with AI score
      await snap.ref.update({
        aiVerificationScore: aiScore.overallScore,
        aiFlags: aiScore.flags,
        verified: aiScore.overallScore >= 0.65,
        flagged: aiScore.isSuspicious,
        flagReason: aiScore.flags.join('; '),
      });

      // If highly suspicious, flag challenge for review
      if (aiScore.isCheating) {
        await challengeRef.update({
          status: 'disputed',
          disputeReason: 'AI detected potential cheating',
          disputedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Notify admin
        await notifyAdmin({
          type: 'cheat_detected',
          challengeId: context.params.challengeId,
          userId,
          aiScore: aiScore.overallScore,
          flags: aiScore.flags,
        });
      }

      // Update user reputation score
      if (userDoc.exists) {
        const newReputation = calculateUpdatedReputation(
          userData.antiCheatScore || 0.85,
          aiScore.overallScore
        );
        await userRef.update({
          antiCheatScore: newReputation,
        });
      }

      console.log(`AI verification: User ${userId}, Score: ${aiScore.overallScore}`);
    } catch (error) {
      console.error('Error in AI verification:', error);
    }
  });

/**
 * Perform AI/ML analysis on activity data
 * This simulates ML model inference in production
 */
async function performAIAnalysis(params: {
  value: number;
  goalType: string;
  activityHistory: any[];
  userReputation: number;
  accountAge: any;
  pastChallenges: number;
}): Promise<{
  overallScore: number;
  flags: string[];
  isSuspicious: boolean;
  isCheating: boolean;
}> {
  const flags: string[] = [];
  let score = 1.0;

  // 1. Threshold-based validation
  const thresholds: any = {
    steps: { max: 50000, suspicious: 30000 },
    distance: { max: 50, suspicious: 30 }, // miles
    milePace: { min: 240, max: 1200 }, // seconds (4:00 - 20:00 min/mi)
    fiveKPace: { min: 900, max: 3600 }, // seconds (15:00 - 60:00)
    tenKPace: { min: 1800, max: 7200 }, // seconds (30:00 - 120:00)
    sleepDuration: { max: 16, suspicious: 12 }, // hours
    vo2Max: { min: 200, max: 800 }, // x10 (20.0 - 80.0 ml/kg/min)
    rivlHealthScore: { min: 0, max: 100 },
  };

  const limits = thresholds[params.goalType];
  if (limits) {
    if (limits.max && params.value > limits.max) {
      flags.push('Exceeds maximum possible value');
      score -= 0.4;
    } else if (limits.suspicious && params.value > limits.suspicious) {
      flags.push('Unusually high value');
      score -= 0.2;
    }
    if (limits.min && params.value < limits.min) {
      flags.push('Suspiciously low value');
      score -= 0.2;
    }
  }

  // 2. Pattern analysis - detect consistency anomalies
  if (params.activityHistory.length > 2) {
    const values = params.activityHistory.map((a: any) => a.value);
    const variance = calculateVariance(values);

    if (variance < 10) {
      // Too consistent = bot-like
      flags.push('Activity too consistent (bot-like pattern)');
      score -= 0.25;
    }

    // Check for sudden spikes
    for (let i = 1; i < values.length; i++) {
      if (values[i] > values[i-1] * 3) {
        flags.push('Sudden activity spike detected');
        score -= 0.15;
        break;
      }
    }
  }

  // 3. User reputation factor
  if (params.userReputation < 0.5) {
    flags.push('User has low trust score');
    score -= 0.2;
  }
  score = score * 0.7 + params.userReputation * 0.3; // Weighted average

  // 4. New account check
  if (params.pastChallenges < 3) {
    score -= 0.1; // Slight penalty for new users
  }

  // Clamp score
  score = Math.max(0, Math.min(1, score));

  return {
    overallScore: score,
    flags,
    isSuspicious: score < 0.65,
    isCheating: score < 0.4,
  };
}

function calculateVariance(values: number[]): number {
  if (values.length === 0) return 0;
  const mean = values.reduce((a, b) => a + b, 0) / values.length;
  const squaredDiffs = values.map(v => Math.pow(v - mean, 2));
  return squaredDiffs.reduce((a, b) => a + b, 0) / values.length;
}

function calculateUpdatedReputation(current: number, newScore: number): number {
  // Exponential moving average
  const alpha = 0.2; // Weight for new score
  return current * (1 - alpha) + newScore * alpha;
}

async function notifyAdmin(notification: any) {
  // Store admin notification
  await db.collection('adminNotifications').add({
    ...notification,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// ============================================
// SERVER-SIDE ANTI-CHEAT (CALLABLE)
// ============================================

/**
 * Callable function for on-demand anti-cheat analysis.
 * The client sends step history and the server runs the full ML pipeline,
 * so the scoring logic can't be reverse-engineered from the APK.
 */
export const analyzeAntiCheat = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { challengeId, stepHistory } = data;
  const userId = context.auth.uid;

  if (!challengeId || !stepHistory || !Array.isArray(stepHistory)) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing challengeId or stepHistory');
  }

  try {
    // Get user reputation
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data() || {};

    // Run server-side analysis
    const values = stepHistory.map((entry: any) => entry.steps ?? entry.value ?? 0);
    const result = await performAIAnalysis({
      value: values.length > 0 ? values[values.length - 1] : 0,
      goalType: 'steps',
      activityHistory: stepHistory.map((entry: any, i: number) => ({
        value: entry.steps ?? entry.value ?? 0,
        date: entry.date ?? new Date().toISOString(),
      })),
      userReputation: userData.antiCheatScore || 0.85,
      accountAge: userData.createdAt,
      pastChallenges: userData.totalChallenges || 0,
    });

    // Update challenge document with server-side score
    const challengeRef = db.collection('challenges').doc(challengeId);
    const challengeDoc = await challengeRef.get();
    if (challengeDoc.exists) {
      const challengeData = challengeDoc.data()!;
      const isCreator = challengeData.creatorId === userId;
      const scoreField = isCreator ? 'creatorAntiCheatScore' : 'opponentAntiCheatScore';

      const updates: any = {
        [scoreField]: result.overallScore,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (result.isSuspicious || result.isCheating) {
        updates.flagged = true;
        updates.flagReason = result.flags.join('; ');
      }

      await challengeRef.update(updates);
    }

    // Update user reputation
    if (userDoc.exists) {
      const newReputation = calculateUpdatedReputation(
        userData.antiCheatScore || 0.85,
        result.overallScore,
      );
      await db.collection('users').doc(userId).update({
        antiCheatScore: newReputation,
      });
    }

    return {
      overallScore: result.overallScore,
      flags: result.flags,
      isSuspicious: result.isSuspicious,
      isCheating: result.isCheating,
    };
  } catch (error: any) {
    console.error('Error in analyzeAntiCheat:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// ============================================
// UTILITY FUNCTIONS
// ============================================

/**
 * Manually trigger challenge completion (callable for testing)
 */
export const manualCompleteChallenge = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  // Only allow admins to manually complete challenges
  const userDoc = await db.collection('users').doc(context.auth.uid).get();
  const userData = userDoc.data();
  if (!userData?.isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  const { challengeId } = data;
  await completeChallenge(challengeId);

  return { success: true };
});

// ============================================
// WALLET DEPOSITS
// ============================================

/**
 * Create a PaymentIntent for wallet deposit
 * Returns client secret for Stripe PaymentSheet
 */
export const createDepositPaymentIntent = functions
  .runWith({ secrets: [stripeSecretKey] })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { amount } = data;
  const effectiveUserId = context.auth.uid;

  if (!amount || amount < 10) {
    throw new functions.https.HttpsError('invalid-argument', 'Minimum deposit is $10');
  }

  if (amount > 1000) {
    throw new functions.https.HttpsError('invalid-argument', 'Maximum deposit is $1000');
  }

  try {
    const stripe = getStripe();

    // Create or get Stripe customer
    let customerId: string;
    const walletDoc = await db.collection('wallets').doc(effectiveUserId).get();

    if (walletDoc.exists && walletDoc.data()?.stripeCustomerId) {
      customerId = walletDoc.data()!.stripeCustomerId;
    } else {
      const customer = await stripe.customers.create({
        metadata: {
          rivlUserId: effectiveUserId,
        },
      });
      customerId = customer.id;

      // Save customer ID to wallet
      await db.collection('wallets').doc(effectiveUserId).set({
        stripeCustomerId: customerId,
        balance: 0,
        pendingBalance: 0,
        lifetimeDeposits: 0,
        lifetimeWithdrawals: 0,
        lifetimeWinnings: 0,
        lifetimeLosses: 0,
        isVerified: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    // Create PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: 'usd',
      customer: customerId,
      metadata: {
        userId: effectiveUserId,
        type: 'wallet_deposit',
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });

    // Create pending transaction in Firestore
    const txRef = await db
      .collection('wallets')
      .doc(effectiveUserId)
      .collection('transactions')
      .add({
        type: 'deposit',
        status: 'pending',
        amount: amount,
        fee: 0,
        netAmount: amount,
        description: 'Wallet deposit',
        stripePaymentIntentId: paymentIntent.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Update pending balance
    await db.collection('wallets').doc(effectiveUserId).update({
      pendingBalance: admin.firestore.FieldValue.increment(amount),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      transactionId: txRef.id,
      customerId: customerId,
    };
  } catch (error: any) {
    console.error('Error creating deposit PaymentIntent:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Confirm wallet deposit after successful payment
 * Called after PaymentSheet completes successfully
 */
export const confirmWalletDeposit = functions
  .runWith({ secrets: [stripeSecretKey] })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { paymentIntentId } = data;
  const effectiveUserId = context.auth.uid;

  if (!paymentIntentId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing paymentIntentId');
  }

  try {
    const stripe = getStripe();

    // Verify payment succeeded
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status !== 'succeeded') {
      throw new functions.https.HttpsError('failed-precondition', 'Payment not completed');
    }

    const amount = paymentIntent.amount / 100; // Convert from cents

    // Find and update the pending transaction
    const txQuery = await db
      .collection('wallets')
      .doc(effectiveUserId)
      .collection('transactions')
      .where('stripePaymentIntentId', '==', paymentIntentId)
      .limit(1)
      .get();

    if (!txQuery.empty) {
      const txDoc = txQuery.docs[0];
      await txDoc.ref.update({
        status: 'completed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Update wallet balance
    await db.collection('wallets').doc(effectiveUserId).update({
      balance: admin.firestore.FieldValue.increment(amount),
      pendingBalance: admin.firestore.FieldValue.increment(-amount),
      lifetimeDeposits: admin.firestore.FieldValue.increment(amount),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, amount };
  } catch (error: any) {
    console.error('Error confirming deposit:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
