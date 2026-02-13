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

  /// Callback invoked when the user earns XP from challenge activity.
  /// Set this from the widget tree where BattlePassProvider is accessible.
  void Function(int xp, String source)? onXPEarned;

  List<ChallengeModel> _challenges = [];
  List<Map<String, dynamic>> _leaderboard = [];
  List<UserModel> _searchResults = [];
  List<UserModel> _demoOpponents = [];
  
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
  List<UserModel> get demoOpponents => _demoOpponents;
  
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

  /// Load demo challenges for unauthenticated users
  void loadDemoChallenges() {
    if (_challenges.isNotEmpty) return;

    final now = DateTime.now();
    _challenges = [
      // Active: Steps challenge - you're winning
      ChallengeModel(
        id: 'demo-1',
        creatorId: 'demo-user',
        opponentId: 'demo-opponent-1',
        creatorName: 'You',
        opponentName: 'Jake M.',
        type: ChallengeType.headToHead,
        status: ChallengeStatus.active,
        stakeAmount: 25,
        totalPot: 50,
        prizeAmount: 48.50,
        goalType: GoalType.steps,
        goalValue: 70000,
        duration: ChallengeDuration.oneWeek,
        startDate: now.subtract(const Duration(days: 4)),
        endDate: now.add(const Duration(days: 3)),
        creatorProgress: 45200,
        opponentProgress: 38700,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now,
      ),
      // Active: Distance challenge - close race
      ChallengeModel(
        id: 'demo-2',
        creatorId: 'demo-user',
        opponentId: 'demo-opponent-2',
        creatorName: 'You',
        opponentName: 'Sarah K.',
        type: ChallengeType.headToHead,
        status: ChallengeStatus.active,
        stakeAmount: 50,
        totalPot: 100,
        prizeAmount: 97.00,
        goalType: GoalType.distance,
        goalValue: 35,
        duration: ChallengeDuration.oneWeek,
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 2)),
        creatorProgress: 22,
        opponentProgress: 24,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
      // Active: RIVL Health Score
      ChallengeModel(
        id: 'demo-3',
        creatorId: 'demo-user',
        opponentId: 'demo-opponent-3',
        creatorName: 'You',
        opponentName: 'Mike R.',
        type: ChallengeType.headToHead,
        status: ChallengeStatus.active,
        stakeAmount: 10,
        totalPot: 20,
        prizeAmount: 19.40,
        goalType: GoalType.rivlHealthScore,
        goalValue: 75,
        duration: ChallengeDuration.twoWeeks,
        startDate: now.subtract(const Duration(days: 6)),
        endDate: now.add(const Duration(days: 8)),
        creatorProgress: 68,
        opponentProgress: 61,
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now,
      ),
      // Pending: Incoming invite
      ChallengeModel(
        id: 'demo-4',
        creatorId: 'demo-opponent-4',
        opponentId: 'demo-user',
        creatorName: 'Alex T.',
        opponentName: 'You',
        type: ChallengeType.headToHead,
        status: ChallengeStatus.pending,
        stakeAmount: 25,
        totalPot: 50,
        prizeAmount: 48.50,
        goalType: GoalType.steps,
        goalValue: 100000,
        duration: ChallengeDuration.twoWeeks,
        creatorProgress: 0,
        opponentProgress: 0,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now,
      ),
      // Pending: Another invite
      ChallengeModel(
        id: 'demo-5',
        creatorId: 'demo-opponent-5',
        opponentId: 'demo-user',
        creatorName: 'Emma L.',
        opponentName: 'You',
        type: ChallengeType.headToHead,
        status: ChallengeStatus.pending,
        stakeAmount: 0,
        totalPot: 0,
        prizeAmount: 0,
        goalType: GoalType.sleepDuration,
        goalValue: 56,
        duration: ChallengeDuration.oneWeek,
        creatorProgress: 0,
        opponentProgress: 0,
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now,
      ),
      // Completed: Won
      ChallengeModel(
        id: 'demo-6',
        creatorId: 'demo-user',
        opponentId: 'demo-opponent-6',
        creatorName: 'You',
        opponentName: 'Chris B.',
        type: ChallengeType.headToHead,
        status: ChallengeStatus.completed,
        stakeAmount: 50,
        totalPot: 100,
        prizeAmount: 97.00,
        goalType: GoalType.steps,
        goalValue: 70000,
        duration: ChallengeDuration.oneWeek,
        startDate: now.subtract(const Duration(days: 14)),
        endDate: now.subtract(const Duration(days: 7)),
        creatorProgress: 78400,
        opponentProgress: 65200,
        winnerId: 'demo-user',
        winnerName: 'You',
        resultDeclaredAt: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      // Completed: Lost
      ChallengeModel(
        id: 'demo-7',
        creatorId: 'demo-user',
        opponentId: 'demo-opponent-7',
        creatorName: 'You',
        opponentName: 'Taylor W.',
        type: ChallengeType.headToHead,
        status: ChallengeStatus.completed,
        stakeAmount: 25,
        totalPot: 50,
        prizeAmount: 48.50,
        goalType: GoalType.fiveKPace,
        goalValue: 1500, // 25:00 in seconds
        duration: ChallengeDuration.oneWeek,
        startDate: now.subtract(const Duration(days: 21)),
        endDate: now.subtract(const Duration(days: 14)),
        creatorProgress: 1560, // 26:00
        opponentProgress: 1440, // 24:00
        winnerId: 'demo-opponent-7',
        winnerName: 'Taylor W.',
        resultDeclaredAt: now.subtract(const Duration(days: 14)),
        createdAt: now.subtract(const Duration(days: 21)),
        updatedAt: now.subtract(const Duration(days: 14)),
      ),
      // Active: VO2 Max challenge
      ChallengeModel(
        id: 'demo-8',
        creatorId: 'demo-user',
        opponentId: 'demo-opponent-8',
        creatorName: 'You',
        opponentName: 'Olivia P.',
        type: ChallengeType.headToHead,
        status: ChallengeStatus.active,
        stakeAmount: 10,
        totalPot: 20,
        prizeAmount: 19.40,
        goalType: GoalType.vo2Max,
        goalValue: 450, // 45.0 mL/kg/min
        duration: ChallengeDuration.oneMonth,
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 20)),
        creatorProgress: 422, // 42.2
        opponentProgress: 398, // 39.8
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
      // Active: Mile Pace challenge (lower is better)
      ChallengeModel(
        id: 'demo-9',
        creatorId: 'demo-user',
        opponentId: 'demo-opponent-9',
        creatorName: 'You',
        opponentName: 'Ryan C.',
        type: ChallengeType.headToHead,
        status: ChallengeStatus.active,
        stakeAmount: 25,
        totalPot: 50,
        prizeAmount: 48.50,
        goalType: GoalType.milePace,
        goalValue: 480, // Target: 8:00/mi
        duration: ChallengeDuration.twoWeeks,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 11)),
        creatorProgress: 462, // 7:42/mi
        opponentProgress: 498, // 8:18/mi
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
      ),
    ];
    notifyListeners();
  }

  /// Load demo opponents for the create challenge flow
  void loadDemoOpponents() {
    if (_demoOpponents.isNotEmpty) return;

    final now = DateTime.now();
    _demoOpponents = [
      UserModel(
        id: 'demo-opponent-jake',
        email: 'jake@rivl.app',
        displayName: 'Jake Morrison',
        username: 'jake_runs',
        totalChallenges: 28,
        wins: 18,
        losses: 10,
        winRate: 0.64,
        totalSteps: 890000,
        totalEarnings: 320.00,
        currentStreak: 5,
        longestStreak: 14,
        referralCode: 'JAKE2024',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now,
        lastActiveAt: now.subtract(const Duration(hours: 2)),
      ),
      UserModel(
        id: 'demo-opponent-sarah',
        email: 'sarah@rivl.app',
        displayName: 'Sarah Kim',
        username: 'sarah_fitness',
        totalChallenges: 35,
        wins: 24,
        losses: 11,
        winRate: 0.69,
        totalSteps: 1100000,
        totalEarnings: 510.00,
        currentStreak: 12,
        longestStreak: 30,
        referralCode: 'SARAH2024',
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now,
        lastActiveAt: now.subtract(const Duration(minutes: 45)),
      ),
      UserModel(
        id: 'demo-opponent-mike',
        email: 'mike@rivl.app',
        displayName: 'Mike Reynolds',
        username: 'mike_steps',
        totalChallenges: 19,
        wins: 10,
        losses: 9,
        winRate: 0.53,
        totalSteps: 620000,
        totalEarnings: 175.00,
        currentStreak: 3,
        longestStreak: 8,
        referralCode: 'MIKE2024',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
        lastActiveAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
    notifyListeners();
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
        return 480; // Target 8:00 min/mile (stored in seconds)
      case GoalType.fiveKPace:
        return 1500; // Target 25:00 5K time (stored in seconds)
      case GoalType.tenKPace:
        return 3000; // Target 50:00 10K time (stored in seconds)
      case GoalType.sleepDuration:
        return _selectedDuration.days * 8; // 8 hours per night
      case GoalType.vo2Max:
        return 450; // Target VO2 max of 45.0 (stored as x10)
      case GoalType.rivlHealthScore:
        return 75; // Target average RIVL Health Score of 75/100
    }
  }

  Future<String?> createChallenge({double? walletBalance}) async {
    if (_selectedOpponent == null) {
      _errorMessage = 'Please select an opponent';
      notifyListeners();
      return null;
    }

    // Validate wallet balance for paid challenges
    if (_selectedStake.amount > 0) {
      final balance = walletBalance ?? 0.0;
      if (balance < _selectedStake.amount) {
        _errorMessage =
            'Insufficient balance. You need \$${_selectedStake.amount.toStringAsFixed(0)} to enter this challenge.';
        notifyListeners();
        return null;
      }
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
      onXPEarned?.call(15, 'challenge_created'); // XPSource.CHALLENGE_CREATED
      resetCreateForm();

      _isCreating = false;
      notifyListeners();
      return challengeId;
    } catch (e) {
      _isCreating = false;
      _errorMessage = e.toString().contains('Exception:')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Failed to create challenge. Please try again.';
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

  Future<bool> acceptChallenge(String challengeId, {double? walletBalance}) async {
    // Validate that the challenge is still pending before accepting
    final challenge = _challenges.where((c) => c.id == challengeId).toList();
    if (challenge.isNotEmpty) {
      if (challenge.first.status != ChallengeStatus.pending) {
        _errorMessage = 'This challenge is no longer available';
        notifyListeners();
        return false;
      }
      // Validate wallet balance for paid challenges
      if (challenge.first.stakeAmount > 0) {
        final balance = walletBalance ?? 0.0;
        if (balance < challenge.first.stakeAmount) {
          _errorMessage =
              'Insufficient balance. You need \$${challenge.first.stakeAmount.toStringAsFixed(0)} to accept this challenge.';
          notifyListeners();
          return false;
        }
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.acceptChallenge(challengeId);
      _successMessage = 'Challenge accepted! Good luck!';
      onXPEarned?.call(15, 'challenge_accepted'); // XPSource.CHALLENGE_ACCEPTED
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
      final result = await _healthService.getProgressForChallenge(
        goalType: challenge.goalType,
        startDate: challenge.startDate!,
        endDate: challenge.endDate ?? DateTime.now(),
      );

      await _firebaseService.syncSteps(
        challengeId: challenge.id,
        steps: result.total,
        stepHistory: result.history,
      );

      _isSyncing = false;
      _successMessage = '${challenge.goalType.displayName} synced successfully';
      notifyListeners();
      return true;
    } catch (e) {
      _isSyncing = false;
      _errorMessage = 'Failed to sync ${challenge.goalType.displayName.toLowerCase()}';
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
