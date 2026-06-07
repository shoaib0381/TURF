class Profile {
  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final double totalDistanceKm;
  final int totalXp;
  final int level;
  final int streakDays;
  final String? bio;
  final DateTime? lastActive;

  Profile({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.totalDistanceKm,
    required this.totalXp,
    required this.level,
    this.streakDays = 0,
    this.bio,
    this.lastActive,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      bio: json['bio'] as String?,
      lastActive: json['last_active'] != null ? DateTime.parse(json['last_active'] as String) : null,
    );
  }
}
