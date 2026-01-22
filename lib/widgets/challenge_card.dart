// widgets/challenge_card.dart

import 'package:flutter/material.dart';
import '../models/challenge_model.dart';
import '../utils/theme.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback? onTap;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'vs ${challenge.opponentName ?? "Opponent"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: challenge.statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          challenge.statusDisplayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: challenge.statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${challenge.prizeAmount.toInt()} Prize',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: RivlColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.timeRemaining,
                        style: RivlTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bars
              Row(
                children: [
                  Expanded(
                    child: _ProgressColumn(
                      label: 'You',
                      progress: challenge.progressPercentage,
                      steps: challenge.creatorProgress,
                      color: RivlColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ProgressColumn(
                      label: challenge.opponentName ?? 'Opponent',
                      progress: challenge.goalValue > 0
                          ? (challenge.opponentProgress / challenge.goalValue).clamp(0.0, 1.0)
                          : 0,
                      steps: challenge.opponentProgress,
                      color: Colors.orange,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressColumn extends StatelessWidget {
  final String label;
  final double progress;
  final int steps;
  final Color color;
  final bool alignEnd;

  const _ProgressColumn({
    required this.label,
    required this.progress,
    required this.steps,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: RivlTextStyles.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatSteps(steps),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}K steps';
    }
    return '$steps steps';
  }
}

// Note: `StepsCard` is implemented in `lib/widgets/steps_card.dart`.
