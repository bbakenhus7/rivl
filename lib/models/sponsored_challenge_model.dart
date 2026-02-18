// models/sponsored_challenge_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'challenge_model.dart';

enum SponsorTier { bronze, silver, gold, platinum }

class SponsoredChallengeModel {
  final String id;
  final String sponsorId;
  final String sponsorName;
  final String sponsorLogoUrl;
  final String title;
  final String description;

  // Challenge Configuration
  final GoalType goalType;
  final int goalValue;
  final ChallengeDuration duration;
  final int maxParticipants;
  final int currentParticipants;

  // Prize & Rewards
  final double prizePool;
  final String prizeDescription;
  final List<String> prizeBreakdown; // ["1st: $500", "2nd: $300", etc.]

  // Sponsor Details
  final SponsorTier tier;
  final String brandColor;
  final String callToAction;
  final String? couponCode;

  // Status
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? registrationDeadline;

  // Requirements
  final bool requiresPremium;
  final int minChallengesCompleted;
  final double minWinRate;

  // Analytics
  final int views;
  final int registrations;
  final int completions;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  SponsoredChallengeModel({
    required this.id,
    required this.sponsorId,
    required this.sponsorName,
    required this.sponsorLogoUrl,
    required this.title,
    required this.description,
    required this.goalType,
    required this.goalValue,
    required this.duration,
    required this.maxParticipants,
    this.currentParticipants = 0,
    required this.prizePool,
    required this.prizeDescription,
    this.prizeBreakdown = const [],
    required this.tier,
    this.brandColor = '#FF6B35',
    this.callToAction = 'Join Challenge',
    this.couponCode,
    this.isActive = true,
    required this.startDate,
    required this.endDate,
    this.registrationDeadline,
    this.requiresPremium = false,
    this.minChallengesCompleted = 0,
    this.minWinRate = 0.0,
    this.views = 0,
    this.registrations = 0,
    this.completions = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFull => currentParticipants >= maxParticipants;
  bool get canRegister => isActive && !isFull &&
    (registrationDeadline == null || DateTime.now().isBefore(registrationDeadline!));

  factory SponsoredChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return SponsoredChallengeModel(
      id: doc.id,
      sponsorId: data['sponsorId'] ?? '',
      sponsorName: data['sponsorName'] ?? '',
      sponsorLogoUrl: data['sponsorLogoUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      goalType: GoalType.values.firstWhere(
        (e) => e.name == data['goalType'],
        orElse: () => GoalType.steps,
      ),
      goalValue: (data['goalValue'] as num? ?? 0).toInt(),
      duration: ChallengeDuration.values.firstWhere(
        (e) => e.name == data['duration'],
        orElse: () => ChallengeDuration.oneWeek,
      ),
      maxParticipants: (data['maxParticipants'] as num? ?? 100).toInt(),
      currentParticipants: (data['currentParticipants'] as num? ?? 0).toInt(),
      prizePool: (data['prizePool'] as num? ?? 0).toDouble(),
      prizeDescription: data['prizeDescription'] ?? '',
      prizeBreakdown: List<String>.from(data['prizeBreakdown'] ?? []),
      tier: SponsorTier.values.firstWhere(
        (e) => e.name == data['tier'],
        orElse: () => SponsorTier.bronze,
      ),
      brandColor: data['brandColor'] ?? '#FF6B35',
      callToAction: data['callToAction'] ?? 'Join Challenge',
      couponCode: data['couponCode'],
      isActive: data['isActive'] ?? true,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      registrationDeadline: (data['registrationDeadline'] as Timestamp?)?.toDate(),
      requiresPremium: data['requiresPremium'] ?? false,
      minChallengesCompleted: (data['minChallengesCompleted'] as num? ?? 0).toInt(),
      minWinRate: (data['minWinRate'] as num? ?? 0).toDouble(),
      views: (data['views'] as num? ?? 0).toInt(),
      registrations: (data['registrations'] as num? ?? 0).toInt(),
      completions: (data['completions'] as num? ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sponsorId': sponsorId,
      'sponsorName': sponsorName,
      'sponsorLogoUrl': sponsorLogoUrl,
      'title': title,
      'description': description,
      'goalType': goalType.name,
      'goalValue': goalValue,
      'duration': duration.name,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'prizePool': prizePool,
      'prizeDescription': prizeDescription,
      'prizeBreakdown': prizeBreakdown,
      'tier': tier.name,
      'brandColor': brandColor,
      'callToAction': callToAction,
      'couponCode': couponCode,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'registrationDeadline': registrationDeadline != null
        ? Timestamp.fromDate(registrationDeadline!)
        : null,
      'requiresPremium': requiresPremium,
      'minChallengesCompleted': minChallengesCompleted,
      'minWinRate': minWinRate,
      'views': views,
      'registrations': registrations,
      'completions': completions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

extension SponsorTierExtension on SponsorTier {
  String get displayName {
    switch (this) {
      case SponsorTier.bronze:
        return 'Bronze';
      case SponsorTier.silver:
        return 'Silver';
      case SponsorTier.gold:
        return 'Gold';
      case SponsorTier.platinum:
        return 'Platinum';
    }
  }

  String get badgeEmoji {
    switch (this) {
      case SponsorTier.bronze:
        return '🥉';
      case SponsorTier.silver:
        return '🥈';
      case SponsorTier.gold:
        return '🥇';
      case SponsorTier.platinum:
        return '💎';
    }
  }
}
