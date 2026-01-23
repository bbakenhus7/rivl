// models/achievement_model.dart

import 'package:flutter/material.dart';

enum AchievementType {
  firstWin,
  winStreak5,
  winStreak10,
  totalWins10,
  totalWins50,
  totalWins100,
  highRoller,
  earner100,
  earner500,
  earner1000,
  socialButterfly,
  stepMaster,
}

class AchievementModel {
  final AchievementType type;
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final int requiredValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  AchievementModel({
    required this.type,
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.requiredValue,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  static List<AchievementModel> getAllAchievements() {
    return [
      AchievementModel(
        type: AchievementType.firstWin,
        id: 'first_win',
        title: 'First Victory',
        description: 'Win your first challenge',
        emoji: '🏆',
        color: Colors.amber,
        requiredValue: 1,
      ),
      AchievementModel(
        type: AchievementType.winStreak5,
        id: 'win_streak_5',
        title: 'Hot Streak',
        description: 'Win 5 challenges in a row',
        emoji: '🔥',
        color: Colors.orange,
        requiredValue: 5,
      ),
      AchievementModel(
        type: AchievementType.winStreak10,
        id: 'win_streak_10',
        title: 'Unstoppable',
        description: 'Win 10 challenges in a row',
        emoji: '⚡',
        color: Colors.deepOrange,
        requiredValue: 10,
      ),
      AchievementModel(
        type: AchievementType.totalWins10,
        id: 'total_wins_10',
        title: 'Rising Star',
        description: 'Win 10 total challenges',
        emoji: '⭐',
        color: Colors.blue,
        requiredValue: 10,
      ),
      AchievementModel(
        type: AchievementType.totalWins50,
        id: 'total_wins_50',
        title: 'Champion',
        description: 'Win 50 total challenges',
        emoji: '👑',
        color: Colors.purple,
        requiredValue: 50,
      ),
      AchievementModel(
        type: AchievementType.totalWins100,
        id: 'total_wins_100',
        title: 'Legend',
        description: 'Win 100 total challenges',
        emoji: '💎',
        color: Colors.cyan,
        requiredValue: 100,
      ),
      AchievementModel(
        type: AchievementType.highRoller,
        id: 'high_roller',
        title: 'High Roller',
        description: 'Win a \$50 challenge',
        emoji: '💰',
        color: Colors.green,
        requiredValue: 50,
      ),
      AchievementModel(
        type: AchievementType.earner100,
        id: 'earner_100',
        title: 'Money Maker',
        description: 'Earn \$100 total',
        emoji: '💵',
        color: Colors.teal,
        requiredValue: 100,
      ),
      AchievementModel(
        type: AchievementType.earner500,
        id: 'earner_500',
        title: 'Big Earner',
        description: 'Earn \$500 total',
        emoji: '💸',
        color: Colors.lightGreen,
        requiredValue: 500,
      ),
      AchievementModel(
        type: AchievementType.earner1000,
        id: 'earner_1000',
        title: 'Millionaire Mindset',
        description: 'Earn \$1000 total',
        emoji: '🤑',
        color: Colors.yellow,
        requiredValue: 1000,
      ),
      AchievementModel(
        type: AchievementType.socialButterfly,
        id: 'social_butterfly',
        title: 'Social Butterfly',
        description: 'Challenge 10 different people',
        emoji: '🦋',
        color: Colors.pink,
        requiredValue: 10,
      ),
      AchievementModel(
        type: AchievementType.stepMaster,
        id: 'step_master',
        title: 'Step Master',
        description: 'Complete 100,000 steps in a challenge',
        emoji: '👟',
        color: Colors.indigo,
        requiredValue: 100000,
      ),
    ];
  }
}
