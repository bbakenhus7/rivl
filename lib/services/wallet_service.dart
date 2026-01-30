// services/wallet_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
      odId: userId,
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
  // DEPOSITS (via Stripe ACH)
  // ============================================

  /// Initiate deposit via Stripe ACH
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

    // Create pending transaction
    final transaction = WalletTransaction(
      id: '',
      odId: userId,
      type: TransactionType.deposit,
      status: TransactionStatus.pending,
      amount: amount,
      fee: 0, // No deposit fee
      netAmount: amount,
      description: 'Bank deposit via ACH',
      createdAt: DateTime.now(),
    );

    final docRef = await _db
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .add(transaction.toFirestore());

    // Update pending balance
    await _db.collection('wallets').doc(userId).update({
      'pendingBalance': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // In production, this would create a Stripe PaymentIntent
    // and return the client secret for frontend to complete payment

    return WalletTransaction(
      id: docRef.id,
      odId: userId,
      type: TransactionType.deposit,
      status: TransactionStatus.pending,
      amount: amount,
      fee: 0,
      netAmount: amount,
      description: 'Bank deposit via ACH',
      createdAt: DateTime.now(),
    );
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
      odId: userId,
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
      odId: userId,
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

  /// Deduct stake for challenge entry
  Future<bool> deductStake({
    required String odId,
    required String challengeId,
    required double amount,
  }) async {
    final wallet = await getOrCreateWallet(odId);

    if (wallet.balance < amount) {
      return false; // Insufficient balance
    }

    final transaction = WalletTransaction(
      id: '',
      odId: odId,
      type: TransactionType.stakeDebit,
      status: TransactionStatus.completed,
      amount: amount,
      netAmount: amount,
      challengeId: challengeId,
      description: 'Challenge entry fee',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    await _db
        .collection('wallets')
        .doc(odId)
        .collection('transactions')
        .add(transaction.toFirestore());

    await _db.collection('wallets').doc(odId).update({
      'balance': FieldValue.increment(-amount),
      'lifetimeLosses': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// Credit winnings from challenge
  Future<void> creditWinnings({
    required String odId,
    required String challengeId,
    required double amount,
  }) async {
    final transaction = WalletTransaction(
      id: '',
      odId: odId,
      type: TransactionType.winnings,
      status: TransactionStatus.completed,
      amount: amount,
      netAmount: amount,
      challengeId: challengeId,
      description: 'Challenge winnings',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    await _db
        .collection('wallets')
        .doc(odId)
        .collection('transactions')
        .add(transaction.toFirestore());

    await _db.collection('wallets').doc(odId).update({
      'balance': FieldValue.increment(amount),
      'lifetimeWinnings': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Refund stake for cancelled challenge
  Future<void> refundStake({
    required String odId,
    required String challengeId,
    required double amount,
  }) async {
    final transaction = WalletTransaction(
      id: '',
      odId: odId,
      type: TransactionType.refund,
      status: TransactionStatus.completed,
      amount: amount,
      netAmount: amount,
      challengeId: challengeId,
      description: 'Challenge refund',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    await _db
        .collection('wallets')
        .doc(odId)
        .collection('transactions')
        .add(transaction.toFirestore());

    await _db.collection('wallets').doc(odId).update({
      'balance': FieldValue.increment(amount),
      'lifetimeLosses': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================
  // TRANSACTION HISTORY
  // ============================================

  /// Get transaction history
  Future<List<WalletTransaction>> getTransactions(
    String userId, {
    int limit = 50,
    TransactionType? filterType,
  }) async {
    Query query = _db
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .orderBy('createdAt', descending: true);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.name);
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
