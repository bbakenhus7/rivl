// screens/create/create_challenge_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';

class CreateChallengeScreen extends StatelessWidget {
  const CreateChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Challenge'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<ChallengeProvider>(
          builder: (context, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Opponent Selection
                const Text('Challenge', style: RivlTextStyles.heading3),
                const SizedBox(height: 12),
                _OpponentSelector(
                  selectedOpponent: provider.selectedOpponent,
                  onTap: () => _showOpponentPicker(context),
                ),
                const SizedBox(height: 24),

                // Stake Selection
                const Text('Stake Amount', style: RivlTextStyles.heading3),
                const SizedBox(height: 12),
                _StakeSelector(
                  selectedStake: provider.selectedStake,
                  onChanged: provider.setSelectedStake,
                ),
                const SizedBox(height: 24),

                // Duration Selection
                const Text('Duration', style: RivlTextStyles.heading3),
                const SizedBox(height: 12),
                _DurationSelector(
                  selectedDuration: provider.selectedDuration,
                  onChanged: provider.setSelectedDuration,
                ),
                const SizedBox(height: 24),

                // Goal Type
                const Text('Competition Type', style: RivlTextStyles.heading3),
                const SizedBox(height: 12),
                _ChallengeTypeGrid(
                  selectedGoalType: provider.selectedGoalType,
                  onGoalTypeSelected: provider.setSelectedGoalType,
                ),
                const SizedBox(height: 24),

                // Prize Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: RivlColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        provider.selectedStake.amount == 0 ? 'Challenge' : 'Prize Pool',
                        style: RivlTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.selectedStake.amount == 0
                            ? 'Free'
                            : '\$${provider.selectedStake.prize.toInt()}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: RivlColors.primary,
                        ),
                      ),
                      Text(
                        provider.selectedStake.amount == 0
                            ? 'Just for fun!'
                            : 'Winner takes all!',
                        style: RivlTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.selectedOpponent == null || provider.isCreating
                        ? null
                        : () async {
                            final challengeId = await provider.createChallenge();
                            if (challengeId != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Challenge sent!')),
                              );
                            }
                          },
                    child: provider.isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Challenge'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showOpponentPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _OpponentPickerSheet(),
    );
  }
}

class _OpponentSelector extends StatelessWidget {
  final UserModel? selectedOpponent;
  final VoidCallback onTap;

  const _OpponentSelector({this.selectedOpponent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (selectedOpponent != null) ...[
                CircleAvatar(
                  backgroundColor: RivlColors.primary.withOpacity(0.2),
                  child: Text(
                    selectedOpponent!.displayName[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: RivlColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedOpponent!.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '@${selectedOpponent!.username}',
                      style: RivlTextStyles.caption,
                    ),
                  ],
                ),
              ] else ...[
                const Icon(Icons.person_add, color: RivlColors.primary),
                const SizedBox(width: 12),
                const Text(
                  'Select Opponent',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              const Spacer(),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: StakeOption.options.map((option) {
        final isSelected = selectedStake.amount == option.amount;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: Container(
            width: (MediaQuery.of(context).size.width - 56) / 3,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? RivlColors.primary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? RivlColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  option.displayAmount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isSelected ? RivlColors.primary : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.amount == 0 ? 'For fun!' : 'Win ${option.displayPrize}',
                  style: RivlTextStyles.caption,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final ChallengeDuration selectedDuration;
  final Function(ChallengeDuration) onChanged;

  const _DurationSelector({required this.selectedDuration, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ChallengeDuration.values.map((duration) {
          final isSelected = selectedDuration == duration;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(duration.displayName),
              selected: isSelected,
              onSelected: (_) => onChanged(duration),
              selectedColor: RivlColors.primary.withOpacity(0.2),
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
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: GoalType.values.map((goalType) {
        return _ChallengeTypeCard(
          goalType: goalType,
          isSelected: selectedGoalType == goalType,
          onTap: goalType.isAvailable
              ? () => onGoalTypeSelected(goalType)
              : null,
        );
      }).toList(),
    );
  }
}

class _ChallengeTypeCard extends StatelessWidget {
  final GoalType goalType;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ChallengeTypeCard({
    required this.goalType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = goalType.isAvailable;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isAvailable
          ? (isSelected ? RivlColors.primary.withOpacity(0.1) : null)
          : RivlColors.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? RivlColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                goalType.icon,
                size: 48,
                color: isSelected ? RivlColors.primary : Colors.grey[600],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                goalType.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                goalType.description,
                style: RivlTextStyles.caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Button or Coming Soon Badge
              if (isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? RivlColors.primary : RivlColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'LAUNCH',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : RivlColors.primary,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'COMING SOON',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select Opponent', style: RivlTextStyles.heading3),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by username',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    context.read<ChallengeProvider>().searchUsers(value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Results
              Expanded(
                child: Consumer<ChallengeProvider>(
                  builder: (context, provider, _) {
                    if (provider.isSearching) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.searchResults.isEmpty) {
                      return const Center(
                        child: Text('Search for users by username'),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: provider.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = provider.searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: RivlColors.primary.withOpacity(0.2),
                            child: Text(
                              user.displayName[0],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: RivlColors.primary,
                              ),
                            ),
                          ),
                          title: Text(user.displayName),
                          subtitle: Text('@${user.username}'),
                          trailing: Text(
                            '${user.wins}W - ${user.losses}L',
                            style: RivlTextStyles.caption,
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


