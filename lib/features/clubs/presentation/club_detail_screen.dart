import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';

import 'package:turf/features/clubs/domain/models/club.dart';
import 'package:turf/features/clubs/presentation/providers/club_provider.dart';

class ClubDetailScreen extends ConsumerStatefulWidget {
  final Club club;
  
  const ClubDetailScreen({super.key, required this.club});

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen> with SingleTickerProviderStateMixin {
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

  void _handleLeaveOrJoin() async {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isOwner = widget.club.createdBy == currentUserId;
    
    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owners cannot leave. Transfer ownership or delete club.')));
      return;
    }
    
    try {
      // Need to check if member first
      final membersList = await ref.read(clubMembersProvider(widget.club.id).future);
      final isMember = membersList.any((m) => m.userId == currentUserId);
      
      if (isMember) {
        await ref.read(clubRepositoryProvider).leaveClub(widget.club.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left club')));
          context.pop();
        }
      } else {
        await ref.read(clubRepositoryProvider).joinClub(widget.club.id, widget.club.isPublic);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined club')));
      }
      ref.invalidate(myClubsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isOwner = widget.club.createdBy == currentUserId;
    final membersAsync = ref.watch(clubMembersProvider(widget.club.id));
    final activitiesAsync = ref.watch(clubActivitiesProvider(widget.club.id));
    final requestsAsync = ref.watch(clubRequestsProvider(widget.club.id));

    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: const Color(0xFF141414),
              actions: [
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1C1C1E),
                          title: const Text('Invite Code', style: TextStyle(color: Colors.white)),
                          content: Text(widget.club.inviteCode, style: const TextStyle(color: Color(0xFF00E676), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: widget.club.inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                                Navigator.pop(context);
                              },
                              child: const Text('Copy', style: TextStyle(color: Color(0xFF00E676))),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (isOwner)
                  IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover Image or Gradient
                    if (widget.club.coverUrl != null)
                      CachedNetworkImage(imageUrl: widget.club.coverUrl!, fit: BoxFit.cover)
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [const Color(0xFF00E676).withOpacity(0.3), Colors.black],
                          ),
                        ),
                      ),
                    // Dark overlay
                    Container(color: Colors.black.withOpacity(0.4)),
                    
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: const Color(0xFF1C1C1E),
                                backgroundImage: widget.club.avatarUrl != null ? CachedNetworkImageProvider(widget.club.avatarUrl!) : null,
                                child: widget.club.avatarUrl == null ? Text(widget.club.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)) : null,
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: _handleLeaveOrJoin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isOwner ? Colors.transparent : const Color(0xFF00E676),
                                  foregroundColor: isOwner ? Colors.white : Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: isOwner ? const BorderSide(color: Colors.white) : BorderSide.none),
                                ),
                                child: Text(isOwner ? 'Owner' : 'Join / Leave', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(widget.club.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          if (widget.club.description != null && widget.club.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(widget.club.description!, style: const TextStyle(color: Colors.white54, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.people, color: Colors.white54, size: 16),
                              const SizedBox(width: 4),
                              Text('${widget.club.memberCount} Members', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                              const SizedBox(width: 16),
                              const Icon(Icons.directions_run, color: Colors.white54, size: 16),
                              const SizedBox(width: 4),
                              Text('${widget.club.totalDistanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF00E676),
                  labelColor: const Color(0xFF00E676),
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: 'Members'),
                    Tab(text: 'Leaderboard'),
                    Tab(text: 'Activities'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // MEMBERS TAB
            membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
              error: (e, _) => const Center(child: Text('Error', style: TextStyle(color: Colors.red))),
              data: (members) {
                return CustomScrollView(
                  slivers: [
                    if (isOwner && !widget.club.isPublic)
                      SliverToBoxAdapter(
                        child: requestsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (reqs) {
                            if (reqs.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Pending Requests', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                                ),
                                ...reqs.map((r) => ListTile(
                                  leading: CircleAvatar(backgroundImage: r.profile?.avatarUrl != null ? CachedNetworkImageProvider(r.profile!.avatarUrl!) : null),
                                  title: Text(r.profile?.fullName ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () async {
                                          await ref.read(clubRepositoryProvider).acceptJoinRequest(r.id, widget.club.id, r.userId, false);
                                          ref.invalidate(clubRequestsProvider);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Color(0xFF00E676)),
                                        onPressed: () async {
                                          await ref.read(clubRepositoryProvider).acceptJoinRequest(r.id, widget.club.id, r.userId, true);
                                          ref.invalidate(clubRequestsProvider);
                                        },
                                      ),
                                    ],
                                  ),
                                )),
                                const Divider(color: Colors.white24),
                              ],
                            );
                          },
                        ),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final m = members[index];
                          final p = m.profile;
                          if (p == null) return const SizedBox.shrink();
                          
                          Color roleColor = Colors.white54;
                          if (m.role == 'owner') roleColor = const Color(0xFFFFD60A);
                          if (m.role == 'admin') roleColor = const Color(0xFF0A84FF);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1C1C1E),
                              backgroundImage: p.avatarUrl != null ? CachedNetworkImageProvider(p.avatarUrl!) : null,
                            ),
                            title: Text(p.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('LVL ${p.level}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(m.role.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            onLongPress: isOwner && m.userId != currentUserId ? () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1C1C1E),
                                  title: const Text('Manage Member', style: TextStyle(color: Colors.white)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: Text(m.role == 'admin' ? 'Remove Admin' : 'Make Admin', style: const TextStyle(color: Colors.white)),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await ref.read(clubRepositoryProvider).updateMemberRole(widget.club.id, m.userId, m.role == 'admin' ? 'member' : 'admin');
                                        },
                                      ),
                                      ListTile(
                                        title: const Text('Remove Member', style: TextStyle(color: Colors.red)),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await ref.read(clubRepositoryProvider).removeMember(widget.club.id, m.userId);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } : null,
                            onTap: () => context.push('/profile/${p.id}', extra: p),
                          );
                        },
                        childCount: members.length,
                      ),
                    ),
                  ],
                );
              },
            ),

            // LEADERBOARD TAB
            membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
              error: (e, _) => const Center(child: Text('Error', style: TextStyle(color: Colors.red))),
              data: (members) {
                final sortedMembers = List.of(members)..sort((a, b) => b.weeklyDistanceKm.compareTo(a.weeklyDistanceKm));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedMembers.length,
                  itemBuilder: (context, index) {
                    final m = sortedMembers[index];
                    final p = m.profile;
                    if (p == null) return const SizedBox.shrink();
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: p.avatarUrl != null ? CachedNetworkImageProvider(p.avatarUrl!) : null),
                      title: Text(p.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      trailing: Text('${m.weeklyDistanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk', fontSize: 18)),
                    );
                  },
                );
              },
            ),

            // ACTIVITIES TAB
            activitiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
              error: (e, _) => const Center(child: Text('Error', style: TextStyle(color: Colors.red))),
              data: (activities) {
                if (activities.isEmpty) {
                  return const Center(child: Text('No activities yet.', style: TextStyle(color: Colors.white54)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final a = activities[index];
                    final p = a.profile;
                    final s = a.session;
                    if (p == null || s == null) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: p.avatarUrl != null ? CachedNetworkImageProvider(p.avatarUrl!) : null,
                              ),
                              const SizedBox(width: 8),
                              Text(p.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(timeago.format(a.postedAt), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('${s.distanceKm.toStringAsFixed(2)} km', style: const TextStyle(color: Color(0xFF00E676), fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                          Text(s.activityType.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
