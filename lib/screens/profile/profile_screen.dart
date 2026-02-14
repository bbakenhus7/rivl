// screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../wallet/wallet_screen.dart';
import '../notifications/notifications_screen.dart';
import 'health_connection_screen.dart';
import 'help_support_screen.dart';

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
                      gradient: RivlColors.primaryDeepGradient,
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

                    // Personal Attributes
                    SlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: _PersonalAttributes(user: user),
                    ),
                    const SizedBox(height: 16),

                    // Achievements
                    SlideIn(
                      delay: const Duration(milliseconds: 200),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
        Container(width: 1, height: 40, color: context.surfaceVariant),
        Expanded(child: _QuickStat(value: '${user.losses}', label: 'Losses', color: RivlColors.error)),
        Container(width: 1, height: 40, color: context.surfaceVariant),
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
            color: context.textSecondary,
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
        color: context.surface,
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
          child: Text(label, style: TextStyle(fontSize: 14, color: context.textSecondary)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PersonalAttributes extends StatelessWidget {
  final UserModel user;

  const _PersonalAttributes({required this.user});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    final runningWorkouts = health.recentWorkouts
        .where((w) => w.type.toUpperCase() == 'RUNNING' && w.distance > 0)
        .toList();

    // Calculate average pace from running workouts (min per mile)
    double? avgPaceMinPerMile;
    if (runningWorkouts.isNotEmpty) {
      double totalPace = 0;
      for (final w in runningWorkouts) {
        totalPace += w.duration.inSeconds / 60 / w.distance; // min/mile
      }
      avgPaceMinPerMile = totalPace / runningWorkouts.length;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
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
              const Text('Personal Attributes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => _showEditSheet(context, user),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: RivlColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RivlColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Body section
          Row(
            children: [
              Expanded(
                child: _AttrTile(
                  label: 'Weight',
                  value: user.weightLbs != null ? '${user.weightLbs!.toStringAsFixed(0)} lbs' : '—',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttrTile(
                  label: 'Height',
                  value: user.heightInches != null
                      ? '${(user.heightInches! ~/ 12)}\' ${(user.heightInches! % 12).toStringAsFixed(0)}"'
                      : '—',
                  icon: Icons.height,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttrTile(
                  label: 'BMI',
                  value: user.bmi != null ? user.bmi!.toStringAsFixed(1) : '—',
                  icon: Icons.accessibility_new,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Running paces (auto from health data)
          _SectionLabel(label: 'Running Pace', subtitle: 'Auto-synced'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AttrTile(
                  label: '1 Mile',
                  value: avgPaceMinPerMile != null ? _formatPace(avgPaceMinPerMile) : '—',
                  icon: Icons.directions_run,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttrTile(
                  label: '5K',
                  value: avgPaceMinPerMile != null ? _formatTime(avgPaceMinPerMile * 3.107) : '—',
                  icon: Icons.directions_run,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttrTile(
                  label: '10K',
                  value: avgPaceMinPerMile != null ? _formatTime(avgPaceMinPerMile * 6.214) : '—',
                  icon: Icons.directions_run,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // PRs (manual input)
          _SectionLabel(label: 'Personal Records', subtitle: 'Manual'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AttrTile(
                  label: 'Pull-ups',
                  value: user.pullUpsPR != null ? '${user.pullUpsPR} reps' : '—',
                  icon: Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttrTile(
                  label: 'Bench',
                  value: user.benchPressPR != null ? '${user.benchPressPR} lbs' : '—',
                  icon: Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttrTile(
                  label: 'Squat',
                  value: user.squatPR != null ? '${user.squatPR} lbs' : '—',
                  icon: Icons.fitness_center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPace(double minPerMile) {
    final mins = minPerMile.floor();
    final secs = ((minPerMile - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}/mi';
  }

  String _formatTime(double totalMinutes) {
    final mins = totalMinutes.floor();
    final secs = ((totalMinutes - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  void _showEditSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditAttributesSheet(user: user),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String subtitle;

  const _SectionLabel({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: context.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: context.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _AttrTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AttrTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: context.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: context.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EditAttributesSheet extends StatefulWidget {
  final UserModel user;

  const _EditAttributesSheet({required this.user});

  @override
  State<_EditAttributesSheet> createState() => _EditAttributesSheetState();
}

class _EditAttributesSheetState extends State<_EditAttributesSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightFtCtrl;
  late final TextEditingController _heightInCtrl;
  late final TextEditingController _pullUpsCtrl;
  late final TextEditingController _benchCtrl;
  late final TextEditingController _squatCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.user.weightLbs?.toStringAsFixed(0) ?? '',
    );
    _heightFtCtrl = TextEditingController(
      text: widget.user.heightInches != null ? '${widget.user.heightInches! ~/ 12}' : '',
    );
    _heightInCtrl = TextEditingController(
      text: widget.user.heightInches != null ? '${(widget.user.heightInches! % 12).toStringAsFixed(0)}' : '',
    );
    _pullUpsCtrl = TextEditingController(
      text: widget.user.pullUpsPR?.toString() ?? '',
    );
    _benchCtrl = TextEditingController(
      text: widget.user.benchPressPR?.toString() ?? '',
    );
    _squatCtrl = TextEditingController(
      text: widget.user.squatPR?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightFtCtrl.dispose();
    _heightInCtrl.dispose();
    _pullUpsCtrl.dispose();
    _benchCtrl.dispose();
    _squatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final weight = double.tryParse(_weightCtrl.text);
    final heightFt = int.tryParse(_heightFtCtrl.text);
    final heightIn = int.tryParse(_heightInCtrl.text);
    final totalInches = (heightFt != null || heightIn != null)
        ? ((heightFt ?? 0) * 12 + (heightIn ?? 0)).toDouble()
        : null;
    final pullUps = int.tryParse(_pullUpsCtrl.text);
    final bench = int.tryParse(_benchCtrl.text);
    final squat = int.tryParse(_squatCtrl.text);

    final updates = <String, dynamic>{};
    if (weight != null) updates['weightLbs'] = weight;
    if (totalInches != null && totalInches > 0) updates['heightInches'] = totalInches;
    if (pullUps != null) updates['pullUpsPR'] = pullUps;
    if (bench != null) updates['benchPressPR'] = bench;
    if (squat != null) updates['squatPR'] = squat;

    if (updates.isNotEmpty) {
      try {
        await FirebaseService().updateUser(widget.user.id, updates);
        // Refresh user data
        if (mounted) {
          await context.read<AuthProvider>().refreshUser();
        }
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Edit Attributes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              // Body
              Row(
                children: [
                  Expanded(
                    child: _FieldInput(
                      controller: _weightCtrl,
                      label: 'Weight (lbs)',
                      hint: '175',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: _FieldInput(
                      controller: _heightFtCtrl,
                      label: 'Feet',
                      hint: '5',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: _FieldInput(
                      controller: _heightInCtrl,
                      label: 'Inches',
                      hint: '10',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // PRs
              Row(
                children: [
                  Expanded(
                    child: _FieldInput(
                      controller: _pullUpsCtrl,
                      label: 'Pull-ups PR',
                      hint: '15',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldInput(
                      controller: _benchCtrl,
                      label: 'Bench PR (lbs)',
                      hint: '225',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldInput(
                      controller: _squatCtrl,
                      label: 'Squat PR (lbs)',
                      hint: '315',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RivlColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _FieldInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.4)),
            filled: true,
            fillColor: context.surfaceVariant.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
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
        color: context.surface,
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
                style: TextStyle(fontSize: 13, color: context.textSecondary, fontWeight: FontWeight.w500),
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
              color: unlocked ? Colors.amber.withOpacity(0.1) : context.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: unlocked
                  ? Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Icon(
              achievement.icon,
              size: 28,
              color: unlocked ? Colors.amber[700] : context.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: unlocked ? context.textPrimary : context.textSecondary,
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
        color: context.surface,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Refer Friends', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(
                      'Earn \$2 for each friend who joins!',
                      style: TextStyle(color: context.textSecondary, fontSize: 13),
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
              Text('${user.referralCount} referrals', style: TextStyle(color: context.textSecondary, fontSize: 13)),
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
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.health_and_safety,
            label: 'Health App Connection',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HealthConnectionScreen()),
            ),
          ),
          Divider(height: 1, indent: 56, color: context.surfaceVariant),
          _ActionTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          Divider(height: 1, indent: 56, color: context.surfaceVariant),
          _ActionTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            ),
          ),
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
                color: context.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: context.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right, color: context.textSecondary, size: 20),
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.surfaceVariant,
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
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
        ),
      ),
    );
  }
}
