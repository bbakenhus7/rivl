// models/wallet_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  deposit,      // Adding funds via Stripe ACH
  withdrawal,   // Withdrawing to bank account
  stakeDebit,   // Entry fee for challenge
  winnings,     // Prize from winning a challenge
  refund,       // Refund from cancelled challenge
  bonus,        // Referral bonus or promotional credit
}

enum TransactionStatus {
  pending,      // Transaction initiated
  processing,   // Being processed by payment provider
  completed,    // Successfully completed
  failed,       // Transaction failed
  cancelled,    // Cancelled by user or system
}

enum WithdrawalMethod {
  ach,          // Bank transfer via ACH
  instantAch,   // Instant bank transfer (higher fee)
}

class WalletModel {
  final String id;
  final String odId;
  final double balance;            // Available balance
  final double pendingBalance;     // Funds in pending transactions
  final double lifetimeDeposits;
  final double lifetimeWithdrawals;
  final double lifetimeWinnings;
  final double lifetimeLosses;
  final bool isVerified;           // Bank account verified
  final String? stripeCustomerId;
  final String? stripeBankAccountId;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.odId,
    this.balance = 0.0,
    this.pendingBalance = 0.0,
    this.lifetimeDeposits = 0.0,
    this.lifetimeWithdrawals = 0.0,
    this.lifetimeWinnings = 0.0,
    this.lifetimeLosses = 0.0,
    this.isVerified = false,
    this.stripeCustomerId,
    this.stripeBankAccountId,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalBalance => balance + pendingBalance;

  double get netProfit => lifetimeWinnings - lifetimeLosses;

  bool get canWithdraw => balance > 0 && isVerified;

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      id: doc.id,
      odId: data['userId'] ?? '',
      balance: (data['balance'] ?? 0).toDouble(),
      pendingBalance: (data['pendingBalance'] ?? 0).toDouble(),
      lifetimeDeposits: (data['lifetimeDeposits'] ?? 0).toDouble(),
      lifetimeWithdrawals: (data['lifetimeWithdrawals'] ?? 0).toDouble(),
      lifetimeWinnings: (data['lifetimeWinnings'] ?? 0).toDouble(),
      lifetimeLosses: (data['lifetimeLosses'] ?? 0).toDouble(),
      isVerified: data['isVerified'] ?? false,
      stripeCustomerId: data['stripeCustomerId'],
      stripeBankAccountId: data['stripeBankAccountId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': odId,
      'balance': balance,
      'pendingBalance': pendingBalance,
      'lifetimeDeposits': lifetimeDeposits,
      'lifetimeWithdrawals': lifetimeWithdrawals,
      'lifetimeWinnings': lifetimeWinnings,
      'lifetimeLosses': lifetimeLosses,
      'isVerified': isVerified,
      'stripeCustomerId': stripeCustomerId,
      'stripeBankAccountId': stripeBankAccountId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  WalletModel copyWith({
    double? balance,
    double? pendingBalance,
    double? lifetimeDeposits,
    double? lifetimeWithdrawals,
    double? lifetimeWinnings,
    double? lifetimeLosses,
    bool? isVerified,
    String? stripeCustomerId,
    String? stripeBankAccountId,
  }) {
    return WalletModel(
      id: id,
      odId: odId,
      balance: balance ?? this.balance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      lifetimeDeposits: lifetimeDeposits ?? this.lifetimeDeposits,
      lifetimeWithdrawals: lifetimeWithdrawals ?? this.lifetimeWithdrawals,
      lifetimeWinnings: lifetimeWinnings ?? this.lifetimeWinnings,
      lifetimeLosses: lifetimeLosses ?? this.lifetimeLosses,
      isVerified: isVerified ?? this.isVerified,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeBankAccountId: stripeBankAccountId ?? this.stripeBankAccountId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class WalletTransaction {
  final String id;
  final String odId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final double fee;                // Platform or payment processing fee
  final double netAmount;          // Amount after fees
  final String? challengeId;       // Related challenge (for stake/winnings)
  final String? stripePaymentId;   // Stripe payment intent ID
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;

  WalletTransaction({
    required this.id,
    required this.odId,
    required this.type,
    required this.status,
    required this.amount,
    this.fee = 0.0,
    required this.netAmount,
    this.challengeId,
    this.stripePaymentId,
    this.description,
    required this.createdAt,
    this.completedAt,
  });

  bool get isPending => status == TransactionStatus.pending ||
                        status == TransactionStatus.processing;

  bool get isCredit => type == TransactionType.deposit ||
                       type == TransactionType.winnings ||
                       type == TransactionType.refund ||
                       type == TransactionType.bonus;

  String get displayAmount {
    final prefix = isCredit ? '+' : '-';
    return '$prefix\$${netAmount.toStringAsFixed(2)}';
  }

  String get displayType {
    switch (type) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.stakeDebit:
        return 'Challenge Entry';
      case TransactionType.winnings:
        return 'Challenge Won';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.bonus:
        return 'Bonus';
    }
  }

  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      id: doc.id,
      odId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.deposit,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      fee: (data['fee'] ?? 0).toDouble(),
      netAmount: (data['netAmount'] ?? 0).toDouble(),
      challengeId: data['challengeId'],
      stripePaymentId: data['stripePaymentId'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': odId,
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'fee': fee,
      'netAmount': netAmount,
      'challengeId': challengeId,
      'stripePaymentId': stripePaymentId,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
