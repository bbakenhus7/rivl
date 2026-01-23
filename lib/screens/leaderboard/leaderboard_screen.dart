// screens/leaderboard/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../utils/theme.dart';
import '../../models/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Time'),
            Tab(text: 'This Month'),
            Tab(text: 'This Week'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LeaderboardTab(period: LeaderboardPeriod.allTime),
          _LeaderboardTab(period: LeaderboardPeriod.monthly),
          _LeaderboardTab(period: LeaderboardPeriod.weekly),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final LeaderboardPeriod period;

  const _LeaderboardTab({required this.period});

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = provider.getLeaderboard(period);

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No leaderboard data yet',
                  style: RivlTextStyles.heading3,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _LeaderboardCard(entry: entry);
          },
        );
      },
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final LeaderboardEntryModel entry;

  const _LeaderboardCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isTopThree = entry.rank <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTopThree ? 4 : 1,
      color: isTopThree
          ? (entry.rank == 1
              ? Colors.amber.withOpacity(0.1)
              : entry.rank == 2
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 50,
              child: Text(
                entry.rankDisplay,
                style: TextStyle(
                  fontSize: isTopThree ? 28 : 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 16),

            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: RivlColors.primary.withOpacity(0.2),
              child: Text(
                entry.displayName[0],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: RivlColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@\${entry.username}',
                    style: RivlTextStyles.caption,
                  ),
                ],
              ),
            ),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '\${entry.wins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '\${entry.winRate.toStringAsFixed(1)}% WR',
                  style: RivlTextStyles.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$\${entry.earnings.toInt()}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
