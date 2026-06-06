class LocationPing {
  final String? id;
  final String sessionId;
  final String userId;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speedMs;
  final double heading;
  final DateTime recordedAt;

  LocationPing({
    this.id,
    required this.sessionId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speedMs,
    required this.heading,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed_ms': speedMs,
      'heading': heading,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}
