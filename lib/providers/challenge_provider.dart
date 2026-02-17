// providers/challenge_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/health_service.dart';
import '../services/wallet_service.dart';
import '../services/anti_cheat_service.dart';
import 'dart:async';

class ChallengeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final HealthService _healthService = HealthService();
  final WalletService _walletService = WalletService();
  final AntiCheatService _antiCheatService = AntiCheatService();

  /// Callback invoked when the user earns XP from challenge activity.
  void Function(int xp, String source)? onXPEarned;

  /// Callback invoked when a challenge event should be posted to the activity feed.
  /// Parameters: (type, message, data)
  void Function(String type, String message, Map<String, dynamic>? data)?
      onActivityFeedPost;

  List<ChallengeModel> _challenges = [];
  List<Map<String, dynamic>> _leaderboard = [];
  List<UserModel> _searchResults = [];
  List<UserModel> _demoOpponents = [];
  
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isSyncing = false;
  bool _isSearching = false;
  bool _isSettling = false;
  final Set<String> _settlingChallengeIds = {};
  String? _errorMessage;
  String? _successMessage;

  // Create challenge form state
  ChallengeType _selectedChallengeType = ChallengeType.headToHead;
  UserModel? _selectedOpponent;
  StakeOption _selectedStake = StakeOption.options[2]; // $25 default
  ChallengeDuration _selectedDuration = ChallengeDuration.oneWeek;
  GoalType _selectedGoalType = GoalType.steps;

  // Group challenge form state
  List<UserModel> _selectedGroupMembers = [];
  int _groupSize = 6;
  GroupPayoutStructure _selectedPayoutStructure = GroupPayoutStructure.standard;

  // Team vs Team form state
  String _teamAName = '';
  String _teamBName = '';
  String? _teamALabel; // "Run Club", "Team", "Business", etc.
  String? _teamBLabel;
  List<UserModel> _teamAMembers = [];
  List<UserModel> _teamBMembers = [];
  int _teamSize = 2; // Members per team (2-20)

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

  ChallengeType get selectedChallengeType => _selectedChallengeType;
  UserModel? get selectedOpponent => _selectedOpponent;
  StakeOption get selectedStake => _selectedStake;
  ChallengeDuration get selectedDuration => _selectedDuration;
  GoalType get selectedGoalType => _selectedGoalType;

  // Group getters
  List<UserModel> get selectedGroupMembers => _selectedGroupMembers;
  int get groupSize => _groupSize;
  GroupPayoutStructure get selectedPayoutStructure => _selectedPayoutStructure;
  bool get isGroupMode => _selectedChallengeType == ChallengeType.group;

  // Team vs Team getters
  bool get isTeamMode => _selectedChallengeType == ChallengeType.teamVsTeam;
  String get teamAName => _teamAName;
  String get teamBName => _teamBName;
  String? get teamALabel => _teamALabel;
  String? get teamBLabel => _teamBLabel;
  List<UserModel> get teamAMembers => _teamAMembers;
  List<UserModel> get teamBMembers => _teamBMembers;
  int get teamSize => _teamSize;

  /// Estimated group prize pool (all participants × stake, minus 5% fee)
  double get groupPrizePool {
    if (_selectedStake.amount <= 0) return 0;
    final totalPot = _selectedStake.amount * _groupSize;
    return (totalPot * 0.95 * 100).roundToDouble() / 100;
  }

  /// Estimated team challenge prize pool (both teams × stake per person, minus 5% fee)
  double get teamPrizePool {
    if (_selectedStake.amount <= 0) return 0;
    final totalParticipants = _teamSize * 2; // Both teams
    final totalPot = _selectedStake.amount * totalParticipants;
    return (totalPot * 0.95 * 100).roundToDouble() / 100;
  }

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
        // Auto-decline expired pending challenges
        _autoDeclineExpired();
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load challenges';
        notifyListeners();
      },
    );
  }

  /// Auto-decline any pending challenges that have passed their expiry date.
  /// Refunds creator's stake for paid challenges.
  void _autoDeclineExpired() {
    final expired = _challenges.where((c) => c.isExpired).toList();
    for (final challenge in expired) {
      if (challenge.id.startsWith('demo-')) {
        // Remove demo challenges locally
        _challenges.removeWhere((c) => c.id == challenge.id);
      } else {
        // Fire-and-forget: decline on Firestore (includes refund)
        _firebaseService.declineChallenge(challenge.id).catchError((_) {});
      }
    }
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
        expiresAt: now.add(const Duration(days: 5, hours: 12)),
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
        expiresAt: now.add(const Duration(days: 6, hours: 16)),
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
      // Active: Squad vs Squad challenge
      ChallengeModel(
        id: 'demo-10',
        creatorId: 'demo-user',
        creatorName: 'You',
        type: ChallengeType.teamVsTeam,
        status: ChallengeStatus.active,
        stakeAmount: 25,
        totalPot: 200,
        prizeAmount: 190,
        goalType: GoalType.steps,
        goalValue: 280000, // 4 members × 70K each
        duration: ChallengeDuration.oneWeek,
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 5)),
        participantIds: ['demo-user', 'demo-t1', 'demo-t2', 'demo-t3', 'demo-t4', 'demo-t5', 'demo-t6', 'demo-t7'],
        teamA: ChallengeTeam(
          name: 'Morning Runners',
          label: 'Run Club',
          members: [
            GroupParticipant(userId: 'demo-user', displayName: 'You', status: ParticipantStatus.accepted, progress: 18200),
            GroupParticipant(userId: 'demo-t1', displayName: 'Jake M.', status: ParticipantStatus.accepted, progress: 15400),
            GroupParticipant(userId: 'demo-t2', displayName: 'Sarah K.', status: ParticipantStatus.accepted, progress: 21300),
            GroupParticipant(userId: 'demo-t3', displayName: 'Mike R.', status: ParticipantStatus.accepted, progress: 12800),
          ],
        ),
        teamB: ChallengeTeam(
          name: 'Night Owls',
          label: 'Run Club',
          members: [
            GroupParticipant(userId: 'demo-t4', displayName: 'Emma L.', status: ParticipantStatus.accepted, progress: 19100),
            GroupParticipant(userId: 'demo-t5', displayName: 'Chris D.', status: ParticipantStatus.accepted, progress: 14600),
            GroupParticipant(userId: 'demo-t6', displayName: 'Alex T.', status: ParticipantStatus.accepted, progress: 16900),
            GroupParticipant(userId: 'demo-t7', displayName: 'Jordan B.', status: ParticipantStatus.accepted, progress: 11200),
          ],
        ),
        teamSize: 4,
        createdAt: now.subtract(const Duration(days: 2)),
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

  void setSelectedChallengeType(ChallengeType type) {
    _selectedChallengeType = type;
    notifyListeners();
  }

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

  // Group challenge setters
  void setGroupSize(int size) {
    _groupSize = size.clamp(3, 20);
    notifyListeners();
  }

  void setSelectedPayoutStructure(GroupPayoutStructure structure) {
    _selectedPayoutStructure = structure;
    notifyListeners();
  }

  void addGroupMember(UserModel user) {
    if (_selectedGroupMembers.any((m) => m.id == user.id)) return;
    if (_selectedGroupMembers.length >= _groupSize - 1) return; // minus creator
    _selectedGroupMembers.add(user);
    notifyListeners();
  }

  void removeGroupMember(String userId) {
    _selectedGroupMembers.removeWhere((m) => m.id == userId);
    notifyListeners();
  }

  // Team vs Team setters
  void setTeamAName(String name) {
    _teamAName = name;
    notifyListeners();
  }

  void setTeamBName(String name) {
    _teamBName = name;
    notifyListeners();
  }

  void setTeamALabel(String? label) {
    _teamALabel = label;
    notifyListeners();
  }

  void setTeamBLabel(String? label) {
    _teamBLabel = label;
    notifyListeners();
  }

  void setTeamSize(int size) {
    _teamSize = size.clamp(2, 20);
    // Trim excess members if size was reduced
    if (_teamAMembers.length > _teamSize - 1) {
      _teamAMembers = _teamAMembers.sublist(0, _teamSize - 1);
    }
    if (_teamBMembers.length > _teamSize) {
      _teamBMembers = _teamBMembers.sublist(0, _teamSize);
    }
    notifyListeners();
  }

  void addTeamAMember(UserModel user) {
    if (_teamAMembers.any((m) => m.id == user.id)) return;
    if (_teamBMembers.any((m) => m.id == user.id)) return; // Can't be on both teams
    if (_teamAMembers.length >= _teamSize - 1) return; // minus creator
    _teamAMembers.add(user);
    notifyListeners();
  }

  void removeTeamAMember(String userId) {
    _teamAMembers.removeWhere((m) => m.id == userId);
    notifyListeners();
  }

  void addTeamBMember(UserModel user) {
    if (_teamBMembers.any((m) => m.id == user.id)) return;
    if (_teamAMembers.any((m) => m.id == user.id)) return; // Can't be on both teams
    if (_teamBMembers.length >= _teamSize) return;
    _teamBMembers.add(user);
    notifyListeners();
  }

  void removeTeamBMember(String userId) {
    _teamBMembers.removeWhere((m) => m.id == userId);
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
    if (_isCreating) return null; // Guard against double-tap
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
      // Use atomic create+deduct for paid challenges
      final challengeId = await _firebaseService.createChallengeWithStake(
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

  Future<String?> createGroupChallenge({double? walletBalance}) async {
    if (_isCreating) return null; // Guard against double-tap
    if (_selectedGroupMembers.isEmpty) {
      _errorMessage = 'Please add at least one member';
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
      final invitedParticipants = _selectedGroupMembers
          .map((m) => GroupParticipant(
                userId: m.id,
                displayName: m.displayName,
                username: m.username,
                status: ParticipantStatus.invited,
              ))
          .toList();

      // Demo mode: create locally
      if (_selectedGroupMembers.every((m) => m.id.startsWith('demo'))) {
        final now = DateTime.now();
        final allParticipants = [
          GroupParticipant(
            userId: 'demo-user',
            displayName: 'You',
            status: ParticipantStatus.accepted,
          ),
          ...invitedParticipants,
        ];
        final totalPot = _selectedStake.amount * allParticipants.length;
        final prizeAmount = (totalPot * 0.95 * 100).roundToDouble() / 100;

        final demoId = 'demo-group-${DateTime.now().millisecondsSinceEpoch}';
        _challenges.insert(
          0,
          ChallengeModel(
            id: demoId,
            creatorId: 'demo-user',
            creatorName: 'You',
            type: ChallengeType.group,
            status: ChallengeStatus.pending,
            stakeAmount: _selectedStake.amount,
            totalPot: totalPot,
            prizeAmount: prizeAmount,
            goalType: _selectedGoalType,
            goalValue: suggestedGoalValue,
            duration: _selectedDuration,
            participants: allParticipants,
            participantIds: allParticipants.map((p) => p.userId).toList(),
            maxParticipants: _groupSize,
            minParticipants: 3,
            payoutStructure: _selectedPayoutStructure,
            createdAt: now,
            updatedAt: now,
          ),
        );

        _successMessage = 'Group challenge created!';
        onXPEarned?.call(15, 'challenge_created');
        resetCreateForm();
        _isCreating = false;
        notifyListeners();
        return demoId;
      }

      final challengeId = await _firebaseService.createGroupChallengeWithStake(
        invitedParticipants: invitedParticipants,
        goalType: _selectedGoalType,
        goalValue: suggestedGoalValue,
        duration: _selectedDuration,
        stakeAmount: _selectedStake.amount,
        maxParticipants: _groupSize,
        minParticipants: 3,
        payoutStructure: _selectedPayoutStructure,
      );

      _successMessage = 'Group challenge created!';
      onXPEarned?.call(15, 'challenge_created');
      resetCreateForm();

      _isCreating = false;
      notifyListeners();
      return challengeId;
    } catch (e) {
      _isCreating = false;
      _errorMessage = e.toString().contains('Exception:')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Failed to create group challenge. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<String?> createTeamChallenge({double? walletBalance}) async {
    if (_isCreating) return null;
    if (_teamAName.trim().isEmpty || _teamBName.trim().isEmpty) {
      _errorMessage = 'Please name both squads';
      notifyListeners();
      return null;
    }
    if (_teamBMembers.isEmpty) {
      _errorMessage = 'Please add at least one member to the opposing squad';
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
      final teamAParticipants = _teamAMembers
          .map((m) => GroupParticipant(
                userId: m.id,
                displayName: m.displayName,
                username: m.username,
                status: ParticipantStatus.invited,
              ))
          .toList();

      final teamBParticipants = _teamBMembers
          .map((m) => GroupParticipant(
                userId: m.id,
                displayName: m.displayName,
                username: m.username,
                status: ParticipantStatus.invited,
              ))
          .toList();

      // Demo mode: create locally
      if (_teamAMembers.every((m) => m.id.startsWith('demo')) &&
          _teamBMembers.every((m) => m.id.startsWith('demo'))) {
        final now = DateTime.now();
        final creatorParticipant = GroupParticipant(
          userId: 'demo-user',
          displayName: 'You',
          status: ParticipantStatus.accepted,
        );
        final teamA = ChallengeTeam(
          name: _teamAName,
          label: _teamALabel,
          members: [creatorParticipant, ...teamAParticipants],
        );
        final teamB = ChallengeTeam(
          name: _teamBName,
          label: _teamBLabel,
          members: teamBParticipants,
        );
        final totalParticipants = teamA.members.length + teamB.members.length;
        final totalPot = _selectedStake.amount * totalParticipants;
        final prizeAmount = (totalPot * 0.95 * 100).roundToDouble() / 100;

        final demoId = 'demo-team-${DateTime.now().millisecondsSinceEpoch}';
        _challenges.insert(
          0,
          ChallengeModel(
            id: demoId,
            creatorId: 'demo-user',
            creatorName: 'You',
            type: ChallengeType.teamVsTeam,
            status: ChallengeStatus.pending,
            stakeAmount: _selectedStake.amount,
            totalPot: totalPot,
            prizeAmount: prizeAmount,
            goalType: _selectedGoalType,
            goalValue: suggestedGoalValue,
            duration: _selectedDuration,
            participantIds: [
              ...teamA.memberIds,
              ...teamB.memberIds,
            ],
            teamA: teamA,
            teamB: teamB,
            teamSize: _teamSize,
            createdAt: now,
            updatedAt: now,
          ),
        );

        _successMessage = 'Squad challenge created!';
        onXPEarned?.call(15, 'challenge_created');
        resetCreateForm();
        _isCreating = false;
        notifyListeners();
        return demoId;
      }

      final challengeId = await _firebaseService.createTeamChallengeWithStake(
        teamAName: _teamAName,
        teamALabel: _teamALabel,
        teamAMembers: teamAParticipants,
        teamBName: _teamBName,
        teamBLabel: _teamBLabel,
        teamBMembers: teamBParticipants,
        goalType: _selectedGoalType,
        goalValue: suggestedGoalValue,
        duration: _selectedDuration,
        stakeAmount: _selectedStake.amount,
        teamSize: _teamSize,
      );

      _successMessage = 'Squad challenge created!';
      onXPEarned?.call(15, 'challenge_created');
      resetCreateForm();

      _isCreating = false;
      notifyListeners();
      return challengeId;
    } catch (e) {
      _isCreating = false;
      _errorMessage = e.toString().contains('Exception:')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Failed to create squad challenge. Please try again.';
      notifyListeners();
      return null;
    }
  }

  void resetCreateForm() {
    _selectedChallengeType = ChallengeType.headToHead;
    _selectedOpponent = null;
    _selectedStake = StakeOption.options[2];
    _selectedDuration = ChallengeDuration.oneWeek;
    _selectedGoalType = GoalType.steps;
    _selectedGroupMembers = [];
    _groupSize = 6;
    _selectedPayoutStructure = GroupPayoutStructure.standard;
    _teamAName = '';
    _teamBName = '';
    _teamALabel = null;
    _teamBLabel = null;
    _teamAMembers = [];
    _teamBMembers = [];
    _teamSize = 2;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ============================================
  // CHALLENGE ACTIONS
  // ============================================

  Future<bool> acceptChallenge(String challengeId, {double? walletBalance}) async {
    if (_isLoading) return false; // Guard against double-tap
    // Validate that the challenge is still pending before accepting
    final matches = _challenges.where((c) => c.id == challengeId).toList();
    if (matches.isEmpty) {
      _errorMessage = 'Challenge not found';
      notifyListeners();
      return false;
    }

    final challenge = matches.first;
    if (challenge.status != ChallengeStatus.pending) {
      _errorMessage = 'This challenge is no longer available';
      notifyListeners();
      return false;
    }

    // Validate wallet balance for paid challenges
    if (challenge.stakeAmount > 0) {
      final balance = walletBalance ?? 0.0;
      if (balance < challenge.stakeAmount) {
        _errorMessage =
            'Insufficient balance. You need \$${challenge.stakeAmount.toStringAsFixed(0)} to accept this challenge.';
        notifyListeners();
        return false;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Handle demo challenges locally
      if (challengeId.startsWith('demo-')) {
        final now = DateTime.now();
        final idx = _challenges.indexWhere((c) => c.id == challengeId);
        if (idx != -1) {
          _challenges[idx] = ChallengeModel(
            id: challenge.id,
            creatorId: challenge.creatorId,
            opponentId: challenge.opponentId,
            creatorName: challenge.creatorName,
            opponentName: challenge.opponentName,
            type: challenge.type,
            status: ChallengeStatus.active,
            stakeAmount: challenge.stakeAmount,
            totalPot: challenge.totalPot,
            prizeAmount: challenge.prizeAmount,
            goalType: challenge.goalType,
            goalValue: challenge.goalValue,
            duration: challenge.duration,
            startDate: now,
            endDate: now.add(Duration(days: challenge.duration.days)),
            creatorProgress: challenge.creatorProgress,
            opponentProgress: challenge.opponentProgress,
            participants: challenge.participants,
            participantIds: challenge.participantIds,
            maxParticipants: challenge.maxParticipants,
            minParticipants: challenge.minParticipants,
            payoutStructure: challenge.payoutStructure,
            teamA: challenge.teamA,
            teamB: challenge.teamB,
            teamSize: challenge.teamSize,
            createdAt: challenge.createdAt,
            updatedAt: now,
          );
        }
      } else {
        // Atomic accept + stake deduction
        if (challenge.stakeAmount > 0) {
          final userId = _firebaseService.currentUser!.uid;
          final success = await _firebaseService.acceptChallengeWithStake(
            challengeId: challengeId,
            userId: userId,
            stakeAmount: challenge.stakeAmount,
          );
          if (!success) {
            _isLoading = false;
            _errorMessage = 'Insufficient balance to accept this challenge';
            notifyListeners();
            return false;
          }
        } else {
          await _firebaseService.acceptChallenge(challengeId);
        }
      }

      _successMessage = 'Challenge accepted! Good luck!';
      onXPEarned?.call(15, 'challenge_accepted');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().contains('Exception:')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Failed to accept challenge';
      notifyListeners();
      return false;
    }
  }

  Future<bool> declineChallenge(String challengeId) async {
    if (_isLoading) return false; // Guard against double-tap
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Handle demo challenges locally
      if (challengeId.startsWith('demo-')) {
        _challenges.removeWhere((c) => c.id == challengeId);
      } else {
        await _firebaseService.declineChallenge(challengeId);
      }

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

      // Run anti-cheat analysis on synced data
      if (result.history.isNotEmpty) {
        _runAntiCheatAnalysis(challenge, result.history);
      }

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

  /// Run anti-cheat analysis asynchronously after step sync.
  /// Stores the score on the challenge document and flags if suspicious.
  Future<void> _runAntiCheatAnalysis(
    ChallengeModel challenge,
    List<DailySteps> stepHistory,
  ) async {
    try {
      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) return;

      final reputation =
          await _antiCheatService.calculateUserReputation(userId);

      final result = await _antiCheatService.analyzeActivity(
        stepHistory: stepHistory,
        userId: userId,
        userReputation: reputation,
        challengeId: challenge.id,
      );

      // Determine which field to update
      final isCreator = challenge.creatorId == userId;
      final scoreField =
          isCreator ? 'creatorAntiCheatScore' : 'opponentAntiCheatScore';

      final updates = <String, dynamic>{
        scoreField: result.overallScore,
      };

      // Flag if suspicious
      if (result.isSuspicious || result.isCheating) {
        updates['flagged'] = true;
        updates['flagReason'] = result.flags.isNotEmpty
            ? result.flags.join('; ')
            : result.recommendation;
      }

      // Update the challenge document (non-demo)
      if (!challenge.id.startsWith('demo-')) {
        await _firebaseService.updateChallenge(challenge.id, updates);
      }
    } catch (_) {
      // Anti-cheat is best-effort; don't block the sync
    }
  }

  /// Settle a completed challenge: determine winner, run anti-cheat,
  /// credit winnings, and update the challenge document.
  Future<bool> settleChallenge(String challengeId) async {
    // Per-challenge guard prevents concurrent settlement of the same challenge
    if (_settlingChallengeIds.contains(challengeId)) return false;
    if (_isLoading) return false; // Guard against double-tap

    final matches = _challenges.where((c) => c.id == challengeId).toList();
    if (matches.isEmpty) return false;

    final challenge = matches.first;
    if (challenge.status != ChallengeStatus.active) return false;

    // Check if challenge has ended
    if (challenge.endDate != null &&
        challenge.endDate!.isAfter(DateTime.now())) {
      return false; // Not yet ended
    }

    _settlingChallengeIds.add(challengeId);
    _isLoading = true;
    notifyListeners();

    try {
      // Run anti-cheat on both sides
      AntiCheatResult? creatorResult;
      AntiCheatResult? opponentResult;

      if (challenge.creatorStepHistory.isNotEmpty) {
        creatorResult = await _antiCheatService.analyzeActivity(
          stepHistory: challenge.creatorStepHistory,
          userId: challenge.creatorId,
        );
      }
      if (challenge.opponentStepHistory.isNotEmpty &&
          challenge.opponentId != null) {
        opponentResult = await _antiCheatService.analyzeActivity(
          stepHistory: challenge.opponentStepHistory,
          userId: challenge.opponentId!,
        );
      }

      // Determine winner
      String? winnerId;
      String? winnerName;
      String? loserId;
      bool isTie = false;

      final creatorFlagged = creatorResult?.isCheating ?? false;
      final opponentFlagged = opponentResult?.isCheating ?? false;

      // For team challenges, use aggregate team progress
      final int sideAProgress;
      final int sideBProgress;
      if (challenge.isTeamVsTeam) {
        sideAProgress = challenge.teamAProgress;
        sideBProgress = challenge.teamBProgress;
      } else {
        sideAProgress = challenge.creatorProgress;
        sideBProgress = challenge.opponentProgress;
      }

      // For team challenges, use first Team B member as representative ID since opponentId is null.
      // Falls back to a synthetic 'teamB' string if the team has no members to avoid null winnerId.
      final teamBRepId = challenge.isTeamVsTeam
          ? (challenge.teamB?.members.firstOrNull?.userId ?? 'teamB_${challenge.id}')
          : challenge.opponentId;

      if (creatorFlagged && !opponentFlagged) {
        winnerId = challenge.isTeamVsTeam ? teamBRepId : challenge.opponentId;
        winnerName = challenge.isTeamVsTeam ? challenge.teamB?.name : challenge.opponentName;
        loserId = challenge.creatorId;
      } else if (!creatorFlagged && opponentFlagged) {
        winnerId = challenge.creatorId;
        winnerName = challenge.isTeamVsTeam ? challenge.teamA?.name : challenge.creatorName;
        loserId = challenge.isTeamVsTeam ? teamBRepId : challenge.opponentId;
      } else {
        if (challenge.goalType.higherIsBetter) {
          if (sideAProgress == sideBProgress) {
            isTie = true;
          } else if (sideAProgress > sideBProgress) {
            // Team A / creator wins
            winnerId = challenge.creatorId;
            winnerName = challenge.isTeamVsTeam
                ? challenge.teamA?.name
                : challenge.creatorName;
            loserId = challenge.isTeamVsTeam ? teamBRepId : challenge.opponentId;
          } else {
            // Team B / opponent wins
            winnerId = challenge.isTeamVsTeam ? teamBRepId : challenge.opponentId;
            winnerName = challenge.isTeamVsTeam
                ? challenge.teamB?.name
                : challenge.opponentName;
            loserId = challenge.creatorId;
          }
        } else {
          // Pace-based: lower is better
          if (sideAProgress == 0 && sideBProgress == 0) {
            isTie = true;
          } else if (sideAProgress == 0) {
            winnerId = challenge.isTeamVsTeam ? teamBRepId : challenge.opponentId;
            winnerName = challenge.isTeamVsTeam
                ? challenge.teamB?.name
                : challenge.opponentName;
            loserId = challenge.creatorId;
          } else if (sideBProgress == 0) {
            winnerId = challenge.creatorId;
            winnerName = challenge.isTeamVsTeam
                ? challenge.teamA?.name
                : challenge.creatorName;
            loserId = challenge.isTeamVsTeam ? teamBRepId : challenge.opponentId;
          } else if (sideAProgress == sideBProgress) {
            isTie = true;
          } else if (sideAProgress < sideBProgress) {
            winnerId = challenge.creatorId;
            winnerName = challenge.isTeamVsTeam
                ? challenge.teamA?.name
                : challenge.creatorName;
            loserId = challenge.isTeamVsTeam ? teamBRepId : challenge.opponentId;
          } else {
            winnerId = challenge.isTeamVsTeam ? teamBRepId : challenge.opponentId;
            winnerName = challenge.isTeamVsTeam
                ? challenge.teamB?.name
                : challenge.opponentName;
            loserId = challenge.creatorId;
          }
        }
      }

      final isFlagged = (creatorResult?.isSuspicious ?? false) ||
          (opponentResult?.isSuspicious ?? false);

      // Update challenge document
      if (!challengeId.startsWith('demo-')) {
        final rewardStatus = isTie
            ? RewardStatus.pending.name
            : (isFlagged ? RewardStatus.pending.name : RewardStatus.sent.name);

        await _firebaseService.updateChallenge(challengeId, {
          'status': ChallengeStatus.completed.name,
          'winnerId': isTie ? null : winnerId,
          'winnerName': isTie ? null : winnerName,
          'isTie': isTie,
          'rewardStatus': rewardStatus,
          'resultDeclaredAt': FieldValue.serverTimestamp(),
          'creatorAntiCheatScore': creatorResult?.overallScore ?? 1.0,
          'opponentAntiCheatScore': opponentResult?.overallScore ?? 1.0,
          'flagged': isFlagged,
          'flagReason': isFlagged
              ? [
                  ...?creatorResult?.flags,
                  ...?opponentResult?.flags,
                ].join('; ')
              : null,
        });

        if (isTie) {
          // Refund stakes on tie
          if (challenge.stakeAmount > 0) {
            if (challenge.isTeamVsTeam) {
              // Refund all team members
              final allMembers = [
                ...?challenge.teamA?.members,
                ...?challenge.teamB?.members,
              ];
              for (final member in allMembers) {
                await _walletService.refundStake(
                  userId: member.userId,
                  challengeId: challengeId,
                  amount: challenge.stakeAmount,
                );
              }
            } else {
              await _walletService.refundStake(
                userId: challenge.creatorId,
                challengeId: challengeId,
                amount: challenge.stakeAmount,
              );
              if (challenge.opponentId != null) {
                await _walletService.refundStake(
                  userId: challenge.opponentId!,
                  challengeId: challengeId,
                  amount: challenge.stakeAmount,
                );
              }
            }
          }
          // Update user stats: increment draws + totalChallenges
          if (challenge.isTeamVsTeam) {
            final allMembers = [
              ...?challenge.teamA?.members,
              ...?challenge.teamB?.members,
            ];
            for (final member in allMembers) {
              await _firebaseService.updateUser(member.userId, {
                'draws': FieldValue.increment(1),
                'totalChallenges': FieldValue.increment(1),
              });
            }
          } else {
            await _firebaseService.updateUser(challenge.creatorId, {
              'draws': FieldValue.increment(1),
              'totalChallenges': FieldValue.increment(1),
            });
            if (challenge.opponentId != null) {
              await _firebaseService.updateUser(challenge.opponentId!, {
                'draws': FieldValue.increment(1),
                'totalChallenges': FieldValue.increment(1),
              });
            }
          }
        } else if (winnerId != null && !isFlagged) {
          if (challenge.isTeamVsTeam) {
            // Determine winning and losing teams
            final bool teamAWon = winnerId == challenge.creatorId;
            final winningTeam = teamAWon ? challenge.teamA : challenge.teamB;
            final losingTeam = teamAWon ? challenge.teamB : challenge.teamA;
            final winningMembers = winningTeam?.members ?? [];
            final losingMembers = losingTeam?.members ?? [];

            // Credit per-member winnings to winning team
            if (challenge.stakeAmount > 0 && winningMembers.isNotEmpty) {
              final perMemberPrize = challenge.prizeAmount / winningMembers.length;
              for (final member in winningMembers) {
                await _walletService.creditWinnings(
                  userId: member.userId,
                  challengeId: challengeId,
                  amount: perMemberPrize,
                );
              }
            }
            // Update winning team member stats
            for (final member in winningMembers) {
              await _firebaseService.updateUser(member.userId, {
                'wins': FieldValue.increment(1),
                'totalChallenges': FieldValue.increment(1),
                'totalEarnings': FieldValue.increment(
                    winningMembers.isNotEmpty
                        ? challenge.prizeAmount / winningMembers.length
                        : 0),
              });
            }
            // Update losing team member stats
            for (final member in losingMembers) {
              await _firebaseService.updateUser(member.userId, {
                'losses': FieldValue.increment(1),
                'totalChallenges': FieldValue.increment(1),
              });
            }
          } else {
            // 1v1 settlement
            // Credit winnings
            if (challenge.stakeAmount > 0) {
              await _walletService.creditWinnings(
                userId: winnerId,
                challengeId: challengeId,
                amount: challenge.prizeAmount,
              );
            }
            // Update winner user stats
            await _firebaseService.updateUser(winnerId, {
              'wins': FieldValue.increment(1),
              'totalChallenges': FieldValue.increment(1),
              'totalEarnings': FieldValue.increment(challenge.prizeAmount),
            });
            // Update loser user stats
            if (loserId != null) {
              await _firebaseService.updateUser(loserId, {
                'losses': FieldValue.increment(1),
                'totalChallenges': FieldValue.increment(1),
              });
            }
          }
        }
      }

      // Post to activity feed
      if (!challengeId.startsWith('demo-') && winnerId != null && !isTie) {
        onActivityFeedPost?.call(
          'challengeWon',
          '$winnerName won \$${challenge.prizeAmount.toStringAsFixed(0)}!',
          {
            'challengeId': challengeId,
            'winnerId': winnerId,
            'loserId': loserId,
            'amount': challenge.prizeAmount,
          },
        );
      }

      _isLoading = false;
      _settlingChallengeIds.remove(challengeId);
      _successMessage = isTie
          ? 'Challenge ended in a tie'
          : '$winnerName wins!';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _settlingChallengeIds.remove(challengeId);
      _errorMessage = 'Failed to settle challenge';
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
      _errorMessage = 'Search failed. Please try again.';
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
      _errorMessage = 'Failed to load leaderboard';
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
