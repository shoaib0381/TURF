import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:turf/features/leaderboard/domain/models/leaderboard_entry.dart';
import 'package:turf/features/leaderboard/presentation/providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with TickerProviderStateMixin {
  late TabController _scopeTabController;
  final List<Map<String, String>> _types = [
    {'id': 'weekly_distance', 'label': 'Weekly Distance'},
    {'id': 'monthly_distance', 'label': 'Monthly Distance'},
    {'id': 'territory_count', 'label': 'Territory Count'},
    {'id': 'total_xp', 'label': 'Total XP'},
    {'id': 'streak', 'label': 'Streak'},
  ];

  late RealtimeChannel _subscription;

  @override
  void initState() {
    super.initState();
    _scopeTabController = TabController(length: 2, vsync: this);
    _scopeTabController.addListener(() {
      if (!_scopeTabController.indexIsChanging) {
        ref.read(leaderboardScopeProvider.notifier).state = _scopeTabController.index == 0 ? 'global' : 'friends';
      }
    });

    // Realtime subscription to animate changes
    _subscription = Supabase.instance.client
        .channel('public:leaderboard_entries')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaderboard_entries',
          callback: (payload) {
            // Trigger a refresh on any change to the leaderboard table
            ref.invalidate(leaderboardProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _scopeTabController.dispose();
    _subscription.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentType = ref.watch(leaderboardTypeProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Color(0xFF00E676)),
            onPressed: () => context.push('/home/challenges'),
          ),
        ],
        bottom: TabBar(
          controller: _scopeTabController,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs (Horizontal Scroll)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _types.length,
              itemBuilder: (context, index) {
                final type = _types[index];
                final isSelected = currentType == type['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type['label']!),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00E676).withOpacity(0.2),
                    backgroundColor: const Color(0xFF1C1C1E),
                    labelStyle: TextStyle(color: isSelected ? const Color(0xFF00E676) : Colors.white54, fontWeight: FontWeight.bold),
                    side: BorderSide(color: isSelected ? const Color(0xFF00E676) : Colors.transparent),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(leaderboardTypeProvider.notifier).state = type['id']!;
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Leaderboard List
          Expanded(
            child: _LeaderboardContent(),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      error: (e, _) => Center(child: Text('Error loading leaderboard', style: const TextStyle(color: Colors.red))),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text("No entries found.", style: TextStyle(color: Colors.white54)));
        }

        final top3 = entries.take(3).toList();
        final rest = entries.skip(3).toList();

        return RefreshIndicator(
          color: const Color(0xFF00E676),
          backgroundColor: const Color(0xFF1C1C1E),
          onRefresh: () => ref.refresh(leaderboardProvider.future),
          child: CustomScrollView(
            slivers: [
              if (top3.isNotEmpty)
                SliverToBoxAdapter(
                  child: _Podium(top3: top3),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _LeaderboardRow(entry: rest[index]);
                  },
                  childCount: rest.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;

  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    // Determine max value for relative height, but we use fixed heights for UI consistency
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1) _PodiumItem(entry: top3[1], rank: 2, height: 120, color: const Color(0xFFC0C0C0)), // Silver
          if (top3.isNotEmpty) _PodiumItem(entry: top3[0], rank: 1, height: 160, color: const Color(0xFFFFD700)), // Gold
          if (top3.length > 2) _PodiumItem(entry: top3[2], rank: 3, height: 100, color: const Color(0xFFCD7F32)), // Bronze
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final Color color;

  const _PodiumItem({required this.entry, required this.rank, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 40 : 30,
              backgroundColor: const Color(0xFF1C1C1E),
              backgroundImage: entry.profile?.avatarUrl != null ? CachedNetworkImageProvider(entry.profile!.avatarUrl!) : null,
              child: entry.profile?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white54) : null,
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text('$rank', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(top: BorderSide(color: color, width: 4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.profile?.username ?? 'Unknown',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatValue(entry.value, entry.leaderboardType),
                style: const TextStyle(color: Colors.white, fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isMe = entry.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF00E676).withOpacity(0.1) : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMe ? const Color(0xFF00E676) : Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(color: isMe ? const Color(0xFF00E676) : Colors.white54, fontWeight: FontWeight.bold),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1C1C1E),
            backgroundImage: entry.profile?.avatarUrl != null ? CachedNetworkImageProvider(entry.profile!.avatarUrl!) : null,
            child: entry.profile?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white54, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.profile?.fullName ?? 'Unknown User',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lvl ${entry.profile?.level ?? 1}',
                  style: const TextStyle(color: Color(0xFF00E676), fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatValue(entry.value, entry.leaderboardType),
            style: const TextStyle(color: Colors.white, fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

String _formatValue(double value, String type) {
  if (type.contains('distance')) return '${value.toStringAsFixed(1)} km';
  if (type == 'total_xp') return '${value.toInt()} XP';
  if (type == 'streak') return '${value.toInt()} days';
  return value.toInt().toString();
}
