import 'package:turf/features/profile/domain/models/profile.dart';

class ClubRequest {
  final String id;
  final String clubId;
  final String userId;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;

  // Joined relation
  final Profile? profile;

  ClubRequest({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.profile,
  });

  factory ClubRequest.fromJson(Map<String, dynamic> json) {
    return ClubRequest(
      id: json['id'],
      clubId: json['club_id'],
      userId: json['user_id'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }
}
