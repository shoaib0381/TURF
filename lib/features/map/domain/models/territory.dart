import 'package:latlong2/latlong.dart';

class Territory {
  final String id;
  final String name;
  final LatLng center;
  final double radiusMeters;
  final String? ownerId;
  final DateTime? capturedAt;
  final int captureCount;
  final int xpValue;
  final String territoryType;

  Territory({
    required this.id,
    required this.name,
    required this.center,
    required this.radiusMeters,
    this.ownerId,
    this.capturedAt,
    required this.captureCount,
    required this.xpValue,
    required this.territoryType,
  });

  factory Territory.fromJson(Map<String, dynamic> json) {
    return Territory(
      id: json['id'] as String,
      name: json['name'] as String,
      center: LatLng(
        (json['center_lat'] as num).toDouble(),
        (json['center_lng'] as num).toDouble(),
      ),
      radiusMeters: (json['radius_meters'] as num).toDouble(),
      ownerId: json['owner_id'] as String?,
      capturedAt: json['captured_at'] != null 
          ? DateTime.parse(json['captured_at'] as String) 
          : null,
      captureCount: json['capture_count'] as int,
      xpValue: json['xp_value'] as int,
      territoryType: json['territory_type'] as String,
    );
  }
}
