// models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String username;
  final String? profileImageUrl;
  final String? phoneNumber;
  
  // Stats
  final int totalChallenges;
  final int wins;
  final int losses;
  final int draws;
  final double winRate;
  final int totalSteps;
  final double totalEarnings;
  final int currentStreak;
  final int longestStreak;

  // Battle Pass & XP
  final int currentXP;
  final int totalXP;
  final int battlePassLevel;
  final int coins;
  
  // Referral
  final String referralCode;
  final String? referredBy;
  final int referralCount;
  final double referralEarnings;
  
  // Personal Attributes
  final double? weightLbs;
  final double? heightInches;
  final int? pullUpsPR;
  final int? benchPressPR;
  final int? squatPR;

  // Settings
  final bool notificationsEnabled;
  final bool healthConnected;
  final String? fcmToken;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActiveAt;
  
  // Status
  final bool isVerified;
  final bool isPremium;
  final String accountStatus;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.username,
    this.profileImageUrl,
    this.phoneNumber,
    this.totalChallenges = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winRate = 0,
    this.totalSteps = 0,
    this.totalEarnings = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.currentXP = 0,
    this.totalXP = 0,
    this.battlePassLevel = 1,
    this.coins = 0,
    required this.referralCode,
    this.referredBy,
    this.referralCount = 0,
    this.referralEarnings = 0,
    this.weightLbs,
    this.heightInches,
    this.pullUpsPR,
    this.benchPressPR,
    this.squatPR,
    this.notificationsEnabled = true,
    this.healthConnected = false,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActiveAt,
    this.isVerified = false,
    this.isPremium = false,
    this.accountStatus = 'active',
  });

  double? get bmi {
    if (weightLbs == null || heightInches == null || heightInches == 0) return null;
    return (weightLbs! / (heightInches! * heightInches!) * 703);
  }

  String get winPercentage {
    if (totalChallenges == 0) return '0%';
    return '${(winRate * 100).toStringAsFixed(0)}%';
  }

  /// Demo user for preview mode when not authenticated
  factory UserModel.demo() {
    return UserModel(
      id: 'demo-user',
      email: 'demo@rivl.app',
      displayName: 'Demo User',
      username: 'demo_athlete',
      totalChallenges: 47,
      wins: 32,
      losses: 15,
      winRate: 0.68,
      totalSteps: 1250000,
      totalEarnings: 485.00,
      currentStreak: 7,
      longestStreak: 21,
      currentXP: 2450,
      totalXP: 12450,
      battlePassLevel: 12,
      coins: 850,
      referralCode: 'DEMO2024',
      referralCount: 5,
      referralEarnings: 10.00,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      isVerified: true,
      isPremium: false,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      username: data['username'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      phoneNumber: data['phoneNumber'],
      totalChallenges: data['totalChallenges'] ?? 0,
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      draws: data['draws'] ?? 0,
      winRate: (data['winRate'] ?? 0).toDouble(),
      totalSteps: data['totalSteps'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      currentXP: data['currentXP'] ?? 0,
      totalXP: data['totalXP'] ?? 0,
      battlePassLevel: data['battlePassLevel'] ?? 1,
      coins: data['coins'] ?? 0,
      referralCode: data['referralCode'] ?? '',
      referredBy: data['referredBy'],
      referralCount: data['referralCount'] ?? 0,
      referralEarnings: (data['referralEarnings'] ?? 0).toDouble(),
      weightLbs: (data['weightLbs'] as num?)?.toDouble(),
      heightInches: (data['heightInches'] as num?)?.toDouble(),
      pullUpsPR: (data['pullUpsPR'] as num?)?.toInt(),
      benchPressPR: (data['benchPressPR'] as num?)?.toInt(),
      squatPR: (data['squatPR'] as num?)?.toInt(),
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      healthConnected: data['healthConnected'] ?? false,
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      isPremium: data['isPremium'] ?? false,
      accountStatus: data['accountStatus'] ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'totalChallenges': totalChallenges,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'winRate': winRate,
      'totalSteps': totalSteps,
      'totalEarnings': totalEarnings,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'currentXP': currentXP,
      'totalXP': totalXP,
      'battlePassLevel': battlePassLevel,
      'coins': coins,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralCount': referralCount,
      'referralEarnings': referralEarnings,
      'weightLbs': weightLbs,
      'heightInches': heightInches,
      'pullUpsPR': pullUpsPR,
      'benchPressPR': benchPressPR,
      'squatPR': squatPR,
      'notificationsEnabled': notificationsEnabled,
      'healthConnected': healthConnected,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'isVerified': isVerified,
      'isPremium': isPremium,
      'accountStatus': accountStatus,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? username,
    String? profileImageUrl,
    String? phoneNumber,
    int? totalChallenges,
    int? wins,
    int? losses,
    int? draws,
    double? winRate,
    int? totalSteps,
    double? totalEarnings,
    int? currentStreak,
    int? longestStreak,
    double? weightLbs,
    double? heightInches,
    int? pullUpsPR,
    int? benchPressPR,
    int? squatPR,
    int? currentXP,
    int? totalXP,
    int? battlePassLevel,
    int? coins,
    int? referralCount,
    double? referralEarnings,
    bool? notificationsEnabled,
    bool? healthConnected,
    String? fcmToken,
    bool? isVerified,
    bool? isPremium,
    String? accountStatus,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      totalChallenges: totalChallenges ?? this.totalChallenges,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      winRate: winRate ?? this.winRate,
      totalSteps: totalSteps ?? this.totalSteps,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      currentXP: currentXP ?? this.currentXP,
      totalXP: totalXP ?? this.totalXP,
      battlePassLevel: battlePassLevel ?? this.battlePassLevel,
      coins: coins ?? this.coins,
      referralCode: referralCode,
      referredBy: referredBy,
      referralCount: referralCount ?? this.referralCount,
      referralEarnings: referralEarnings ?? this.referralEarnings,
      weightLbs: weightLbs ?? this.weightLbs,
      heightInches: heightInches ?? this.heightInches,
      pullUpsPR: pullUpsPR ?? this.pullUpsPR,
      benchPressPR: benchPressPR ?? this.benchPressPR,
      squatPR: squatPR ?? this.squatPR,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      healthConnected: healthConnected ?? this.healthConnected,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }
}
