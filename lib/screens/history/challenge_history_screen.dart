// screens/history/challenge_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../models/challenge_model.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';

class ChallengeHistoryScreen extends StatelessWidget {
  const ChallengeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge History'),
      ),
      body: Consumer<ChallengeProvider>(
        builder: (context, provider, _) {
          final completedChallenges = provider.challenges
              .where((c) => c.status == ChallengeStatus.completed)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (completedChallenges.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No completed challenges yet',
                    style: RivlTextStyles.heading3.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your challenge history will appear here',
                    style: RivlTextStyles.caption,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completedChallenges.length,
            itemBuilder: (context, index) {
              final challenge = completedChallenges[index];
              return _ChallengeHistoryCard(challenge: challenge);
            },
          );
        },
      ),
    );
  }
}

class _ChallengeHistoryCard extends StatelessWidget {
  final ChallengeModel challenge;

  const _ChallengeHistoryCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final isWinner = challenge.winnerId != null;
    final didWin = isWinner && challenge.winnerId == challenge.creatorId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/challenge-detail',
            arguments: challenge.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Win/Loss Badge + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: didWin
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          didWin ? Icons.emoji_events : Icons.cancel,
                          size: 16,
                          color: didWin ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          didWin ? 'WON' : 'LOST',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: didWin ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(challenge.endDate ?? challenge.createdAt),
                    style: RivlTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Opponent
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'vs ${challenge.opponentName ?? "Unknown"}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Challenge Type
              Row(
                children: [
                  Text(challenge.goalType.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    challenge.goalType.displayName,
                    style: RivlTextStyles.caption,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    challenge.duration.displayName,
                    style: RivlTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('You', style: RivlTextStyles.caption),
                      const SizedBox(height: 4),
                      Text(
                        '${challenge.creatorProgress}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: didWin ? Colors.green : null,
                        ),
                      ),
                    ],
                  ),
                  const Text('-', style: TextStyle(fontSize: 20)),
                  Column(
                    children: [
                      const Text('Them', style: RivlTextStyles.caption),
                      const SizedBox(height: 4),
                      Text(
                        '${challenge.opponentProgress}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: !didWin ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Prize/Loss Amount
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: didWin
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      didWin ? Icons.add_circle : Icons.remove_circle,
                      size: 16,
                      color: didWin ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      didWin
                          ? '+\$${challenge.prizeAmount.toInt()}'
                          : '-\$${challenge.stakeAmount.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: didWin ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
