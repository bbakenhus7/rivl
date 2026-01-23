// providers/wallet_provider.dart

import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';

class WalletProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  
  double _balance = 0.0;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  WalletProvider(this._firebaseService);

  double get balance => _balance;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> loadWallet(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final stats = await _firebaseService.getUserStats(userId);
      _balance = (stats is Map) ? (stats['currentBalance'] ?? 0.0) : 0.0;
      _transactions = []; // Mock for now - Firebase integration pending
    } catch (e) {
      debugPrint('Error loading wallet: \$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deposit(double amount) async {
    // Simulate deposit - in production, this would integrate with Stripe
    _balance += amount;
    _transactions.insert(0, TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user',
      type: TransactionType.deposit,
      status: TransactionStatus.completed,
      amount: amount,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<void> withdraw(double amount) async {
    if (amount > _balance) return;
    
    _balance -= amount;
    _transactions.insert(0, TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user',
      type: TransactionType.withdrawal,
      status: TransactionStatus.processing,
      amount: amount,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }
}
