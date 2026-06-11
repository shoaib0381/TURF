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
    _tabController = TabController(length: 4, vsync: this);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white54),
            onPressed: () => context.push('/friends/search'), // Assuming route setup
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Discover'),
            Tab(text: 'Clubs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendsListTab(),
          _RequestsTab(),
          _DiscoverTab(),
          _ClubsTab(),
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
            subtitle: 'Find your tribe in the Discover tab.',
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
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1C1C1E),
                      title: const Text('Unfriend?', style: TextStyle(color: Colors.white)),
                      content: Text('Remove ${friendProfile.username} from your friends list?', style: const TextStyle(color: Colors.white54)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref.read(socialRepositoryProvider).deleteFriendship(friendProfile.id);
                            ref.invalidate(friendsProvider);
                          },
                          child: const Text('Unfriend', style: TextStyle(color: Color(0xFFFF453A))),
                        ),
                      ],
                    ),
                  );
                },
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
    final incomingAsync = ref.watch(pendingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);

    return RefreshIndicator(
      color: const Color(0xFF00E676),
      backgroundColor: const Color(0xFF1C1C1E),
      onRefresh: () async {
        ref.invalidate(pendingRequestsProvider);
        ref.invalidate(outgoingRequestsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Incoming Requests', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          incomingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
            error: (e, _) => const Text('Error loading', style: TextStyle(color: Colors.red)),
            data: (requests) {
              if (requests.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No incoming requests.', style: TextStyle(color: Colors.white54))),
                );
              }
              return Column(
                children: requests.map((request) {
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
                  );
                }).toList(),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          const Text('Outgoing Requests', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          outgoingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
            error: (e, _) => const Text('Error loading', style: TextStyle(color: Colors.red)),
            data: (requests) {
              if (requests.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No outgoing requests.', style: TextStyle(color: Colors.white54))),
                );
              }
              return Column(
                children: requests.map((request) {
                  final targetProfile = request.profile2;
                  if (targetProfile == null) return const SizedBox.shrink();

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF1C1C1E),
                      backgroundImage: targetProfile.avatarUrl != null ? CachedNetworkImageProvider(targetProfile.avatarUrl!) : null,
                      child: targetProfile.avatarUrl == null ? const Icon(Icons.person, color: Colors.white54) : null,
                    ),
                    title: Text(targetProfile.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: TextButton(
                      onPressed: () async {
                        // Cancel request means deleting it
                        await ref.read(socialRepositoryProvider).respondToRequest(request.id, false);
                        ref.invalidate(outgoingRequestsProvider);
                      },
                      child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DiscoverTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverAsync = ref.watch(discoverUsersProvider);

    return discoverAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      error: (e, _) => const Center(child: Text('Error loading discover list', style: TextStyle(color: Colors.red))),
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('No users to discover right now.', style: TextStyle(color: Colors.white54)));
        }

        return RefreshIndicator(
          color: const Color(0xFF00E676),
          backgroundColor: const Color(0xFF1C1C1E),
          onRefresh: () => ref.refresh(discoverUsersProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1C1C1E),
                  backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? const Icon(Icons.person, color: Colors.white54) : null,
                ),
                title: Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('LVL ${user.level} • ${user.totalDistanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(socialRepositoryProvider).sendRequestSimple(user.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!'), backgroundColor: Color(0xFF00E676)));
                      ref.invalidate(discoverUsersProvider);
                      ref.invalidate(outgoingRequestsProvider);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send request'), backgroundColor: Color(0xFFFF453A)));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
                    foregroundColor: const Color(0xFF00E676),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Add Friend'),
                ),
                onTap: () => context.push('/profile/${user.id}', extra: user),
              );
            },
          ),
        );
      },
    );
  }
}

class _ClubsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.shield_outlined, size: 64, color: Color(0xFF00E676)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Join the Club',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Run together. Capture together. Dominate the leaderboards as a team.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.push('/clubs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Explore Clubs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
