// models/transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TransactionType {
  deposit,
  withdrawal,
  challengeStake,
  challengeWin,
  challengeRefund,
  referralBonus,
  streakBonus,
}

enum TransactionStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String? challengeId;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.amount,
    this.challengeId,
    this.description,
    required this.createdAt,
    this.completedAt,
  });

  String get displayAmount {
    final sign = isCredit ? '+' : '-';
    return '$sign\$${amount.toStringAsFixed(2)}';
  }

  bool get isCredit => type == TransactionType.challengeWin ||
      type == TransactionType.referralBonus ||
      type == TransactionType.streakBonus ||
      type == TransactionType.challengeRefund ||
      type == TransactionType.deposit;

  Color get amountColor => isCredit ? Colors.green : Colors.red;

  String get typeDisplayName {
    switch (type) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.challengeStake:
        return 'Challenge Stake';
      case TransactionType.challengeWin:
        return 'Challenge Win';
      case TransactionType.challengeRefund:
        return 'Refund';
      case TransactionType.referralBonus:
        return 'Referral Bonus';
      case TransactionType.streakBonus:
        return 'Streak Bonus';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.deposit,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      challengeId: data['challengeId'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'challengeId': challengeId,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
