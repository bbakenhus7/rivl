// models/challenge_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ChallengeType { headToHead, group }

enum ChallengeStatus { pending, accepted, active, completed, cancelled, disputed }

enum GoalType {
  steps,           // Total step count over challenge period
  distance,        // Total miles walked or run
  milePace,        // Average mile time improvement
  fiveKPace,       // Best 5K time
  tenKPace,        // Best 10K time
  sleepDuration,   // Total hours of quality sleep
  vo2Max,          // VO2 max cardiovascular fitness
  rivlHealthScore  // Combined health score from all 6 metrics (0-100)
}

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
  
  // Group challenge fields
  final List<GroupParticipant> participants;
  final List<String> participantIds; // Flat list of user IDs for Firestore arrayContains queries
  final int maxParticipants;
  final int minParticipants;
  final GroupPayoutStructure? payoutStructure;

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
    this.participants = const [],
    this.participantIds = const [],
    this.maxParticipants = 2,
    this.minParticipants = 2,
    this.payoutStructure,
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
  bool get isGroup => type == ChallengeType.group;
  int get acceptedParticipantCount =>
      participants.where((p) => p.status == ParticipantStatus.accepted).length;

  bool get isTied => creatorProgress == opponentProgress;

  bool get isUserWinning {
    if (isTied) return false;
    if (goalType.higherIsBetter) {
      return creatorProgress > opponentProgress;
    } else {
      // Pace-based: lower is better, but 0 means no data (losing)
      if (creatorProgress == 0) return false;
      if (opponentProgress == 0) return true;
      return creatorProgress < opponentProgress;
    }
  }
  
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
        orElse: () => GoalType.steps,
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
      participants: (data['participants'] as List<dynamic>?)
          ?.map((e) => GroupParticipant.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      participantIds: (data['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      maxParticipants: data['maxParticipants'] ?? 2,
      minParticipants: data['minParticipants'] ?? 2,
      payoutStructure: data['payoutStructure'] != null
          ? GroupPayoutStructure.fromMap(data['payoutStructure'] as Map<String, dynamic>)
          : null,
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
      if (participants.isNotEmpty)
        'participants': participants.map((e) => e.toMap()).toList(),
      if (participantIds.isNotEmpty)
        'participantIds': participantIds,
      if (maxParticipants > 2) 'maxParticipants': maxParticipants,
      if (minParticipants > 2) 'minParticipants': minParticipants,
      if (payoutStructure != null)
        'payoutStructure': payoutStructure!.toMap(),
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

// Group challenge participant
enum ParticipantStatus { invited, accepted, declined }

class GroupParticipant {
  final String userId;
  final String displayName;
  final String? username;
  final ParticipantStatus status;
  final int progress;
  final List<DailySteps> stepHistory;

  const GroupParticipant({
    required this.userId,
    required this.displayName,
    this.username,
    this.status = ParticipantStatus.invited,
    this.progress = 0,
    this.stepHistory = const [],
  });

  factory GroupParticipant.fromMap(Map<String, dynamic> map) {
    return GroupParticipant(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      username: map['username'],
      status: ParticipantStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ParticipantStatus.invited,
      ),
      progress: map['progress'] ?? 0,
      stepHistory: (map['stepHistory'] as List<dynamic>?)
          ?.map((e) => DailySteps.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'username': username,
      'status': status.name,
      'progress': progress,
      'stepHistory': stepHistory.map((e) => e.toMap()).toList(),
    };
  }
}

// Payout structure for group challenges (1st / 2nd / 3rd)
class GroupPayoutStructure {
  final double firstPercent;  // e.g. 0.60
  final double secondPercent; // e.g. 0.25
  final double thirdPercent;  // e.g. 0.15

  const GroupPayoutStructure({
    this.firstPercent = 0.60,
    this.secondPercent = 0.25,
    this.thirdPercent = 0.15,
  });

  /// Calculate dollar payouts from a prize pool (total pot minus fees)
  double firstPayout(double prizePool) => (prizePool * firstPercent * 100).roundToDouble() / 100;
  double secondPayout(double prizePool) => (prizePool * secondPercent * 100).roundToDouble() / 100;
  double thirdPayout(double prizePool) => (prizePool * thirdPercent * 100).roundToDouble() / 100;

  String firstDisplay(double prizePool) => '\$${firstPayout(prizePool).toStringAsFixed(0)}';
  String secondDisplay(double prizePool) => '\$${secondPayout(prizePool).toStringAsFixed(0)}';
  String thirdDisplay(double prizePool) => '\$${thirdPayout(prizePool).toStringAsFixed(0)}';

  factory GroupPayoutStructure.fromMap(Map<String, dynamic> map) {
    return GroupPayoutStructure(
      firstPercent: (map['firstPercent'] ?? 0.60).toDouble(),
      secondPercent: (map['secondPercent'] ?? 0.25).toDouble(),
      thirdPercent: (map['thirdPercent'] ?? 0.15).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstPercent': firstPercent,
      'secondPercent': secondPercent,
      'thirdPercent': thirdPercent,
    };
  }

  /// Standard payout: 60 / 25 / 15
  static const standard = GroupPayoutStructure();

  /// Winner-heavy: 70 / 20 / 10
  static const winnerHeavy = GroupPayoutStructure(
    firstPercent: 0.70,
    secondPercent: 0.20,
    thirdPercent: 0.10,
  );

  /// Flat-ish: 50 / 30 / 20
  static const flat = GroupPayoutStructure(
    firstPercent: 0.50,
    secondPercent: 0.30,
    thirdPercent: 0.20,
  );
}

// Stake options
class StakeOption {
  final double amount;
  final double prize;      // Prize for 1v1 (3% fee)
  final double groupPrize; // Prize for groups (5% fee)
  final double fee;        // Fee for 1v1
  final double groupFee;   // Fee for groups

  const StakeOption({
    required this.amount,
    required this.prize,
    required this.groupPrize,
    required this.fee,
    required this.groupFee,
  });

  String get displayAmount => amount == 0 ? 'Free' : '\$${amount.toInt()}';
  String get displayPrize => prize == 0 ? 'Free' : '\$${prize.toInt()}';
  String get displayGroupPrize => groupPrize == 0 ? 'Free' : '\$${groupPrize.toInt()}';

  // Calculate prize based on challenge type (3% for 1v1, 5% for groups)
  double getPrizeForType(ChallengeType type) {
    return type == ChallengeType.headToHead ? prize : groupPrize;
  }

  double getFeeForType(ChallengeType type) {
    return type == ChallengeType.headToHead ? fee : groupFee;
  }

  bool get isCustom => amount == -1;

  /// Create a custom stake option from user-entered amount
  static StakeOption custom(double amount) {
    final totalPot = amount * 2;
    final h2hFee = totalPot * 0.03;
    final groupFee = totalPot * 0.05;
    return StakeOption(
      amount: amount,
      prize: totalPot - h2hFee,
      groupPrize: totalPot - groupFee,
      fee: h2hFee,
      groupFee: groupFee,
    );
  }

  static const List<StakeOption> options = [
    StakeOption(amount: 0, prize: 0, groupPrize: 0, fee: 0, groupFee: 0),
    StakeOption(amount: 10, prize: 19.40, groupPrize: 19.00, fee: 0.60, groupFee: 1.00),
    StakeOption(amount: 25, prize: 48.50, groupPrize: 47.50, fee: 1.50, groupFee: 2.50),
    StakeOption(amount: 50, prize: 97.00, groupPrize: 95.00, fee: 3.00, groupFee: 5.00),
    StakeOption(amount: 100, prize: 194.00, groupPrize: 190.00, fee: 6.00, groupFee: 10.00),
    // Custom placeholder — triggers input dialog
    StakeOption(amount: -1, prize: 0, groupPrize: 0, fee: 0, groupFee: 0),
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
      case GoalType.steps:
        return 'Steps';
      case GoalType.distance:
        return 'Distance';
      case GoalType.milePace:
        return 'Mile Pace';
      case GoalType.fiveKPace:
        return '5K Pace';
      case GoalType.tenKPace:
        return '10K Pace';
      case GoalType.sleepDuration:
        return 'Sleep Duration';
      case GoalType.vo2Max:
        return 'VO2 Max';
      case GoalType.rivlHealthScore:
        return 'RIVL Health Score';
    }
  }

  String get description {
    switch (this) {
      case GoalType.steps:
        return 'Total step count over challenge period';
      case GoalType.distance:
        return 'Total miles walked or run';
      case GoalType.milePace:
        return 'Average mile time improvement';
      case GoalType.fiveKPace:
        return 'Best 5K completion time';
      case GoalType.tenKPace:
        return 'Best 10K completion time';
      case GoalType.sleepDuration:
        return 'Total hours of quality sleep';
      case GoalType.vo2Max:
        return 'Cardiovascular fitness level';
      case GoalType.rivlHealthScore:
        return 'Overall health combining steps, distance, sleep, heart rate, HRV & VO2 max';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalType.steps:
        return Icons.directions_walk;
      case GoalType.distance:
        return Icons.straighten;
      case GoalType.milePace:
        return Icons.timer_outlined;
      case GoalType.fiveKPace:
        return Icons.speed;
      case GoalType.tenKPace:
        return Icons.speed;
      case GoalType.sleepDuration:
        return Icons.bedtime_outlined;
      case GoalType.vo2Max:
        return Icons.favorite_outline;
      case GoalType.rivlHealthScore:
        return Icons.shield;
    }
  }

  bool get isAvailable {
    // All challenge types are now available
    return true;
  }

  /// Short unit label for displaying progress values
  String get unit {
    switch (this) {
      case GoalType.steps:
        return 'steps';
      case GoalType.distance:
        return 'mi';
      case GoalType.milePace:
        return 'min/mi';
      case GoalType.fiveKPace:
        return 'min';
      case GoalType.tenKPace:
        return 'min';
      case GoalType.sleepDuration:
        return 'hrs';
      case GoalType.vo2Max:
        return 'mL/kg/min';
      case GoalType.rivlHealthScore:
        return 'pts';
    }
  }

  /// Whether higher progress value means winning (false for pace: lower = faster)
  bool get higherIsBetter {
    switch (this) {
      case GoalType.milePace:
      case GoalType.fiveKPace:
      case GoalType.tenKPace:
        return false;
      default:
        return true;
    }
  }

  /// Format a raw progress int for display
  String formatProgress(int value) {
    switch (this) {
      case GoalType.steps:
        if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
        return '$value';
      case GoalType.distance:
        return '$value';
      case GoalType.milePace:
      case GoalType.fiveKPace:
      case GoalType.tenKPace:
        final mins = value ~/ 60;
        final secs = value % 60;
        return '$mins:${secs.toString().padLeft(2, '0')}';
      case GoalType.sleepDuration:
        final h = value ~/ 10;
        final decimal = value % 10;
        return '$h.${decimal}';
      case GoalType.vo2Max:
        final whole = value ~/ 10;
        final decimal = value % 10;
        return '$whole.${decimal}';
      case GoalType.rivlHealthScore:
        return '$value';
    }
  }
}
