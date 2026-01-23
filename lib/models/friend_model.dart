// models/friend_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendshipStatus {
  pending,
  accepted,
  declined,
  blocked,
}

class FriendModel {
  final String id;
  final String userId;
  final String friendId;
  final String friendName;
  final String friendUsername;
  final FriendshipStatus status;
  final int challengesTogether;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  FriendModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendName,
    required this.friendUsername,
    required this.status,
    this.challengesTogether = 0,
    required this.createdAt,
    this.acceptedAt,
  });

  bool get isActive => status == FriendshipStatus.accepted;

  factory FriendModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FriendModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      friendId: data['friendId'] ?? '',
      friendName: data['friendName'] ?? '',
      friendUsername: data['friendUsername'] ?? '',
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      challengesTogether: data['challengesTogether'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'friendId': friendId,
      'friendName': friendName,
      'friendUsername': friendUsername,
      'status': status.name,
      'challengesTogether': challengesTogether,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    };
  }
}
