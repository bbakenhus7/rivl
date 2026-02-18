// providers/subscription_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';

class SubscriptionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _disposed = false;

  SubscriptionModel? _subscription;
  bool _isLoading = false;
  String? _error;

  SubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _subscription?.isPremium ?? false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Load user's subscription
  Future<void> loadSubscription(String userId) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .get();

      if (doc.exists) {
        _subscription = SubscriptionModel.fromFirestore(doc);
      } else {
        // Create free subscription
        _subscription = SubscriptionModel.free(userId);
        await _saveSubscription(userId);
      }

      _isLoading = false;
      _safeNotify();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Upgrade to premium
  Future<bool> upgradeToPremium(String userId) async {
    try {
      _subscription = SubscriptionModel.premium(userId);
      await _saveSubscription(userId);

      // Also update user document
      await _firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _safeNotify();
      return true;
    } catch (e) {
      _error = e.toString();
      _safeNotify();
      return false;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String userId) async {
    if (_subscription == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .update({
        'status': 'cancelled',
        'cancelAtPeriodEnd': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _subscription = SubscriptionModel(
        id: _subscription!.id,
        userId: userId,
        plan: _subscription!.plan,
        status: SubscriptionStatus.cancelled,
        createdAt: _subscription!.createdAt,
        updatedAt: DateTime.now(),
      );

      _safeNotify();
      return true;
    } catch (e) {
      _error = e.toString();
      _safeNotify();
      return false;
    }
  }

  /// Check if user has access to a feature
  bool hasFeature(String feature) {
    if (_subscription == null) return false;

    switch (feature) {
      case 'unlimited_challenges':
        return _subscription!.unlimitedChallenges;
      case 'advanced_analytics':
        return _subscription!.advancedAnalytics;
      case 'ai_coaching':
        return _subscription!.aiCoaching;
      case 'sponsored_challenges':
        return _subscription!.sponsoredChallengesAccess;
      case 'custom_challenges':
        return _subscription!.customChallenges;
      case 'no_ads':
        return _subscription!.noAds;
      default:
        return false;
    }
  }

  /// Get max stake amount for user
  int getMaxStakeAmount() {
    return _subscription?.maxStakeAmount ?? 50;
  }

  Future<void> _saveSubscription(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .set(_subscription!.toFirestore());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
