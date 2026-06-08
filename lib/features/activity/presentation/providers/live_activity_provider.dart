import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/core/services/background_tracking_service.dart';
import 'package:turf/core/utils/polyline_codec.dart';
import 'package:turf/features/activity/data/activity_repository.dart';
import 'package:turf/features/activity/domain/models/activity_session.dart';
import 'package:turf/features/activity/domain/models/location_ping.dart';
import 'package:turf/features/map/presentation/providers/location_provider.dart';
import 'package:turf/features/map/domain/models/territory.dart';
import 'package:turf/features/map/presentation/providers/territories_provider.dart';
import 'package:turf/features/activity/presentation/providers/activity_feed_provider.dart';

enum TrackingState { idle, countdown, active, paused, finished }

class LiveActivityState {
  final TrackingState status;
  final String activityType; // 'run', 'walk', 'cycle'
  final int durationSeconds;
  final double distanceKm;
  final double currentSpeedKmh;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int caloriesBurned;
  final double elevationGainM;
  final List<LatLng> routePoints;
  final List<LocationPing> pendingPings;
  final Territory? nearbyTerritory;

  LiveActivityState({
    this.status = TrackingState.idle,
    this.activityType = 'run',
    this.durationSeconds = 0,
    this.distanceKm = 0.0,
    this.currentSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.caloriesBurned = 0,
    this.elevationGainM = 0.0,
    this.routePoints = const [],
    this.pendingPings = const [],
    this.nearbyTerritory,
  });

  LiveActivityState copyWith({
    TrackingState? status,
    String? activityType,
    int? durationSeconds,
    double? distanceKm,
    double? currentSpeedKmh,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    int? caloriesBurned,
    double? elevationGainM,
    List<LatLng>? routePoints,
    List<LocationPing>? pendingPings,
    Territory? nearbyTerritory,
  }) {
    return LiveActivityState(
      status: status ?? this.status,
      activityType: activityType ?? this.activityType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      routePoints: routePoints ?? this.routePoints,
      pendingPings: pendingPings ?? this.pendingPings,
      nearbyTerritory: nearbyTerritory, // Can be null
    );
  }
}

final activityRepositoryProvider = Provider((ref) => ActivityRepository());

class LiveActivityNotifier extends Notifier<LiveActivityState> {
  Timer? _timer;
  Timer? _pingTimer;
  Timer? _territoryTimer;
  StreamSubscription<Position>? _positionSub;
  DateTime? _startedAt;

  @override
  LiveActivityState build() {
    ref.onDispose(() {
      _cleanup();
    });
    return LiveActivityState();
  }

  void _cleanup() {
    _timer?.cancel();
    _pingTimer?.cancel();
    _territoryTimer?.cancel();
    _positionSub?.cancel();
    BackgroundTrackingService.stopTrackingTask();
  }

  void setActivityType(String type) {
    state = state.copyWith(activityType: type);
  }

  void startCountdown() {
    state = state.copyWith(status: TrackingState.countdown);
  }

