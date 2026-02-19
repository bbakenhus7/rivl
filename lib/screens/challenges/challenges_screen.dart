// screens/challenges/challenges_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/challenge_model.dart';
import '../../utils/haptics.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/add_funds_sheet.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/confetti_celebration.dart';
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
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) Haptics.selection();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) {
        context.read<ChallengeProvider>().loadDemoChallenges();
      }
    });
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
          tabs: [
            Tab(
              child: Consumer<ChallengeProvider>(
                builder: (context, p, _) => Semantics(
                  label: p.activeChallenges.isNotEmpty
                      ? 'Active, ${p.activeChallenges.length} challenges'
                      : 'Active',
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Active'),
                    if (p.activeChallenges.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: RivlColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${p.activeChallenges.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: RivlColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                ),
              ),
            ),
            Tab(
              child: Consumer<ChallengeProvider>(
                builder: (context, p, _) => Semantics(
                  label: p.pendingChallenges.isNotEmpty
                      ? 'Pending, ${p.pendingChallenges.length} challenges'
                      : 'Pending',
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pending'),
                    if (p.pendingChallenges.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: RivlColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${p.pendingChallenges.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: RivlColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                ),
              ),
            ),
            const Tab(text: 'History'),
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
        // Show skeleton cards on initial load
        if (provider.isLoading && provider.challenges.isEmpty) {
          return SkeletonList(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ChallengeCardSkeleton(),
            ),
          );
        }

        List<ChallengeModel> challenges;
        String emptyTitle;
        String emptySubtitle;
        IconData emptyIcon;
        Color emptyColor;

        switch (filter) {
          case ChallengeStatus.active:
            challenges = provider.activeChallenges;
            emptyTitle = 'No active challenges';
            emptySubtitle = 'Challenge a friend to get started!\nTap the + button to create one.';
            emptyIcon = Icons.local_fire_department;
            emptyColor = RivlColors.secondary;
            break;
          case ChallengeStatus.pending:
            challenges = provider.pendingChallenges;
            emptyTitle = 'No pending invites';
            emptySubtitle = 'When someone challenges you,\nit will appear here.';
            emptyIcon = Icons.mail_outline;
            emptyColor = RivlColors.warning;
            break;
          case ChallengeStatus.completed:
            challenges = provider.completedChallenges;
            emptyTitle = 'No history yet';
            emptySubtitle = 'Completed challenges and\nyour results will show up here.';
            emptyIcon = Icons.emoji_events_outlined;
            emptyColor = Colors.purple;
            break;
          default:
            challenges = [];
            emptyTitle = 'No challenges';
            emptySubtitle = '';
            emptyIcon = Icons.inbox;
            emptyColor = Colors.grey;
        }

        if (challenges.isEmpty) {
          return IllustratedEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
            accentColor: emptyColor,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            try {
              final auth = context.read<AuthProvider>();
              if (auth.user != null) {
                provider.startListening(auth.user!.id);
              } else {
                provider.loadDemoChallenges();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to refresh challenges'),
                    backgroundColor: RivlColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              final isPending = filter == ChallengeStatus.pending;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StaggeredListAnimation(
                  index: index,
                  child: ChallengeCard(
                    challenge: challenge,
                    currentUserId: context.read<AuthProvider>().user?.id ?? 'demo-user',
                    onTap: () {
                      Navigator.push(
                        context,
                        SlidePageRoute(
                          page: ChallengeDetailScreen(challengeId: challenge.id),
                        ),
                      );
                    },
                    onAccept: isPending
                        ? () async {
                            var walletBalance = context.read<WalletProvider>().balance;

                            // Prompt to add funds if balance is insufficient
                            if (challenge.stakeAmount > 0 && walletBalance < challenge.stakeAmount) {
                              final funded = await showAddFundsSheet(
                                context,
                                stakeAmount: challenge.stakeAmount,
                                currentBalance: walletBalance,
                              );
                              if (!funded || !context.mounted) return;
                              // Re-read balance after deposit
                              walletBalance = context.read<WalletProvider>().balance;
                            }

                            final success = await provider.acceptChallenge(
                              challenge.id,
                              walletBalance: walletBalance,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Challenge accepted! Good luck!'
                                    : provider.errorMessage ?? 'Failed to accept challenge'),
                                backgroundColor: success ? RivlColors.success : RivlColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                            provider.clearMessages();
                          }
                        : null,
                    onDecline: isPending
                        ? () async {
                            final success = await provider.declineChallenge(challenge.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Challenge declined'
                                    : provider.errorMessage ?? 'Failed to decline challenge'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                            provider.clearMessages();
                          }
                        : null,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// IllustratedEmptyState is imported from '../../widgets/confetti_celebration.dart'
