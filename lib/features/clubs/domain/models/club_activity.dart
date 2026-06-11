import 'package:turf/features/profile/domain/models/profile.dart';
import 'package:turf/features/activity/domain/models/activity_session.dart';

class ClubActivity {
  final String id;
  final String clubId;
  final String sessionId;
  final String userId;
  final DateTime postedAt;

  // Joined relations
  final Profile? profile;
  final ActivitySession? session;

  ClubActivity({
    required this.id,
    required this.clubId,
    required this.sessionId,
    required this.userId,
    required this.postedAt,
    this.profile,
    this.session,
  });

  factory ClubActivity.fromJson(Map<String, dynamic> json) {
    return ClubActivity(
      id: json['id'],
      clubId: json['club_id'],
      sessionId: json['session_id'],
      userId: json['user_id'],
      postedAt: DateTime.parse(json['posted_at']),
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
      session: json['activity_sessions'] != null ? ActivitySession.fromJson(json['activity_sessions']) : null,
    );
  }
}
