// models/challenge_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ChallengeType { headToHead, group }

enum ChallengeStatus { pending, accepted, active, completed, cancelled, disputed }

enum GoalType { totalSteps, dailyAverage, mostStepsInDay }

enum ChallengeDuration { oneDay, threeDays, oneWeek, twoWeeks, oneMonth }

enum PaymentStatus { pending, processing, completed, failed, refunded }

enum RewardStatus { pending, processing, sent, claimed, failed }

class ChallengeModel {
  final String id;
  final String creatorId;
  final String? opponentId;
  final String creatorName;
  final String? opponentName;
  
  // Challenge Details
  final ChallengeType type;
  final ChallengeStatus status;
  final double stakeAmount;
  final double totalPot;
  final double prizeAmount;
  
  // Goal & Progress
  final GoalType goalType;
  final int goalValue;
  final ChallengeDuration duration;
  final DateTime? startDate;
  final DateTime? endDate;
  
  // Progress
  final int creatorProgress;
  final int opponentProgress;
  final List<DailySteps> creatorStepHistory;
  final List<DailySteps> opponentStepHistory;
  
  // Results
  final String? winnerId;
  final String? winnerName;
  final DateTime? resultDeclaredAt;
  
  // Payment
  final PaymentStatus creatorPaymentStatus;
  final PaymentStatus opponentPaymentStatus;
  final RewardStatus rewardStatus;
  final String? rewardId;
  
