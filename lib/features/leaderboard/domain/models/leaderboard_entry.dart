import 'package:turf/features/profile/domain/models/profile.dart';

class LeaderboardEntry {
  final String id;
  final String userId;
  final String leaderboardType;
  final double value;
  final int rank;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime updatedAt;
  final Profile? profile; // Joined from profiles table

  LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.leaderboardType,
    required this.value,
    required this.rank,
    this.periodStart,
    this.periodEnd,
    required this.updatedAt,
    this.profile,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      leaderboardType: json['leaderboard_type'] as String,
      value: (json['value'] as num).toDouble(),
      rank: json['rank'] as int,
      periodStart: json['period_start'] != null ? DateTime.parse(json['period_start'] as String) : null,
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end'] as String) : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      profile: json['profiles'] != null ? Profile.fromJson(json['profiles']) : null,
    );
  }
}
