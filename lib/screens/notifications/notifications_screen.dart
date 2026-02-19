// screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/haptics.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
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
                  Haptics.light();
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: context.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_none_rounded, size: 40, color: context.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Challenge updates and rewards will appear here',
                    style: TextStyle(color: context.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Group notifications by date
          final grouped = _groupByDate(provider.notifications);
          final sections = grouped.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.xl),
            itemCount: _countItems(sections) + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Figure out which section + item this index maps to
              int remaining = index;
              for (final section in sections) {
                // Section header
                if (remaining == 0) {
                  return _DateHeader(label: section.key);
                }
                remaining--;
                // Items in section
                if (remaining < section.value.length) {
                  final notification = section.value[remaining];
                  return _NotificationTile(notification: notification, provider: provider);
                }
                remaining -= section.value.length;
              }
              // "Load more" button
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
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
            },
          );
        },
      ),
    );
  }

  int _countItems(List<MapEntry<String, List<Map<String, dynamic>>>> sections) {
    int count = 0;
    for (final section in sections) {
      count++; // header
      count += section.value.length;
    }
    return count;
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(List<Map<String, dynamic>> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));

    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final n in notifications) {
      final createdAt = (n['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) {
        groups.putIfAbsent('Earlier', () => []).add(n);
        continue;
      }

      final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final String label;
      if (date == today || date.isAfter(today)) {
        label = 'Today';
      } else if (date == yesterday || (date.isAfter(yesterday) && date.isBefore(today))) {
        label = 'Yesterday';
      } else if (date.isAfter(thisWeek)) {
        label = 'This Week';
      } else {
        label = 'Earlier';
      }
      groups.putIfAbsent(label, () => []).add(n);
    }

    return groups;
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.pagePadding, Spacing.md, Spacing.pagePadding, Spacing.xs),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final NotificationProvider provider;

  const _NotificationTile({required this.notification, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isRead = notification['read'] == true;
    final type = notification['type'] as String? ?? 'general';
    final createdAt = (notification['createdAt'] as Timestamp?)?.toDate();
    final color = provider.getNotificationColor(type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isRead ? null : RivlColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Icon(
            provider.getNotificationIcon(type),
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          notification['title'] ?? '',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              notification['body'] ?? '',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _timeAgo(createdAt),
                  style: TextStyle(color: context.textSecondary.withValues(alpha: 0.6), fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: isRead
            ? Icon(Icons.chevron_right_rounded, size: 20, color: context.textSecondary.withValues(alpha: 0.4))
            : Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: RivlColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          Haptics.light();
          if (!isRead) {
            provider.markAsRead(notification['id']);
          }
          final data = notification['data'] as Map<String, dynamic>?;
          final challengeId = data?['challengeId'] as String?;
          if (challengeId != null && challengeId.isNotEmpty) {
            Navigator.push(
              context,
              SlidePageRoute(
                page: ChallengeDetailScreen(challengeId: challengeId),
              ),
            );
          }
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
