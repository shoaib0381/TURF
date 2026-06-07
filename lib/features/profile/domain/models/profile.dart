class Profile {
  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final double totalDistanceKm;
  final int level;
  final DateTime? lastActive;

  Profile({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.totalDistanceKm,
    required this.level,
    this.lastActive,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      lastActive: json['last_active'] != null ? DateTime.parse(json['last_active'] as String) : null,
    );
  }
}
