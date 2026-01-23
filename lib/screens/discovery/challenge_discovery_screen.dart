// screens/discovery/challenge_discovery_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../utils/theme.dart';
import '../../models/user_model.dart';
import '../../models/challenge_model.dart';

class ChallengeDiscoveryScreen extends StatelessWidget {
  const ChallengeDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Opponents'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Match Card
            Card(
              color: RivlColors.primary,
              child: InkWell(
                onTap: () => _showQuickMatchDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.flash_on,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Quick Match',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Get matched with a random opponent instantly',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Suggested Opponents
            const Text('Suggested Opponents', style: RivlTextStyles.heading3),
            const SizedBox(height: 12),
            _SuggestedOpponents(),
            const SizedBox(height: 24),

            // Active Challenges Lobby
            const Text('Active Challenges', style: RivlTextStyles.heading3),
            const SizedBox(height: 12),
            _ActiveChallengesLobby(),
          ],
        ),
      ),
    );
  }

  void _showQuickMatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flash_on, color: RivlColors.primary),
            SizedBox(width: 8),
            Text('Quick Match'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding an opponent...'),
          ],
        ),
      ),
    );

    // Simulate finding opponent (2 seconds)
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match found! Challenge sent to RandomUser123'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
}

class _SuggestedOpponents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock suggested opponents based on skill level
    final suggestions = [
      {'name': 'Sarah Johnson', 'username': 'sarahj', 'record': '15-12', 'winRate': '55%'},
      {'name': 'Mike Chen', 'username': 'mikechen', 'record': '22-18', 'winRate': '55%'},
      {'name': 'Emma Davis', 'username': 'emmad', 'record': '18-15', 'winRate': '54%'},
    ];

    return Column(
      children: suggestions.map((opponent) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: RivlColors.primary.withOpacity(0.2),
              child: Text(
                opponent['name']![0],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: RivlColors.primary,
                ),
              ),
            ),
            title: Text(opponent['name']!),
            subtitle: Text('@${opponent['username']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  opponent['record']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  opponent['winRate']!,
                  style: RivlTextStyles.caption,
                ),
              ],
            ),
            onTap: () {
              // Navigate to create challenge with this opponent pre-selected
              Navigator.pushNamed(context, '/create-challenge');
            },
          ),
        );
      }).toList(),
    );
  }
}

class _ActiveChallengesLobby extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        final activeChallenges = provider.challenges
            .where((c) => c.status.name == 'active')
            .take(5)
            .toList();

        if (activeChallenges.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'No active challenges',
                      style: RivlTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: activeChallenges.map((challenge) {
            return Card(
              child: ListTile(
                leading: Text(
                  challenge.goalType.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                title: Text('\$\${challenge.stakeAmount.toInt()} Challenge'),
                subtitle: Text(
                  '\${challenge.creatorName} vs \${challenge.opponentName ?? "..."}',
                ),
                trailing: Text(
                  challenge.duration.displayName,
                  style: RivlTextStyles.caption,
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/challenge-detail',
                    arguments: challenge.id,
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
