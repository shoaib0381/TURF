import 'package:turf/features/profile/domain/models/profile.dart';

class Friendship {
  final String id;
  final String userId1;
  final String userId2;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;
  
  // Optional populated profiles
  final Profile? profile1;
  final Profile? profile2;

  Friendship({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.createdAt,
    this.profile1,
    this.profile2,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      userId1: json['user_id_1'] as String,
      userId2: json['user_id_2'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      profile1: json['profile1'] != null ? Profile.fromJson(json['profile1'] as Map<String, dynamic>) : null,
      profile2: json['profile2'] != null ? Profile.fromJson(json['profile2'] as Map<String, dynamic>) : null,
    );
  }
}
