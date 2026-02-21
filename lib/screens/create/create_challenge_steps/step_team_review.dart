// Step 4 (team mode): Team Review

import 'package:flutter/material.dart';
import '../../../models/challenge_model.dart';
import '../../../models/user_model.dart';
import '../../../utils/theme.dart';
import '../../../utils/animations.dart';

class StepTeamReview extends StatelessWidget {
  final String teamAName;
  final String teamBName;
  final String? teamALabel;
  final String? teamBLabel;
  final List<UserModel> teamAMembers;
  final List<UserModel> teamBMembers;
  final int teamSize;
  final StakeOption stake;
  final ChallengeDuration duration;
  final GoalType goalType;
  final Function(int) onEditStep;

  const StepTeamReview({
    super.key,
    required this.teamAName,
    required this.teamBName,
    this.teamALabel,
    this.teamBLabel,
    required this.teamAMembers,
    required this.teamBMembers,
    required this.teamSize,
    required this.stake,
    required this.duration,
    required this.goalType,
    required this.onEditStep,
  });

  @override
  Widget build(BuildContext context) {
    final totalParticipants = teamSize * 2;
    final totalPot = stake.amount * totalParticipants;
    final prizePool = (totalPot * 0.95 * 100).roundToDouble() / 100;
    final perPersonWinnings = teamSize > 0
        ? (prizePool / teamSize)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideIn(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Review your\nsquad challenge',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          // Prize pool header
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [RivlColors.primary, RivlColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    stake.amount > 0 ? '\$${prizePool.toStringAsFixed(0)}' : 'Free',
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Prize Pool',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
                  ),
                  if (stake.amount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Winners get ~\$${perPersonWinnings.toStringAsFixed(0)} each',
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Squads display
          SlideIn(
            delay: const Duration(milliseconds: 250),
            child: ReviewSquadCard(
              squadName: teamAName.isEmpty ? 'Your Squad' : teamAName,
              label: teamALabel,
              members: ['You (Captain)', ...teamAMembers.map((m) => m.displayName)],
              color: RivlColors.primary,
              onEdit: () => onEditStep(1),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: context.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: ReviewSquadCard(
              squadName: teamBName.isEmpty ? 'Rival Squad' : teamBName,
              label: teamBLabel,
              members: teamBMembers.map((m) => m.displayName).toList(),
              color: const Color(0xFFFF6B5B),
              onEdit: () => onEditStep(1),
            ),
          ),
          const SizedBox(height: 20),

          // Challenge details
          SlideIn(
            delay: const Duration(milliseconds: 350),
            child: Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.06),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SquadReviewRow(
                      icon: goalType.icon,
                      label: 'Type',
                      value: goalType.displayName,
                      onEdit: () => onEditStep(3),
                    ),
                    const Divider(height: 20),
                    SquadReviewRow(
                      icon: Icons.schedule_outlined,
                      label: 'Duration',
                      value: duration.displayName,
                      onEdit: () => onEditStep(3),
                    ),
                    const Divider(height: 20),
                    SquadReviewRow(
                      icon: Icons.attach_money,
                      label: 'Stake',
                      value: stake.amount > 0 ? '\$${stake.amount.toInt()} per person' : 'Free',
                      onEdit: () => onEditStep(2),
                    ),
                    const Divider(height: 20),
                    SquadReviewRow(
                      icon: Icons.shield_outlined,
                      label: 'Format',
                      value: '${teamSize}v$teamSize ($totalParticipants players)',
                      onEdit: () => onEditStep(1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Disclaimer
          if (stake.amount > 0)
            SlideIn(
              delay: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RivlColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RivlColors.warning.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: RivlColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your \$${stake.amount.toInt()} stake will be held in escrow. All squad members must accept and stake to start. Winning squad splits the prize pool evenly.',
                        style: TextStyle(fontSize: 12, color: RivlColors.warning, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class ReviewSquadCard extends StatelessWidget {
  final String squadName;
  final String? label;
  final List<String> members;
  final Color color;
  final VoidCallback onEdit;

  const ReviewSquadCard({
    super.key,
    required this.squadName,
    this.label,
    required this.members,
    required this.color,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shield_outlined, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      squadName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
                    ),
                    if (label != null)
                      Text(label!, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: context.textSecondary),
                tooltip: 'Edit squad',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: members
                .map((name) => Chip(
                      avatar: CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                      label: Text(name, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class SquadReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const SquadReviewRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: RivlColors.primary),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, color: context.textSecondary, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onEdit,
          child: Icon(Icons.edit_outlined, size: 14, color: context.textSecondary),
        ),
      ],
    );
  }
}
