// screens/battle_pass/battle_pass_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/battle_pass_model.dart';
import '../../providers/battle_pass_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class BattlePassScreen extends StatefulWidget {
  const BattlePassScreen({Key? key}) : super(key: key);

  @override
  State<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends State<BattlePassScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context.read<BattlePassProvider>().loadProgress(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BattlePassProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final progress = provider.progress;
          if (progress == null) {
            return const Center(child: Text('No battle pass data'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(progress),
              _buildXPProgress(progress),
              _buildPremiumBanner(provider),
              _buildRewardTiers(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BattlePassProgress progress) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: RivlColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Season ${progress.season}'),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                RivlColors.primary,
                RivlColors.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Level ${progress.currentLevel}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${progress.daysRemaining} days remaining',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildXPProgress(BattlePassProgress progress) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${progress.currentLevel}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${progress.currentXP} / ${progress.xpForNextLevel} XP',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.levelProgress,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(RivlColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _XPInfoChip(
                      icon: Icons.stars,
                      label: 'Total XP',
                      value: progress.totalXP.toString(),
                    ),
                    const SizedBox(width: 12),
                    _XPInfoChip(
                      icon: Icons.emoji_events,
                      label: 'Max Level',
                      value: '100',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBanner(BattlePassProvider provider) {
    if (provider.isPremiumUnlocked) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          color: Colors.amber[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unlock Premium Pass',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Get 2x rewards on every level!',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _unlockPremium(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardTiers(BattlePassProvider provider) {
    final season = provider.currentSeason;
    if (season == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // Group rewards by level
    final rewardsByLevel = <int, List<BattlePassReward>>{};
    for (final reward in season.rewards) {
      if (!rewardsByLevel.containsKey(reward.level)) {
        rewardsByLevel[reward.level] = [];
      }
      rewardsByLevel[reward.level]!.add(reward);
    }

    final sortedLevels = rewardsByLevel.keys.toList()..sort();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final level = sortedLevels[index];
          final rewards = rewardsByLevel[level]!;
          final isLocked = level > provider.currentLevel;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _LevelRewardCard(
              level: level,
              rewards: rewards,
              isLocked: isLocked,
              isPremiumUnlocked: provider.isPremiumUnlocked,
              onClaimReward: (reward) => _claimReward(provider, reward),
              isClaimed: (reward) => provider.isRewardClaimed(reward.level, reward.tier),
            ),
          );
        },
        childCount: sortedLevels.length,
      ),
    );
  }

  void _unlockPremium(BattlePassProvider provider) {
    // In production, this would trigger a payment flow
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Premium Pass'),
        content: const Text('Premium Pass: \$9.99\n\nGet access to all premium rewards!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              await provider.unlockPremium(authProvider.user!.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium Pass unlocked!')),
              );
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _claimReward(BattlePassProvider provider, BattlePassReward reward) async {
    final authProvider = context.read<AuthProvider>();
    final success = await provider.claimReward(
      authProvider.user!.id,
      reward.level,
      reward.tier,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Claimed: ${reward.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to claim reward')),
      );
    }
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

class _XPInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _XPInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: RivlColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: RivlColors.primary, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelRewardCard extends StatelessWidget {
  final int level;
  final List<BattlePassReward> rewards;
  final bool isLocked;
  final bool isPremiumUnlocked;
  final Function(BattlePassReward) onClaimReward;
  final bool Function(BattlePassReward) isClaimed;

  const _LevelRewardCard({
    required this.level,
    required this.rewards,
    required this.isLocked,
    required this.isPremiumUnlocked,
    required this.onClaimReward,
    required this.isClaimed,
  });

  @override
  Widget build(BuildContext context) {
    final freeReward = rewards.firstWhere(
      (r) => r.tier == RewardTier.free,
      orElse: () => BattlePassReward(
        level: level,
        tier: RewardTier.free,
        type: RewardType.coins,
        name: '',
        description: '',
      ),
    );

    final premiumReward = rewards.firstWhere(
      (r) => r.tier == RewardTier.premium,
      orElse: () => BattlePassReward(
        level: level,
        tier: RewardTier.premium,
        type: RewardType.coins,
        name: '',
        description: '',
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Level indicator
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey[300] : RivlColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.grey[600] : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Free reward
            Expanded(
              child: freeReward.name.isNotEmpty
                  ? _RewardItem(
                      reward: freeReward,
                      isLocked: isLocked,
                      isClaimed: isClaimed(freeReward),
                      onClaim: () => onClaimReward(freeReward),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('—')),
                    ),
            ),
            const SizedBox(width: 16),

            // Premium reward
            Expanded(
              child: premiumReward.name.isNotEmpty
                  ? _RewardItem(
                      reward: premiumReward,
                      isLocked: isLocked || !isPremiumUnlocked,
                      isClaimed: isClaimed(premiumReward),
                      onClaim: () => onClaimReward(premiumReward),
                      isPremium: true,
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('—')),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final BattlePassReward reward;
  final bool isLocked;
  final bool isClaimed;
  final VoidCallback onClaim;
  final bool isPremium;

  const _RewardItem({
    required this.reward,
    required this.isLocked,
    required this.isClaimed,
    required this.onClaim,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPremium ? Colors.amber[50] : Colors.grey[50];
    final accentColor = isPremium ? Colors.amber : RivlColors.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPremium ? Colors.amber : Colors.grey[300]!,
          width: isPremium ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRewardIcon(reward.type),
                size: 20,
                color: isLocked ? Colors.grey : accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reward.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isLocked ? Colors.grey : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!isLocked)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: isClaimed
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Claimed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: onClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        minimumSize: const Size(double.infinity, 32),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Claim',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.coins:
        return Icons.monetization_on;
      case RewardType.premium_days:
        return Icons.workspace_premium;
      case RewardType.avatar:
        return Icons.face;
      case RewardType.badge:
        return Icons.military_tech;
      case RewardType.boost:
        return Icons.rocket_launch;
      case RewardType.unlock:
        return Icons.lock_open;
      case RewardType.product:
        return Icons.redeem;
      case RewardType.giftcard:
        return Icons.card_giftcard;
    }
  }
}
