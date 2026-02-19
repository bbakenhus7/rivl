// screens/create/create_challenge_screen.dart
//
// Orchestrator for the multi-step challenge creation flow.
// Individual step widgets live in create_challenge_steps/.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/challenge_model.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../main_screen.dart';
import '../../widgets/confetti_celebration.dart';
import '../../widgets/add_funds_sheet.dart';
import '../../providers/friend_provider.dart';

// Step widgets
import 'create_challenge_steps/step_challenge_type.dart';
import 'create_challenge_steps/step_select_opponent.dart';
import 'create_challenge_steps/step_choose_stake.dart';
import 'create_challenge_steps/step_select_charity.dart';
import 'create_challenge_steps/step_duration_type.dart';
import 'create_challenge_steps/step_review.dart';
import 'create_challenge_steps/step_group_members.dart';
import 'create_challenge_steps/step_group_review.dart';
import 'create_challenge_steps/step_build_teams.dart';
import 'create_challenge_steps/step_team_review.dart';

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
          return StepChallengeType(
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
          return StepSelectOpponent(
            selectedOpponent: provider.selectedOpponent,
            suggestedOpponents: provider.demoOpponents,
            onTap: () => _showOpponentPicker(context),
            onClear: () => provider.setSelectedOpponent(null),
            onSelectOpponent: (user) => provider.setSelectedOpponent(user),
          );
        case 2:
          return StepChooseStake(
            selectedStake: provider.selectedStake,
            onChanged: provider.setSelectedStake,
            isCharity: true,
          );
        case 3:
          return StepSelectCharity(
            selectedCharity: provider.selectedCharity,
            onChanged: provider.setSelectedCharity,
          );
        case 4:
          return StepDurationAndType(
            selectedDuration: provider.selectedDuration,
            onDurationChanged: provider.setSelectedDuration,
            selectedGoalType: provider.selectedGoalType,
            onGoalTypeSelected: provider.setSelectedGoalType,
          );
        case 5:
          final isFriend = provider.selectedOpponent != null &&
              context.read<FriendProvider>().isFriend(provider.selectedOpponent!.id);
          return StepReview(
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
        return StepChallengeType(
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
          return StepBuildTeams(
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
          return StepAddGroupMembers(
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
        return StepSelectOpponent(
          selectedOpponent: provider.selectedOpponent,
          suggestedOpponents: provider.demoOpponents,
          onTap: () => _showOpponentPicker(context),
          onClear: () => provider.setSelectedOpponent(null),
          onSelectOpponent: (user) => provider.setSelectedOpponent(user),
        );
      case 2:
        return StepChooseStake(
          selectedStake: provider.selectedStake,
          onChanged: provider.setSelectedStake,
          isGroup: isGroup || isTeam,
          groupSize: isTeam ? provider.teamSize * 2 : provider.groupSize,
        );
      case 3:
        return StepDurationAndType(
          selectedDuration: provider.selectedDuration,
          onDurationChanged: provider.setSelectedDuration,
          selectedGoalType: provider.selectedGoalType,
          onGoalTypeSelected: provider.setSelectedGoalType,
        );
      case 4:
        if (isTeam) {
          return StepTeamReview(
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
          return StepGroupReview(
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
        return StepReview(
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
      builder: (_) => const OpponentPickerSheet(),
    );
  }

  void _showGroupMemberPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GroupMemberPickerSheet(),
    );
  }

  void _showTeamMemberPicker(
      BuildContext context, bool isTeamA, ChallengeProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TeamMemberPickerSheet(
        isTeamA: isTeamA,
        provider: provider,
      ),
    );
  }
}

// =============================================================================
// SHARED: STEP PROGRESS INDICATOR
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
// SHARED: BOTTOM NAVIGATION BUTTONS
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
