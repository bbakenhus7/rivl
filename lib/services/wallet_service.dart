// services/wallet_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/wallet_model.dart';

/// Wallet service for managing user funds, deposits, and withdrawals
/// Integrates with Stripe ACH for bank transfers
class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Minimum amounts
  static const double MIN_DEPOSIT = 10.0;
  static const double MAX_DEPOSIT = 1000.0;
  static const double MIN_WITHDRAWAL = 10.0;

  // Withdrawal fees
  static const double ACH_WITHDRAWAL_FEE = 0.0; // Free standard ACH
  static const double INSTANT_ACH_FEE_PERCENT = 0.015; // 1.5% for instant

  // ============================================
  // WALLET MANAGEMENT
  // ============================================

  /// Get or create wallet for user
  Future<WalletModel> getOrCreateWallet(String userId) async {
    final doc = await _db.collection('wallets').doc(userId).get();

    if (doc.exists) {
      return WalletModel.fromFirestore(doc);
    }

    // Create new wallet
    final wallet = WalletModel(
      id: userId,
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.collection('wallets').doc(userId).set(wallet.toFirestore());
    return wallet;
  }

  /// Stream wallet updates
  Stream<WalletModel?> walletStream(String userId) {
    return _db.collection('wallets').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return WalletModel.fromFirestore(doc);
    });
  }

  /// Get wallet balance
  Future<double> getBalance(String userId) async {
    final wallet = await getOrCreateWallet(userId);
    return wallet.balance;
  }

  // ============================================
  // DEPOSITS (via Stripe)
  // ============================================

  /// Initiate deposit via Stripe PaymentSheet
  Future<WalletTransaction> initiateDeposit({
    required String userId,
    required double amount,
  }) async {
    if (amount < MIN_DEPOSIT) {
      throw Exception('Minimum deposit is \$${MIN_DEPOSIT.toStringAsFixed(0)}');
    }
    if (amount > MAX_DEPOSIT) {
      throw Exception('Maximum deposit is \$${MAX_DEPOSIT.toStringAsFixed(0)}');
    }

    try {
      // Call Cloud Function to create PaymentIntent
      final functions = FirebaseFunctions.instance;
      final result = await functions
          .httpsCallable('createDepositPaymentIntent')
          .call({'amount': amount, 'userId': userId});

      final data = result.data as Map<String, dynamic>;
      final clientSecret = data['clientSecret'] as String;
      final paymentIntentId = data['paymentIntentId'] as String;
      final transactionId = data['transactionId'] as String;

      // Initialize PaymentSheet (skip on web)
      if (!kIsWeb) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'RIVL',
            style: ThemeMode.system,
          ),
        );

        // Present PaymentSheet
        await Stripe.instance.presentPaymentSheet();

        // Payment succeeded - confirm the deposit
        await functions
            .httpsCallable('confirmWalletDeposit')
            .call({'paymentIntentId': paymentIntentId, 'userId': userId});
      } else {
        // For web, we need a different approach - for now just throw
        throw Exception('Web payments coming soon! Please use the mobile app.');
      }

      return WalletTransaction(
        id: transactionId,
        userId: userId,
        type: TransactionType.deposit,
        status: TransactionStatus.completed,
        amount: amount,
        fee: 0,
        netAmount: amount,
        description: 'Wallet deposit',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
    } on StripeException catch (e) {
      // User cancelled or payment failed
      throw Exception(e.error.localizedMessage ?? 'Payment cancelled');
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to process deposit');
    }
  }

  /// Complete deposit (called by Stripe webhook)
  Future<void> completeDeposit({
    required String userId,
    required String transactionId,
    required String stripePaymentId,
  }) async {
    final batch = _db.batch();

    // Update transaction
    final txRef = _db
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId);

    final txDoc = await txRef.get();
    if (!txDoc.exists) throw Exception('Transaction not found');

    final tx = WalletTransaction.fromFirestore(txDoc);

    batch.update(txRef, {
      'status': TransactionStatus.completed.name,
      'stripePaymentId': stripePaymentId,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Update wallet balance
    final walletRef = _db.collection('wallets').doc(userId);
    batch.update(walletRef, {
      'balance': FieldValue.increment(tx.netAmount),
      'pendingBalance': FieldValue.increment(-tx.amount),
      'lifetimeDeposits': FieldValue.increment(tx.netAmount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ============================================
  // WITHDRAWALS
  // ============================================

  /// Initiate withdrawal to bank account
  Future<WalletTransaction> initiateWithdrawal({
    required String userId,
    required double amount,
    WithdrawalMethod method = WithdrawalMethod.ach,
  }) async {
    final wallet = await getOrCreateWallet(userId);

    if (!wallet.isVerified) {
      throw Exception('Please verify your bank account before withdrawing');
    }

    if (amount < MIN_WITHDRAWAL) {
      throw Exception('Minimum withdrawal is \$${MIN_WITHDRAWAL.toStringAsFixed(0)}');
    }

    if (amount > wallet.balance) {
      throw Exception('Insufficient balance');
    }

    // Calculate fee
    double fee = 0;
    if (method == WithdrawalMethod.instantAch) {
      fee = amount * INSTANT_ACH_FEE_PERCENT;
    }
    final netAmount = amount - fee;

    // Create pending transaction
    final transaction = WalletTransaction(
      id: '',
      userId: userId,
      type: TransactionType.withdrawal,
      status: TransactionStatus.processing,
      amount: amount,
      fee: fee,
      netAmount: netAmount,
      description: method == WithdrawalMethod.instantAch
          ? 'Instant withdrawal to bank'
          : 'Standard withdrawal to bank (1-3 business days)',
      createdAt: DateTime.now(),
    );

    final docRef = await _db
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .add(transaction.toFirestore());

    // Deduct from balance
    await _db.collection('wallets').doc(userId).update({
      'balance': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // In production, this would initiate Stripe payout

    return WalletTransaction(
      id: docRef.id,
      userId: userId,
      type: TransactionType.withdrawal,
      status: TransactionStatus.processing,
      amount: amount,
      fee: fee,
      netAmount: netAmount,
      description: transaction.description,
      createdAt: DateTime.now(),
    );
  }

  /// Complete withdrawal (called by Stripe webhook)
  Future<void> completeWithdrawal({
    required String userId,
    required String transactionId,
    required String stripePayoutId,
  }) async {
    final batch = _db.batch();

    final txRef = _db
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId);

    final txDoc = await txRef.get();
    if (!txDoc.exists) throw Exception('Transaction not found');

    final tx = WalletTransaction.fromFirestore(txDoc);

    batch.update(txRef, {
      'status': TransactionStatus.completed.name,
      'stripePaymentId': stripePayoutId,
      'completedAt': FieldValue.serverTimestamp(),
    });

    final walletRef = _db.collection('wallets').doc(userId);
    batch.update(walletRef, {
      'lifetimeWithdrawals': FieldValue.increment(tx.netAmount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ============================================
  // CHALLENGE STAKES
  // ============================================

  /// Deduct stake for challenge entry (atomic transaction)
  Future<bool> deductStake({
    required String userId,
    required String challengeId,
    required double amount,
  }) async {
    try {
      return await _db.runTransaction<bool>((txn) async {
        final walletRef = _db.collection('wallets').doc(userId);
        final walletDoc = await txn.get(walletRef);

        if (!walletDoc.exists) return false;

        final currentBalance = (walletDoc.data()?['balance'] ?? 0).toDouble();
        if (currentBalance < amount) return false;

        // Create transaction record
        final txRef = walletRef.collection('transactions').doc();
        txn.set(txRef, {
          'userId': userId,
          'type': TransactionType.stakeDebit.name,
          'status': TransactionStatus.completed.name,
          'amount': amount,
          'fee': 0.0,
          'netAmount': amount,
          'challengeId': challengeId,
          'description': 'Challenge entry fee',
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Deduct from balance atomically (stake, not a loss)
        txn.update(walletRef, {
          'balance': currentBalance - amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Credit winnings from challenge (atomic transaction)
  Future<void> creditWinnings({
    required String userId,
    required String challengeId,
    required double amount,
  }) async {
    await _db.runTransaction((txn) async {
      final walletRef = _db.collection('wallets').doc(userId);
      final walletDoc = await txn.get(walletRef);

      if (!walletDoc.exists) throw Exception('Wallet not found');

      final currentBalance = (walletDoc.data()?['balance'] ?? 0).toDouble();

      // Create transaction record
      final txRef = walletRef.collection('transactions').doc();
      txn.set(txRef, {
        'userId': userId,
        'type': TransactionType.winnings.name,
        'status': TransactionStatus.completed.name,
        'amount': amount,
        'fee': 0.0,
        'netAmount': amount,
        'challengeId': challengeId,
        'description': 'Challenge winnings',
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Credit balance atomically
      txn.update(walletRef, {
        'balance': currentBalance + amount,
        'lifetimeWinnings': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Refund stake for cancelled challenge (atomic transaction)
  Future<void> refundStake({
    required String userId,
    required String challengeId,
    required double amount,
  }) async {
    await _db.runTransaction((txn) async {
      final walletRef = _db.collection('wallets').doc(userId);
      final walletDoc = await txn.get(walletRef);

      if (!walletDoc.exists) throw Exception('Wallet not found');

      final currentBalance = (walletDoc.data()?['balance'] ?? 0).toDouble();

      // Create refund transaction record
      final txRef = walletRef.collection('transactions').doc();
      txn.set(txRef, {
        'userId': userId,
        'type': TransactionType.refund.name,
        'status': TransactionStatus.completed.name,
        'amount': amount,
        'fee': 0.0,
        'netAmount': amount,
        'challengeId': challengeId,
        'description': 'Challenge refund',
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Refund balance atomically
      txn.update(walletRef, {
        'balance': currentBalance + amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ============================================
  // TRANSACTION HISTORY
  // ============================================

  /// Get transaction history with pagination support.
  /// Pass [startAfter] to get the next page.
  Future<List<WalletTransaction>> getTransactions(
    String userId, {
    int limit = 20,
    TransactionType? filterType,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _db
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .orderBy('createdAt', descending: true);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.name);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => WalletTransaction.fromFirestore(doc))
        .toList();
  }

  /// Stream transaction updates
  Stream<List<WalletTransaction>> transactionsStream(String userId) {
    return _db
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => WalletTransaction.fromFirestore(doc)).toList());
  }

  // ============================================
  // BANK ACCOUNT VERIFICATION
  // ============================================

  /// Link bank account via Stripe (Plaid integration)
  Future<void> linkBankAccount({
    required String userId,
    required String stripeCustomerId,
    required String stripeBankAccountId,
  }) async {
    await _db.collection('wallets').doc(userId).update({
      'stripeCustomerId': stripeCustomerId,
      'stripeBankAccountId': stripeBankAccountId,
      'isVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unlink bank account
  Future<void> unlinkBankAccount(String userId) async {
    await _db.collection('wallets').doc(userId).update({
      'stripeBankAccountId': null,
      'isVerified': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
