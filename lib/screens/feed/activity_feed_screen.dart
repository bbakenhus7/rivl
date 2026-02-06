// screens/feed/activity_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_feed_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/battle_pass_provider.dart';
import '../../models/activity_feed_model.dart';
import '../../models/battle_pass_model.dart';
import '../../utils/theme.dart';
import '../challenges/challenge_detail_screen.dart';
import '../leaderboard/leaderboard_screen.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityFeedProvider>().startListening();
      final auth = context.read<AuthProvider>();
      final battlePass = context.read<BattlePassProvider>();
      if (auth.user != null) {
        battlePass.loadProgress(auth.user!.id);
      } else {
        battlePass.ensureDemoData();
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
        title: const Text('Feed'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: RivlColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: RivlColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'Season'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ActivityTab(),
          _LeaderboardTab(),
          _SeasonTab(),
        ],
      ),
    );
  }
}

// ============================================
// TAB 1: ACTIVITY FEED
// ============================================

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityFeedProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.feedItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.feedItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dynamic_feed, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No activity yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Challenge someone to get the feed going!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            provider.startListening();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.feedItems.length,
            itemBuilder: (context, index) {
              final item = provider.feedItems[index];
              return _ActivityFeedTile(item: item);
            },
          ),
        );
      },
    );
  }
}

// ============================================
// TAB 2: LEADERBOARD
// ============================================

class _LeaderboardTab extends StatefulWidget {
  const _LeaderboardTab();

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  List<LeaderboardEntry> _entries = [];
  int _userRank = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final mockEntries = List.generate(50, (index) {
      return LeaderboardEntry(
        rank: index + 1,
        odId: 'user_$index',
        displayName: _getRandomName(index),
        username: 'user${index + 1}',
        wins: 50 - index + (index % 3),
        totalChallenges: 60 + (index % 10),
        winRate: (0.9 - (index * 0.015)).clamp(0.3, 0.95),
        totalEarnings: (5000 - (index * 80)).toDouble().clamp(100, 5000),
        isCurrentUser: index == 7,
      );
    });

