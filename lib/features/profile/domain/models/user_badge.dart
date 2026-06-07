import 'package:turf/features/profile/domain/models/badge.dart';

class UserBadge {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final String? sessionId;
  final Badge? badge; // Joined from badges

  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.sessionId,
    this.badge,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeId: json['badge_id'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
      sessionId: json['session_id'] as String?,
      badge: json['badges'] != null ? Badge.fromJson(json['badges']) : null,
    );
  }
}
