// screens/leaderboard/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../../widgets/skeleton_loader.dart';
import '../main_screen.dart';

enum LeaderboardFilter { global, friends, weekly, monthly }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardFilter _currentFilter = LeaderboardFilter.global;
  bool _isLoading = true;
  List<LeaderboardEntry> _entries = [];
  int _userRank = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _currentFilter = LeaderboardFilter.values[_tabController.index];
    });
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    // Simulate API call - in production, fetch from Firebase
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate mock data
    final mockEntries = List.generate(50, (index) {
      return LeaderboardEntry(
        rank: index + 1,
        odId: 'user_$index',
        displayName: _getRandomName(index),
        username: 'user${index + 1}',
        profileImageUrl: null,
        wins: 50 - index + (index % 3),
        totalChallenges: 60 + (index % 10),
        winRate: (0.9 - (index * 0.015)).clamp(0.3, 0.95),
        totalEarnings: (5000 - (index * 80)).toDouble().clamp(100, 5000),
        isCurrentUser: index == 7, // Mock current user at rank 8
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
    final names = [
      'Alex Runner', 'Sam Stepper', 'Jordan Fit', 'Taylor Active',
      'Morgan Steps', 'Casey Cardio', 'Riley Pace', 'Avery Stride',
      'Quinn Walker', 'Blake Motion', 'Jamie Sprint', 'Drew Distance',
    ];
    return names[index % names.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _buildTabBar(),
              ),
            ),
          ];
        },
        body: _isLoading ? _buildLoadingState() : _buildLeaderboardList(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RivlColors.primary,
            RivlColors.primaryDark,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Leaderboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compete with the best',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          if (_userRank > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Your Rank: #$_userRank',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: RivlColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: RivlColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'Global'),
          Tab(text: 'Friends'),
          Tab(text: 'Weekly'),
          Tab(text: 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: LeaderboardItemSkeleton(),
        );
      },
    );
  }

  Widget _buildLeaderboardList() {
    if (_entries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: CustomScrollView(
        slivers: [
          // Top 3 podium
          SliverToBoxAdapter(
            child: _buildPodium(),
          ),

          // Remaining rankings
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = _entries[index + 3]; // Skip top 3
                  return SlideIn(
                    delay: Duration(milliseconds: 50 * (index % 10)),
                    child: _LeaderboardTile(
                      entry: entry,
                      onTap: () => _showUserProfile(entry),
                    ),
                  );
                },
                childCount: _entries.length > 3 ? _entries.length - 3 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    if (_entries.length < 3) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: _PodiumCard(
              entry: _entries[1],
              height: 100,
              color: const Color(0xFFC0C0C0), // Silver
              onTap: () => _showUserProfile(_entries[1]),
            ),
          ),
          const SizedBox(width: 8),
          // 1st place
          SlideIn(
            delay: const Duration(milliseconds: 100),
            child: _PodiumCard(
              entry: _entries[0],
              height: 130,
              color: const Color(0xFFFFD700), // Gold
              isFirst: true,
              onTap: () => _showUserProfile(_entries[0]),
            ),
          ),
          const SizedBox(width: 8),
          // 3rd place
          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: _PodiumCard(
              entry: _entries[2],
              height: 80,
              color: const Color(0xFFCD7F32), // Bronze
              onTap: () => _showUserProfile(_entries[2]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No rankings yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete challenges to appear on the leaderboard',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showUserProfile(LeaderboardEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserProfileSheet(entry: entry),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color color;
  final bool isFirst;
  final VoidCallback onTap;

  const _PodiumCard({
    required this.entry,
    required this.height,
    required this.color,
    this.isFirst = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown for first place
          if (isFirst)
            const Icon(
              Icons.workspace_premium,
              color: Color(0xFFFFD700),
              size: 32,
            ),

          // Avatar
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CircleAvatar(
                radius: isFirst ? 40 : 32,
                backgroundColor: color.withOpacity(0.3),
                backgroundImage: entry.profileImageUrl != null
                    ? NetworkImage(entry.profileImageUrl!)
                    : null,
                child: entry.profileImageUrl == null
                    ? Text(
                        (entry.displayName.isNotEmpty ? entry.displayName[0] : '?').toUpperCase(),
                        style: TextStyle(
                          fontSize: isFirst ? 28 : 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${entry.rank}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name
          SizedBox(
            width: 80,
            child: Text(
              entry.displayName.split(' ').first,
              style: TextStyle(
                fontSize: isFirst ? 14 : 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),

          // Wins
          Text(
            '${entry.wins} wins',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),

          // Podium block
          Container(
            width: isFirst ? 90 : 75,
            height: height,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${(entry.winRate * 100).toInt()}%',
                style: TextStyle(
                  fontSize: isFirst ? 18 : 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final VoidCallback onTap;

  const _LeaderboardTile({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = entry.isCurrentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrentUser
          ? RivlColors.primary.withOpacity(0.1)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentUser
            ? const BorderSide(color: RivlColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 36,
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? RivlColors.primary : Colors.grey[600],
                  ),
                ),
              ),

              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: RivlColors.primary.withOpacity(0.1),
                backgroundImage: entry.profileImageUrl != null
                    ? NetworkImage(entry.profileImageUrl!)
                    : null,
                child: entry.profileImageUrl == null
                    ? Text(
                        (entry.displayName.isNotEmpty ? entry.displayName[0] : '?').toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: RivlColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name and username
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
                              color: isCurrentUser ? RivlColors.primary : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: RivlColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${entry.username}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.wins} wins',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(entry.winRate * 100).toInt()}% rate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserProfileSheet extends StatelessWidget {
  final LeaderboardEntry entry;

  const _UserProfileSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Profile content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar and rank badge
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: RivlColors.primary.withOpacity(0.1),
                      backgroundImage: entry.profileImageUrl != null
                          ? NetworkImage(entry.profileImageUrl!)
                          : null,
                      child: entry.profileImageUrl == null
                          ? Text(
                              (entry.displayName.isNotEmpty ? entry.displayName[0] : '?').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: RivlColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRankColor(entry.rank),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${entry.rank}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  entry.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${entry.username}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatColumn(
                      label: 'Wins',
                      value: '${entry.wins}',
                    ),
                    _StatColumn(
                      label: 'Challenges',
                      value: '${entry.totalChallenges}',
                    ),
                    _StatColumn(
                      label: 'Win Rate',
                      value: '${(entry.winRate * 100).toInt()}%',
                    ),
                    _StatColumn(
                      label: 'Earnings',
                      value: '\$${entry.totalEarnings.toInt()}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Challenge button
                if (!entry.isCurrentUser)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        MainScreen.onTabSelected?.call(2);
                      },
                      child: const Text('Challenge'),
                    ),
                  ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return RivlColors.primary;
    }
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String odId;
  final String displayName;
  final String username;
  final String? profileImageUrl;
  final int wins;
  final int totalChallenges;
  final double winRate;
  final double totalEarnings;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.odId,
    required this.displayName,
    required this.username,
    this.profileImageUrl,
    required this.wins,
    required this.totalChallenges,
    required this.winRate,
    required this.totalEarnings,
    this.isCurrentUser = false,
  });
}
