// Step 1 (h2h): Select Opponent

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../providers/challenge_provider.dart';
import '../../../providers/friend_provider.dart';
import '../../../utils/theme.dart';
import '../../../utils/animations.dart';

class StepSelectOpponent extends StatelessWidget {
  final UserModel? selectedOpponent;
  final List<UserModel> suggestedOpponents;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final Function(UserModel) onSelectOpponent;

  const StepSelectOpponent({
    super.key,
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
              child: OpponentSelector(
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
                  child: SuggestedOpponentCard(
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
              child: SearchOpponentButton(onTap: onTap),
            ),
          ],
        ],
      ),
    );
  }
}

class SuggestedOpponentCard extends StatelessWidget {
  final UserModel opponent;
  final VoidCallback onTap;

  const SuggestedOpponentCard({
    super.key,
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

class SearchOpponentButton extends StatelessWidget {
  final VoidCallback onTap;

  const SearchOpponentButton({super.key, required this.onTap});

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

class OpponentSelector extends StatelessWidget {
  final UserModel? selectedOpponent;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const OpponentSelector({
    super.key,
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
// OPPONENT PICKER BOTTOM SHEET
// =============================================================================

class OpponentPickerSheet extends StatefulWidget {
  const OpponentPickerSheet({super.key});

  @override
  State<OpponentPickerSheet> createState() => OpponentPickerSheetState();
}

class OpponentPickerSheetState extends State<OpponentPickerSheet> {
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
                                          color: RivlColors.warning),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${user.currentStreak} streak',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: RivlColors.warning,
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
