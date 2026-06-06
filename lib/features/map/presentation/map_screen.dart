import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:confetti/confetti.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:turf/features/map/domain/models/territory.dart';
import 'package:turf/features/map/presentation/providers/location_provider.dart';
import 'package:turf/features/map/presentation/providers/territories_provider.dart';
import 'package:turf/features/map/presentation/widgets/floating_bottom_stats.dart';
import 'package:turf/features/map/presentation/widgets/floating_top_bar.dart';
import 'package:turf/features/map/presentation/widgets/pulsing_marker.dart';
import 'package:turf/features/map/presentation/widgets/territory_info_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  late ConfettiController _confettiController;
  bool _isMapCentered = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    ref.read(mapBoundsProvider.notifier).updateBounds(camera.visibleBounds);
  }

  void _showTerritoryInfo(Territory territory, Position? userPos) {
    bool canCapture = false;
    
    if (userPos != null) {
      final distance = Geolocator.distanceBetween(
        userPos.latitude, userPos.longitude,
        territory.center.latitude, territory.center.longitude,
      );
      canCapture = distance <= territory.radiusMeters;
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnedByMe = territory.ownerId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TerritoryInfoSheet(
        territory: territory,
        canCapture: canCapture,
        isOwnedByMe: isOwnedByMe,
        onCapture: () async {
          Navigator.pop(context); // Close sheet
          try {
            await ref.read(territoryRepositoryProvider).captureTerritory(
                  territory.id,
                  territory.xpValue,
                );
            _confettiController.play();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Captured! +${territory.xpValue} XP'),
                  backgroundColor: const Color(0xFF00E676),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to capture territory.'),
                  backgroundColor: Color(0xFFFF453A),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Color _getTerritoryColor(Territory territory) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (territory.ownerId == null) return Colors.white;
    if (territory.ownerId == currentUserId) return const Color(0xFF00E676);
    // Assume blue for friends (requires friendship check in real app), red for others
    return const Color(0xFFFF453A); 
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);
    final territoriesAsync = ref.watch(territoriesProvider);

    Position? currentPos;
    locationAsync.whenData((pos) {
      currentPos = pos;
      if (!_isMapCentered) {
        _isMapCentered = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
        });
      }
    });

    List<Territory> territories = territoriesAsync.value ?? [];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(30.0, 70.0), // Default fallback
              initialZoom: 15.0,
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.turf.app',
              ),
              
              // Territories Circles
              CircleLayer(
                circles: territories.map((t) {
                  final color = _getTerritoryColor(t);
                  return CircleMarker(
                    point: t.center,
                    radius: t.radiusMeters,
                    useRadiusInMeter: true,
                    color: color.withOpacity(t.ownerId == null ? 0.2 : 0.4),
                    borderColor: color,
                    borderStrokeWidth: t.ownerId == null ? 2 : 0,
                  );
                }).toList(),
              ),

              // Territories Markers
              MarkerLayer(
                markers: territories.map((t) {
                  return Marker(
                    point: t.center,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showTerritoryInfo(t, currentPos),
                      child: PulsingMarker(
                        color: _getTerritoryColor(t),
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // User Location
              if (currentPos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(currentPos!.latitude, currentPos!.longitude),
                      width: 40,
                      height: 40,
                      child: const PulsingMarker(color: Color(0xFF00E676), size: 16),
                    ),
                  ],
                ),
            ],
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFF00E676), Colors.white, Colors.yellow],
            ),
          ),

          // Floating UI
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingTopBar(),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FloatingBottomStats(),
          ),
        ],
      ),
    );
  }
}
