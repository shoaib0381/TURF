class Challenge {
  final String id;
  final String createdBy;
  final String title;
  final String? description;
  final String challengeType; // 'distance', 'territory', 'streak', 'speed', 'elevation'
  final double targetValue;
  final String activityType; // 'run', 'walk', 'cycle', 'any'
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isPublic;
  final int xpReward;
  final String? badgeId;
  final DateTime createdAt;

  // Computed
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  bool get isCompleted {
    return DateTime.now().isAfter(endsAt);
  }

  Challenge({
    required this.id,
    required this.createdBy,
    required this.title,
    this.description,
    required this.challengeType,
    required this.targetValue,
    required this.activityType,
    required this.startsAt,
    required this.endsAt,
    required this.isPublic,
    required this.xpReward,
    this.badgeId,
    required this.createdAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      challengeType: json['challenge_type'] as String,
      targetValue: (json['target_value'] as num).toDouble(),
      activityType: json['activity_type'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      isPublic: json['is_public'] as bool? ?? true,
      xpReward: json['xp_reward'] as int,
      badgeId: json['badge_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'created_by': createdBy,
      'title': title,
      'description': description,
      'challenge_type': challengeType,
      'target_value': targetValue,
      'activity_type': activityType,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'is_public': isPublic,
      'xp_reward': xpReward,
      if (badgeId != null) 'badge_id': badgeId,
    };
  }
}
