// Step 4/5 (h2h review): Review & Send

import 'package:flutter/material.dart';
import '../../../models/challenge_model.dart';
import '../../../models/user_model.dart';
import '../../../models/charity_model.dart';
import '../../../utils/theme.dart';
import '../../../utils/animations.dart';

class StepReview extends StatelessWidget {
  final UserModel? opponent;
  final StakeOption stake;
  final ChallengeDuration duration;
  final GoalType goalType;
  final Function(int) onEditStep;
  final bool isFriendChallenge;
  final bool isCharityChallenge;
  final CharityModel? charity;

  const StepReview({
    super.key,
    required this.opponent,
    required this.stake,
    required this.duration,
    required this.goalType,
    required this.onEditStep,
    this.isFriendChallenge = false,
    this.isCharityChallenge = false,
    this.charity,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideIn(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Review your\nchallenge',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Make sure everything looks good before sending.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 28),

          // Review card
          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with prize
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCharityChallenge
                            ? [Colors.pink[600]!, Colors.pink[400]!]
                            : [RivlColors.primary, RivlColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isCharityChallenge ? 'CHARITY CHALLENGE' : 'PRIZE POOL',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCharityChallenge
                              ? '\$${stake.amount.toInt()}'
                              : stake.amount == 0
                                  ? 'Free'
                                  : '\$${(isFriendChallenge ? stake.friendPrize : stake.prize).toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCharityChallenge) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Loser\'s ${stake.displayAmount} goes to charity',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ] else if (stake.amount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            isFriendChallenge
                                ? 'You stake ${stake.displayAmount}  |  No fee'
                                : 'You stake ${stake.displayAmount}  |  3% AI Anti-Cheat Referee fee',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        ReviewRow(
                          icon: Icons.person_outline,
                          label: 'Opponent',
                          value: opponent?.displayName ?? 'Not selected',
                          subtitle: opponent != null
                              ? '@${opponent!.username}'
                              : null,
                          onEdit: () => onEditStep(1),
                        ),
                        _buildDivider(context),
                        ReviewRow(
                          icon: Icons.attach_money,
                          label: 'Your Stake',
                          value: stake.displayAmount,
                          onEdit: () => onEditStep(2),
                        ),
                        if (isCharityChallenge && charity != null) ...[
                          _buildDivider(context),
                          ReviewRow(
                            icon: Icons.volunteer_activism,
                            label: 'Charity',
                            value: charity!.name,
                            subtitle: charity!.category,
                            onEdit: () => onEditStep(3),
                          ),
                        ],
                        _buildDivider(context),
                        ReviewRow(
                          icon: Icons.schedule,
                          label: 'Duration',
                          value: duration.displayName,
                          onEdit: () => onEditStep(isCharityChallenge ? 4 : 3),
                        ),
                        _buildDivider(context),
                        ReviewRow(
                          icon: goalType.icon,
                          label: 'Type',
                          value: goalType.displayName,
                          subtitle: goalType.description,
                          onEdit: () => onEditStep(isCharityChallenge ? 4 : 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Disclaimer
          SlideIn(
            delay: const Duration(milliseconds: 400),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RivlColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: RivlColors.warning.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: RivlColors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isCharityChallenge
                          ? 'Your stake of ${stake.displayAmount} will be held in escrow. Winner keeps their stake. Loser\'s stake goes to ${charity?.name ?? 'charity'}. No platform fee.'
                          : stake.amount > 0
                              ? isFriendChallenge
                                  ? 'Your stake of ${stake.displayAmount} will be held in escrow until the challenge ends. No fee for friend challenges — winner takes the full pot!'
                                  : 'Your stake of ${stake.displayAmount} will be held in escrow until the challenge ends. 3% AI Anti-Cheat Referee fee applies.'
                              : 'This is a free challenge. No money will be exchanged. Winner earns bragging rights and XP!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.4,
                          ),
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

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 24,
      thickness: 1,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(0.06)
          : Colors.grey[100],
    );
  }
}

class ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback onEdit;

  const ReviewRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: RivlColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: RivlColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: RivlColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Edit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RivlColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
