class ActivitySession {
  final String? id;
  final String userId;
  final String activityType; // 'run', 'walk', 'cycle'
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final double distanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int caloriesBurned;
  final double elevationGainM;
  final String routePolyline;
  final int xpEarned;

  ActivitySession({
    this.id,
    required this.userId,
    required this.activityType,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.caloriesBurned,
    required this.elevationGainM,
    required this.routePolyline,
    required this.xpEarned,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'activity_type': activityType,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration_seconds': durationSeconds,
      'distance_km': distanceKm,
      'avg_speed_kmh': avgSpeedKmh,
      'max_speed_kmh': maxSpeedKmh,
      'calories_burned': caloriesBurned,
      'elevation_gain_m': elevationGainM,
      'route_polyline': routePolyline,
      'xp_earned': xpEarned,
    };
  }

  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    return ActivitySession(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      activityType: json['activity_type'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: DateTime.parse(json['ended_at'] as String),
      durationSeconds: json['duration_seconds'] as int,
      distanceKm: (json['distance_km'] as num).toDouble(),
      avgSpeedKmh: (json['avg_speed_kmh'] as num).toDouble(),
      maxSpeedKmh: (json['max_speed_kmh'] as num).toDouble(),
      caloriesBurned: json['calories_burned'] as int,
      elevationGainM: (json['elevation_gain_m'] as num).toDouble(),
      routePolyline: json['route_polyline'] as String,
      xpEarned: json['xp_earned'] as int,
    );
  }
}
