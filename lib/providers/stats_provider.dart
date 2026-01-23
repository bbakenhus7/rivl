// providers/stats_provider.dart

import 'package:flutter/foundation.dart';
import '../models/user_stats_model.dart';
import '../services/firebase_service.dart';

class StatsProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  
  UserStatsModel? _stats;
  bool _isLoading = false;

  StatsProvider(this._firebaseService);

  UserStatsModel? get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> loadStats(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _stats = await _firebaseService.getUserStats(userId);
    } catch (e) {
      debugPrint('Error loading stats: \$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateStats(UserStatsModel stats) {
    _stats = stats;
    notifyListeners();
  }
}
