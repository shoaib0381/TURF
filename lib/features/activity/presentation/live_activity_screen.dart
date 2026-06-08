import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:turf/features/activity/presentation/providers/live_activity_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveActivityScreen extends ConsumerStatefulWidget {
  const LiveActivityScreen({super.key});

  @override
  ConsumerState<LiveActivityScreen> createState() => _LiveActivityScreenState();
}

class _LiveActivityScreenState extends ConsumerState<LiveActivityScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveActivityProvider);
    final notifier = ref.read(liveActivityProvider.notifier);

    // Auto-center map on latest point
    if (state.routePoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(state.routePoints.last, 17.0);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Top 40% Map
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialZoom: 17.0,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.none, // Lock map interaction
                    )
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png?api_key={api_key}',
                      additionalOptions: const {
                        'api_key': 'aba107a2-3f38-4e4a-8d0a-135e6ff7c2f7',
                      },
                      maxZoom: 20,
                      maxNativeZoom: 20,
                      userAgentPackageName: 'com.turf.app',
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('Stadia Maps', onTap: () => launchUrl(Uri.parse('https://stadiamaps.com/')), prependCopyright: true),
                        TextSourceAttribution('OpenMapTiles', onTap: () => launchUrl(Uri.parse('https://openmaptiles.org/')), prependCopyright: true),
                        TextSourceAttribution('OpenStreetMap', onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')), prependCopyright: true),
                      ],
                    ),
                    if (state.nearbyTerritory != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: state.nearbyTerritory!.center,
                            radius: state.nearbyTerritory!.radiusMeters,
                            useRadiusInMeter: true,
                            color: const Color(0xFF00E676).withOpacity(0.3),
                            borderColor: const Color(0xFF00E676),
                            borderStrokeWidth: 2,
                          )
                        ],
                      ),
                    if (state.routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: state.routePoints,
                            color: const Color(0xFF00E676),
                            strokeWidth: 5.0,
                          ),
                        ],
                      ),
                    if (state.routePoints.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: state.routePoints.last,
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E676),
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          )
                        ],
                      )
                  ],
                ),
              ),

              // Bottom 60% Stats
              Expanded(
                child: Container(
                  color: const Color(0xFF141414),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        state.distanceKm.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Space Grotesk',
                        ),
                      ),
                      const Text('kilometers', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 32),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Duration', value: _formatDuration(state.durationSeconds)),
                          _StatItem(label: 'Avg Pace', value: _formatPace(state.distanceKm, state.durationSeconds)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Speed', value: '${state.currentSpeedKmh.toStringAsFixed(1)} km/h'),
                          _StatItem(label: 'Calories', value: '${state.caloriesBurned} kcal'),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Controls
                      if (state.status == TrackingState.active)
                        GestureDetector(
                          onTap: notifier.pauseActivity,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pause, size: 40, color: Colors.black),
                          ),
                        )
                      else if (state.status == TrackingState.paused)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: notifier.resumeActivity,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, size: 40, color: Colors.black),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showStopDialog(context, notifier),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF453A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.stop, size: 40, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              )
            ],
          ),

          // Territory Nearby Banner
          if (state.nearbyTerritory != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  // Trigger capture flow or show sheet
                  // For now we clear it to act as "acknowledged"
                  notifier.clearNearbyTerritory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Capture sheet opening... (Implement Capture here)')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.black),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Territory nearby: ${state.nearbyTerritory!.name}\nTap to capture!',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
                        onPressed: notifier.clearNearbyTerritory,
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showStopDialog(BuildContext context, LiveActivityNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Finish Activity?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to end your session?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context, 
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
              );
              try {
                final session = await notifier.stopAndSaveActivity();
                if (mounted) {
                  Navigator.pop(context); // pop loading
                  context.pushReplacement('/activity/summary', extra: session);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving session')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            child: const Text('FINISH', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double distanceKm, int durationSeconds) {
    if (distanceKm == 0) return "0:00";
    final pace = (durationSeconds / 60) / distanceKm;
    final mins = pace.toInt();
    final secs = ((pace % 1) * 60).toInt();
    return "$mins:${secs.toString().padLeft(2, '0')}";
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Space Grotesk',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white54,
          ),
        )
      ],
    );
  }
}
