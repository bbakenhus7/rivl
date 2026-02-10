// screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../wallet/wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();
      final userId = authProvider.user?.id ?? 'demo_user';
      walletProvider.initialize(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user ?? UserModel.demo();

          return CustomScrollView(
            slivers: [
              // Gradient header with profile info
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: RivlColors.primary,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () => _showSettings(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2277DD), Color(0xFF3399FF), Color(0xFF55AAFF)],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          // Avatar with ring border
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage: user.profileImageUrl != null
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                              child: user.profileImageUrl == null
                                  ? Text(
                                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (user.isVerified)
                                _HeaderBadge(icon: Icons.verified, label: 'Verified'),
                              if (user.isPremium)
                                _HeaderBadge(icon: Icons.star, label: 'Premium'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Demo mode banner
                    if (authProvider.user == null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RivlColors.info.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RivlColors.info.withOpacity(0.15)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: RivlColors.info, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Demo Mode — Sign in to see your real stats',
                                style: TextStyle(color: RivlColors.info, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Quick Stats Row (Robinhood-style bold numbers)
                    SlideIn(
                      child: _QuickStatsRow(user: user),
                    ),
                    const SizedBox(height: 16),

                    // Wallet Card
                    SlideIn(
                      delay: const Duration(milliseconds: 50),
                      child: _WalletQuickAccess(),
                    ),
                    const SizedBox(height: 16),

                    // Detailed Stats
                    SlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: _DetailedStats(user: user),
                    ),
                    const SizedBox(height: 16),

                    // Achievements
                    SlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: _AchievementsSection(user: user),
                    ),
                    const SizedBox(height: 16),

                    // Referral
                    SlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: _ReferralSection(user: user),
                    ),
                    const SizedBox(height: 16),

                    // Account Actions
                    SlideIn(
                      delay: const Duration(milliseconds: 250),
                      child: _AccountActions(),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

/// Bold number stats at top (like Robinhood portfolio summary)
class _QuickStatsRow extends StatelessWidget {
  final UserModel user;

  const _QuickStatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickStat(value: '${user.wins}', label: 'Wins', color: RivlColors.success)),
        Container(width: 1, height: 40, color: Colors.grey[200]),
        Expanded(child: _QuickStat(value: '${user.losses}', label: 'Losses', color: RivlColors.error)),
        Container(width: 1, height: 40, color: Colors.grey[200]),
        Expanded(child: _QuickStat(value: user.winPercentage, label: 'Win Rate', color: RivlColors.primary)),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _QuickStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _WalletQuickAccess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        return ScaleOnTap(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: RivlColors.success.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet Balance',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${walletProvider.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailedStats extends StatelessWidget {
  final UserModel user;

  const _DetailedStats({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _StatRow(
            icon: Icons.local_fire_department,
            label: 'Current Streak',
            value: '${user.currentStreak} days',
            color: RivlColors.warning,
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.directions_walk,
            label: 'Total Steps',
            value: _formatNumber(user.totalSteps),
            color: RivlColors.info,
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.attach_money,
            label: 'Total Earned',
            value: '\$${user.totalEarnings.toStringAsFixed(0)}',
            color: RivlColors.success,
          ),
          const SizedBox(height: 14),
          _StatRow(
            icon: Icons.emoji_events,
            label: 'Longest Streak',
            value: '${user.longestStreak} days',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final UserModel user;

  const _AchievementsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      _Achievement(icon: Icons.emoji_events, title: 'First Win', unlocked: user.wins >= 1),
      _Achievement(icon: Icons.military_tech, title: '10 Wins', unlocked: user.wins >= 10),
      _Achievement(icon: Icons.local_fire_department, title: 'On Fire', unlocked: user.currentStreak >= 5),
      _Achievement(icon: Icons.directions_walk, title: '100K Steps', unlocked: user.totalSteps >= 100000),
      _Achievement(icon: Icons.star, title: 'Champion', unlocked: user.wins >= 50),
      _Achievement(icon: Icons.trending_up, title: '30 Day Streak', unlocked: user.longestStreak >= 30),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Achievements', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text(
                '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
                style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((a) => _AchievementBadge(achievement: a)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final IconData icon;
  final String title;
  final bool unlocked;

  const _Achievement({required this.icon, required this.title, required this.unlocked});
}

class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 80) / 3,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: unlocked ? Colors.amber.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: unlocked
                  ? Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Icon(
              achievement.icon,
              size: 28,
              color: unlocked ? Colors.amber[700] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: unlocked ? Colors.grey[800] : Colors.grey[400],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReferralSection extends StatelessWidget {
  final UserModel user;

  const _ReferralSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RivlColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people, size: 18, color: RivlColors.primary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Refer Friends', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(
                      'Earn \$2 for each friend who joins!',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: RivlColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    user.referralCode,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: RivlColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${user.referralCount} referrals', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(
                '+\$${user.referralEarnings.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: RivlColors.success, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _ActionTile(icon: Icons.health_and_safety, label: 'Health App Connection', onTap: () {}),
          Divider(height: 1, indent: 56, color: Colors.grey[100]),
          _ActionTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
          Divider(height: 1, indent: 56, color: Colors.grey[100]),
          _ActionTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: Colors.grey[700]),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: RivlColors.error),
            title: const Text('Sign Out', style: TextStyle(color: RivlColors.error)),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
    );
  }
}