  // Anti-Cheat
  final double creatorAntiCheatScore;
  final double opponentAntiCheatScore;
  final bool flagged;
  final String? flagReason;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  ChallengeModel({
    required this.id,
    required this.creatorId,
    this.opponentId,
    required this.creatorName,
    this.opponentName,
    required this.type,
    required this.status,
    required this.stakeAmount,
    required this.totalPot,
    required this.prizeAmount,
    required this.goalType,
    required this.goalValue,
    required this.duration,
    this.startDate,
    this.endDate,
    this.creatorProgress = 0,
    this.opponentProgress = 0,
    this.creatorStepHistory = const [],
    this.opponentStepHistory = const [],
    this.winnerId,
    this.winnerName,
    this.resultDeclaredAt,
    this.creatorPaymentStatus = PaymentStatus.pending,
    this.opponentPaymentStatus = PaymentStatus.pending,
    this.rewardStatus = RewardStatus.pending,
    this.rewardId,
    this.creatorAntiCheatScore = 1.0,
    this.opponentAntiCheatScore = 1.0,
    this.flagged = false,
    this.flagReason,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  bool get isUserWinning => creatorProgress > opponentProgress;
  
  double get progressPercentage {
    if (goalValue == 0) return 0;
    return (creatorProgress / goalValue).clamp(0.0, 1.0);
  }
  
  String get timeRemaining {
    if (endDate == null) return 'Not started';
    final remaining = endDate!.difference(DateTime.now());
    if (remaining.isNegative) return 'Ended';
    
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    
    if (days > 0) {
      return '${days}d ${hours}h';
    } else {
      final minutes = remaining.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }

  Color get statusColor {
    switch (status) {
      case ChallengeStatus.pending:
        return Colors.orange;
      case ChallengeStatus.accepted:
        return Colors.blue;
      case ChallengeStatus.active:
        return Colors.green;
      case ChallengeStatus.completed:
        return Colors.purple;
      case ChallengeStatus.cancelled:
        return Colors.grey;
      case ChallengeStatus.disputed:
        return Colors.red;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ChallengeStatus.pending:
        return 'Pending';
      case ChallengeStatus.accepted:
        return 'Accepted';
      case ChallengeStatus.active:
        return 'In Progress';
      case ChallengeStatus.completed:
        return 'Completed';
      case ChallengeStatus.cancelled:
        return 'Cancelled';
      case ChallengeStatus.disputed:
        return 'Disputed';
    }
  }

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChallengeModel(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      opponentId: data['opponentId'],
      creatorName: data['creatorName'] ?? '',
      opponentName: data['opponentName'],
      type: ChallengeType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChallengeType.headToHead,
      ),
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ChallengeStatus.pending,
      ),
      stakeAmount: (data['stakeAmount'] ?? 0).toDouble(),
      totalPot: (data['totalPot'] ?? 0).toDouble(),
      prizeAmount: (data['prizeAmount'] ?? 0).toDouble(),
      goalType: GoalType.values.firstWhere(
        (e) => e.name == data['goalType'],
        orElse: () => GoalType.totalSteps,
      ),
      goalValue: data['goalValue'] ?? 0,
      duration: ChallengeDuration.values.firstWhere(
        (e) => e.name == data['duration'],
        orElse: () => ChallengeDuration.oneWeek,
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      creatorProgress: data['creatorProgress'] ?? 0,
      opponentProgress: data['opponentProgress'] ?? 0,
      creatorStepHistory: (data['creatorStepHistory'] as List<dynamic>?)
          ?.map((e) => DailySteps.fromMap(e))
          .toList() ?? [],
      opponentStepHistory: (data['opponentStepHistory'] as List<dynamic>?)
          ?.map((e) => DailySteps.fromMap(e))
          .toList() ?? [],
      winnerId: data['winnerId'],
      winnerName: data['winnerName'],
      resultDeclaredAt: (data['resultDeclaredAt'] as Timestamp?)?.toDate(),
      creatorPaymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == data['creatorPaymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      opponentPaymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == data['opponentPaymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      rewardStatus: RewardStatus.values.firstWhere(
        (e) => e.name == data['rewardStatus'],
        orElse: () => RewardStatus.pending,
      ),
      rewardId: data['rewardId'],
      creatorAntiCheatScore: (data['creatorAntiCheatScore'] ?? 1.0).toDouble(),
      opponentAntiCheatScore: (data['opponentAntiCheatScore'] ?? 1.0).toDouble(),
      flagged: data['flagged'] ?? false,
      flagReason: data['flagReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'opponentId': opponentId,
      'creatorName': creatorName,
      'opponentName': opponentName,
      'type': type.name,
      'status': status.name,
      'stakeAmount': stakeAmount,
      'totalPot': totalPot,
      'prizeAmount': prizeAmount,
      'goalType': goalType.name,
      'goalValue': goalValue,
      'duration': duration.name,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'creatorProgress': creatorProgress,
      'opponentProgress': opponentProgress,
      'creatorStepHistory': creatorStepHistory.map((e) => e.toMap()).toList(),
      'opponentStepHistory': opponentStepHistory.map((e) => e.toMap()).toList(),
      'winnerId': winnerId,
      'winnerName': winnerName,
      'resultDeclaredAt': resultDeclaredAt != null ? Timestamp.fromDate(resultDeclaredAt!) : null,
      'creatorPaymentStatus': creatorPaymentStatus.name,
      'opponentPaymentStatus': opponentPaymentStatus.name,
      'rewardStatus': rewardStatus.name,
      'rewardId': rewardId,
      'creatorAntiCheatScore': creatorAntiCheatScore,
      'opponentAntiCheatScore': opponentAntiCheatScore,
      'flagged': flagged,
      'flagReason': flagReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class DailySteps {
  final String date;
  final int steps;
  final String source;
  final DateTime syncedAt;
  final bool verified;

  DailySteps({
    required this.date,
    required this.steps,
    required this.source,
    required this.syncedAt,
    this.verified = true,
  });

  factory DailySteps.fromMap(Map<String, dynamic> map) {
    return DailySteps(
      date: map['date'] ?? '',
      steps: map['steps'] ?? 0,
      source: map['source'] ?? 'unknown',
      syncedAt: (map['syncedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verified: map['verified'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'steps': steps,
      'source': source,
      'syncedAt': Timestamp.fromDate(syncedAt),
      'verified': verified,
    };
  }
}

// Stake options
class StakeOption {
  final double amount;
  final double prize;
  final double fee;

  const StakeOption({
    required this.amount,
    required this.prize,
    required this.fee,
  });

  String get displayAmount => '\$${amount.toInt()}';
  String get displayPrize => '\$${prize.toInt()}';

  static const List<StakeOption> options = [
    StakeOption(amount: 5, prize: 8, fee: 0.5),
    StakeOption(amount: 10, prize: 17, fee: 0.85),
    StakeOption(amount: 15, prize: 25, fee: 1.25),
    StakeOption(amount: 20, prize: 34, fee: 1.70),
    StakeOption(amount: 25, prize: 42, fee: 2.10),
    StakeOption(amount: 50, prize: 85, fee: 4.25),
  ];
}

// Duration helpers
extension ChallengeDurationExtension on ChallengeDuration {
  int get days {
    switch (this) {
      case ChallengeDuration.oneDay:
        return 1;
      case ChallengeDuration.threeDays:
        return 3;
      case ChallengeDuration.oneWeek:
        return 7;
      case ChallengeDuration.twoWeeks:
        return 14;
      case ChallengeDuration.oneMonth:
        return 30;
    }
  }

  String get displayName {
    switch (this) {
      case ChallengeDuration.oneDay:
        return '1 Day';
      case ChallengeDuration.threeDays:
        return '3 Days';
      case ChallengeDuration.oneWeek:
        return '1 Week';
      case ChallengeDuration.twoWeeks:
        return '2 Weeks';
      case ChallengeDuration.oneMonth:
        return '1 Month';
    }
  }
}

// Goal type helpers
extension GoalTypeExtension on GoalType {
  String get displayName {
    switch (this) {
      case GoalType.totalSteps:
        return 'Total Steps';
      case GoalType.dailyAverage:
        return 'Daily Average';
      case GoalType.mostStepsInDay:
        return 'Most Steps in a Day';
    }
  }

  String get description {
    switch (this) {
      case GoalType.totalSteps:
        return 'Most total steps wins';
      case GoalType.dailyAverage:
        return 'Highest daily average wins';
      case GoalType.mostStepsInDay:
        return 'Best single day wins';
    }
  }
}
