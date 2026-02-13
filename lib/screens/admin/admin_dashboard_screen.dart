// screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FraudDetectionTab(),
    const UserManagementTab(),
    const ChallengeMonitoringTab(),
    const AnalyticsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: RivlColors.primary,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: RivlColors.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Fraud',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_score),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

// ============================================
// FRAUD DETECTION TAB
// ============================================

class FraudDetectionTab extends StatelessWidget {
  const FraudDetectionTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('challenges')
          .where('flagged', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final flaggedChallenges = snapshot.data?.docs ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Stats
            _buildStatsCards(flaggedChallenges.length),
            const SizedBox(height: 24),

            // Flagged Challenges
            Text(
              'Flagged Challenges (${flaggedChallenges.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (flaggedChallenges.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No flagged challenges'),
                ),
              )
            else
              ...flaggedChallenges.map((doc) {
                final challenge = ChallengeModel.fromFirestore(doc);
                return _FlaggedChallengeCard(challenge: challenge);
              }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildStatsCards(int flaggedCount) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Flagged',
            value: flaggedCount.toString(),
            icon: Icons.flag,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Reviewed',
            value: '0',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Pending',
            value: flaggedCount.toString(),
            icon: Icons.pending,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _FlaggedChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;

  const _FlaggedChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Challenge #${challenge.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    challenge.flagReason ?? 'Flagged',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  label: 'Creator Score',
                  value: '${(challenge.creatorAntiCheatScore * 100).toInt()}%',
                  color: _getScoreColor(challenge.creatorAntiCheatScore),
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  label: 'Opponent Score',
                  value: '${(challenge.opponentAntiCheatScore * 100).toInt()}%',
                  color: _getScoreColor(challenge.opponentAntiCheatScore),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _approveChallenge(context, challenge),
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _viewDetails(context, challenge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RivlColors.primary,
                  ),
                  child: const Text('Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _approveChallenge(BuildContext context, ChallengeModel challenge) async {
    await FirebaseFirestore.instance
        .collection('challenges')
        .doc(challenge.id)
        .update({'flagged': false, 'flagReason': null});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Challenge approved')),
    );
  }

  void _viewDetails(BuildContext context, ChallengeModel challenge) {
    // Navigate to detailed review screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeReviewScreen(challenge: challenge),
      ),
    );
  }
}

// ============================================
// USER MANAGEMENT TAB
// ============================================

class UserManagementTab extends StatelessWidget {
  const UserManagementTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Total Users: ${users.length}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...users.map((doc) {
              final user = UserModel.fromFirestore(doc);
              return _UserCard(user: user);
            }).toList(),
          ],
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? Text(user.displayName[0].toUpperCase())
              : null,
        ),
        title: Text(user.displayName),
        subtitle: Text(
          '${user.wins}W-${user.losses}L • \$${user.totalEarnings.toStringAsFixed(2)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showUserActions(context, user),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserActions(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Suspend Account'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Send Message'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CHALLENGE MONITORING TAB
// ============================================

class ChallengeMonitoringTab extends StatelessWidget {
  const ChallengeMonitoringTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('challenges')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final challenges = snapshot.data?.docs ?? [];
        final active = challenges.where((d) => d.get('status') == 'active').length;
        final completed = challenges.where((d) => d.get('status') == 'completed').length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Active',
                    value: active.toString(),
                    icon: Icons.play_arrow,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Completed',
                    value: completed.toString(),
                    icon: Icons.check,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Challenges',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...challenges.map((doc) {
              final challenge = ChallengeModel.fromFirestore(doc);
              return _ChallengeCard(challenge: challenge);
            }).toList(),
          ],
        );
      },
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: challenge.statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            challenge.goalType.icon,
            size: 24,
            color: challenge.statusColor,
          ),
        ),
        title: Text('${challenge.creatorName} vs ${challenge.opponentName ?? "Pending"}'),
        subtitle: Text(
          '\$${challenge.stakeAmount.toInt()} • ${challenge.statusDisplayName}',
        ),
        trailing: Text(
          challenge.timeRemaining,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ============================================
// ANALYTICS TAB
// ============================================

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Platform Analytics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildAnalyticsCard('Total Revenue', '\$12,450', Icons.attach_money, Colors.green),
        _buildAnalyticsCard('Active Users', '1,234', Icons.people, Colors.blue),
        _buildAnalyticsCard('Avg Challenge Value', '\$35', Icons.trending_up, Colors.orange),
        _buildAnalyticsCard('Platform Fee Collected', '\$1,867', Icons.account_balance, Colors.purple),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
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

// ============================================
// HELPER WIDGETS
// ============================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
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
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CHALLENGE REVIEW SCREEN
// ============================================

class ChallengeReviewScreen extends StatelessWidget {
  final ChallengeModel challenge;

  const ChallengeReviewScreen({Key? key, required this.challenge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Review'),
        backgroundColor: RivlColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Challenge Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _DetailRow('Challenge ID', challenge.id),
                  _DetailRow('Type', challenge.goalType.displayName),
                  _DetailRow('Stake', '\$${challenge.stakeAmount}'),
                  _DetailRow('Status', challenge.statusDisplayName),
                  _DetailRow('Creator Score', '${(challenge.creatorAntiCheatScore * 100).toInt()}%'),
                  _DetailRow('Opponent Score', '${(challenge.opponentAntiCheatScore * 100).toInt()}%'),
                  if (challenge.flagReason != null)
                    _DetailRow('Flag Reason', challenge.flagReason!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _resolveDispute(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Approve Challenge'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _resolveDispute(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Cancel Challenge'),
          ),
        ],
      ),
    );
  }

  void _resolveDispute(BuildContext context, bool approve) async {
    await FirebaseFirestore.instance
        .collection('challenges')
        .doc(challenge.id)
        .update({
      'status': approve ? 'active' : 'cancelled',
      'flagged': false,
      'flagReason': null,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? 'Challenge approved' : 'Challenge cancelled'),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
