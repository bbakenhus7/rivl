// widgets/streak_reward_popup.dart

import 'package:flutter/material.dart';
import '../models/streak_model.dart';
import '../utils/theme.dart';

class StreakRewardPopup extends StatelessWidget {
  final LoginReward reward;
  final int currentStreak;
  final VoidCallback onDismiss;

  const StreakRewardPopup({
    super.key,
    required this.reward,
    required this.currentStreak,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isMilestone = LoginReward.isMilestone(currentStreak);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isMilestone
              ? const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [RivlColors.primary, RivlColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isMilestone ? Colors.amber : RivlColors.primary)
                  .withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fire icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMilestone ? Icons.star : Icons.local_fire_department,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            // Streak count
            Text(
              isMilestone ? 'MILESTONE!' : 'DAILY STREAK!',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$currentStreak Day${currentStreak == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Rewards
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '+${reward.coins} coins',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.flash_on, color: Colors.lightBlueAccent, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    '+${reward.xp} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (isMilestone) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Bonus: +${LoginReward.milestoneBonus(currentStreak)} coins!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Streak multiplier hint
            if (currentStreak < 30)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _nextMilestoneHint(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            // Claim button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isMilestone ? Colors.amber[800] : RivlColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Collect',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nextMilestoneHint() {
    if (currentStreak < 3) return 'Reach 3 days for 1.5x XP multiplier!';
    if (currentStreak < 7) return '${7 - currentStreak} days until 2x XP multiplier!';
    if (currentStreak < 14) return '${14 - currentStreak} days until 3x XP multiplier!';
    if (currentStreak < 30) return '${30 - currentStreak} days until 5x XP multiplier!';
    return '';
  }
}
