// screens/challenges/challenge_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../utils/theme.dart';
import '../../models/challenge_model.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final String challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Details'),
      ),
      body: Consumer<ChallengeProvider>(
        builder: (context, provider, _) {
          final challenge = provider.challenges.firstWhere(
            (c) => c.id == challengeId,
            orElse: () => throw Exception('Challenge not found'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: challenge.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    challenge.statusDisplayName,
                    style: TextStyle(
                      color: challenge.statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Prize
                Text(
                  '\$${challenge.prizeAmount.toInt()}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: RivlColors.primary,
                  ),
                ),
                const Text(
                  'Prize',
                  style: RivlTextStyles.bodySecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.timeRemaining,
                  style: RivlTextStyles.caption,
                ),
                const SizedBox(height: 32),

                // VS Display
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        // Creator
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: RivlColors.primary.withOpacity(0.2),
                                child: Text(
                                  challenge.creatorName[0],
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: RivlColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                challenge.creatorName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${challenge.creatorProgress}',
                                style: RivlTextStyles.stat,
                              ),
                              const Text('steps', style: RivlTextStyles.caption),
                            ],
                          ),
                        ),

                        // VS
                        Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.textSecondary,
                          ),
                        ),

                        // Opponent
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.orange.withOpacity(0.2),
                                child: Text(
                                  (challenge.opponentName ?? 'O')[0],
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                challenge.opponentName ?? 'Opponent',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${challenge.opponentProgress}',
                                style: RivlTextStyles.stat,
                              ),
                              const Text('steps', style: RivlTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Type', value: challenge.goalType.displayName),
                        const Divider(),
                        _DetailRow(label: 'Goal', value: '${challenge.goalValue} steps'),
                        const Divider(),
                        _DetailRow(label: 'Duration', value: challenge.duration.displayName),
                        const Divider(),
                        _DetailRow(label: 'Stake', value: '\$${challenge.stakeAmount.toInt()} each'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sync button
                if (challenge.status == ChallengeStatus.active)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isSyncing
                          ? null
                          : () => provider.syncSteps(challenge),
                      icon: provider.isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(provider.isSyncing ? 'Syncing...' : 'Sync Steps'),
                    ),
                  ),

                // Quick Rematch button (shown when challenge is completed)
                if (challenge.status == ChallengeStatus.completed) ...[
                  const SizedBox(height: 16),
                  _QuickRematchCard(challenge: challenge),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Quick rematch card shown on completed challenges
class _QuickRematchCard extends StatelessWidget {
  final ChallengeModel challenge;

  const _QuickRematchCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final isCreator = challenge.creatorId == currentUserId;
    final opponentId = isCreator ? challenge.opponentId : challenge.creatorId;
    final opponentName = isCreator ? challenge.opponentName : challenge.creatorName;
    final didWin = challenge.winnerId == currentUserId;

    return Card(
      color: didWin
          ? RivlColors.success.withOpacity(0.05)
          : RivlColors.secondary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              didWin ? Icons.emoji_events : Icons.replay,
              color: didWin ? Colors.amber : RivlColors.secondary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              didWin ? 'You won! Run it back?' : 'Rematch?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Same settings vs ${opponentName ?? 'opponent'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Quick rematch — same settings
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startRematch(context, challenge, opponentId, opponentName),
                    icon: const Icon(Icons.flash_on, size: 20),
                    label: const Text('Quick Rematch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RivlColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Modify & rematch
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _modifyRematch(context, challenge, opponentId, opponentName),
                    icon: const Icon(Icons.tune, size: 20),
                    label: const Text('Modify'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Double or nothing
            if (challenge.stakeAmount > 0)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () =>
                      _doubleOrNothing(context, challenge, opponentId, opponentName),
                  child: Text(
                    'Double or Nothing (\$${(challenge.stakeAmount * 2).toInt()})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _startRematch(BuildContext context, ChallengeModel challenge,
      String? opponentId, String? opponentName) async {
    if (opponentId == null) return;

    final provider = context.read<ChallengeProvider>();

    // Set up same challenge parameters
    final opponent = await _getOpponentAsUser(context, opponentId, opponentName);
    if (opponent == null) return;

    provider.setSelectedOpponent(opponent);
    provider.setSelectedGoalType(challenge.goalType);
    provider.setSelectedDuration(challenge.duration);

    // Find matching stake
    final stakeMatch = StakeOption.options.firstWhere(
      (s) => s.amount == challenge.stakeAmount,
      orElse: () => StakeOption.options[0],
    );
    provider.setSelectedStake(stakeMatch);

    // Create the challenge
    final challengeId = await provider.createChallenge();
    if (challengeId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rematch sent to ${opponentName ?? 'opponent'}!'),
          backgroundColor: RivlColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _modifyRematch(BuildContext context, ChallengeModel challenge,
      String? opponentId, String? opponentName) async {
    if (opponentId == null) return;

    final provider = context.read<ChallengeProvider>();
    final opponent = await _getOpponentAsUser(context, opponentId, opponentName);
    if (opponent == null) return;

    // Pre-fill form with previous settings
    provider.setSelectedOpponent(opponent);
    provider.setSelectedGoalType(challenge.goalType);
    provider.setSelectedDuration(challenge.duration);

    final stakeMatch = StakeOption.options.firstWhere(
      (s) => s.amount == challenge.stakeAmount,
      orElse: () => StakeOption.options[0],
    );
    provider.setSelectedStake(stakeMatch);

    // Navigate to create screen (tab index 2)
    if (context.mounted) {
      Navigator.pop(context);
      // The main screen's create tab will have the pre-filled data
    }
  }

  void _doubleOrNothing(BuildContext context, ChallengeModel challenge,
      String? opponentId, String? opponentName) async {
    if (opponentId == null) return;

    final provider = context.read<ChallengeProvider>();
    final opponent = await _getOpponentAsUser(context, opponentId, opponentName);
    if (opponent == null) return;

    provider.setSelectedOpponent(opponent);
    provider.setSelectedGoalType(challenge.goalType);
    provider.setSelectedDuration(challenge.duration);

    // Double the stake
    final doubleStake = challenge.stakeAmount * 2;
    final stakeMatch = StakeOption.options.firstWhere(
      (s) => s.amount == doubleStake,
      orElse: () => StakeOption.options.last,
    );
    provider.setSelectedStake(stakeMatch);

    final challengeId = await provider.createChallenge();
    if (challengeId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Double or nothing! \$${doubleStake.toInt()} challenge sent to ${opponentName ?? 'opponent'}!'),
          backgroundColor: RivlColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<dynamic> _getOpponentAsUser(
      BuildContext context, String opponentId, String? opponentName) async {
    // Search for opponent to get their UserModel
    final provider = context.read<ChallengeProvider>();
    if (opponentName != null) {
      await provider.searchUsers(opponentName);
      final results = provider.searchResults;
      final match = results.where((u) => u.id == opponentId).toList();
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: RivlTextStyles.bodySecondary),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
