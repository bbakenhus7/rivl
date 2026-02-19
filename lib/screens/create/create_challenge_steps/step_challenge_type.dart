// Step 0: Challenge Type Selection

import 'package:flutter/material.dart';
import '../../../models/challenge_model.dart';
import '../../../utils/theme.dart';
import '../../../utils/animations.dart';

class StepChallengeType extends StatelessWidget {
  final ChallengeType selectedType;
  final bool isCharityMode;
  final Function(ChallengeType) onChanged;
  final Function(bool) onCharityToggled;

  const StepChallengeType({
    super.key,
    required this.selectedType,
    required this.isCharityMode,
    required this.onChanged,
    required this.onCharityToggled,
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
              'What kind of\nchallenge?',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Choose a head-to-head battle, group league, team vs team, or give back with a charity challenge.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: ChallengeTypeOption(
              icon: Icons.people_outline,
              title: '1v1 Challenge',
              subtitle: 'Head-to-head. Winner takes all.\nFree for friends | 3% AI Anti-Cheat Referee fee.',
              isSelected: selectedType == ChallengeType.headToHead && !isCharityMode,
              onTap: () {
                onCharityToggled(false);
                onChanged(ChallengeType.headToHead);
              },
            ),
          ),
          const SizedBox(height: 16),
          SlideIn(
            delay: const Duration(milliseconds: 400),
            child: ChallengeTypeOption(
              icon: Icons.volunteer_activism,
              title: '1v1 for Charity',
              subtitle: 'Head-to-head. Winner keeps their stake.\nLoser\'s stake goes to a charity of the winner\'s choice.',
              isSelected: isCharityMode,
              onTap: () {
                onCharityToggled(true);
                onChanged(ChallengeType.headToHead);
              },
            ),
          ),
          const SizedBox(height: 16),
          SlideIn(
            delay: const Duration(milliseconds: 500),
            child: ChallengeTypeOption(
              icon: Icons.groups_outlined,
              title: 'Group League',
              subtitle: '3-20 players. Top 3 win payouts.\n5% AI Anti-Cheat Referee fee.',
              isSelected: selectedType == ChallengeType.group && !isCharityMode,
              onTap: () {
                onCharityToggled(false);
                onChanged(ChallengeType.group);
              },
            ),
          ),
          const SizedBox(height: 16),
          SlideIn(
            delay: const Duration(milliseconds: 600),
            child: ChallengeTypeOption(
              icon: Icons.shield_outlined,
              title: 'Squad vs Squad',
              subtitle: '2v2 up to 20v20. Squads compete.\nWinning squad splits the prize. 5% AI Anti-Cheat Referee fee.',
              isSelected: selectedType == ChallengeType.teamVsTeam && !isCharityMode,
              onTap: () {
                onCharityToggled(false);
                onChanged(ChallengeType.teamVsTeam);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChallengeTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const ChallengeTypeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? RivlColors.primary.withOpacity(0.08)
              : context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? RivlColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? RivlColors.primary.withOpacity(0.15)
                    : RivlColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? RivlColors.primary : context.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? RivlColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textSecondary,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: RivlColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
