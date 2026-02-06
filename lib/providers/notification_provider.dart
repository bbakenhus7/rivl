// providers/notification_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import 'dart:async';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadSubscription;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;

  /// Initialize notifications for a user
  Future<void> initialize(String userId) async {
    // Initialize push notifications
    await _notificationService.initialize(userId);

    // Listen to notification stream
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Notifications stream error: $e');
    });

    // Listen to unread count
    _unreadSubscription?.cancel();
    _unreadSubscription =
        _notificationService.unreadCountStream(userId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Unread count stream error: $e');
    });
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unread = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Mark all as read error: $e');
    }
  }

  /// Get icon for notification type
  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'challenge_invite':
        return Icons.local_fire_department;
      case 'challenge_accepted':
        return Icons.check_circle;
      case 'challenge_complete':
        return Icons.emoji_events;
      case 'challenge_update':
        return Icons.trending_up;
      case 'streak_reminder':
        return Icons.whatshot;
      case 'referral':
        return Icons.people;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  /// Get color for notification type
  Color getNotificationColor(String type) {
    switch (type) {
      case 'challenge_invite':
        return Colors.orange;
      case 'challenge_accepted':
        return Colors.green;
      case 'challenge_complete':
        return Colors.purple;
      case 'challenge_update':
        return Colors.blue;
      case 'streak_reminder':
        return Colors.red;
      case 'referral':
        return Colors.teal;
      case 'wallet':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadSubscription?.cancel();
    super.dispose();
  }
}