  void startActivity() {
    _startedAt = DateTime.now();
    state = state.copyWith(status: TrackingState.active);
    BackgroundTrackingService.startTrackingTask();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == TrackingState.active) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
        _updateCalories();
        if (state.durationSeconds % 5 == 0) {
          _updateNotification();
        }
      }
    });

    _pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (state.pendingPings.isNotEmpty && state.status == TrackingState.active) {
        final repo = ref.read(activityRepositoryProvider);
        repo.batchInsertLocationPings(List.from(state.pendingPings));
        state = state.copyWith(pendingPings: []);
      }
    });

    _territoryTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (state.status == TrackingState.active && state.routePoints.isNotEmpty) {
        _checkForNearbyTerritories(state.routePoints.last);
      }
    });

    _startLocationUpdates();
  }

  Future<void> _startLocationUpdates() async {
    final locationService = ref.read(locationServiceProvider);
    
    final hasPermission = await locationService.handlePermission();
    if (!hasPermission) return;

    _positionSub = locationService.getPositionStream().listen((pos) {
      if (state.status != TrackingState.active) return;

      final newPoint = LatLng(pos.latitude, pos.longitude);
      final updatedPoints = List<LatLng>.from(state.routePoints)..add(newPoint);
      
      double addedDistance = 0.0;
      if (state.routePoints.isNotEmpty) {
        final lastPoint = state.routePoints.last;
        addedDistance = Geolocator.distanceBetween(
              lastPoint.latitude, lastPoint.longitude,
              newPoint.latitude, newPoint.longitude,
            ) / 1000.0; // km
      }

      final speedKmh = pos.speed * 3.6;
      final newDistance = state.distanceKm + addedDistance;
      final avgSpeed = state.durationSeconds > 0 ? (newDistance / (state.durationSeconds / 3600.0)) : 0.0;
      final maxSpeed = speedKmh > state.maxSpeedKmh ? speedKmh : state.maxSpeedKmh;

      final ping = LocationPing(
        sessionId: 'temp_session_id', // Replaced upon full save if needed, or kept empty
        userId: Supabase.instance.client.auth.currentUser!.id,
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
        speedMs: pos.speed,
        heading: pos.heading,
        recordedAt: DateTime.now(),
      );

      state = state.copyWith(
        routePoints: updatedPoints,
        distanceKm: newDistance,
        currentSpeedKmh: speedKmh,
        avgSpeedKmh: avgSpeed,
        maxSpeedKmh: maxSpeed,
        pendingPings: List.from(state.pendingPings)..add(ping),
      );
    });
  }

  void _updateCalories() {
    // MET calculation
    double met = 0;
    if (state.activityType == 'run') met = 9.8;
    if (state.activityType == 'walk') met = 3.5;
    if (state.activityType == 'cycle') met = 7.5;

    double weightKg = 70.0; // Default
    double durationHours = state.durationSeconds / 3600.0;
    int cals = (met * weightKg * durationHours).round();

    state = state.copyWith(caloriesBurned: cals);
  }

  void _updateNotification() {
    final pace = state.distanceKm > 0 ? (state.durationSeconds / 60) / state.distanceKm : 0.0;
    final paceStr = "${pace.toInt()}:${((pace % 1) * 60).toInt().toString().padLeft(2, '0')} /km";
    BackgroundTrackingService.showTrackingNotification(
      "TURF - Tracking your ${state.activityType}", 
      "${state.distanceKm.toStringAsFixed(2)} km | $paceStr",
    );
  }

  void _checkForNearbyTerritories(LatLng currentLoc) {
    // get current territories
    final territories = ref.read(territoriesProvider).value ?? [];
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    for (var t in territories) {
      if (t.ownerId != currentUserId) {
        final dist = Geolocator.distanceBetween(
          currentLoc.latitude, currentLoc.longitude,
          t.center.latitude, t.center.longitude,
        );
        if (dist <= 200) {
          state = state.copyWith(nearbyTerritory: t);
          return; // just show one
        }
      }
    }
    state = state.copyWith(nearbyTerritory: null); // Clear if none
  }

  void clearNearbyTerritory() {
    // Force clear the territory state if we close it
    state = LiveActivityState(
      status: state.status,
      activityType: state.activityType,
      durationSeconds: state.durationSeconds,
      distanceKm: state.distanceKm,
      currentSpeedKmh: state.currentSpeedKmh,
      avgSpeedKmh: state.avgSpeedKmh,
      maxSpeedKmh: state.maxSpeedKmh,
      caloriesBurned: state.caloriesBurned,
      elevationGainM: state.elevationGainM,
      routePoints: state.routePoints,
      pendingPings: state.pendingPings,
      nearbyTerritory: null, 
    );
  }

  void pauseActivity() {
    state = state.copyWith(status: TrackingState.paused);
    BackgroundTrackingService.showTrackingNotification("TURF - Paused", "Activity is paused");
  }

  void resumeActivity() {
    state = state.copyWith(status: TrackingState.active);
  }

  Future<ActivitySession> stopAndSaveActivity() async {
    _cleanup();
    state = state.copyWith(status: TrackingState.finished);
    
    // flush pings
    if (state.pendingPings.isNotEmpty) {
      ref.read(activityRepositoryProvider).batchInsertLocationPings(state.pendingPings);
    }

    final polyline = PolylineCodec.encode(state.routePoints);
    int xpEarned = (state.distanceKm * 10).round();
    // Add pace bonus logic later

    final session = ActivitySession(
      userId: Supabase.instance.client.auth.currentUser!.id,
      activityType: state.activityType,
      startedAt: _startedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
      durationSeconds: state.durationSeconds,
      distanceKm: state.distanceKm,
      avgSpeedKmh: state.avgSpeedKmh,
      maxSpeedKmh: state.maxSpeedKmh,
      caloriesBurned: state.caloriesBurned,
      elevationGainM: state.elevationGainM,
      routePolyline: polyline,
      xpEarned: xpEarned,
    );

    await ref.read(activityRepositoryProvider).saveActivitySession(session);
    
    // Refresh the feed immediately so it shows up in "My Activities"
    ref.read(activityFeedProvider.notifier).loadInitialData();
    
    return session;
  }
}

final liveActivityProvider = NotifierProvider<LiveActivityNotifier, LiveActivityState>(() {
  return LiveActivityNotifier();
});
