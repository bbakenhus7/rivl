// Step 1 (group mode): Add Group Members

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/challenge_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/challenge_provider.dart';
import '../../../utils/theme.dart';
import '../../../utils/animations.dart';
import 'step_select_opponent.dart';

class StepAddGroupMembers extends StatelessWidget {
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

  const StepAddGroupMembers({
    super.key,
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
            child: GroupSizeSelector(
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
            child: PayoutStructureSelector(
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
            child: MemberChip(name: 'You (Creator)', isCreator: true),
          ),

          // Selected members
          ...List.generate(selectedMembers.length, (index) {
            final member = selectedMembers[index];
            return SlideIn(
              delay: Duration(milliseconds: 520 + (index * 50)),
              child: MemberChip(
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
                  SearchOpponentButton(onTap: onSearchTap),
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

class MemberChip extends StatelessWidget {
  final String name;
  final String? subtitle;
  final bool isCreator;
  final VoidCallback? onRemove;

  const MemberChip({
    super.key,
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

class GroupSizeSelector extends StatelessWidget {
  final int groupSize;
  final Function(int) onChanged;

  const GroupSizeSelector({super.key, required this.groupSize, required this.onChanged});

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

class PayoutStructureSelector extends StatelessWidget {
  final GroupPayoutStructure selected;
  final Function(GroupPayoutStructure) onChanged;

  const PayoutStructureSelector({super.key, required this.selected, required this.onChanged});

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

class GroupPrizePoolDisplay extends StatelessWidget {
  final StakeOption stake;
  final int groupSize;

  const GroupPrizePoolDisplay({super.key, required this.stake, required this.groupSize});

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
                PayoutBadge(place: '1st', amount: payout.firstDisplay(prizePool), color: const Color(0xFFFFD700)),
                PayoutBadge(place: '2nd', amount: payout.secondDisplay(prizePool), color: const Color(0xFFC0C0C0)),
                PayoutBadge(place: '3rd', amount: payout.thirdDisplay(prizePool), color: const Color(0xFFCD7F32)),
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

class PayoutBadge extends StatelessWidget {
  final String place;
  final String amount;
  final Color color;

  const PayoutBadge({super.key, required this.place, required this.amount, required this.color});

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
// GROUP: MEMBER PICKER BOTTOM SHEET
// =============================================================================

class GroupMemberPickerSheet extends StatefulWidget {
  const GroupMemberPickerSheet({super.key});

  @override
  State<GroupMemberPickerSheet> createState() => GroupMemberPickerSheetState();
}

class GroupMemberPickerSheetState extends State<GroupMemberPickerSheet> {
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
