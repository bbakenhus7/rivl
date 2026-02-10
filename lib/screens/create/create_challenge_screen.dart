// screens/create/create_challenge_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../../widgets/confetti_celebration.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _challengeSent = false;

  static const int _totalSteps = 4;
  static const List<String> _stepTitles = [
    'Select Opponent',
    'Choose Stake',
    'Duration & Type',
    'Review & Send',
  ];

  bool _canProceed(ChallengeProvider provider) {
    switch (_currentStep) {
      case 0:
        return provider.selectedOpponent != null;
      case 1:
        return true; // Stake always has a default
      case 2:
        return true; // Duration and type always have defaults
      case 3:
        return !provider.isCreating;
      default:
        return false;
    }
  }

  void _nextStep(ChallengeProvider provider) {
    if (_currentStep < _totalSteps - 1 && _canProceed(provider)) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _sendChallenge(ChallengeProvider provider) async {
    final challengeId = await provider.createChallenge();
    if (challengeId != null && mounted) {
      setState(() => _challengeSent = true);
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to send challenge'),
          backgroundColor: RivlColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        return ConfettiCelebration(
          celebrate: _challengeSent,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _challengeSent ? 'Challenge Sent!' : _stepTitles[_currentStep],
                  key: ValueKey(_challengeSent ? 'sent' : _currentStep),
                ),
              ),
              leading: _currentStep == 0 || _challengeSent
                  ? const CloseButton()
                  : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _previousStep,
                    ),
            ),
            body: _challengeSent
                ? _buildSuccessView(provider)
                : Column(
                    children: [
                      // Progress indicator
                      _StepProgressIndicator(
                        currentStep: _currentStep,
                        totalSteps: _totalSteps,
                      ),

                      // Step content
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.05, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(_currentStep),
                            child: _buildStepContent(provider),
                          ),
                        ),
                      ),

                      // Bottom navigation buttons
                      _BottomNavButtons(
                        currentStep: _currentStep,
                        totalSteps: _totalSteps,
                        canProceed: _canProceed(provider),
                        isCreating: provider.isCreating,
                        onNext: () => _currentStep == _totalSteps - 1
                            ? _sendChallenge(provider)
                            : _nextStep(provider),
                        onBack: _previousStep,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(ChallengeProvider provider) {
    switch (_currentStep) {
      case 0:
        return _StepSelectOpponent(
          selectedOpponent: provider.selectedOpponent,
          onTap: () => _showOpponentPicker(context),
          onClear: () => provider.setSelectedOpponent(null),
        );
      case 1:
        return _StepChooseStake(
          selectedStake: provider.selectedStake,
          onChanged: provider.setSelectedStake,
        );
      case 2:
        return _StepDurationAndType(
          selectedDuration: provider.selectedDuration,
          onDurationChanged: provider.setSelectedDuration,
          selectedGoalType: provider.selectedGoalType,
          onGoalTypeSelected: provider.setSelectedGoalType,
        );
      case 3:
        return _StepReview(
          opponent: provider.selectedOpponent,
          stake: provider.selectedStake,
          duration: provider.selectedDuration,
          goalType: provider.selectedGoalType,
          onEditStep: (step) => setState(() => _currentStep = step),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSuccessView(ChallengeProvider provider) {
    final opponent = provider.selectedOpponent;
    return Center(
      child: SlideIn(
        offset: const Offset(0, 30),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: RivlColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: RivlColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Challenge Sent!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                opponent != null
                    ? '${opponent.displayName} has been challenged.\nThey\'ll be notified shortly.'
                    : 'Your challenge has been sent.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOpponentPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OpponentPickerSheet(),
    );
  }
}

// =============================================================================
// STEP PROGRESS INDICATOR
// =============================================================================

class _StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isCompleted
                      ? RivlColors.primary
                      : isCurrent
                          ? RivlColors.primary.withOpacity(0.6)
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.grey[300],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
// BOTTOM NAVIGATION BUTTONS
// =============================================================================

class _BottomNavButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool canProceed;
  final bool isCreating;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _BottomNavButtons({
    required this.currentStep,
    required this.totalSteps,
    required this.canProceed,
    required this.isCreating,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),

          // Next / Send button
          Expanded(
            flex: currentStep > 0 ? 2 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: canProceed ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep ? RivlColors.success : null,
                ),
                child: isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isLastStep ? 'Send Challenge' : 'Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 1: SELECT OPPONENT
// =============================================================================

class _StepSelectOpponent extends StatelessWidget {
  final UserModel? selectedOpponent;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _StepSelectOpponent({
    this.selectedOpponent,
    required this.onTap,
    required this.onClear,
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
              'Who do you want\nto challenge?',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Search for a friend or rival to compete against.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: _OpponentSelector(
              selectedOpponent: selectedOpponent,
              onTap: onTap,
              onClear: onClear,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentSelector extends StatelessWidget {
  final UserModel? selectedOpponent;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _OpponentSelector({
    this.selectedOpponent,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedOpponent != null) {
      return _buildSelectedCard(context);
    }
    return _buildEmptyCard(context);
  }

  Widget _buildSelectedCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RivlColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RivlColors.primary, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: RivlColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      selectedOpponent!.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: RivlColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedOpponent!.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${selectedOpponent!.username}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedOpponent!.wins}W - ${selectedOpponent!.losses}L',
                        style: TextStyle(
                          fontSize: 13,
                          color: RivlColors.primary.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: context.textSecondary,
                  ),
                  onPressed: onClear,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.12)
              : Colors.grey[300]!,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: RivlColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    size: 32,
                    color: RivlColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to search for an opponent',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find them by username',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// STEP 2: CHOOSE STAKE
// =============================================================================

class _StepChooseStake extends StatelessWidget {
  final StakeOption selectedStake;
  final Function(StakeOption) onChanged;

  const _StepChooseStake({
    required this.selectedStake,
    required this.onChanged,
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
              'How much are\nyou putting up?',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Both players stake the same amount. Winner takes the prize pool.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 32),

          // Prize pool display
          SlideIn(
            delay: const Duration(milliseconds: 250),
            child: _AnimatedPrizePool(stake: selectedStake),
          ),
          const SizedBox(height: 32),

          // Stake options
          SlideIn(
            delay: const Duration(milliseconds: 350),
            child: _StakeSelector(
              selectedStake: selectedStake,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPrizePool extends StatelessWidget {
  final StakeOption stake;

  const _AnimatedPrizePool({required this.stake});

  @override
  Widget build(BuildContext context) {
    final isFree = stake.amount == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RivlColors.primary.withOpacity(0.08),
            RivlColors.primary.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RivlColors.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            isFree ? 'Challenge Type' : 'Prize Pool',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          AnimatedValue(
            value: isFree ? 0 : stake.prize,
            prefix: isFree ? '' : '\$',
            decimals: isFree ? 0 : 0,
            duration: const Duration(milliseconds: 600),
            style: TextStyle(
              fontSize: isFree ? 36 : 48,
              fontWeight: FontWeight.bold,
              color: RivlColors.primary,
            ),
          ),
          if (isFree)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Free',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: RivlColors.primary,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            isFree ? 'Just for bragging rights!' : 'Winner takes all!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textSecondary,
                ),
          ),
          if (!isFree) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: RivlColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You stake ${stake.displayAmount}  |  3% platform fee',
                style: TextStyle(
                  fontSize: 12,
                  color: RivlColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StakeSelector extends StatelessWidget {
  final StakeOption selectedStake;
  final Function(StakeOption) onChanged;

  const _StakeSelector({required this.selectedStake, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isCustomSelected = !StakeOption.options
        .any((o) => o.amount == selectedStake.amount);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: StakeOption.options.map((option) {
        final bool isSelected;
        if (option.isCustom) {
          isSelected = isCustomSelected;
        } else {
          isSelected = selectedStake.amount == option.amount;
        }

        return GestureDetector(
          onTap: () {
            if (option.isCustom) {
              _showCustomStakeDialog(context);
            } else {
              onChanged(option);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 72) / 3,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? RivlColors.primary.withOpacity(0.1)
                  : context.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? RivlColors.primary
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  option.isCustom
                      ? (isCustomSelected
                          ? '\$${selectedStake.amount.toInt()}'
                          : 'Custom')
                      : option.displayAmount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isSelected ? RivlColors.primary : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.isCustom
                      ? (isCustomSelected
                          ? 'Win ${selectedStake.displayPrize}'
                          : 'Set amount')
                      : (option.amount == 0
                          ? 'For fun!'
                          : 'Win ${option.displayPrize}'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCustomStakeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Stake'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: '\$ ',
            hintText: 'Enter amount (5-500)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 5 && value <= 500) {
                onChanged(StakeOption.custom(value));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 3: DURATION & TYPE
// =============================================================================

class _StepDurationAndType extends StatelessWidget {
  final ChallengeDuration selectedDuration;
  final Function(ChallengeDuration) onDurationChanged;
  final GoalType selectedGoalType;
  final Function(GoalType) onGoalTypeSelected;

  const _StepDurationAndType({
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
            child: _DurationSelector(
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
            child: _ChallengeTypeGrid(
              selectedGoalType: selectedGoalType,
              onGoalTypeSelected: onGoalTypeSelected,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final ChallengeDuration selectedDuration;
  final Function(ChallengeDuration) onChanged;

  const _DurationSelector({
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

class _ChallengeTypeGrid extends StatelessWidget {
  final GoalType selectedGoalType;
  final Function(GoalType) onGoalTypeSelected;

  const _ChallengeTypeGrid({
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
        return _ChallengeTypeCard(
          goalType: goalType,
          isSelected: selectedGoalType == goalType,
          onTap: () => onGoalTypeSelected(goalType),
        );
      }).toList(),
    );
  }
}

class _ChallengeTypeCard extends StatelessWidget {
  final GoalType goalType;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChallengeTypeCard({
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

// =============================================================================
// STEP 4: REVIEW & SEND
// =============================================================================

class _StepReview extends StatelessWidget {
  final UserModel? opponent;
  final StakeOption stake;
  final ChallengeDuration duration;
  final GoalType goalType;
  final Function(int) onEditStep;

  const _StepReview({
    required this.opponent,
    required this.stake,
    required this.duration,
    required this.goalType,
    required this.onEditStep,
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
                        colors: [
                          RivlColors.primary,
                          RivlColors.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PRIZE POOL',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stake.amount == 0
                              ? 'Free'
                              : '\$${stake.prize.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (stake.amount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'You stake ${stake.displayAmount}',
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
                        _ReviewRow(
                          icon: Icons.person_outline,
                          label: 'Opponent',
                          value: opponent?.displayName ?? 'Not selected',
                          subtitle: opponent != null
                              ? '@${opponent!.username}'
                              : null,
                          onEdit: () => onEditStep(0),
                        ),
                        _buildDivider(context),
                        _ReviewRow(
                          icon: Icons.attach_money,
                          label: 'Your Stake',
                          value: stake.displayAmount,
                          onEdit: () => onEditStep(1),
                        ),
                        _buildDivider(context),
                        _ReviewRow(
                          icon: Icons.schedule,
                          label: 'Duration',
                          value: duration.displayName,
                          onEdit: () => onEditStep(2),
                        ),
                        _buildDivider(context),
                        _ReviewRow(
                          icon: goalType.icon,
                          label: 'Type',
                          value: goalType.displayName,
                          subtitle: goalType.description,
                          onEdit: () => onEditStep(2),
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
                      stake.amount > 0
                          ? 'Your stake of ${stake.displayAmount} will be held in escrow until the challenge ends. The winner receives the full prize pool.'
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

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback onEdit;

  const _ReviewRow({
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

// =============================================================================
// OPPONENT PICKER BOTTOM SHEET
// =============================================================================

class _OpponentPickerSheet extends StatefulWidget {
  const _OpponentPickerSheet();

  @override
  State<_OpponentPickerSheet> createState() => _OpponentPickerSheetState();
}

class _OpponentPickerSheetState extends State<_OpponentPickerSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  'Find Opponent',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by username...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<ChallengeProvider>()
                                  .clearSearch();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    context.read<ChallengeProvider>().searchUsers(value);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Results
              Expanded(
                child: Consumer<ChallengeProvider>(
                  builder: (context, provider, _) {
                    if (provider.isSearching) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (_searchController.text.length < 2) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 56,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Search for users',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: context.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Type at least 2 characters to find opponents',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (provider.searchResults.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off_outlined,
                                size: 56,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: context.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try a different username',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        bottom: 16 + bottomPadding,
                      ),
                      itemCount: provider.searchResults.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 72,
                      ),
                      itemBuilder: (context, index) {
                        final user = provider.searchResults[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: RivlColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: RivlColors.primary,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            user.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text('@${user.username}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${user.wins}W - ${user.losses}L',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.winPercentage,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            provider.setSelectedOpponent(user);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