    if (mounted) {
      setState(() {
        _entries = mockEntries;
        _userRank = 8;
        _isLoading = false;
      });
    }
  }

  String _getRandomName(int index) {
    const names = [
      'Alex Runner', 'Sam Stepper', 'Jordan Fit', 'Taylor Active',
      'Morgan Steps', 'Casey Cardio', 'Riley Pace', 'Avery Stride',
      'Quinn Walker', 'Blake Motion', 'Jamie Sprint', 'Drew Distance',
    ];
    return names[index % names.length];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: CustomScrollView(
        slivers: [
          // Your rank header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: RivlColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '#$_userRank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top 3 podium
          if (_entries.length >= 3)
            SliverToBoxAdapter(child: _buildPodium()),

          // Remaining rankings
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = _entries[index + 3];
                  return _LeaderboardTile(entry: entry);
                },
                childCount: _entries.length > 3 ? _entries.length - 3 : 0,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PodiumCard(entry: _entries[1], height: 90, color: const Color(0xFFC0C0C0)),
          const SizedBox(width: 8),
          _PodiumCard(entry: _entries[0], height: 120, color: const Color(0xFFFFD700), isFirst: true),
          const SizedBox(width: 8),
          _PodiumCard(entry: _entries[2], height: 70, color: const Color(0xFFCD7F32)),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color color;
  final bool isFirst;

  const _PodiumCard({
    required this.entry,
    required this.height,
    required this.color,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst)
          const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 28),
        CircleAvatar(
          radius: isFirst ? 36 : 28,
          backgroundColor: color.withOpacity(0.3),
          child: Text(
            entry.displayName[0],
            style: TextStyle(
              fontSize: isFirst ? 24 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 75,
          child: Text(
            entry.displayName.split(' ').first,
            style: TextStyle(fontSize: isFirst ? 13 : 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text('${entry.wins} wins', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 6),
        Container(
          width: isFirst ? 85 : 70,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: isFirst ? 18 : 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: entry.isCurrentUser ? RivlColors.primary.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: entry.isCurrentUser
            ? const BorderSide(color: RivlColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: entry.isCurrentUser ? RivlColors.primary : Colors.grey[600],
                ),
              ),
            ),
            CircleAvatar(
              radius: 20,
              backgroundColor: RivlColors.primary.withOpacity(0.1),
              child: Text(
                entry.displayName[0],
                style: const TextStyle(fontWeight: FontWeight.bold, color: RivlColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: entry.isCurrentUser ? RivlColors.primary : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: RivlColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text('@${entry.username}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry.wins} wins', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${(entry.winRate * 100).toInt()}%', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TAB 3: SEASON / BATTLE PASS
// ============================================

class _SeasonTab extends StatelessWidget {
  const _SeasonTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<BattlePassProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final progress = provider.progress;
        final season = provider.currentSeason;

        if (progress == null || season == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.military_tech, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No season data', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        // Group rewards by level
        final rewardsByLevel = <int, List<BattlePassReward>>{};
        for (final reward in season.rewards) {
          rewardsByLevel.putIfAbsent(reward.level, () => []);
          rewardsByLevel[reward.level]!.add(reward);
        }
        final sortedLevels = rewardsByLevel.keys.toList()..sort();

        // Calculate overall XP progress
        final totalXP = progress.totalXP;
        final maxXP = BattlePassSeason.tierXPThresholds.last;

        return ListView(
          padding: const EdgeInsets.all(0),
          children: [
            // Season header card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: RivlColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            season.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${progress.daysRemaining} days remaining',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${totalXP.clamp(0, maxXP)} / $maxXP XP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Overall progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (totalXP / maxXP).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tier ${progress.currentLevel} of 10',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                      Text(
                        '${((totalXP / maxXP) * 100).clamp(0, 100).toInt()}% Complete',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horizontal battle pass bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 72,
              child: _BattlePassBar(
                currentXP: totalXP,
                currentTier: progress.currentLevel,
              ),
            ),

            // Premium banner
            if (!provider.isPremiumUnlocked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unlock Premium Rewards',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Get gift cards, electrolytes, gear & more',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final auth = context.read<AuthProvider>();
                          provider.unlockPremium(auth.user!.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Reward tier list
            ...sortedLevels.map((level) {
              final rewards = rewardsByLevel[level]!;
              final isUnlocked = level <= provider.currentLevel;
              final xpNeeded = BattlePassSeason.xpForTier(level);

              return _TierRewardCard(
                tier: level,
                xpNeeded: xpNeeded,
                currentXP: totalXP,
                rewards: rewards,
                isUnlocked: isUnlocked,
                isPremium: provider.isPremiumUnlocked,
                isClaimed: (r) => provider.isRewardClaimed(r.level, r.tier),
                onClaim: (r) {
                  final auth = context.read<AuthProvider>();
                  provider.claimReward(auth.user!.id, r.level, r.tier);
                },
              );
            }),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

/// Horizontal scrollable battle pass progress bar
class _BattlePassBar extends StatelessWidget {
  final int currentXP;
  final int currentTier;

  const _BattlePassBar({required this.currentXP, required this.currentTier});

  @override
  Widget build(BuildContext context) {
    final thresholds = BattlePassSeason.tierXPThresholds;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(10, (index) {
          final tier = index + 1;
          final tierXP = thresholds[tier];
          final prevXP = thresholds[tier - 1];
          final isUnlocked = currentXP >= tierXP;
          final isActive = currentXP >= prevXP && currentXP < tierXP;
          final segmentProgress = isUnlocked
              ? 1.0
              : isActive
                  ? ((currentXP - prevXP) / (tierXP - prevXP)).clamp(0.0, 1.0)
                  : 0.0;

          return Row(
            children: [
              // Tier node
              _TierNode(
                tier: tier,
                isUnlocked: isUnlocked,
                isActive: isActive,
                icon: _tierIcon(tier),
              ),
              // Progress connector (except after last)
              if (tier < 10)
                SizedBox(
                  width: 32,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: segmentProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUnlocked ? RivlColors.success : RivlColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  IconData _tierIcon(int tier) {
    switch (tier) {
      case 1: return Icons.monetization_on;
      case 2: return Icons.water_drop;
      case 3: return Icons.blender;
      case 4: return Icons.eco;
      case 5: return Icons.card_giftcard;
      case 6: return Icons.fitness_center;
      case 7: return Icons.local_drink;
      case 8: return Icons.card_giftcard;
      case 9: return Icons.sports_gymnastics;
      case 10: return Icons.emoji_events;
      default: return Icons.star;
    }
  }
}

class _TierNode extends StatelessWidget {
  final int tier;
  final bool isUnlocked;
  final bool isActive;
  final IconData icon;

  const _TierNode({
    required this.tier,
    required this.isUnlocked,
    required this.isActive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color iconColor;
    final Color borderColor;

    if (isUnlocked) {
      bgColor = RivlColors.success.withOpacity(0.15);
      iconColor = RivlColors.success;
      borderColor = RivlColors.success;
    } else if (isActive) {
      bgColor = RivlColors.primary.withOpacity(0.15);
      iconColor = RivlColors.primary;
      borderColor = RivlColors.primary;
    } else {
      bgColor = Colors.grey[100]!;
      iconColor = Colors.grey[400]!;
      borderColor = Colors.grey[300]!;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2.5),
          ),
          child: Center(
            child: isUnlocked
                ? Icon(Icons.check, color: iconColor, size: 22)
                : Icon(icon, color: iconColor, size: 20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$tier',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isUnlocked ? FontWeight.bold : FontWeight.normal,
            color: isActive ? RivlColors.primary : isUnlocked ? RivlColors.success : Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

/// Individual tier reward card showing free + premium tracks
class _TierRewardCard extends StatelessWidget {
  final int tier;
  final int xpNeeded;
  final int currentXP;
  final List<BattlePassReward> rewards;
  final bool isUnlocked;
  final bool isPremium;
  final bool Function(BattlePassReward) isClaimed;
  final Function(BattlePassReward) onClaim;

  const _TierRewardCard({
    required this.tier,
    required this.xpNeeded,
    required this.currentXP,
    required this.rewards,
    required this.isUnlocked,
    required this.isPremium,
    required this.isClaimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final freeRewards = rewards.where((r) => r.tier == RewardTier.free).toList();
    final premiumRewards = rewards.where((r) => r.tier == RewardTier.premium).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnlocked
              ? RivlColors.success.withOpacity(0.4)
              : Colors.grey[200]!,
          width: isUnlocked ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tier header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? RivlColors.success.withOpacity(0.06)
                  : Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isUnlocked ? RivlColors.success : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: isUnlocked
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '$tier',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tier $tier',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isUnlocked ? RivlColors.success : null,
                        ),
                      ),
                      Text(
                        isUnlocked
                            ? 'Unlocked'
                            : '${(xpNeeded - currentXP).clamp(0, xpNeeded)} XP to unlock',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked ? RivlColors.success : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? RivlColors.success.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_formatXP(xpNeeded)} XP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? RivlColors.success : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rewards row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Free track
                Expanded(
                  child: freeRewards.isNotEmpty
                      ? _RewardItem(
                          reward: freeRewards.first,
                          isLocked: !isUnlocked,
                          claimed: isUnlocked && isClaimed(freeRewards.first),
                          onClaim: () => onClaim(freeRewards.first),
                          trackLabel: 'FREE',
                          trackColor: RivlColors.primary,
                        )
                      : const SizedBox.shrink(),
                ),
                // Divider
                Container(
                  width: 1,
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.grey[200],
                ),
                // Premium track
                Expanded(
                  child: premiumRewards.isNotEmpty
                      ? _RewardItem(
                          reward: premiumRewards.first,
                          isLocked: !isUnlocked || !isPremium,
                          claimed: isUnlocked && isPremium && isClaimed(premiumRewards.first),
                          onClaim: () => onClaim(premiumRewards.first),
                          trackLabel: 'PREMIUM',
                          trackColor: Colors.amber,
                          showLock: !isPremium && isUnlocked,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatXP(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(xp % 1000 == 0 ? 0 : 1)}K';
    return '$xp';
  }
}

class _RewardItem extends StatelessWidget {
  final BattlePassReward reward;
  final bool isLocked;
  final bool claimed;
  final VoidCallback onClaim;
  final String trackLabel;
  final Color trackColor;
  final bool showLock;

  const _RewardItem({
    required this.reward,
    required this.isLocked,
    required this.claimed,
    required this.onClaim,
    required this.trackLabel,
    required this.trackColor,
    this.showLock = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Track label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: trackColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            trackLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: trackColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Reward icon + name
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey[100] : trackColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _rewardIcon(reward.type),
                      size: 18,
                      color: isLocked ? Colors.grey[400] : trackColor,
                    ),
                  ),
                  if (showLock)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lock, size: 10, color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reward.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isLocked ? Colors.grey[400] : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Claim button or status
        if (claimed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RivlColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 12, color: RivlColors.success),
                const SizedBox(width: 4),
                Text(
                  'Claimed',
                  style: TextStyle(
                    color: RivlColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else if (!isLocked && !showLock)
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: trackColor,
                foregroundColor: trackColor == Colors.amber ? Colors.black : Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Claim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          )
        else
          Text(
            showLock ? 'Premium only' : 'Locked',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
      ],
    );
  }

  IconData _rewardIcon(RewardType type) {
    switch (type) {
      case RewardType.coins:
        return Icons.monetization_on;
      case RewardType.premium_days:
        return Icons.workspace_premium;
      case RewardType.avatar:
        return Icons.auto_awesome;
      case RewardType.badge:
        return Icons.military_tech;
      case RewardType.boost:
        return Icons.rocket_launch;
      case RewardType.unlock:
        return Icons.emoji_events;
      case RewardType.product:
        return Icons.inventory_2;
      case RewardType.giftcard:
        return Icons.card_giftcard;
    }
  }
}

// ============================================
// SHARED WIDGETS
// ============================================

class _ActivityFeedTile extends StatelessWidget {
  final ActivityFeedItem item;

  const _ActivityFeedTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.hasChallenge
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChallengeDetailScreen(challengeId: item.challengeId!),
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: item.color.withOpacity(0.15),
                  child: Text(
                    item.displayName.isNotEmpty ? item.displayName[0] : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.color,
                      fontSize: 18,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                      ],
                    ),
                    child: Icon(item.icon, size: 14, color: item.color),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: item.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: ' ${_actionText(item)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.amount != null && item.amount! > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.type == ActivityType.challengeWon
                            ? RivlColors.success.withOpacity(0.1)
                            : RivlColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '\$${item.amount!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: item.type == ActivityType.challengeWon
                              ? RivlColors.success
                              : RivlColors.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(item.createdAt),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (item.hasChallenge)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ),
          ],
        ),
      ),
    );
  }

  String _actionText(ActivityFeedItem item) {
    switch (item.type) {
      case ActivityType.challengeWon:
        return 'won against ${item.opponentName ?? 'an opponent'}';
      case ActivityType.challengeLost:
        return 'completed a challenge vs ${item.opponentName ?? 'an opponent'}';
      case ActivityType.challengeCreated:
        return 'challenged ${item.opponentName ?? 'someone'}';
      case ActivityType.challengeAccepted:
        return 'accepted a challenge from ${item.opponentName ?? 'someone'}';
      case ActivityType.streakMilestone:
        final days = item.data['streakDays'] ?? 0;
        return 'hit a $days-day streak!';
      case ActivityType.joinedApp:
        return 'joined RIVL';
      case ActivityType.levelUp:
        final level = item.data['level'] ?? 0;
        return 'reached Level $level';
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}
