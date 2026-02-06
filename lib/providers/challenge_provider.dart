// providers/challenge_provider.dart

import 'package:flutter/material.dart';
import '../models/challenge_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/health_service.dart';
import 'dart:async';

class ChallengeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final HealthService _healthService = HealthService();

  List<ChallengeModel> _challenges = [];
  List<Map<String, dynamic>> _leaderboard = [];
  List<UserModel> _searchResults = [];
  
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isSyncing = false;
  bool _isSearching = false;
  String? _errorMessage;
  String? _successMessage;

  // Create challenge form state
  UserModel? _selectedOpponent;
  StakeOption _selectedStake = StakeOption.options[2]; // $25 default
  ChallengeDuration _selectedDuration = ChallengeDuration.oneWeek;
  GoalType _selectedGoalType = GoalType.steps;

  StreamSubscription? _challengesSubscription;

  // Getters
  List<ChallengeModel> get challenges => _challenges;
  List<ChallengeModel> get activeChallenges => 
      _challenges.where((c) => c.status == ChallengeStatus.active || c.status == ChallengeStatus.accepted).toList();
  List<ChallengeModel> get pendingChallenges => 
      _challenges.where((c) => c.status == ChallengeStatus.pending).toList();
  List<ChallengeModel> get completedChallenges => 
      _challenges.where((c) => c.status == ChallengeStatus.completed).toList();
  
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  List<UserModel> get searchResults => _searchResults;
  
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isSyncing => _isSyncing;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  UserModel? get selectedOpponent => _selectedOpponent;
  StakeOption get selectedStake => _selectedStake;
  ChallengeDuration get selectedDuration => _selectedDuration;
  GoalType get selectedGoalType => _selectedGoalType;

  int get pendingCount => pendingChallenges.length;
  bool get hasActiveChallenges => activeChallenges.isNotEmpty;
  bool get hasPendingChallenges => pendingChallenges.isNotEmpty;

  // ============================================
  // INITIALIZATION
  // ============================================

  void startListening(String userId) {
    _challengesSubscription?.cancel();
    _challengesSubscription = _firebaseService.userChallengesStream(userId).listen(
      (challenges) {
        _challenges = challenges;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load challenges';
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _challengesSubscription?.cancel();
  }

  // ============================================
  // CREATE CHALLENGE
  // ============================================

  void setSelectedOpponent(UserModel? opponent) {
    _selectedOpponent = opponent;
    notifyListeners();
  }

  void setSelectedStake(StakeOption stake) {
    _selectedStake = stake;
    notifyListeners();
  }

  void setSelectedDuration(ChallengeDuration duration) {
    _selectedDuration = duration;
    notifyListeners();
  }

  void setSelectedGoalType(GoalType goalType) {
    _selectedGoalType = goalType;
    notifyListeners();
  }

  int get suggestedGoalValue {
    switch (_selectedGoalType) {
      case GoalType.steps:
        return _selectedDuration.days * 10000; // 10K steps per day
      case GoalType.distance:
        return _selectedDuration.days * 5; // 5 miles per day
      case GoalType.milePace:
        return 8; // Target 8 min/mile pace
      case GoalType.fiveKPace:
        return 25; // Target 25 min 5K time
      case GoalType.sleepDuration:
        return _selectedDuration.days * 8; // 8 hours per night
      case GoalType.vo2Max:
        return 45; // Target VO2 max of 45
      case GoalType.rivlHealthScore:
        return 75; // Target average RIVL Health Score of 75/100
    }
  }

  Future<String?> createChallenge() async {
    if (_selectedOpponent == null) {
      _errorMessage = 'Please select an opponent';
      notifyListeners();
      return null;
    }

    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final challengeId = await _firebaseService.createChallenge(
        opponentId: _selectedOpponent!.id,
        opponentName: _selectedOpponent!.displayName,
        type: ChallengeType.headToHead,
        goalType: _selectedGoalType,
        goalValue: suggestedGoalValue,
        duration: _selectedDuration,
        stakeAmount: _selectedStake.amount,
      );

      _successMessage = 'Challenge sent to ${_selectedOpponent!.displayName}!';
      resetCreateForm();
      
      _isCreating = false;
      notifyListeners();
      return challengeId;
    } catch (e) {
      _isCreating = false;
      _errorMessage = 'Failed to create challenge. Please try again.';
      notifyListeners();
      return null;
    }
  }

  void resetCreateForm() {
    _selectedOpponent = null;
    _selectedStake = StakeOption.options[2];
    _selectedDuration = ChallengeDuration.oneWeek;
    _selectedGoalType = GoalType.steps;
    notifyListeners();
  }

  // ============================================
  // CHALLENGE ACTIONS
  // ============================================

  Future<bool> acceptChallenge(String challengeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.acceptChallenge(challengeId);
      _successMessage = 'Challenge accepted! Good luck!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to accept challenge';
      notifyListeners();
      return false;
    }
  }

  Future<bool> declineChallenge(String challengeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.declineChallenge(challengeId);
      _successMessage = 'Challenge declined';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to decline challenge';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // STEP SYNCING
  // ============================================

  Future<bool> syncSteps(ChallengeModel challenge) async {
    if (challenge.startDate == null) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final stepHistory = await _healthService.getStepsForChallenge(
        challenge.startDate!,
        challenge.endDate ?? DateTime.now(),
      );

      final totalSteps = stepHistory.fold<int>(0, (sum, day) => sum + day.steps);

      await _firebaseService.syncSteps(
        challengeId: challenge.id,
        steps: totalSteps,
        stepHistory: stepHistory,
      );

      _isSyncing = false;
      _successMessage = 'Steps synced successfully';
      notifyListeners();
      return true;
    } catch (e) {
      _isSyncing = false;
      _errorMessage = 'Failed to sync steps';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // SEARCH
  // ============================================

  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _firebaseService.searchUsers(query);
    } catch (e) {
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // ============================================
  // LEADERBOARD
  // ============================================

  Future<void> fetchLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      _leaderboard = await _firebaseService.getLeaderboard();
    } catch (e) {
      _leaderboard = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============================================
  // HELPERS
  // ============================================

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _challengesSubscription?.cancel();
    super.dispose();
  }
}
