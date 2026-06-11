import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:turf/core/widgets/empty_state.dart';
import 'package:turf/core/widgets/animated_number.dart';
import 'package:turf/features/profile/presentation/providers/badge_provider.dart';
import 'package:turf/features/profile/presentation/providers/profile_provider.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
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

  (int, int) _getLevelThresholds(int currentXp) {
    List<int> thresholds = [0, 500, 1200, 2500, 5000, 10000, 20000, 40000, 80000, 160000];
    int currentLevelThreshold = 0;
    int nextLevelThreshold = 500;
    for (int i = 0; i < thresholds.length - 1; i++) {
      if (currentXp >= thresholds[i] && currentXp < thresholds[i+1]) {
        currentLevelThreshold = thresholds[i];
        nextLevelThreshold = thresholds[i+1];
        break;
      }
    }
    // Fallback if super high level
    if (currentXp >= thresholds.last) {
       currentLevelThreshold = thresholds.last;
       nextLevelThreshold = thresholds.last * 2;
    }
    return (currentLevelThreshold, nextLevelThreshold);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
        error: (e, _) => Center(child: Text('Error loading profile: $e', style: const TextStyle(color: Colors.red))),
        data: (profile) {
          if (profile == null) return const Center(child: Text('No profile found.'));

          final thresholds = _getLevelThresholds(profile.totalXp);
          final minXp = thresholds.$1;
          final maxXp = thresholds.$2;
          final progress = (profile.totalXp - minXp) / (maxXp - minXp);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  backgroundColor: Colors.black,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Gradient
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF00E676), Colors.black],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, 0.4],
                            ),
                          ),
                        ),
                        // Profile Info
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.black,
                              child: CircleAvatar(
                                radius: 37,
                                backgroundColor: const Color(0xFF1C1C1E),
                                backgroundImage: profile.avatarUrl != null ? CachedNetworkImageProvider(profile.avatarUrl!) : null,
                                child: profile.avatarUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white54) : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profile.fullName,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(profile.bio!, style: const TextStyle(color: Colors.white70)),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'LVL ${profile.level}',
                                style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // XP Progress
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      AnimatedNumber(value: profile.totalXp, suffix: ' XP', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      Text('$maxXp XP', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                                      duration: const Duration(milliseconds: 1500),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, val, child) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: val,
                                            backgroundColor: const Color(0xFF1C1C1E),
                                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                                            minHeight: 6,
                                          ),
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${maxXp - profile.totalXp} XP to Level ${profile.level + 1}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Container(
                        color: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(label: 'Total km', value: profile.totalDistanceKm.toStringAsFixed(1)),
                            _StatItem(label: 'Total XP', value: profile.totalXp.toString()),
                            _StatItem(label: 'Streak', value: '${profile.streakDays}d'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/clubs'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C1E),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shield_outlined, color: Color(0xFF00E676), size: 20),
                                      SizedBox(width: 8),
                                      Text('My Clubs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/friends'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C1E),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outline, color: Color(0xFF00E676), size: 20),
                                      SizedBox(width: 8),
                                      Text('Friends', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF00E676),
                      labelColor: const Color(0xFF00E676),
                      unselectedLabelColor: Colors.white54,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: const [
                        Tab(text: 'Activities'),
                        Tab(text: 'Badges'),
                        Tab(text: 'Goals'),
                        Tab(text: 'Territories'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _ActivitiesTab(userId: profile.id),
                _BadgesTab(userId: profile.id),
                const _GoalsTab(), // We will use inline goals
                _TerritoriesTab(userId: profile.id),
              ],
            ),
          );
        },
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedNumber(
          value: double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
          suffix: value.contains('d') ? 'd' : null,
          fractionDigits: value.contains('.') ? 1 : 0,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _ActivitiesTab extends ConsumerWidget {
  final String userId;

  const _ActivitiesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, we will just show a placeholder or fetch using a simple query since ActivityFeedScreen handles global/friends feed
    // Ideally we would reuse the feed provider with a user filter. Let's just fetch directly for the profile tab.
    return FutureBuilder(
      future: Supabase.instance.client.from('activity_sessions').select().eq('user_id', userId).order('created_at', ascending: false).limit(20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        
        final sessions = snapshot.data as List?;
        if (sessions == null || sessions.isEmpty) return const EmptyState(icon: Icons.directions_run, title: 'No activities yet', subtitle: 'Start moving!');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Card(
              color: const Color(0xFF141414),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.directions_run, color: Color(0xFF00E676)),
                ),
                title: Text('${(session['distance_km'] as num).toStringAsFixed(2)} km ${session['activity_type'].toString().toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${(session['duration_seconds'] / 60).toStringAsFixed(0)} min', style: const TextStyle(color: Colors.white54)),
                trailing: Text('+${session['xp_earned']} XP', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                onTap: () => context.push('/activity/${session['id']}'),
              ),
            );
          },
        );
      },
    );
  }
}

