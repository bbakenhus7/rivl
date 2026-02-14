// screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../challenges/challenge_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (!provider.hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  final userId = context.read<AuthProvider>().user?.id;
                  if (userId != null) {
                    provider.markAllAsRead(userId);
                  }
                },
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see challenge updates and rewards here',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // "Load more" button at the end
              if (index >= provider.notifications.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: provider.isLoadingMore
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: () => provider.loadMore(),
                            child: const Text('Load more'),
                          ),
                  ),
                );
              }

              final notification = provider.notifications[index];
              final isRead = notification['read'] == true;
              final type = notification['type'] as String? ?? 'general';
              final createdAt = (notification['createdAt'] as Timestamp?)?.toDate();

              return Container(
                color: isRead ? null : RivlColors.primary.withOpacity(0.05),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: provider.getNotificationColor(type).withOpacity(0.15),
                    child: Icon(
                      provider.getNotificationIcon(type),
                      color: provider.getNotificationColor(type),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    notification['title'] ?? '',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['body'] ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _timeAgo(createdAt),
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  trailing: isRead
                      ? null
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: RivlColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () {
                    if (!isRead) {
                      provider.markAsRead(notification['id']);
                    }
                    // Navigate based on notification type/data
                    final data = notification['data'] as Map<String, dynamic>?;
                    final challengeId = data?['challengeId'] as String?;
                    if (challengeId != null && challengeId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChallengeDetailScreen(challengeId: challengeId),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
