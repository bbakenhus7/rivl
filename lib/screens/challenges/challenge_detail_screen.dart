// screens/challenges/challenge_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
              ],
            ),
          );
        },
      ),
    );
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
