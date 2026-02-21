// screens/profile/friends_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../utils/haptics.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../../widgets/cached_avatar.dart';
import '../../widgets/skeleton_loader.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  final Set<String> _sentRequests = {};
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) Haptics.selection();
      });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    final currentUserId = context.read<AuthProvider>().user?.id;
    setState(() => _isSearching = true);
    try {
      _searchResults = await FirebaseService().searchUsers(query);
      _searchResults.removeWhere((u) => u.id == currentUserId);
    } catch (e) {
      _searchResults = [];
    }
    if (mounted) setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Consumer<FriendProvider>(
              builder: (context, fp, _) => Tab(
                text: 'Friends (${fp.friends.length})',
              ),
            ),
            Consumer<FriendProvider>(
              builder: (context, fp, _) {
                final count = fp.pendingRequests.length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: RivlColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(text: 'Add'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildRequestsList(),
          _buildAddFriends(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, _) {
        if (friendProvider.friends.isEmpty) {
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
                  child: Icon(Icons.people_outline, size: 40, color: context.textSecondary),
                ),
                const SizedBox(height: 20),
                Text(
                  'No friends yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add friends to challenge them with no fees!',
                  style: TextStyle(color: context.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(2),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Find Friends'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final userId = context.read<AuthProvider>().user?.id;
            if (userId != null) {
              friendProvider.startListening(userId);
            }
            // Brief delay so the spinner is visible
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: friendProvider.friends.length,
            itemBuilder: (context, index) {
              final friend = friendProvider.friends[index];
              final displayName = friend['displayName'] as String? ?? 'Unknown';
              return SlideIn(
                delay: Duration(milliseconds: 30 * index.clamp(0, 10)),
                child: ListTile(
                  leading: CachedAvatar(
                    imageUrl: friend['profileImageUrl'] as String?,
                    displayName: displayName,
                    radius: 22,
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('@${friend['username'] ?? ''}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'remove') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove Friend'),
                            content: Text(
                                'Remove $displayName from your friends?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Remove',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await friendProvider
                              .removeFriend(friend['userId'] as String? ?? '');
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Remove Friend',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, _) {
        if (friendProvider.pendingRequests.isEmpty) {
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
                  child: Icon(Icons.mail_outline, size: 40, color: context.textSecondary),
                ),
                const SizedBox(height: 20),
                Text(
                  'No pending requests',
                  style: TextStyle(
                    fontSize: 18,
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: friendProvider.pendingRequests.length,
          itemBuilder: (context, index) {
            final request = friendProvider.pendingRequests[index];
            return SlideIn(
              delay: Duration(milliseconds: 30 * index.clamp(0, 10)),
              child: ListTile(
              leading: CachedAvatar(
                imageUrl: request['senderProfileImageUrl'] as String?,
                displayName: request['senderName'] as String? ?? '?',
                radius: 22,
              ),
              title: Text(
                request['senderName'] as String? ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('@${request['senderUsername'] ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Decline Request'),
                          content: Text(
                              'Decline friend request from ${request['senderName'] ?? 'this user'}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Decline',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await friendProvider
                          .declineFriendRequest(request['id'] as String? ?? '');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Request from ${request['senderName'] ?? 'user'} declined'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () async {
                      await friendProvider
                          .acceptFriendRequest(request['id'] as String? ?? '');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${request['senderName']} is now your friend!'),
                            backgroundColor: RivlColors.success,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddFriends() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by username...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (_isSearching)
          Expanded(
            child: ShimmerEffect(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const SkeletonCircle(size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(height: 14, width: 120),
                            const SizedBox(height: 6),
                            SkeletonBox(height: 12, width: 80),
                          ],
                        ),
                      ),
                      SkeletonBox(height: 32, width: 60, borderRadius: 16),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.length < 2
                          ? 'Type at least 2 characters to search'
                          : 'No users found',
                      style: TextStyle(color: context.textSecondary),
                    ),
                  )
                : Consumer<FriendProvider>(
                    builder: (context, friendProvider, _) {
                      return ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final isFriend = friendProvider.isFriend(user.id);
                          final requestSent = _sentRequests.contains(user.id);

                          return ListTile(
                            leading: CachedAvatar(
                              imageUrl: user.profileImageUrl,
                              displayName: user.displayName,
                              radius: 22,
                            ),
                            title: Text(
                              user.displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('@${user.username}'),
                            trailing: isFriend
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          RivlColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Friends',
                                      style: TextStyle(
                                        color: RivlColors.success,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : requestSent
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Sent',
                                          style: TextStyle(
                                            color: context.textSecondary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton.icon(
                                        onPressed: () async {
                                          final success =
                                              await friendProvider
                                                  .sendFriendRequest(
                                            receiverId: user.id,
                                            receiverName: user.displayName,
                                            receiverUsername: user.username,
                                          );
                                          if (success && mounted) {
                                            setState(() {
                                              _sentRequests.add(user.id);
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Friend request sent to ${user.displayName}'),
                                                backgroundColor:
                                                    RivlColors.success,
                                              ),
                                            );
                                          } else if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    friendProvider
                                                            .errorMessage ??
                                                        'Failed to send request'),
                                                backgroundColor:
                                                    RivlColors.error,
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.person_add,
                                            size: 16),
                                        label: const Text('Add'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                      ),
                          );
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
