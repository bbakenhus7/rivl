// providers/friend_provider.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/firebase_service.dart';

class FriendProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool _disposed = false;

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  Set<String> _friendIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _friendsSubscription;
  StreamSubscription? _requestsSubscription;

  List<Map<String, dynamic>> get friends => _friends;
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;
  Set<String> get friendIds => _friendIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Whether the given userId is a friend of the current user.
  bool isFriend(String userId) => _friendIds.contains(userId);

  /// Start listening to friends and friend requests.
  void startListening(String userId) {
    _friendsSubscription?.cancel();
    _requestsSubscription?.cancel();

    _friendsSubscription = _firebaseService.friendsStream(userId).listen(
      (friends) {
        _friends = friends;
        _friendIds = friends
            .map((f) => f['userId'] as String?)
            .whereType<String>()
            .toSet();
        _safeNotify();
      },
      onError: (e) {
        debugPrint('Friends stream error: $e');
      },
    );

    _requestsSubscription =
        _firebaseService.pendingFriendRequestsStream(userId).listen(
      (requests) {
        _pendingRequests = requests;
        _safeNotify();
      },
      onError: (e) {
        debugPrint('Friend requests stream error: $e');
      },
    );
  }

  /// Send a friend request.
  Future<bool> sendFriendRequest({
    required String receiverId,
    required String receiverName,
    required String receiverUsername,
  }) async {
    if (_isLoading) return false; // Guard against double-tap
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await _firebaseService.sendFriendRequest(
        receiverId: receiverId,
        receiverName: receiverName,
        receiverUsername: receiverUsername,
      );
      _safeNotify();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _safeNotify();
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Accept a friend request.
  Future<bool> acceptFriendRequest(String requestId) async {
    if (_isLoading) return false; // Guard against double-tap
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await _firebaseService.acceptFriendRequest(requestId);
      _safeNotify();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _safeNotify();
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Decline a friend request.
  Future<bool> declineFriendRequest(String requestId) async {
    if (_isLoading) return false; // Guard against double-tap
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await _firebaseService.declineFriendRequest(requestId);
      _safeNotify();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _safeNotify();
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Remove a friend.
  Future<bool> removeFriend(String friendId) async {
    if (_isLoading) return false; // Guard against double-tap
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await _firebaseService.removeFriend(friendId);
      _safeNotify();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _safeNotify();
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Load friend IDs (one-shot, for initialization).
  Future<void> loadFriendIds() async {
    try {
      _friendIds = await _firebaseService.getFriendIds();
      _safeNotify();
    } catch (e) {
      debugPrint('Error loading friend IDs: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _friendsSubscription?.cancel();
    _requestsSubscription?.cancel();
    super.dispose();
  }
}
