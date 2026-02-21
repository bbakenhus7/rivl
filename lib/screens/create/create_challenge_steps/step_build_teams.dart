// Step 1 (team mode): Build Squads

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/challenge_provider.dart';
import '../../../utils/theme.dart';
import '../../../utils/animations.dart';
import 'step_select_opponent.dart';
import 'step_group_members.dart';

const List<String> squadLabelOptions = ['Squad', 'Run Club', 'Business', 'Crew', 'Team'];

class StepBuildTeams extends StatelessWidget {
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

  const StepBuildTeams({
    super.key,
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
            child: SquadSizeSelector(
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
                children: squadLabelOptions.map((label) {
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
            child: SquadSection(
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
            child: SquadSection(
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

class SquadSizeSelector extends StatelessWidget {
  final int squadSize;
  final Function(int) onChanged;

  const SquadSizeSelector({super.key, required this.squadSize, required this.onChanged});

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

class SquadSection extends StatefulWidget {
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

  const SquadSection({
    super.key,
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
  State<SquadSection> createState() => _SquadSectionState();
}

class _SquadSectionState extends State<SquadSection> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.squadName);
  }

  @override
  void didUpdateWidget(covariant SquadSection oldWidget) {
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
            MemberChip(name: 'You (Captain)', isCreator: true),

          // Members
          ...widget.members.map((member) => MemberChip(
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
            SearchOpponentButton(onTap: widget.onSearchTap),
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

class TeamMemberPickerSheet extends StatefulWidget {
  final bool isTeamA;
  final ChallengeProvider provider;

  const TeamMemberPickerSheet({
    super.key,
    required this.isTeamA,
    required this.provider,
  });

  @override
  State<TeamMemberPickerSheet> createState() => _TeamMemberPickerSheetState();
}

class _TeamMemberPickerSheetState extends State<TeamMemberPickerSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final squadName = widget.isTeamA
        ? (provider.teamAName.isEmpty ? 'Your Squad' : provider.teamAName)
        : (provider.teamBName.isEmpty ? 'Rival Squad' : provider.teamBName);

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
                      provider.searchUsers(query);
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
