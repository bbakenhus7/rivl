// screens/create/create_challenge_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../main_screen.dart';
import '../../widgets/confetti_celebration.dart';
import '../../widgets/add_funds_sheet.dart';
import '../../providers/friend_provider.dart';
import '../../models/charity_model.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _challengeSent = false;

  // Step definitions change based on mode
  List<String> _stepTitles(ChallengeType type, {bool isCharity = false}) {
    switch (type) {
      case ChallengeType.group:
        return ['Challenge Type', 'Add Members', 'Choose Stake', 'Duration & Type', 'Review & Send'];
      case ChallengeType.teamVsTeam:
        return ['Challenge Type', 'Build Squads', 'Choose Stake', 'Duration & Type', 'Review & Send'];
      case ChallengeType.headToHead:
        if (isCharity) {
          return ['Challenge Type', 'Select Opponent', 'Choose Stake', 'Select Charity', 'Duration & Type', 'Review & Send'];
        }
        return ['Challenge Type', 'Select Opponent', 'Choose Stake', 'Duration & Type', 'Review & Send'];
    }
  }

  int _totalSteps(ChallengeType type, {bool isCharity = false}) => _stepTitles(type, isCharity: isCharity).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().loadDemoOpponents();
    });
  }

  bool _canProceed(ChallengeProvider provider) {
    final isCharity = provider.isCharityMode;
    final total = _totalSteps(provider.selectedChallengeType, isCharity: isCharity);
    switch (_currentStep) {
      case 0:
        return true; // Challenge type always selected
      case 1:
        if (provider.isGroupMode) {
          return provider.selectedGroupMembers.isNotEmpty;
        } else if (provider.isTeamMode) {
          final hasNames = provider.teamAName.trim().isNotEmpty &&
              provider.teamBName.trim().isNotEmpty;
          final hasTeamBMembers = provider.teamBMembers.isNotEmpty;
          final hasTeamAMembers = provider.teamSize <= 2 || provider.teamAMembers.isNotEmpty;
          return hasNames && hasTeamBMembers && hasTeamAMembers;
        }
        return provider.selectedOpponent != null;
      case 2:
        if (isCharity && provider.selectedStake.amount <= 0) return false;
        return true; // Stake always has a default
      case 3:
        if (isCharity) return provider.selectedCharity != null;
        return true; // Duration and type always have defaults
      case 4:
        if (isCharity) return true; // Duration & Type step for charity
        return !provider.isCreating;
      case 5:
        if (isCharity) return !provider.isCreating;
        return false;
      default:
        return _currentStep == total - 1 ? !provider.isCreating : false;
    }
  }

  void _nextStep(ChallengeProvider provider) async {
    final isCharity = provider.isCharityMode;
    final total = _totalSteps(provider.selectedChallengeType, isCharity: isCharity);
    if (_currentStep < total - 1 && _canProceed(provider)) {
      // Validate balance when leaving the stake step (step 2)
      if (_currentStep == 2) {
        final stakeAmount = provider.selectedStake.amount;
        var walletBalance = context.read<WalletProvider>().balance;
        if (stakeAmount > 0 && walletBalance < stakeAmount) {
          final funded = await showAddFundsSheet(
            context,
            stakeAmount: stakeAmount,
            currentBalance: walletBalance,
          );
          if (!funded || !mounted) return;
        }
      }
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _sendChallenge(ChallengeProvider provider) async {
    var walletBalance = context.read<WalletProvider>().balance;
    final stakeAmount = provider.selectedStake.amount;

    // Prompt to add funds if balance is insufficient
    if (stakeAmount > 0 && walletBalance < stakeAmount) {
      final funded = await showAddFundsSheet(
        context,
        stakeAmount: stakeAmount,
        currentBalance: walletBalance,
      );
      if (!funded || !mounted) return;
      walletBalance = context.read<WalletProvider>().balance;
    }

    final String? challengeId;
    if (provider.isTeamMode) {
      challengeId = await provider.createTeamChallenge(walletBalance: walletBalance);
    } else if (provider.isGroupMode) {
      challengeId = await provider.createGroupChallenge(walletBalance: walletBalance);
    } else {
      final isFriend = provider.selectedOpponent != null &&
          context.read<FriendProvider>().isFriend(provider.selectedOpponent!.id);
      challengeId = await provider.createChallenge(
        walletBalance: walletBalance,
        isFriendChallenge: isFriend,
      );
    }

    if (challengeId != null && mounted) {
      setState(() => _challengeSent = true);
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        // Switch to Challenges tab instead of pop — this screen is
        // embedded in MainScreen's IndexedStack, not a pushed route,
        // so pop() would remove MainScreen itself.
        MainScreen.onTabSelected?.call(1);
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
        final challengeType = provider.selectedChallengeType;
        final isCharity = provider.isCharityMode;
        final totalSteps = _totalSteps(challengeType, isCharity: isCharity);
        final titles = _stepTitles(challengeType, isCharity: isCharity);

        return ConfettiCelebration(
          celebrate: _challengeSent,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _challengeSent ? 'Challenge Sent!' : titles[_currentStep.clamp(0, titles.length - 1)],
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
                        totalSteps: totalSteps,
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
                            key: ValueKey('${challengeType.name}-${isCharity ? 'charity' : 'normal'}-$_currentStep'),
                            child: _buildStepContent(provider),
                          ),
                        ),
                      ),

                      // Bottom navigation buttons
                      _BottomNavButtons(
                        currentStep: _currentStep,
                        totalSteps: totalSteps,
                        canProceed: _canProceed(provider),
                        isCreating: provider.isCreating,
                        onNext: () => _currentStep == totalSteps - 1
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
    final isGroup = provider.isGroupMode;
    final isTeam = provider.isTeamMode;
    final isCharity = provider.isCharityMode;

    // For charity mode, steps are: 0-Type, 1-Opponent, 2-Stake, 3-Charity, 4-Duration, 5-Review
    // For normal h2h:              0-Type, 1-Opponent, 2-Stake, 3-Duration, 4-Review
    if (isCharity && !isGroup && !isTeam) {
      switch (_currentStep) {
        case 0:
          return _StepChallengeType(
            selectedType: provider.selectedChallengeType,
            isCharityMode: true,
            onChanged: (type) {
              provider.setSelectedChallengeType(type);
            },
            onCharityToggled: (enabled) {
              provider.setCharityMode(enabled);
              if (!enabled) setState(() => _currentStep = 0);
            },
          );
        case 1:
          return _StepSelectOpponent(
            selectedOpponent: provider.selectedOpponent,
            suggestedOpponents: provider.demoOpponents,
            onTap: () => _showOpponentPicker(context),
            onClear: () => provider.setSelectedOpponent(null),
            onSelectOpponent: (user) => provider.setSelectedOpponent(user),
          );
        case 2:
          return _StepChooseStake(
            selectedStake: provider.selectedStake,
            onChanged: provider.setSelectedStake,
            isCharity: true,
          );
        case 3:
          return _StepSelectCharity(
            selectedCharity: provider.selectedCharity,
            onChanged: provider.setSelectedCharity,
          );
        case 4:
          return _StepDurationAndType(
            selectedDuration: provider.selectedDuration,
            onDurationChanged: provider.setSelectedDuration,
            selectedGoalType: provider.selectedGoalType,
            onGoalTypeSelected: provider.setSelectedGoalType,
          );
        case 5:
          final isFriend = provider.selectedOpponent != null &&
              context.read<FriendProvider>().isFriend(provider.selectedOpponent!.id);
          return _StepReview(
            opponent: provider.selectedOpponent,
            stake: provider.selectedStake,
            duration: provider.selectedDuration,
            goalType: provider.selectedGoalType,
            onEditStep: (step) => setState(() => _currentStep = step),
            isFriendChallenge: isFriend,
            isCharityChallenge: true,
            charity: provider.selectedCharity,
          );
        default:
          return const SizedBox.shrink();
      }
    }

    switch (_currentStep) {
      case 0:
        return _StepChallengeType(
          selectedType: provider.selectedChallengeType,
          isCharityMode: false,
          onChanged: (type) {
            provider.setSelectedChallengeType(type);
          },
          onCharityToggled: (enabled) {
            provider.setCharityMode(enabled);
            if (enabled) {
              provider.setSelectedChallengeType(ChallengeType.headToHead);
            }
          },
        );
      case 1:
        if (isTeam) {
          return _StepBuildTeams(
            teamAName: provider.teamAName,
            teamBName: provider.teamBName,
            teamALabel: provider.teamALabel,
            teamBLabel: provider.teamBLabel,
            teamAMembers: provider.teamAMembers,
            teamBMembers: provider.teamBMembers,
            teamSize: provider.teamSize,
            suggestedOpponents: provider.demoOpponents,
            onTeamANameChanged: provider.setTeamAName,
            onTeamBNameChanged: provider.setTeamBName,
            onTeamALabelChanged: provider.setTeamALabel,
            onTeamBLabelChanged: provider.setTeamBLabel,
            onTeamSizeChanged: provider.setTeamSize,
            onAddTeamAMember: provider.addTeamAMember,
            onRemoveTeamAMember: provider.removeTeamAMember,
            onAddTeamBMember: provider.addTeamBMember,
            onRemoveTeamBMember: provider.removeTeamBMember,
            onSearchTap: (bool isTeamA) =>
                _showTeamMemberPicker(context, isTeamA, provider),
          );
        }
        if (isGroup) {
          return _StepAddGroupMembers(
            selectedMembers: provider.selectedGroupMembers,
            suggestedOpponents: provider.demoOpponents,
            groupSize: provider.groupSize,
            onGroupSizeChanged: provider.setGroupSize,
            onAddMember: provider.addGroupMember,
            onRemoveMember: provider.removeGroupMember,
            onSearchTap: () => _showGroupMemberPicker(context),
            payoutStructure: provider.selectedPayoutStructure,
            onPayoutChanged: provider.setSelectedPayoutStructure,
            stakeAmount: provider.selectedStake.amount,
          );
        }
        return _StepSelectOpponent(
          selectedOpponent: provider.selectedOpponent,
          suggestedOpponents: provider.demoOpponents,
          onTap: () => _showOpponentPicker(context),
          onClear: () => provider.setSelectedOpponent(null),
          onSelectOpponent: (user) => provider.setSelectedOpponent(user),
        );
      case 2:
        return _StepChooseStake(
          selectedStake: provider.selectedStake,
          onChanged: provider.setSelectedStake,
          isGroup: isGroup || isTeam,
          groupSize: isTeam ? provider.teamSize * 2 : provider.groupSize,
        );
      case 3:
        return _StepDurationAndType(
          selectedDuration: provider.selectedDuration,
          onDurationChanged: provider.setSelectedDuration,
          selectedGoalType: provider.selectedGoalType,
          onGoalTypeSelected: provider.setSelectedGoalType,
        );
      case 4:
        if (isTeam) {
          return _StepTeamReview(
            teamAName: provider.teamAName,
            teamBName: provider.teamBName,
            teamALabel: provider.teamALabel,
            teamBLabel: provider.teamBLabel,
            teamAMembers: provider.teamAMembers,
            teamBMembers: provider.teamBMembers,
            teamSize: provider.teamSize,
            stake: provider.selectedStake,
            duration: provider.selectedDuration,
            goalType: provider.selectedGoalType,
            onEditStep: (step) => setState(() => _currentStep = step),
          );
        }
        if (isGroup) {
          return _StepGroupReview(
            members: provider.selectedGroupMembers,
            stake: provider.selectedStake,
            duration: provider.selectedDuration,
            goalType: provider.selectedGoalType,
            groupSize: provider.groupSize,
            payoutStructure: provider.selectedPayoutStructure,
            onEditStep: (step) => setState(() => _currentStep = step),
          );
        }
        final isFriend = provider.selectedOpponent != null &&
            context.read<FriendProvider>().isFriend(provider.selectedOpponent!.id);
        return _StepReview(
          opponent: provider.selectedOpponent,
          stake: provider.selectedStake,
          duration: provider.selectedDuration,
          goalType: provider.selectedGoalType,
          onEditStep: (step) => setState(() => _currentStep = step),
          isFriendChallenge: isFriend,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSuccessView(ChallengeProvider provider) {
    final message = provider.successMessage ?? 'Your challenge has been sent.';
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
                message,
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

  void _showGroupMemberPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GroupMemberPickerSheet(),
    );
  }

  void _showTeamMemberPicker(
      BuildContext context, bool isTeamA, ChallengeProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TeamMemberPickerSheet(
        isTeamA: isTeamA,
        provider: provider,
      ),
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
  final List<UserModel> suggestedOpponents;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final Function(UserModel) onSelectOpponent;

  const _StepSelectOpponent({
    this.selectedOpponent,
    required this.suggestedOpponents,
    required this.onTap,
    required this.onClear,
    required this.onSelectOpponent,
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
              'Select an opponent or search for a friend.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          if (selectedOpponent != null)
            SlideIn(
              delay: const Duration(milliseconds: 300),
              child: _OpponentSelector(
                selectedOpponent: selectedOpponent,
                onTap: onTap,
                onClear: onClear,
              ),
            )
          else ...[
            // Suggested opponents
            if (suggestedOpponents.isNotEmpty) ...[
              SlideIn(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Suggested',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(suggestedOpponents.length, (index) {
                final opponent = suggestedOpponents[index];
                return SlideIn(
                  delay: Duration(milliseconds: 350 + (index * 80)),
                  child: _SuggestedOpponentCard(
                    opponent: opponent,
                    onTap: () => onSelectOpponent(opponent),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
            // Search button
            SlideIn(
              delay: Duration(
                milliseconds: suggestedOpponents.isNotEmpty
                    ? 350 + (suggestedOpponents.length * 80)
                    : 300,
              ),
              child: _SearchOpponentButton(onTap: onTap),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestedOpponentCard extends StatelessWidget {
  final UserModel opponent;
  final VoidCallback onTap;

  const _SuggestedOpponentCard({
    required this.opponent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[200]!,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: RivlColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (opponent.displayName.isNotEmpty ? opponent.displayName[0] : '?').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: RivlColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opponent.displayName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '@${opponent.username}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.textSecondary,
                                  ),
                            ),
                            if (context.read<FriendProvider>().isFriend(opponent.id)) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: RivlColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Friend',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: RivlColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${opponent.wins}W - ${opponent.losses}L',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opponent.winPercentage,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: context.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchOpponentButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchOpponentButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey[200]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color: RivlColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Search by username',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: RivlColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
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
                      (selectedOpponent!.displayName.isNotEmpty ? selectedOpponent!.displayName[0] : '?').toUpperCase(),
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
  final bool isGroup;
  final int groupSize;
  final bool isCharity;

  const _StepChooseStake({
    required this.selectedStake,
    required this.onChanged,
    this.isGroup = false,
    this.groupSize = 2,
    this.isCharity = false,
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
              isCharity
                  ? 'Both players stake the same amount. Winner keeps their stake. Loser\'s stake goes to charity.'
                  : isGroup
                      ? 'Each player stakes the same amount. Top 3 split the prize pool.'
                      : 'Both players stake the same amount. Winner takes the prize pool.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          if (isCharity && selectedStake.amount <= 0) ...[
            const SizedBox(height: 16),
            SlideIn(
              delay: const Duration(milliseconds: 220),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RivlColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RivlColors.warning.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: RivlColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Charity challenges require a stake amount.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: RivlColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Prize pool display
          SlideIn(
            delay: const Duration(milliseconds: 250),
            child: isCharity
                ? _CharityPrizeDisplay(stake: selectedStake)
                : isGroup
                    ? _GroupPrizePoolDisplay(stake: selectedStake, groupSize: groupSize)
                    : Builder(
                        builder: (context) {
                          final opponent = context.read<ChallengeProvider>().selectedOpponent;
                          final isFriend = opponent != null &&
                              context.read<FriendProvider>().isFriend(opponent.id);
                          return _AnimatedPrizePool(stake: selectedStake, isFriendChallenge: isFriend);
                        },
                      ),
          ),
          const SizedBox(height: 32),

          // Wallet balance indicator
          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: Consumer<WalletProvider>(
              builder: (context, wallet, _) {
                final insufficient =
                    selectedStake.amount > 0 && wallet.balance < selectedStake.amount;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: insufficient
                        ? Colors.orange.withOpacity(0.1)
                        : RivlColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: insufficient
                          ? Colors.orange.withOpacity(0.3)
                          : RivlColors.success.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        insufficient
                            ? Icons.warning_amber_rounded
                            : Icons.account_balance_wallet,
                        size: 18,
                        color: insufficient ? Colors.orange[700] : RivlColors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          insufficient
                              ? 'Balance: \$${wallet.balance.toStringAsFixed(0)} — need \$${selectedStake.amount.toStringAsFixed(0)}'
                              : 'Balance: \$${wallet.balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: insufficient ? Colors.orange[700] : RivlColors.success,
                          ),
                        ),
                      ),
                      if (insufficient)
                        Text(
                          'Add funds on next step',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

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
  final bool isFriendChallenge;

  const _AnimatedPrizePool({required this.stake, this.isFriendChallenge = false});

  @override
  Widget build(BuildContext context) {
    final isFree = stake.amount == 0;
    final displayPrize = isFriendChallenge ? stake.friendPrize : stake.prize;
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
            value: isFree ? 0 : displayPrize,
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
                color: isFriendChallenge
                    ? RivlColors.success.withOpacity(0.1)
                    : RivlColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isFriendChallenge
                    ? 'You stake ${stake.displayAmount}  |  No fee (friend challenge)'
                    : 'You stake ${stake.displayAmount}  |  3% AI Anti-Cheat Referee fee',
                style: TextStyle(
                  fontSize: 12,
                  color: isFriendChallenge
                      ? RivlColors.success.withOpacity(0.8)
                      : RivlColors.primary.withOpacity(0.8),
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

class _CharityPrizeDisplay extends StatelessWidget {
  final StakeOption stake;

  const _CharityPrizeDisplay({required this.stake});

  @override
  Widget build(BuildContext context) {
    final isFree = stake.amount <= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.withOpacity(0.08),
            Colors.purple.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.pink.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Charity Stake',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isFree ? '\$0' : '\$${stake.amount.toInt()}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isFree ? Colors.grey : Colors.pink[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFree
                ? 'Select a stake amount above'
                : 'Loser\'s stake goes to charity',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textSecondary,
                ),
          ),
          if (!isFree) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: RivlColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Winner keeps their ${stake.displayAmount}  |  No platform fee',
                style: TextStyle(
                  fontSize: 12,
                  color: RivlColors.success.withOpacity(0.8),
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
          const SizedBox(height: 24),

          // Goal preview card
          SlideIn(
            delay: const Duration(milliseconds: 450),
            child: _GoalPreviewCard(
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
class _GoalPreviewCard extends StatelessWidget {
  final GoalType goalType;
  final ChallengeDuration duration;

  const _GoalPreviewCard({
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
        return (label: 'Moderate', color: Colors.orange);
      case GoalType.distance:
        return (label: 'Moderate', color: Colors.orange);
      case GoalType.milePace:
        return (label: 'Hard', color: RivlColors.error);
      case GoalType.fiveKPace:
        return (label: 'Moderate', color: Colors.orange);
      case GoalType.tenKPace:
        return (label: 'Hard', color: RivlColors.error);
      case GoalType.sleepDuration:
        return (label: 'Easy', color: RivlColors.success);
      case GoalType.zone2Cardio:
        return (label: 'Moderate', color: Colors.orange);
      case GoalType.rivlHealthScore:
        return (label: 'Moderate', color: Colors.orange);
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
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
  final bool isFriendChallenge;
  final bool isCharityChallenge;
  final CharityModel? charity;

  const _StepReview({
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
                        _ReviewRow(
                          icon: Icons.person_outline,
                          label: 'Opponent',
                          value: opponent?.displayName ?? 'Not selected',
                          subtitle: opponent != null
                              ? '@${opponent!.username}'
                              : null,
                          onEdit: () => onEditStep(1),
                        ),
                        _buildDivider(context),
                        _ReviewRow(
                          icon: Icons.attach_money,
                          label: 'Your Stake',
                          value: stake.displayAmount,
                          onEdit: () => onEditStep(2),
                        ),
                        if (isCharityChallenge && charity != null) ...[
                          _buildDivider(context),
                          _ReviewRow(
                            icon: Icons.volunteer_activism,
                            label: 'Charity',
                            value: charity!.name,
                            subtitle: charity!.category,
                            onEdit: () => onEditStep(3),
                          ),
                        ],
                        _buildDivider(context),
                        _ReviewRow(
                          icon: Icons.schedule,
                          label: 'Duration',
                          value: duration.displayName,
                          onEdit: () => onEditStep(isCharityChallenge ? 4 : 3),
                        ),
                        _buildDivider(context),
                        _ReviewRow(
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
                    color: context.surfaceVariant,
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
                      // Show demo opponents as suggestions
                      if (provider.demoOpponents.isNotEmpty) {
                        return ListView(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                            bottom: 16 + bottomPadding,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Text(
                                'Suggested',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: context.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            ...provider.demoOpponents.map((user) {
                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 6,
                                    ),
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: RivlColors.primary
                                            .withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          (user.displayName.isNotEmpty ? user.displayName[0] : '?')
                                              .toUpperCase(),
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
                                    subtitle: Row(
                                      children: [
                                        Text('@${user.username}'),
                                        if (context.read<FriendProvider>().isFriend(user.id)) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: RivlColors.success.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Friend',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: RivlColors.success,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${user.wins}W - ${user.losses}L',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w500,
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
                                        if (user.currentStreak > 0)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    top: 2),
                                            child: Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Icon(Icons.whatshot,
                                                    size: 11,
                                                    color: Colors
                                                        .orange[600]),
                                                const SizedBox(
                                                    width: 2),
                                                Text(
                                                  '${user.currentStreak} streak',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors
                                                        .orange[600],
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      provider
                                          .setSelectedOpponent(user);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  const Divider(
                                    height: 1,
                                    indent: 72,
                                  ),
                                ],
                              );
                            }),
                          ],
                        );
                      }
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 56,
                                color: context.textSecondary,
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
                                color: context.textSecondary,
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
                                (user.displayName.isNotEmpty ? user.displayName[0] : '?').toUpperCase(),
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
                              if (user.currentStreak > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.whatshot,
                                          size: 11,
                                          color: Colors.orange[600]),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${user.currentStreak} streak',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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

// =============================================================================
// CHARITY: SELECT CHARITY STEP
// =============================================================================

class _StepSelectCharity extends StatelessWidget {
  final CharityModel? selectedCharity;
  final Function(CharityModel?) onChanged;

  const _StepSelectCharity({
    this.selectedCharity,
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
              'Choose a\ncharity',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'The winner chooses where the loser\'s stake goes. Select a charity.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          ...List.generate(CharityModel.availableCharities.length, (index) {
            final charity = CharityModel.availableCharities[index];
            final isSelected = selectedCharity?.id == charity.id;
            return SlideIn(
              delay: Duration(milliseconds: 300 + (index * 80)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => onChanged(charity),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.pink.withOpacity(0.08)
                          : context.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.pink : Colors.transparent,
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.pink.withOpacity(0.15)
                                : Colors.pink.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            charity.icon,
                            size: 24,
                            color: isSelected
                                ? Colors.pink[600]
                                : context.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                charity.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.pink[600] : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                charity.description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.textSecondary,
                                      height: 1.3,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isSelected)
                          Icon(Icons.check_circle, color: Colors.pink[600], size: 24)
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pink.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              charity.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.pink[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 0: CHALLENGE TYPE SELECTOR (1v1 vs Group)
// =============================================================================

class _StepChallengeType extends StatelessWidget {
  final ChallengeType selectedType;
  final bool isCharityMode;
  final Function(ChallengeType) onChanged;
  final Function(bool) onCharityToggled;

  const _StepChallengeType({
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
            child: _ChallengeTypeOption(
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
            child: _ChallengeTypeOption(
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
            child: _ChallengeTypeOption(
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
            child: _ChallengeTypeOption(
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

class _ChallengeTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChallengeTypeOption({
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

// =============================================================================
// GROUP: ADD MEMBERS STEP
// =============================================================================

class _StepAddGroupMembers extends StatelessWidget {
  final List<UserModel> selectedMembers;
  final List<UserModel> suggestedOpponents;
  final int groupSize;
  final Function(int) onGroupSizeChanged;
  final Function(UserModel) onAddMember;
  final Function(String) onRemoveMember;
  final VoidCallback onSearchTap;
  final GroupPayoutStructure payoutStructure;
  final Function(GroupPayoutStructure) onPayoutChanged;
  final double stakeAmount;

  const _StepAddGroupMembers({
    required this.selectedMembers,
    required this.suggestedOpponents,
    required this.groupSize,
    required this.onGroupSizeChanged,
    required this.onAddMember,
    required this.onRemoveMember,
    required this.onSearchTap,
    required this.payoutStructure,
    required this.onPayoutChanged,
    required this.stakeAmount,
  });

  @override
  Widget build(BuildContext context) {
    final slotsRemaining = groupSize - 1 - selectedMembers.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideIn(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Build your\nleague',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Add members and configure the payout structure.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 28),

          // Group size selector
          SlideIn(
            delay: const Duration(milliseconds: 250),
            child: Text(
              'Group Size',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: _GroupSizeSelector(
              groupSize: groupSize,
              onChanged: onGroupSizeChanged,
            ),
          ),
          const SizedBox(height: 24),

          // Payout structure
          SlideIn(
            delay: const Duration(milliseconds: 350),
            child: Text(
              'Payout Split',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          SlideIn(
            delay: const Duration(milliseconds: 400),
            child: _PayoutStructureSelector(
              selected: payoutStructure,
              onChanged: onPayoutChanged,
            ),
          ),
          const SizedBox(height: 24),

          // Members list header
          SlideIn(
            delay: const Duration(milliseconds: 450),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${selectedMembers.length + 1}/$groupSize',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: RivlColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // You (creator)
          SlideIn(
            delay: const Duration(milliseconds: 500),
            child: _MemberChip(name: 'You (Creator)', isCreator: true),
          ),

          // Selected members
          ...List.generate(selectedMembers.length, (index) {
            final member = selectedMembers[index];
            return SlideIn(
              delay: Duration(milliseconds: 520 + (index * 50)),
              child: _MemberChip(
                name: member.displayName,
                subtitle: '@${member.username}',
                onRemove: () => onRemoveMember(member.id),
              ),
            );
          }),

          // Add from suggested
          if (slotsRemaining > 0) ...[
            const SizedBox(height: 12),
            SlideIn(
              delay: Duration(milliseconds: 520 + (selectedMembers.length * 50)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (suggestedOpponents.isNotEmpty) ...[
                    Text(
                      'Quick Add',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestedOpponents
                          .where((u) => !selectedMembers.any((m) => m.id == u.id))
                          .map((user) => ActionChip(
                                avatar: CircleAvatar(
                                  backgroundColor: RivlColors.primary.withOpacity(0.15),
                                  child: Text(
                                    (user.displayName.isNotEmpty ? user.displayName[0] : '?').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: RivlColors.primary,
                                    ),
                                  ),
                                ),
                                label: Text(user.displayName),
                                onPressed: () => onAddMember(user),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _SearchOpponentButton(onTap: onSearchTap),
                  const SizedBox(height: 8),
                  Text(
                    '$slotsRemaining slot${slotsRemaining == 1 ? '' : 's'} remaining',
                    style: TextStyle(fontSize: 13, color: context.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final String name;
  final String? subtitle;
  final bool isCreator;
  final VoidCallback? onRemove;

  const _MemberChip({
    required this.name,
    this.subtitle,
    this.isCreator = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCreator
              ? RivlColors.primary.withOpacity(0.08)
              : context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCreator
                ? RivlColors.primary.withOpacity(0.3)
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: RivlColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RivlColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isCreator ? RivlColors.primary : null,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                ],
              ),
            ),
            if (isCreator)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RivlColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HOST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: RivlColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            if (onRemove != null)
              IconButton(
                icon: Icon(Icons.close, size: 18, color: context.textSecondary),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupSizeSelector extends StatelessWidget {
  final int groupSize;
  final Function(int) onChanged;

  const _GroupSizeSelector({required this.groupSize, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const sizes = [3, 4, 5, 6, 8, 10, 12, 16, 20];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sizes.map((size) {
          final isSelected = groupSize == size;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(size),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? RivlColors.primary : context.surface,
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
                child: Center(
                  child: Text(
                    '$size',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isSelected ? Colors.white : null,
                    ),
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

class _PayoutStructureSelector extends StatelessWidget {
  final GroupPayoutStructure selected;
  final Function(GroupPayoutStructure) onChanged;

  const _PayoutStructureSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (structure: GroupPayoutStructure.standard, label: 'Standard', detail: '60 / 25 / 15'),
      (structure: GroupPayoutStructure.winnerHeavy, label: 'Winner Heavy', detail: '70 / 20 / 10'),
      (structure: GroupPayoutStructure.flat, label: 'Balanced', detail: '50 / 30 / 20'),
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = selected.firstPercent == opt.structure.firstPercent &&
            selected.secondPercent == opt.structure.secondPercent;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: opt != options.last ? 10 : 0),
            child: GestureDetector(
              onTap: () => onChanged(opt.structure),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? RivlColors.primary.withOpacity(0.1)
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
                child: Column(
                  children: [
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected ? RivlColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opt.detail,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// GROUP: PRIZE POOL DISPLAY
// =============================================================================

class _GroupPrizePoolDisplay extends StatelessWidget {
  final StakeOption stake;
  final int groupSize;

  const _GroupPrizePoolDisplay({required this.stake, required this.groupSize});

  @override
  Widget build(BuildContext context) {
    final isFree = stake.amount == 0;
    final totalPot = stake.amount * groupSize;
    final prizePool = (totalPot * 0.95 * 100).roundToDouble() / 100;
    final fee = totalPot - prizePool;
    final payout = GroupPayoutStructure.standard;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
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
        border: Border.all(color: RivlColors.primary.withOpacity(0.15)),
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
          Text(
            isFree ? 'Free' : '\$${prizePool.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isFree ? 36 : 44,
              fontWeight: FontWeight.bold,
              color: RivlColors.primary,
            ),
          ),
          if (!isFree) ...[
            const SizedBox(height: 4),
            Text(
              '$groupSize players \u00d7 ${stake.displayAmount}  |  5% AI Anti-Cheat Referee fee (\$${fee.toStringAsFixed(0)})',
              style: TextStyle(
                fontSize: 12,
                color: RivlColors.primary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PayoutBadge(place: '1st', amount: payout.firstDisplay(prizePool), color: const Color(0xFFFFD700)),
                _PayoutBadge(place: '2nd', amount: payout.secondDisplay(prizePool), color: const Color(0xFFC0C0C0)),
                _PayoutBadge(place: '3rd', amount: payout.thirdDisplay(prizePool), color: const Color(0xFFCD7F32)),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Just for bragging rights!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayoutBadge extends StatelessWidget {
  final String place;
  final String amount;
  final Color color;

  const _PayoutBadge({required this.place, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4), width: 2),
          ),
          child: Center(
            child: Icon(
              place == '1st' ? Icons.emoji_events : Icons.workspace_premium,
              size: 18,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(place, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textSecondary)),
        Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

// =============================================================================
// GROUP: REVIEW STEP
// =============================================================================

class _StepGroupReview extends StatelessWidget {
  final List<UserModel> members;
  final StakeOption stake;
  final ChallengeDuration duration;
  final GoalType goalType;
  final int groupSize;
  final GroupPayoutStructure payoutStructure;
  final Function(int) onEditStep;

  const _StepGroupReview({
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
                              _ReviewPayoutBadge(place: '1st', amount: payoutStructure.firstDisplay(prizePool), color: const Color(0xFFFFD700)),
                              _ReviewPayoutBadge(place: '2nd', amount: payoutStructure.secondDisplay(prizePool), color: const Color(0xFFC0C0C0)),
                              _ReviewPayoutBadge(place: '3rd', amount: payoutStructure.thirdDisplay(prizePool), color: const Color(0xFFCD7F32)),
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
                        _ReviewRow(
                          icon: Icons.groups_outlined,
                          label: 'Members',
                          value: '${members.length + 1} of $groupSize',
                          subtitle: members.map((m) => m.displayName).join(', '),
                          onEdit: () => onEditStep(1),
                        ),
                        _buildDivider(context),
                        _ReviewRow(
                          icon: Icons.attach_money,
                          label: 'Entry Fee',
                          value: stake.displayAmount,
                          onEdit: () => onEditStep(2),
                        ),
                        _buildDivider(context),
                        _ReviewRow(
                          icon: Icons.schedule,
                          label: 'Duration',
                          value: duration.displayName,
                          onEdit: () => onEditStep(3),
                        ),
                        _buildDivider(context),
                        _ReviewRow(
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

class _ReviewPayoutBadge extends StatelessWidget {
  final String place;
  final String amount;
  final Color color;

  const _ReviewPayoutBadge({required this.place, required this.amount, required this.color});

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

// =============================================================================
// GROUP: MEMBER PICKER BOTTOM SHEET
// =============================================================================

class _GroupMemberPickerSheet extends StatefulWidget {
  const _GroupMemberPickerSheet();

  @override
  State<_GroupMemberPickerSheet> createState() => _GroupMemberPickerSheetState();
}

class _GroupMemberPickerSheetState extends State<_GroupMemberPickerSheet> {
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: context.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text('Add Members', style: Theme.of(context).textTheme.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                              context.read<ChallengeProvider>().clearSearch();
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
              Expanded(
                child: Consumer<ChallengeProvider>(
                  builder: (context, provider, _) {
                    if (provider.isSearching) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final usersToShow = _searchController.text.length < 2
                        ? provider.demoOpponents
                        : provider.searchResults;

                    if (usersToShow.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 56, color: context.textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.length < 2 ? 'Search for users' : 'No users found',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: context.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.only(bottom: 16 + bottomPadding),
                      itemCount: usersToShow.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final user = usersToShow[index];
                        final isAlreadyAdded = provider.selectedGroupMembers.any((m) => m.id == user.id);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: RivlColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (user.displayName.isNotEmpty ? user.displayName[0] : '?').toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: RivlColors.primary),
                              ),
                            ),
                          ),
                          title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('@${user.username}'),
                          trailing: isAlreadyAdded
                              ? const Icon(Icons.check_circle, color: RivlColors.primary)
                              : OutlinedButton(
                                  onPressed: () {
                                    provider.addGroupMember(user);
                                    setState(() {});
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Add'),
                                ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// SQUAD VS SQUAD: BUILD SQUADS STEP
// =============================================================================

const List<String> _squadLabelOptions = ['Squad', 'Run Club', 'Business', 'Crew', 'Team'];

class _StepBuildTeams extends StatelessWidget {
  final String teamAName;
  final String teamBName;
  final String? teamALabel;
  final String? teamBLabel;
  final List<UserModel> teamAMembers;
  final List<UserModel> teamBMembers;
  final int teamSize;
  final List<UserModel> suggestedOpponents;
  final Function(String) onTeamANameChanged;
  final Function(String) onTeamBNameChanged;
  final Function(String?) onTeamALabelChanged;
  final Function(String?) onTeamBLabelChanged;
  final Function(int) onTeamSizeChanged;
  final Function(UserModel) onAddTeamAMember;
  final Function(String) onRemoveTeamAMember;
  final Function(UserModel) onAddTeamBMember;
  final Function(String) onRemoveTeamBMember;
  final Function(bool isTeamA) onSearchTap;

  const _StepBuildTeams({
    required this.teamAName,
    required this.teamBName,
    this.teamALabel,
    this.teamBLabel,
    required this.teamAMembers,
    required this.teamBMembers,
    required this.teamSize,
    required this.suggestedOpponents,
    required this.onTeamANameChanged,
    required this.onTeamBNameChanged,
    required this.onTeamALabelChanged,
    required this.onTeamBLabelChanged,
    required this.onTeamSizeChanged,
    required this.onAddTeamAMember,
    required this.onRemoveTeamAMember,
    required this.onAddTeamBMember,
    required this.onRemoveTeamBMember,
    required this.onSearchTap,
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
              'Build your\nsquads',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Set up two squads to compete head-to-head. Great for run clubs, businesses, or friend groups.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 28),

          // Squad size selector
          SlideIn(
            delay: const Duration(milliseconds: 250),
            child: Text(
              'Squad Size',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: _SquadSizeSelector(
              squadSize: teamSize,
              onChanged: onTeamSizeChanged,
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 320),
            child: Text(
              '${teamSize}v$teamSize — ${teamSize * 2} total players',
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Squad label selector
          SlideIn(
            delay: const Duration(milliseconds: 350),
            child: Text(
              'Squad Type (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 370),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _squadLabelOptions.map((label) {
                  final isSelected = teamALabel == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        final value = selected ? label : null;
                        onTeamALabelChanged(value);
                        onTeamBLabelChanged(value);
                      },
                      selectedColor: RivlColors.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? RivlColors.primary : null,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ---- SQUAD A ----
          SlideIn(
            delay: const Duration(milliseconds: 400),
            child: _SquadSection(
              squadLabel: 'Your Squad',
              squadName: teamAName,
              squadLabelTag: teamALabel,
              members: teamAMembers,
              squadSize: teamSize,
              isCreatorSquad: true,
              suggestedOpponents: suggestedOpponents
                  .where((u) => !teamBMembers.any((m) => m.id == u.id))
                  .toList(),
              onNameChanged: onTeamANameChanged,
              onAddMember: onAddTeamAMember,
              onRemoveMember: onRemoveTeamAMember,
              onSearchTap: () => onSearchTap(true),
              color: RivlColors.primary,
            ),
          ),
          const SizedBox(height: 20),

          // VS divider
          SlideIn(
            delay: const Duration(milliseconds: 450),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: context.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ---- SQUAD B ----
          SlideIn(
            delay: const Duration(milliseconds: 500),
            child: _SquadSection(
              squadLabel: 'Rival Squad',
              squadName: teamBName,
              squadLabelTag: teamBLabel,
              members: teamBMembers,
              squadSize: teamSize,
              isCreatorSquad: false,
              suggestedOpponents: suggestedOpponents
                  .where((u) => !teamAMembers.any((m) => m.id == u.id))
                  .toList(),
              onNameChanged: onTeamBNameChanged,
              onAddMember: onAddTeamBMember,
              onRemoveMember: onRemoveTeamBMember,
              onSearchTap: () => onSearchTap(false),
              color: const Color(0xFFFF6B5B),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SquadSizeSelector extends StatelessWidget {
  final int squadSize;
  final Function(int) onChanged;

  const _SquadSizeSelector({required this.squadSize, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('2v2', style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500)),
        Expanded(
          child: Slider(
            value: squadSize.toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            activeColor: RivlColors.primary,
            label: '${squadSize}v$squadSize',
            onChanged: (val) => onChanged(val.round()),
          ),
        ),
        Text('20v20', style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SquadSection extends StatefulWidget {
  final String squadLabel;
  final String squadName;
  final String? squadLabelTag;
  final List<UserModel> members;
  final int squadSize;
  final bool isCreatorSquad;
  final List<UserModel> suggestedOpponents;
  final Function(String) onNameChanged;
  final Function(UserModel) onAddMember;
  final Function(String) onRemoveMember;
  final VoidCallback onSearchTap;
  final Color color;

  const _SquadSection({
    required this.squadLabel,
    required this.squadName,
    this.squadLabelTag,
    required this.members,
    required this.squadSize,
    required this.isCreatorSquad,
    required this.suggestedOpponents,
    required this.onNameChanged,
    required this.onAddMember,
    required this.onRemoveMember,
    required this.onSearchTap,
    required this.color,
  });

  @override
  State<_SquadSection> createState() => _SquadSectionState();
}

class _SquadSectionState extends State<_SquadSection> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.squadName);
  }

  @override
  void didUpdateWidget(covariant _SquadSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.squadName != oldWidget.squadName &&
        widget.squadName != _nameController.text) {
      _nameController.text = widget.squadName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxMembers = widget.isCreatorSquad ? widget.squadSize - 1 : widget.squadSize;
    final slotsRemaining = maxMembers - widget.members.length;
    final color = widget.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Squad header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shield_outlined, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.squadLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      '${widget.members.length + (widget.isCreatorSquad ? 1 : 0)}/${widget.squadSize} members',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Squad name field
          TextField(
            controller: _nameController,
            onChanged: widget.onNameChanged,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: widget.squadLabelTag != null
                  ? '${widget.squadLabelTag} name (e.g. Morning Runners)'
                  : 'Squad name',
              hintStyle: TextStyle(
                color: context.textSecondary.withOpacity(0.6),
                fontSize: 14,
              ),
              counterText: '', // Hide character counter
              filled: true,
              fillColor: context.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),

          // Captain (always first in creator squad)
          if (widget.isCreatorSquad)
            _MemberChip(name: 'You (Captain)', isCreator: true),

          // Members
          ...widget.members.map((member) => _MemberChip(
                name: member.displayName,
                subtitle: '@${member.username}',
                onRemove: () => widget.onRemoveMember(member.id),
              )),

          // Add members
          if (slotsRemaining > 0) ...[
            const SizedBox(height: 8),
            if (widget.suggestedOpponents.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.suggestedOpponents
                    .where((u) => !widget.members.any((m) => m.id == u.id))
                    .take(3)
                    .map((user) => ActionChip(
                          avatar: CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: Text(
                              (user.displayName.isNotEmpty ? user.displayName[0] : '?').toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                          label: Text(user.displayName, style: const TextStyle(fontSize: 12)),
                          onPressed: () => widget.onAddMember(user),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            _SearchOpponentButton(onTap: widget.onSearchTap),
            const SizedBox(height: 4),
            Text(
              '$slotsRemaining slot${slotsRemaining == 1 ? '' : 's'} remaining',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// SQUAD VS SQUAD: REVIEW STEP
// =============================================================================

class _StepTeamReview extends StatelessWidget {
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

  const _StepTeamReview({
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
    final totalParticipants = teamSize * 2; // Both squads at full size
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
            child: _ReviewSquadCard(
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
            child: _ReviewSquadCard(
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
                    _SquadReviewRow(
                      icon: goalType.icon,
                      label: 'Type',
                      value: goalType.displayName,
                      onEdit: () => onEditStep(3),
                    ),
                    const Divider(height: 20),
                    _SquadReviewRow(
                      icon: Icons.schedule_outlined,
                      label: 'Duration',
                      value: duration.displayName,
                      onEdit: () => onEditStep(3),
                    ),
                    const Divider(height: 20),
                    _SquadReviewRow(
                      icon: Icons.attach_money,
                      label: 'Stake',
                      value: stake.amount > 0 ? '\$${stake.amount.toInt()} per person' : 'Free',
                      onEdit: () => onEditStep(2),
                    ),
                    const Divider(height: 20),
                    _SquadReviewRow(
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
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your \$${stake.amount.toInt()} stake will be held in escrow. All squad members must accept and stake to start. Winning squad splits the prize pool evenly.',
                        style: TextStyle(fontSize: 12, color: Colors.orange[700], height: 1.4),
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

class _ReviewSquadCard extends StatelessWidget {
  final String squadName;
  final String? label;
  final List<String> members;
  final Color color;
  final VoidCallback onEdit;

  const _ReviewSquadCard({
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

class _SquadReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _SquadReviewRow({
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

// =============================================================================
// SQUAD VS SQUAD: MEMBER PICKER SHEET
// =============================================================================

class _TeamMemberPickerSheet extends StatefulWidget {
  final bool isTeamA;
  final ChallengeProvider provider;

  const _TeamMemberPickerSheet({
    required this.isTeamA,
    required this.provider,
  });

  @override
  State<_TeamMemberPickerSheet> createState() => _TeamMemberPickerSheetState();
}

class _TeamMemberPickerSheetState extends State<_TeamMemberPickerSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final squadName = widget.isTeamA
        ? (widget.provider.teamAName.isEmpty ? 'Your Squad' : widget.provider.teamAName)
        : (widget.provider.teamBName.isEmpty ? 'Rival Squad' : widget.provider.teamBName);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add to $squadName',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by username...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (query) {
                    if (query.length >= 2) {
                      widget.provider.searchUsers(query);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ChallengeProvider>(
              builder: (context, provider, _) {
                if (provider.isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }
                final results = provider.searchResults;
                final currentUserId = context.read<AuthProvider>().user?.id;
                final existingIds = {
                  if (currentUserId != null) currentUserId,
                  ...provider.teamAMembers.map((m) => m.id),
                  ...provider.teamBMembers.map((m) => m.id),
                };
                final filtered = results.where((u) => !existingIds.contains(u.id)).toList();

                if (filtered.isEmpty && _searchController.text.length >= 2) {
                  return Center(
                    child: Text('No users found', style: TextStyle(color: context.textSecondary)),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: RivlColors.primary.withOpacity(0.12),
                        child: Text(
                          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: RivlColors.primary),
                        ),
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      trailing: Text(
                        '${user.wins}W - ${user.losses}L',
                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                      ),
                      onTap: () {
                        if (widget.isTeamA) {
                          provider.addTeamAMember(user);
                        } else {
                          provider.addTeamBMember(user);
                        }
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
  }
}
