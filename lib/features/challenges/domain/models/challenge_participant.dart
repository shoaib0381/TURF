import 'package:turf/features/profile/domain/models/profile.dart';
import 'package:turf/features/challenges/domain/models/challenge.dart';

class ChallengeParticipant {
  final String id;
  final String challengeId;
  final String userId;
  final DateTime joinedAt;
  final double currentValue;
  final bool completed;
  final DateTime? completedAt;
  final Profile? profile; // Joined from profiles
  final Challenge? challenge; // Joined from challenges

  ChallengeParticipant({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.joinedAt,
    required this.currentValue,
    required this.completed,
    this.completedAt,
    this.profile,
    this.challenge,
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipant(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      currentValue: (json['current_value'] as num).toDouble(),
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      profile: json['profiles'] != null ? Profile.fromJson(json['profiles']) : null,
      challenge: json['challenges'] != null ? Challenge.fromJson(json['challenges']) : null,
    );
  }
}
