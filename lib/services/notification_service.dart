// services/notification_service.dart

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Track subscriptions to prevent leaks on re-initialization
  StreamSubscription? _tokenRefreshSubscription;
  StreamSubscription? _foregroundMessageSubscription;
  StreamSubscription? _messageOpenedSubscription;

  /// Initialize push notifications
  Future<void> initialize(String userId) async {
    if (kIsWeb) {
      // Web doesn't support FCM in the same way
      return;
    }

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _fcmToken = await _messaging.getToken();

        if (_fcmToken != null) {
          // Save token to user document
          await _db.collection('users').doc(userId).update({
            'fcmToken': _fcmToken,
            'notificationsEnabled': true,
          });
        }

        // Cancel previous subscriptions to prevent leaks on re-init
        await _tokenRefreshSubscription?.cancel();
        await _foregroundMessageSubscription?.cancel();
        await _messageOpenedSubscription?.cancel();

        // Listen for token refresh
        _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) async {
          _fcmToken = newToken;
          await _db.collection('users').doc(userId).update({
            'fcmToken': newToken,
          });
        });

        // Handle foreground messages
        _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background/terminated message taps
        _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

        // Check if app was opened from a notification
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageTap(initialMessage);
        }
      }
    } catch (e) {
      // Notification initialization error — push notifications unavailable
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Foreground messages appear in the system tray on most platforms
    // In-app banner handling can be added here if needed
  }

  void _handleMessageTap(RemoteMessage message) {
    // Navigate to relevant screen based on message data
    // e.g., message.data['challengeId'] -> navigate to challenge detail
    // TODO: implement deep link navigation from notification tap
  }

  /// Subscribe to topic-based notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      // Topic subscription error — silently ignored
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      // Topic unsubscription error — silently ignored
    }
  }

  /// Send a local notification to a user (stored in Firestore, triggers cloud function)
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data ?? {},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get unread notification count
  Stream<int> unreadCountStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Send engagement notifications (called from streak/challenge logic)
  Future<void> sendStreakReminder(String userId, int currentStreak) async {
    await sendNotification(
      userId: userId,
      type: 'streak_reminder',
      title: 'Keep your streak alive!',
      body: 'You have a $currentStreak day streak. Open RIVL to keep it going!',
      data: {'action': 'claim_streak'},
    );
  }

  Future<void> sendChallengeUpdate(
      String userId, String challengeId, String opponentName, int opponentSteps) async {
    await sendNotification(
      userId: userId,
      type: 'challenge_update',
      title: 'Your opponent is moving!',
      body: '$opponentName just logged $opponentSteps steps today. Time to step up!',
      data: {'challengeId': challengeId, 'action': 'view_challenge'},
    );
  }

  Future<void> sendChallengeComplete(
      String userId, String challengeId, bool won, double amount) async {
    await sendNotification(
      userId: userId,
      type: 'challenge_complete',
      title: won ? 'You won!' : 'Challenge complete',
      body: won
          ? 'You won \$${amount.toStringAsFixed(0)}! Start a new challenge?'
          : 'Better luck next time. Rematch?',
      data: {'challengeId': challengeId, 'action': won ? 'celebrate' : 'rematch'},
    );
  }
}
