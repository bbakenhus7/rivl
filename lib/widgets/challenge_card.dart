// widgets/challenge_card.dart

import 'package:flutter/material.dart';
import '../models/challenge_model.dart';
import '../utils/theme.dart';
import '../utils/animations.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isWinning = challenge.isUserWinning && challenge.status == ChallengeStatus.active;
    final isLosing = !challenge.isUserWinning &&
        challenge.opponentProgress > 0 &&
        challenge.status == ChallengeStatus.active;
    final isCompleted = challenge.status == ChallengeStatus.completed;
    final didWin = isCompleted && challenge.winnerId == challenge.creatorId;

    // Dynamic accent color (Robinhood-style)
    final Color accentColor;
    if (isCompleted && didWin) {
      accentColor = RivlColors.success;
    } else if (isCompleted) {
      accentColor = RivlColors.error;
    } else if (isWinning) {
      accentColor = RivlColors.success;
    } else if (isLosing) {
      accentColor = RivlColors.error;
    } else {
      accentColor = RivlColors.primary;
    }

    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(isWinning || (isCompleted && didWin) ? 0.3 : 0.08),
            width: isWinning || (isCompleted && didWin) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(isWinning ? 0.08 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Colored accent bar at top (like Robinhood position cards)
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Challenge type icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          challenge.goalType.icon,
                          size: 18,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Opponent and status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'vs ${challenge.opponentName ?? "Opponent"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: challenge.statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  challenge.statusDisplayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (challenge.status == ChallengeStatus.active) ...[
                                  Text(
                                    '  •  ',
                                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                                  ),
                                  Text(
                                    challenge.timeRemaining,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Prize amount (bold, Robinhood-style)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            challenge.stakeAmount == 0
                                ? 'Free'
                                : '\$${challenge.prizeAmount.toInt()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: accentColor,
                            ),
                          ),
                          if (challenge.stakeAmount > 0)
                            Text(
                              'prize',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Head-to-head progress (improved)
                  _HeadToHeadProgress(
                    challenge: challenge,
                    accentColor: accentColor,
                    isWinning: isWinning,
                  ),

                  // Pending challenge actions (Accept / Decline inline)
                  if (challenge.status == ChallengeStatus.pending &&
                      (onAccept != null || onDecline != null)) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (onDecline != null)
                          Expanded(
                            child: ScaleOnTap(
                              onTap: onDecline,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: context.textSecondary.withOpacity(0.3),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Decline',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (onAccept != null && onDecline != null)
                          const SizedBox(width: 10),
                        if (onAccept != null)
                          Expanded(
                            flex: 2,
                            child: ScaleOnTap(
                              onTap: onAccept,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [RivlColors.primary, RivlColors.primaryLight],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Accept Challenge',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Daily goal breakdown for active challenges
                  if (challenge.status == ChallengeStatus.active &&
                      challenge.endDate != null) ...[
                    const SizedBox(height: 10),
                    _DailyGoalHint(challenge: challenge),
                  ],

                  // Win/loss result badge for completed
                  if (isCompleted) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: didWin
                            ? RivlColors.success.withOpacity(0.08)
                            : context.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            didWin ? Icons.emoji_events : Icons.close,
                            size: 16,
                            color: didWin ? RivlColors.success : context.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            didWin ? 'Victory!' : 'Defeated',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: didWin ? RivlColors.success : context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadToHeadProgress extends StatelessWidget {
  final ChallengeModel challenge;
  final Color accentColor;
  final bool isWinning;

  const _HeadToHeadProgress({
    required this.challenge,
    required this.accentColor,
    required this.isWinning,
  });

  @override
  Widget build(BuildContext context) {
    final youProgress = challenge.goalValue > 0
        ? (challenge.creatorProgress / challenge.goalValue).clamp(0.0, 1.0)
        : 0.0;
    final opponentProgress = challenge.goalValue > 0
        ? (challenge.opponentProgress / challenge.goalValue).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'You',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isWinning ? RivlColors.success : context.textSecondary,
                  ),
                ),
                if (isWinning) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_upward, size: 12, color: RivlColors.success),
                ],
              ],
            ),
            Text(
              challenge.opponentName ?? 'Opponent',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: !isWinning && challenge.opponentProgress > 0
                    ? Colors.orange[700]
                    : context.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Dual progress bar (like a tug-of-war)
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: (youProgress * 100).toInt().clamp(1, 100),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - youProgress) * 100).toInt().clamp(1, 100),
                  child: Container(color: context.surfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Step counts
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatSteps(challenge.creatorProgress),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            Text(
              _formatSteps(challenge.opponentProgress),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}K';
    }
    return '$steps';
  }
}

/// Shows a small hint about daily pace needed to win
class _DailyGoalHint extends StatelessWidget {
  final ChallengeModel challenge;

  const _DailyGoalHint({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final remaining = challenge.endDate!.difference(DateTime.now());
    if (remaining.isNegative || remaining.inDays == 0) return const SizedBox.shrink();

    final daysLeft = remaining.inDays.clamp(1, 999);
    final stepsNeeded = challenge.goalValue - challenge.creatorProgress;
    if (stepsNeeded <= 0) {
      return Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: RivlColors.success),
          const SizedBox(width: 6),
          Text(
            'Goal reached!',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: RivlColors.success,
            ),
          ),
        ],
      );
    }

    final dailyPace = (stepsNeeded / daysLeft).ceil();
    final unit = challenge.goalType == GoalType.steps
        ? 'steps'
        : challenge.goalType.displayName.toLowerCase();

    return Row(
      children: [
        Icon(Icons.trending_flat, size: 14, color: context.textSecondary),
        const SizedBox(width: 6),
        Text(
          '${_formatNumber(dailyPace)} $unit/day needed  ·  $daysLeft days left',
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
