// providers/notification_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import 'dart:async';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  static const int _pageSize = 20;

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _userId;
  DocumentSnapshot? _lastDocument;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadSubscription;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// Initialize notifications for a user (loads first page)
  Future<void> initialize(String userId) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    // Initialize push notifications
    await _notificationService.initialize(userId);

    // Listen to first page of notifications via stream
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length >= _pageSize;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      notifyListeners();
    });

    // Listen to unread count
    _unreadSubscription?.cancel();
    _unreadSubscription =
        _notificationService.unreadCountStream(userId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    }, onError: (e) {
      // Unread count stream error — count may be stale
    });
  }

  /// Load next page of notifications
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _userId == null || _lastDocument == null) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      final newItems = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();

      _notifications.addAll(newItems);
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDocument;
      _hasMore = snapshot.docs.length >= _pageSize;
    } catch (e) {
      // Load more error — pagination stopped
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      // Mark as read error — notification may still appear unread
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
      // Mark all as read error — some may still appear unread
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
