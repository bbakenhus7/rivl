// screens/feed/activity_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_feed_provider.dart';
import '../../models/activity_feed_model.dart';
import '../../utils/theme.dart';
import '../challenges/challenge_detail_screen.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityFeedProvider>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
      ),
      body: Consumer<ActivityFeedProvider>(
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
      ),
    );
  }
}

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
            // Avatar with activity icon
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
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(item.icon, size: 14, color: item.color),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
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

                  // Amount badge
                  if (item.amount != null && item.amount! > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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

            // Challenge arrow
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
