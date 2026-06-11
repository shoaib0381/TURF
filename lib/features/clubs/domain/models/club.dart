class Club {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? coverUrl;
  final String createdBy;
  final bool isPublic;
  final String inviteCode;
  final int memberCount;
  final double totalDistanceKm;
  final DateTime createdAt;

  Club({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.coverUrl,
    required this.createdBy,
    required this.isPublic,
    required this.inviteCode,
    required this.memberCount,
    required this.totalDistanceKm,
    required this.createdAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatar_url'],
      coverUrl: json['cover_url'],
      createdBy: json['created_by'],
      isPublic: json['is_public'] ?? true,
      inviteCode: json['invite_code'],
      memberCount: json['member_count'] ?? 1,
      totalDistanceKm: (json['total_distance_km'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'created_by': createdBy,
      'is_public': isPublic,
      'invite_code': inviteCode,
      'member_count': memberCount,
      'total_distance_km': totalDistanceKm,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
