// providers/leaderboard_provider.dart

import 'package:flutter/foundation.dart';
import '../models/leaderboard_model.dart';
import '../services/firebase_service.dart';

class LeaderboardProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  
  List<LeaderboardEntryModel> _allTimeLeaderboard = [];
  List<LeaderboardEntryModel> _monthlyLeaderboard = [];
  List<LeaderboardEntryModel> _weeklyLeaderboard = [];
  bool _isLoading = false;

  LeaderboardProvider(this._firebaseService);

  bool get isLoading => _isLoading;

  List<LeaderboardEntryModel> getLeaderboard(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.allTime:
        return _allTimeLeaderboard;
      case LeaderboardPeriod.monthly:
        return _monthlyLeaderboard;
      case LeaderboardPeriod.weekly:
        return _weeklyLeaderboard;
    }
  }

  Future<void> loadLeaderboards() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mock data for now - in production, fetch from Firebase
      _allTimeLeaderboard = _generateMockLeaderboard();
      _monthlyLeaderboard = _generateMockLeaderboard();
      _weeklyLeaderboard = _generateMockLeaderboard();
    } catch (e) {
      debugPrint('Error loading leaderboards: \$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<LeaderboardEntryModel> _generateMockLeaderboard() {
    // Mock data - replace with real Firebase query
    return List.generate(20, (index) {
      return LeaderboardEntryModel(
        rank: index + 1,
        userId: 'user_\$index',
        displayName: 'Player \${index + 1}',
        username: 'player\${index + 1}',
        wins: 50 - index * 2,
        totalChallenges: 70 - index * 2,
        earnings: 1000.0 - index * 50,
        winRate: 70.0 - index * 2.0,
        currentStreak: 10 - index,
      );
    });
  }
}
