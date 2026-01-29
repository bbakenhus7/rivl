// models/subscription_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlan { free, premium }

enum SubscriptionStatus { active, cancelled, expired, trial }

class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;

  // Pricing
  final double monthlyPrice;
  final double? annualPrice;

  // Features
  final bool unlimitedChallenges;
  final bool advancedAnalytics;
  final bool prioritySupport;
  final bool customChallenges;
  final bool noAds;
  final bool sponsoredChallengesAccess;
  final bool aiCoaching;
  final int maxStakeAmount;

  // Billing
  final String? stripeSubscriptionId;
  final String? stripeCustomerId;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEnd;
  final bool cancelAtPeriodEnd;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    this.monthlyPrice = 9.99,
    this.annualPrice = 99.99,
    this.unlimitedChallenges = false,
    this.advancedAnalytics = false,
    this.prioritySupport = false,
    this.customChallenges = false,
    this.noAds = false,
    this.sponsoredChallengesAccess = false,
    this.aiCoaching = false,
    this.maxStakeAmount = 50,
    this.stripeSubscriptionId,
    this.stripeCustomerId,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialEnd,
    this.cancelAtPeriodEnd = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.trial;
  bool get isPremium => plan == SubscriptionPlan.premium && isActive;
  bool get isTrial => status == SubscriptionStatus.trial;

  factory SubscriptionModel.free(String userId) {
    final now = DateTime.now();
    return SubscriptionModel(
      id: 'free_$userId',
      userId: userId,
      plan: SubscriptionPlan.free,
      status: SubscriptionStatus.active,
      monthlyPrice: 0,
      unlimitedChallenges: false,
      advancedAnalytics: false,
      prioritySupport: false,
      customChallenges: false,
      noAds: false,
      sponsoredChallengesAccess: false,
      aiCoaching: false,
      maxStakeAmount: 50,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory SubscriptionModel.premium(String userId) {
    final now = DateTime.now();
    return SubscriptionModel(
      id: 'premium_$userId',
      userId: userId,
      plan: SubscriptionPlan.premium,
      status: SubscriptionStatus.active,
      monthlyPrice: 9.99,
      annualPrice: 99.99,
      unlimitedChallenges: true,
      advancedAnalytics: true,
      prioritySupport: true,
      customChallenges: true,
      noAds: true,
      sponsoredChallengesAccess: true,
      aiCoaching: true,
      maxStakeAmount: 100,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == data['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      monthlyPrice: (data['monthlyPrice'] ?? 9.99).toDouble(),
      annualPrice: data['annualPrice'] != null
        ? (data['annualPrice'] as num).toDouble()
        : null,
      unlimitedChallenges: data['unlimitedChallenges'] ?? false,
      advancedAnalytics: data['advancedAnalytics'] ?? false,
      prioritySupport: data['prioritySupport'] ?? false,
      customChallenges: data['customChallenges'] ?? false,
      noAds: data['noAds'] ?? false,
      sponsoredChallengesAccess: data['sponsoredChallengesAccess'] ?? false,
      aiCoaching: data['aiCoaching'] ?? false,
      maxStakeAmount: data['maxStakeAmount'] ?? 50,
      stripeSubscriptionId: data['stripeSubscriptionId'],
      stripeCustomerId: data['stripeCustomerId'],
      currentPeriodStart: (data['currentPeriodStart'] as Timestamp?)?.toDate(),
      currentPeriodEnd: (data['currentPeriodEnd'] as Timestamp?)?.toDate(),
      trialEnd: (data['trialEnd'] as Timestamp?)?.toDate(),
      cancelAtPeriodEnd: data['cancelAtPeriodEnd'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'plan': plan.name,
      'status': status.name,
      'monthlyPrice': monthlyPrice,
      'annualPrice': annualPrice,
      'unlimitedChallenges': unlimitedChallenges,
      'advancedAnalytics': advancedAnalytics,
      'prioritySupport': prioritySupport,
      'customChallenges': customChallenges,
      'noAds': noAds,
      'sponsoredChallengesAccess': sponsoredChallengesAccess,
      'aiCoaching': aiCoaching,
      'maxStakeAmount': maxStakeAmount,
      'stripeSubscriptionId': stripeSubscriptionId,
      'stripeCustomerId': stripeCustomerId,
      'currentPeriodStart': currentPeriodStart != null
        ? Timestamp.fromDate(currentPeriodStart!)
        : null,
      'currentPeriodEnd': currentPeriodEnd != null
        ? Timestamp.fromDate(currentPeriodEnd!)
        : null,
      'trialEnd': trialEnd != null ? Timestamp.fromDate(trialEnd!) : null,
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class PremiumFeature {
  final String title;
  final String description;
  final String icon;

  const PremiumFeature({
    required this.title,
    required this.description,
    required this.icon,
  });

  static const List<PremiumFeature> features = [
    PremiumFeature(
      title: 'Unlimited Challenges',
      description: 'Create and join unlimited challenges per month',
      icon: '♾️',
    ),
    PremiumFeature(
      title: 'Advanced Analytics',
      description: 'Detailed performance insights and trend analysis',
      icon: '📊',
    ),
    PremiumFeature(
      title: 'AI Coaching',
      description: 'Personalized AI-powered training recommendations',
      icon: '🤖',
    ),
    PremiumFeature(
      title: 'Priority Support',
      description: '24/7 priority customer support',
      icon: '⚡',
    ),
    PremiumFeature(
      title: 'Custom Challenges',
      description: 'Create custom challenge types and rules',
      icon: '🎯',
    ),
    PremiumFeature(
      title: 'No Ads',
      description: 'Ad-free experience across the app',
      icon: '🚫',
    ),
    PremiumFeature(
      title: 'Sponsored Challenges',
      description: 'Access to exclusive brand-sponsored competitions',
      icon: '🏆',
    ),
    PremiumFeature(
      title: 'Higher Stakes',
      description: 'Challenge with up to \$100 (vs \$50 for free)',
      icon: '💰',
    ),
  ];
}
