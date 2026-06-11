import 'package:turf/features/profile/domain/models/profile.dart';

class ClubMember {
  final String id;
  final String clubId;
  final String userId;
  final String role; // 'owner', 'admin', 'member'
  final double weeklyDistanceKm;
  final double totalDistanceKm;
  final DateTime joinedAt;
  
  // Joined relation
  final Profile? profile;

  ClubMember({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.role,
    required this.weeklyDistanceKm,
    required this.totalDistanceKm,
    required this.joinedAt,
    this.profile,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      id: json['id'],
      clubId: json['club_id'],
      userId: json['user_id'],
      role: json['role'] ?? 'member',
      weeklyDistanceKm: (json['weekly_distance_km'] ?? 0).toDouble(),
      totalDistanceKm: (json['total_distance_km'] ?? 0).toDouble(),
      joinedAt: DateTime.parse(json['joined_at']),
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }
}
