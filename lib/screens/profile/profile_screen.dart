// screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../../utils/theme.dart';
import '../../models/achievement_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, StatsProvider>(
        builder: (context, authProvider, statsProvider, _) {
          final user = authProvider.user;
          final stats = statsProvider.stats;

          if (user == null) {
            return const Center(child: Text('Please sign in'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Photo
                CircleAvatar(
                  radius: 60,
                  backgroundColor: RivlColors.primary.withOpacity(0.2),
                  child: Text(
                    user.displayName[0],
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: RivlColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name & Username
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@\${user.username}',
                  style: RivlTextStyles.bodySecondary,
                ),
                const SizedBox(height: 24),

                // Quick Stats Cards
                if (stats != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _QuickStatCard(
                          label: 'Record',
                          value: stats.winLossRecord,
                          icon: Icons.sports_score,
                          color: RivlColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickStatCard(
                          label: 'Win Rate',
                          value: stats.winRateDisplay,
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickStatCard(
                          label: 'Total Earned',
                          value: '\$\${stats.totalEarnings.toInt()}',
                          icon: Icons.attach_money,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickStatCard(
                          label: 'Streak',
                          value: '\${stats.currentStreak}🔥',
                          icon: Icons.local_fire_department,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Action Buttons
                _ActionButton(
                  icon: Icons.bar_chart,
                  label: 'View Stats',
                  onTap: () => Navigator.pushNamed(context, '/stats'),
                ),
                _ActionButton(
                  icon: Icons.history,
                  label: 'Challenge History',
                  onTap: () => Navigator.pushNamed(context, '/challenge-history'),
                ),
                _ActionButton(
                  icon: Icons.account_balance_wallet,
                  label: 'Wallet',
                  onTap: () => Navigator.pushNamed(context, '/wallet'),
                ),
                _ActionButton(
                  icon: Icons.emoji_events,
                  label: 'Achievements',
                  onTap: () => Navigator.pushNamed(context, '/achievements'),
                ),
                _ActionButton(
                  icon: Icons.people,
                  label: 'Friends',
                  onTap: () => Navigator.pushNamed(context, '/friends'),
                ),
                const SizedBox(height: 24),

                // Sign Out Button
                OutlinedButton.icon(
                  onPressed: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 48),
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

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: RivlTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: RivlColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
