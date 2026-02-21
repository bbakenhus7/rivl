// screens/battle_pass/battle_pass_screen.dart
//
// Standalone Battle Pass screen — now delegates to the shared _SeasonTab
// in ActivityFeedScreen to avoid duplication.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/battle_pass_model.dart';
import '../../providers/battle_pass_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/skeleton_loader.dart';

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
      } else {
        context.read<BattlePassProvider>().ensureDemoData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Season Pass'),
      ),
      body: Consumer<BattlePassProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const _BattlePassSkeleton();
          }

          final progress = provider.progress;
          final season = provider.currentSeason;

          if (progress == null || season == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.military_tech, size: 64, color: context.textSecondary),
                  const SizedBox(height: 16),
                  Text('No season data', style: TextStyle(fontSize: 18, color: context.textSecondary)),
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
                                style: TextStyle(color: context.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final auth = context.read<AuthProvider>();
                            final userId = auth.user?.id;
                            if (userId == null) return;
                            provider.unlockPremium(userId);
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

              // Reward tier list — same layout as _SeasonTab in activity_feed_screen
              ...sortedLevels.map((level) {
                final rewards = rewardsByLevel[level]!;
                final isUnlocked = level <= provider.currentLevel;
                final xpNeeded = BattlePassSeason.xpForTier(level);
                final freeRewards = rewards.where((r) => r.tier == RewardTier.free).toList();
                final premiumRewards = rewards.where((r) => r.tier == RewardTier.premium).toList();

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUnlocked
                          ? RivlColors.success.withOpacity(0.4)
                          : context.surfaceVariant,
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
                              : context.surfaceVariant,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isUnlocked ? RivlColors.success : context.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: isUnlocked
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : Text(
                                        '$level',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: context.textSecondary,
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
                                    'Tier $level',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isUnlocked ? RivlColors.success : null,
                                    ),
                                  ),
                                  Text(
                                    isUnlocked
                                        ? 'Unlocked'
                                        : '${(xpNeeded - totalXP).clamp(0, xpNeeded)} XP to unlock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isUnlocked ? RivlColors.success : context.textSecondary,
                                    ),
                                  ),
                                ],
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
                            Expanded(
                              child: freeRewards.isNotEmpty
                                  ? _RewardChip(
                                      reward: freeRewards.first,
                                      isLocked: !isUnlocked,
                                      claimed: isUnlocked && provider.isRewardClaimed(freeRewards.first.level, freeRewards.first.tier),
                                      onClaim: () {
                                        final userId = context.read<AuthProvider>().user?.id;
                                        if (userId != null) provider.claimReward(userId, freeRewards.first.level, freeRewards.first.tier);
                                      },
                                      trackLabel: 'FREE',
                                      trackColor: RivlColors.primary,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            Container(
                              width: 1,
                              height: 80,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              color: context.surfaceVariant,
                            ),
                            Expanded(
                              child: premiumRewards.isNotEmpty
                                  ? _RewardChip(
                                      reward: premiumRewards.first,
                                      isLocked: !isUnlocked || !provider.isPremiumUnlocked,
                                      claimed: isUnlocked && provider.isPremiumUnlocked && provider.isRewardClaimed(premiumRewards.first.level, premiumRewards.first.tier),
                                      onClaim: () {
                                        final userId = context.read<AuthProvider>().user?.id;
                                        if (userId != null) provider.claimReward(userId, premiumRewards.first.level, premiumRewards.first.tier);
                                      },
                                      trackLabel: 'PREMIUM',
                                      trackColor: Colors.amber,
                                      showLock: !provider.isPremiumUnlocked && isUnlocked,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final BattlePassReward reward;
  final bool isLocked;
  final bool claimed;
  final VoidCallback onClaim;
  final String trackLabel;
  final Color trackColor;
  final bool showLock;

  const _RewardChip({
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
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isLocked ? context.surfaceVariant : trackColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _rewardIcon(reward.type),
                      size: 18,
                      color: isLocked ? context.textSecondary : trackColor,
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
                        child: Icon(Icons.lock, size: 10, color: context.textSecondary),
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
                  color: isLocked ? context.textSecondary : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
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
            style: TextStyle(fontSize: 11, color: context.textSecondary),
          ),
      ],
    );
  }

  IconData _rewardIcon(RewardType type) {
    switch (type) {
      case RewardType.coins: return Icons.monetization_on;
      case RewardType.premium_days: return Icons.workspace_premium;
      case RewardType.avatar: return Icons.auto_awesome;
      case RewardType.badge: return Icons.military_tech;
      case RewardType.boost: return Icons.rocket_launch;
      case RewardType.unlock: return Icons.emoji_events;
      case RewardType.product: return Icons.inventory_2;
      case RewardType.giftcard: return Icons.card_giftcard;
    }
  }
}

class _BattlePassSkeleton extends StatelessWidget {
  const _BattlePassSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBox(height: 100, borderRadius: 16),
            const SizedBox(height: 16),
            SkeletonBox(height: 48, borderRadius: 12),
            const SizedBox(height: 16),
            for (int i = 0; i < 5; i++) ...[
              SkeletonBox(height: 70, borderRadius: 14),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
