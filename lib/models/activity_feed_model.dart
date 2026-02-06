// models/activity_feed_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  challengeWon,
  challengeLost,
  challengeCreated,
  challengeAccepted,
  streakMilestone,
  joinedApp,
  levelUp,
}

class ActivityFeedItem {
  final String id;
  final String userId;
  final String username;
  final String displayName;
  final ActivityType type;
  final String message;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  ActivityFeedItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.type,
    required this.message,
    this.data = const {},
    required this.createdAt,
  });

  IconData get icon {
    switch (type) {
      case ActivityType.challengeWon:
        return Icons.emoji_events;
      case ActivityType.challengeLost:
        return Icons.sports;
      case ActivityType.challengeCreated:
        return Icons.add_circle;
      case ActivityType.challengeAccepted:
        return Icons.handshake;
      case ActivityType.streakMilestone:
        return Icons.whatshot;
      case ActivityType.joinedApp:
        return Icons.person_add;
      case ActivityType.levelUp:
        return Icons.arrow_upward;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.challengeWon:
        return Colors.amber;
      case ActivityType.challengeLost:
        return Colors.grey;
      case ActivityType.challengeCreated:
        return Colors.blue;
      case ActivityType.challengeAccepted:
        return Colors.green;
      case ActivityType.streakMilestone:
        return Colors.red;
      case ActivityType.joinedApp:
        return Colors.teal;
      case ActivityType.levelUp:
        return Colors.purple;
    }
  }

  bool get hasChallenge =>
      data.containsKey('challengeId') && data['challengeId'] != null;

  String? get challengeId => data['challengeId'] as String?;
  double? get amount => (data['amount'] as num?)?.toDouble();
  String? get opponentName => data['opponentName'] as String?;

  factory ActivityFeedItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityFeedItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.joinedApp,
      ),
      message: data['message'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'type': type.name,
      'message': message,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
