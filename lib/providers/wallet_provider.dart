// providers/wallet_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();
  bool _disposed = false;

  WalletModel? _wallet;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  StreamSubscription? _walletSubscription;
  StreamSubscription? _transactionsSubscription;

  // Getters
  WalletModel? get wallet => _wallet;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  double get balance => _wallet?.balance ?? 0.0;
  double get pendingBalance => _wallet?.pendingBalance ?? 0.0;
  double get totalBalance => _wallet?.totalBalance ?? 0.0;
  bool get isVerified => _wallet?.isVerified ?? false;
  bool get canWithdraw => _wallet?.canWithdraw ?? false;

  // Stats
  double get lifetimeWinnings => _wallet?.lifetimeWinnings ?? 0.0;
  double get lifetimeLosses => _wallet?.lifetimeLosses ?? 0.0;
  double get netProfit => _wallet?.netProfit ?? 0.0;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> initialize(String userId) async {
    _isLoading = true;
    _safeNotify();

    try {
      // Get or create wallet
      _wallet = await _walletService.getOrCreateWallet(userId);

      // Start listening to updates
      _walletSubscription?.cancel();
      _walletSubscription = _walletService.walletStream(userId).listen(
        (wallet) {
          if (wallet == null) return;
          _wallet = wallet;
          _safeNotify();
        },
        onError: (error) {
          _errorMessage = 'Failed to sync wallet';
          _safeNotify();
        },
      );

      // Start listening to transactions
      _transactionsSubscription?.cancel();
      _transactionsSubscription = _walletService.transactionsStream(userId).listen(
        (transactions) {
          _transactions = transactions;
          _safeNotify();
        },
        onError: (error) {
          _errorMessage = 'Failed to sync transactions';
          _safeNotify();
        },
      );

      _isLoading = false;
      _safeNotify();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load wallet';
      _safeNotify();
    }
  }

  // ============================================
  // DEPOSITS
  // ============================================

  Future<WalletTransaction?> initiateDeposit(double amount) async {
    if (_wallet == null) return null;
    if (amount <= 0) {
      _errorMessage = 'Deposit amount must be greater than zero';
      _safeNotify();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final transaction = await _walletService.initiateDeposit(
        userId: _wallet!.userId,
        amount: amount,
      );

      _successMessage = 'Deposit initiated! Complete payment to add funds.';
      _isProcessing = false;
      _safeNotify();

      return transaction;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return null;
    }
  }

  // ============================================
  // WITHDRAWALS
  // ============================================

  Future<WalletTransaction?> initiateWithdrawal(
    double amount, {
    WithdrawalMethod method = WithdrawalMethod.ach,
  }) async {
    if (_wallet == null) return null;
    if (amount <= 0) {
      _errorMessage = 'Withdrawal amount must be greater than zero';
      _safeNotify();
      return null;
    }
    if (amount > balance) {
      _errorMessage = 'Insufficient balance';
      _safeNotify();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final transaction = await _walletService.initiateWithdrawal(
        userId: _wallet!.userId,
        amount: amount,
        method: method,
      );

      _successMessage = method == WithdrawalMethod.instantAch
          ? 'Instant withdrawal initiated!'
          : 'Withdrawal initiated! Funds will arrive in 1-3 business days.';
      _isProcessing = false;
      _safeNotify();

      return transaction;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return null;
    }
  }

  // ============================================
  // TRANSACTIONS
  // ============================================

  Future<void> refreshTransactions() async {
    if (_wallet == null) return;

    try {
      _transactions = await _walletService.getTransactions(_wallet!.userId);
      _safeNotify();
    } catch (e) {
      _errorMessage = 'Failed to refresh transactions';
      _safeNotify();
    }
  }

  List<WalletTransaction> getFilteredTransactions(TransactionType? type) {
    if (type == null) return _transactions;
    return _transactions.where((tx) => tx.type == type).toList();
  }

  // ============================================
  // HELPERS
  // ============================================

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
