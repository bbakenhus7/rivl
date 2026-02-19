// Step 3/4: Duration & Type

import 'package:flutter/material.dart';
import '../../../models/challenge_model.dart';
import '../../../utils/theme.dart';
import '../../../utils/animations.dart';

class StepDurationAndType extends StatelessWidget {
  final ChallengeDuration selectedDuration;
  final Function(ChallengeDuration) onDurationChanged;
  final GoalType selectedGoalType;
  final Function(GoalType) onGoalTypeSelected;

  const StepDurationAndType({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
    required this.selectedGoalType,
    required this.onGoalTypeSelected,
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
              'Set the rules',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Choose how long and what type of challenge.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 28),

          // Duration
          SlideIn(
            delay: const Duration(milliseconds: 250),
            child: Text(
              'Duration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: DurationSelector(
              selectedDuration: selectedDuration,
              onChanged: onDurationChanged,
            ),
          ),
          const SizedBox(height: 28),

          // Competition Type
          SlideIn(
            delay: const Duration(milliseconds: 350),
            child: Text(
              'Competition Type',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          SlideIn(
            delay: const Duration(milliseconds: 400),
            child: ChallengeTypeGrid(
              selectedGoalType: selectedGoalType,
              onGoalTypeSelected: onGoalTypeSelected,
            ),
          ),
          const SizedBox(height: 24),

          // Goal preview card
          SlideIn(
            delay: const Duration(milliseconds: 450),
            child: GoalPreviewCard(
              goalType: selectedGoalType,
              duration: selectedDuration,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Shows the auto-calculated goal with daily breakdown and difficulty estimate
class GoalPreviewCard extends StatelessWidget {
  final GoalType goalType;
  final ChallengeDuration duration;

  const GoalPreviewCard({
    super.key,
    required this.goalType,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final totalGoal = _calculateGoal();
    final dailyGoal = _calculateDailyGoal();
    final unit = _getUnit();
    final difficulty = _getDifficulty();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RivlColors.primary.withOpacity(0.06),
            RivlColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RivlColors.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: RivlColors.primary),
              const SizedBox(width: 8),
              Text(
                'Challenge Goal',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: RivlColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: difficulty.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difficulty.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: difficulty.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Goal',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalGoal $unit',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: context.surfaceVariant,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Pace',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dailyGoal $unit/day',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: RivlColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${duration.displayName} · ${goalType.description}',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateGoal() {
    switch (goalType) {
      case GoalType.steps:
        return _formatNumber(duration.days * 10000);
      case GoalType.distance:
        return '${duration.days * 5}';
      case GoalType.milePace:
        return '8:00';
      case GoalType.fiveKPace:
        return '25:00';
      case GoalType.tenKPace:
        return '50:00';
      case GoalType.sleepDuration:
        return '${duration.days * 8}';
      case GoalType.zone2Cardio:
        return '${duration.days * 20}'; // ~20 min/day
      case GoalType.rivlHealthScore:
        return '75';
    }
  }

  String _calculateDailyGoal() {
    switch (goalType) {
      case GoalType.steps:
        return _formatNumber(10000);
      case GoalType.distance:
        return '5';
      case GoalType.milePace:
        return '8:00';
      case GoalType.fiveKPace:
        return '25:00';
      case GoalType.tenKPace:
        return '50:00';
      case GoalType.sleepDuration:
        return '8';
      case GoalType.zone2Cardio:
        return '20';
      case GoalType.rivlHealthScore:
        return '75';
    }
  }

  String _getUnit() {
    return goalType.unit;
  }

  ({String label, Color color}) _getDifficulty() {
    switch (goalType) {
      case GoalType.steps:
        return (label: 'Moderate', color: RivlColors.warning);
      case GoalType.distance:
        return (label: 'Moderate', color: RivlColors.warning);
      case GoalType.milePace:
        return (label: 'Hard', color: RivlColors.error);
      case GoalType.fiveKPace:
        return (label: 'Moderate', color: RivlColors.warning);
      case GoalType.tenKPace:
        return (label: 'Hard', color: RivlColors.error);
      case GoalType.sleepDuration:
        return (label: 'Easy', color: RivlColors.success);
      case GoalType.zone2Cardio:
        return (label: 'Moderate', color: RivlColors.warning);
      case GoalType.rivlHealthScore:
        return (label: 'Moderate', color: RivlColors.warning);
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}

class DurationSelector extends StatelessWidget {
  final ChallengeDuration selectedDuration;
  final Function(ChallengeDuration) onChanged;

  const DurationSelector({
    super.key,
    required this.selectedDuration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ChallengeDuration.values.map((duration) {
          final isSelected = selectedDuration == duration;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onChanged(duration),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? RivlColors.primary
                      : context.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? RivlColors.primary
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  duration.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ChallengeTypeGrid extends StatelessWidget {
  final GoalType selectedGoalType;
  final Function(GoalType) onGoalTypeSelected;

  const ChallengeTypeGrid({
    super.key,
    required this.selectedGoalType,
    required this.onGoalTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: GoalType.values.map((goalType) {
        return ChallengeTypeCard(
          goalType: goalType,
          isSelected: selectedGoalType == goalType,
          onTap: () => onGoalTypeSelected(goalType),
        );
      }).toList(),
    );
  }
}

class ChallengeTypeCard extends StatelessWidget {
  final GoalType goalType;
  final bool isSelected;
  final VoidCallback onTap;

  const ChallengeTypeCard({
    super.key,
    required this.goalType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? RivlColors.primary.withOpacity(0.1)
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with background circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? RivlColors.primary.withOpacity(0.2)
                      : RivlColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  goalType.icon,
                  size: 24,
                  color: isSelected
                      ? RivlColors.primary
                      : context.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                goalType.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? RivlColors.primary : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                goalType.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