class _BadgesTab extends ConsumerWidget {
  final String userId;

  const _BadgesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider(userId));

    return allBadgesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (allBadges) {
        return userBadgesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          data: (userBadges) {
            final earnedBadgeIds = userBadges.map((ub) => ub.badgeId).toSet();

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: allBadges.length,
              itemBuilder: (context, index) {
                final badge = allBadges[index];
                final isEarned = earnedBadgeIds.contains(badge.id);

                return GestureDetector(
                  onTap: () {
                    if (isEarned) {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF1C1C1E),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                        builder: (context) => _BadgeDetailSheet(badge: badge),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isEarned ? const Color(0xFF00E676).withOpacity(0.1) : const Color(0xFF141414),
                            border: Border.all(color: isEarned ? const Color(0xFF00E676) : Colors.white10, width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              _getBadgeIcon(badge.badgeType),
                              size: 32,
                              color: isEarned ? const Color(0xFF00E676) : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isEarned ? Colors.white : Colors.white54,
                          fontSize: 10,
                          fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _getBadgeIcon(String type) {
    switch (type) {
      case 'milestone': return Icons.emoji_events;
      case 'challenge': return Icons.military_tech;
      case 'streak': return Icons.local_fire_department;
      case 'territory': return Icons.flag;
      case 'speed': return Icons.speed;
      case 'elevation': return Icons.terrain;
      default: return Icons.star;
    }
  }
}

class _BadgeDetailSheet extends StatelessWidget {
  final dynamic badge;

  const _BadgeDetailSheet({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events, size: 64, color: Color(0xFF00E676)),
          ),
          const SizedBox(height: 24),
          Text(badge.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(badge.description ?? 'Achievement unlocked!', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(16)),
            child: Text('+${badge.xpBonus} XP', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _GoalsTab extends StatelessWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.track_changes, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Manage your fitness goals', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/goals'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
            child: const Text('View Goals'),
          ),
        ],
      ),
    );
  }
}

class _TerritoriesTab extends ConsumerWidget {
  final String userId;

  const _TerritoriesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now use a direct query since territory_provider manages viewport map bounds
    return FutureBuilder(
      future: Supabase.instance.client.from('territories').select().eq('owner_id', userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        
        final territories = snapshot.data as List?;
        if (territories == null || territories.isEmpty) return const EmptyState(icon: Icons.flag, title: 'No territories owned', subtitle: 'Go claim some zones!');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: territories.length,
          itemBuilder: (context, index) {
            final territory = territories[index];
            return Card(
              color: const Color(0xFF141414),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.flag, color: Color(0xFF00E676)),
                ),
                title: Text(territory['name'] ?? 'Unknown Territory', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Captured ${territory['capture_count']} times', style: const TextStyle(color: Colors.white54)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () {
                  // Navigate to map centered on territory (optional feature)
                  context.go('/home/map');
                },
              ),
            );
          },
        );
      },
    );
  }
}
