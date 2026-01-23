// models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  challengeInvite,
  challengeAccepted,
  challengeStarted,
  challengeEnding,
  challengeEnded,
  challengeWon,
  challengeLost,
  paymentReceived,
  friendRequest,
  newAchievement,
  dailyReminder,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? challengeId;
  final String? relatedUserId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.challengeId,
    this.relatedUserId,
    this.isRead = false,
    required this.createdAt,
  });

  String get emoji {
    switch (type) {
      case NotificationType.challengeInvite:
        return '📨';
      case NotificationType.challengeAccepted:
        return '✅';
      case NotificationType.challengeStarted:
        return '🏁';
      case NotificationType.challengeEnding:
        return '⏰';
      case NotificationType.challengeEnded:
        return '🏁';
      case NotificationType.challengeWon:
        return '🏆';
      case NotificationType.challengeLost:
        return '😔';
      case NotificationType.paymentReceived:
        return '💰';
      case NotificationType.friendRequest:
        return '👋';
      case NotificationType.newAchievement:
        return '🎉';
      case NotificationType.dailyReminder:
        return '📱';
    }
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.dailyReminder,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      challengeId: data['challengeId'],
      relatedUserId: data['relatedUserId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'challengeId': challengeId,
      'relatedUserId': relatedUserId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
