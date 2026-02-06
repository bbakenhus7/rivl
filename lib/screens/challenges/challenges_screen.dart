// screens/challenges/challenges_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../models/challenge_model.dart';
import '../../utils/theme.dart';
import '../../widgets/challenge_card.dart';
import 'challenge_detail_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      context.read<ChallengeProvider>().loadDemoChallenges();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChallengeList(filter: ChallengeStatus.active),
          _ChallengeList(filter: ChallengeStatus.pending),
          _ChallengeList(filter: ChallengeStatus.completed),
        ],
      ),
    );
  }
}

class _ChallengeList extends StatelessWidget {
  final ChallengeStatus filter;

  const _ChallengeList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        List<ChallengeModel> challenges;
        String emptyMessage;
        IconData emptyIcon;

        switch (filter) {
          case ChallengeStatus.active:
            challenges = provider.activeChallenges;
            emptyMessage = 'No active challenges';
            emptyIcon = Icons.local_fire_department;
            break;
          case ChallengeStatus.pending:
            challenges = provider.pendingChallenges;
            emptyMessage = 'No pending invites';
            emptyIcon = Icons.mail_outline;
            break;
          case ChallengeStatus.completed:
            challenges = provider.completedChallenges;
            emptyMessage = 'No completed challenges';
            emptyIcon = Icons.history;
            break;
          default:
            challenges = [];
            emptyMessage = 'No challenges';
            emptyIcon = Icons.inbox;
        }

        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(emptyIcon, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: RivlTextStyles.bodySecondary,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChallengeCard(
                challenge: challenge,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChallengeDetailScreen(challengeId: challenge.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ChallengeDetailScreen moved to challenge_detail_screen.dart
