import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:turf/core/widgets/empty_state.dart';
import 'package:turf/features/profile/domain/models/profile.dart';
import 'package:turf/features/friends/presentation/providers/friends_provider.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Social', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Find People'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendsListTab(),
          _RequestsTab(),
          _FindPeopleTab(),
        ],
      ),
    );
  }
}

class _FriendsListTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      error: (e, _) => Center(child: Text('Error loading friends', style: const TextStyle(color: Colors.red))),
      data: (friendships) {
        if (friendships.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            title: 'No friends yet',
            subtitle: 'Find your tribe in the Find People tab.',
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF00E676),
          backgroundColor: const Color(0xFF1C1C1E),
          onRefresh: () => ref.refresh(friendsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: friendships.length,
            itemBuilder: (context, index) {
              final friendship = friendships[index];
              // Determine which profile is the friend (not the current user)
              final isUser1 = friendship.userId1 == currentUserId;
              final friendProfile = isUser1 ? friendship.profile2 : friendship.profile1;

              if (friendProfile == null) return const SizedBox.shrink();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1C1C1E),
                  backgroundImage: friendProfile.avatarUrl != null ? CachedNetworkImageProvider(friendProfile.avatarUrl!) : null,
                  child: friendProfile.avatarUrl == null ? const Icon(Icons.person, color: Colors.white54) : null,
                ),
                title: Text(friendProfile.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  friendProfile.lastActive != null ? 'Active ${timeago.format(friendProfile.lastActive!)}' : 'Offline',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Lvl ${friendProfile.level}', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                onTap: () => context.push('/profile/${friendProfile.id}', extra: friendProfile),
              );
            },
          ),
        );
      },
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      error: (e, _) => Center(child: Text('Error loading requests', style: const TextStyle(color: Colors.red))),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyState(
            icon: Icons.mail_outline,
            title: 'No pending requests',
            subtitle: 'You are all caught up!',
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF00E676),
          backgroundColor: const Color(0xFF1C1C1E),
          onRefresh: () => ref.refresh(pendingRequestsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              // Sender is user_id_1
              final senderProfile = request.profile1;

              if (senderProfile == null) return const SizedBox.shrink();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1C1C1E),
                  backgroundImage: senderProfile.avatarUrl != null ? CachedNetworkImageProvider(senderProfile.avatarUrl!) : null,
                  child: senderProfile.avatarUrl == null ? const Icon(Icons.person, color: Colors.white54) : null,
                ),
                title: Text(senderProfile.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Sent you a friend request', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFFFF453A)),
                      onPressed: () async {
                        await ref.read(socialRepositoryProvider).respondToRequest(request.id, false);
                        ref.invalidate(pendingRequestsProvider);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Color(0xFF00E676)),
                      onPressed: () async {
                        await ref.read(socialRepositoryProvider).respondToRequest(request.id, true);
                        ref.invalidate(pendingRequestsProvider);
                        ref.invalidate(friendsProvider);
                      },
                    ),
                  ],
                ),
                onTap: () => context.push('/profile/${senderProfile.id}', extra: senderProfile),
              );
            },
          ),
        );
      },
    );
  }
}

class _FindPeopleTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FindPeopleTab> createState() => _FindPeopleTabState();
}

class _FindPeopleTabState extends ConsumerState<_FindPeopleTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Profile> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      try {
        final results = await ref.read(socialRepositoryProvider).searchUsers(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search by username...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_isSearching)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676))),
              ],
            ),
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? const Center(child: Text('Search for users to add them.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF1C1C1E),
                        backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                        child: user.avatarUrl == null ? const Icon(Icons.person, color: Colors.white54) : null,
                      ),
                      title: Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('@${user.username}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            await ref.read(socialRepositoryProvider).sendRequestSimple(user.id);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!'), backgroundColor: Color(0xFF00E676)));
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send request'), backgroundColor: Color(0xFFFF453A)));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
                          foregroundColor: const Color(0xFF00E676),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Add'),
                      ),
                      onTap: () => context.push('/profile/${user.id}', extra: user),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
