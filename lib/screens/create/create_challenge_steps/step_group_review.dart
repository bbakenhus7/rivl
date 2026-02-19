// Step 4 (group review): Group Review & Send

import 'package:flutter/material.dart';
import '../../../models/challenge_model.dart';
import '../../../models/user_model.dart';
import '../../../utils/theme.dart';
import '../../../utils/animations.dart';
import 'step_review.dart';

class StepGroupReview extends StatelessWidget {
  final List<UserModel> members;
  final StakeOption stake;
  final ChallengeDuration duration;
  final GoalType goalType;
  final int groupSize;
  final GroupPayoutStructure payoutStructure;
  final Function(int) onEditStep;

  const StepGroupReview({
    super.key,
    required this.members,
    required this.stake,
    required this.duration,
    required this.goalType,
    required this.groupSize,
    required this.payoutStructure,
    required this.onEditStep,
  });

  @override
  Widget build(BuildContext context) {
    final totalPot = stake.amount * groupSize;
    final prizePool = (totalPot * 0.95 * 100).roundToDouble() / 100;
    final isFree = stake.amount == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideIn(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Review your\ngroup league',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Make sure everything looks good before sending invites.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.textSecondary),
            ),
          ),
          const SizedBox(height: 28),

          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [RivlColors.primary, RivlColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups, color: Colors.white70, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'GROUP LEAGUE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isFree ? 'Free' : '\$${prizePool.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        if (!isFree) ...[
                          const SizedBox(height: 4),
                          Text(
                            'You stake ${stake.displayAmount}  |  $groupSize players',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ReviewPayoutBadge(place: '1st', amount: payoutStructure.firstDisplay(prizePool), color: const Color(0xFFFFD700)),
                              ReviewPayoutBadge(place: '2nd', amount: payoutStructure.secondDisplay(prizePool), color: const Color(0xFFC0C0C0)),
                              ReviewPayoutBadge(place: '3rd', amount: payoutStructure.thirdDisplay(prizePool), color: const Color(0xFFCD7F32)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        ReviewRow(
                          icon: Icons.groups_outlined,
                          label: 'Members',
                          value: '${members.length + 1} of $groupSize',
                          subtitle: members.map((m) => m.displayName).join(', '),
                          onEdit: () => onEditStep(1),
                        ),
                        _buildDivider(context),
                        ReviewRow(
                          icon: Icons.attach_money,
                          label: 'Entry Fee',
                          value: stake.displayAmount,
                          onEdit: () => onEditStep(2),
                        ),
                        _buildDivider(context),
                        ReviewRow(
                          icon: Icons.schedule,
                          label: 'Duration',
                          value: duration.displayName,
                          onEdit: () => onEditStep(3),
                        ),
                        _buildDivider(context),
                        ReviewRow(
                          icon: goalType.icon,
                          label: 'Type',
                          value: goalType.displayName,
                          subtitle: goalType.description,
                          onEdit: () => onEditStep(3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          SlideIn(
            delay: const Duration(milliseconds: 400),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RivlColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RivlColors.warning.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: RivlColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isFree
                          ? 'This is a free group league. No money will be exchanged. Top 3 earn XP and bragging rights!'
                          : 'Your entry fee of ${stake.displayAmount} will be held in escrow. 5% AI Anti-Cheat Referee fee. 1st, 2nd, and 3rd place win payouts when the challenge ends.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
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

class ReviewPayoutBadge extends StatelessWidget {
  final String place;
  final String amount;
  final Color color;

  const ReviewPayoutBadge({super.key, required this.place, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(place, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.9))),
        const SizedBox(height: 2),
        Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }
}
