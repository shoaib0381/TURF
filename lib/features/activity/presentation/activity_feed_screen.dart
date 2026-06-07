import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_map/flutter_map.dart';
import 'package:shimmer/shimmer.dart';

import 'package:turf/core/utils/polyline_codec.dart';
import 'package:turf/features/activity/domain/models/feed_activity.dart';
import 'package:turf/features/activity/presentation/providers/activity_feed_provider.dart';

class ActivityFeedScreen extends ConsumerStatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  ConsumerState<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends ConsumerState<ActivityFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _friendsScrollController = ScrollController();
  final ScrollController _myScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _friendsScrollController.addListener(() {
      if (_friendsScrollController.position.pixels >= _friendsScrollController.position.maxScrollExtent - 200) {
        ref.read(activityFeedProvider.notifier).loadMoreFriendsActivities();
      }
    });

    _myScrollController.addListener(() {
      if (_myScrollController.position.pixels >= _myScrollController.position.maxScrollExtent - 200) {
        ref.read(activityFeedProvider.notifier).loadMoreMyActivities();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _friendsScrollController.dispose();
    _myScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Activity Feed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'My Activities'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildFeedList(state.friendsActivities, state.isLoading, _friendsScrollController),
              _buildFeedList(state.myActivities, state.isLoading, _myScrollController),
            ],
          ),
          
          if (state.hasNewFriendsActivity)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => ref.read(activityFeedProvider.notifier).clearNewActivityBadge(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.black, size: 16),
                        SizedBox(width: 8),
                        Text('New Activity', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedList(List<FeedActivity> activities, bool isLoading, ScrollController controller) {
    if (isLoading && activities.isEmpty) {
      return _buildShimmerFeed();
    }

    if (activities.isEmpty) {
      return const Center(child: Text('No activities yet.', style: TextStyle(color: Colors.white54)));
    }

    return RefreshIndicator(
      color: const Color(0xFF00E676),
      backgroundColor: const Color(0xFF1C1C1E),
      onRefresh: () async => ref.read(activityFeedProvider.notifier).loadInitialData(),
      child: ListView.separated(
        controller: controller,
        padding: const EdgeInsets.all(16),
        itemCount: activities.length + (isLoading ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          if (index == activities.length) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
          }
          return FeedCard(activity: activities[index]);
        },
      ),
    );
  }

  Widget _buildShimmerFeed() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFF1C1C1E),
        highlightColor: const Color(0xFF2C2C2E),
        child: Container(
          height: 350,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class FeedCard extends ConsumerWidget {
  final FeedActivity activity;

  const FeedCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routePoints = PolylineCodec.decode(activity.session.routePolyline);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1C1C1E),
                  backgroundImage: activity.profile.avatarUrl != null
                      ? CachedNetworkImageProvider(activity.profile.avatarUrl!)
                      : null,
                  child: activity.profile.avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.profile.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(timeago.format(activity.session.endedAt), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(activity.session.activityType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.session.activityType.toUpperCase(),
                    style: TextStyle(color: _getTypeColor(activity.session.activityType), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Main Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  activity.session.distanceKm.toStringAsFixed(2),
                  style: const TextStyle(fontFamily: 'Space Grotesk', fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0, left: 4),
                  child: Text('km', style: TextStyle(color: Colors.white54, fontSize: 16)),
                ),
                const Spacer(),
                if (activity.session.xpEarned > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text('+${activity.session.xpEarned} XP', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
          ),
          
          // Secondary Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _StatText(icon: Icons.timer, text: _formatDuration(activity.session.durationSeconds)),
                const SizedBox(width: 16),
                _StatText(icon: Icons.speed, text: '${activity.session.avgSpeedKmh.toStringAsFixed(1)} km/h'),
                const SizedBox(width: 16),
                _StatText(icon: Icons.local_fire_department, text: '${activity.session.caloriesBurned} kcal'),
              ],
            ),
          ),

          // Territories
          if (activity.territoriesCaptured > 0)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Color(0xFF00E676), size: 16),
                  const SizedBox(width: 4),
                  Text('${activity.territoriesCaptured} Territories Captured', style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // Map Thumbnail
          if (routePoints.isNotEmpty)
            SizedBox(
              height: 180,
              child: ClipRRect(
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(routePoints),
                      padding: const EdgeInsets.all(24),
                    ),
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png?api_key={api_key}',
                      additionalOptions: const {'api_key': 'aba107a2-3f38-4e4a-8d0a-135e6ff7c2f7'},
                      maxZoom: 20, maxNativeZoom: 20,
                      userAgentPackageName: 'com.turf.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(points: routePoints, color: const Color(0xFF00E676), strokeWidth: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.favorite_border,
                  count: activity.likeCount,
                  onTap: () => ref.read(activityFeedProvider.notifier).toggleLike(activity.session.id!, true),
                ),
                const SizedBox(width: 24),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: activity.commentCount,
                  onTap: () {
                    // Open comment sheet
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comments coming soon!')));
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white54),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'run': return const Color(0xFF00E676);
      case 'walk': return const Color(0xFF00B0FF);
      case 'cycle': return const Color(0xFFFF9100);
      default: return const Color(0xFF00E676);
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${seconds % 60}s';
  }
}

class _StatText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StatText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 24),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Text(count.toString(), style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}
