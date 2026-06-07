class Badge {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl; // Reusing as icon name for now
  final String badgeType; // 'milestone', 'challenge', 'streak', 'territory', 'speed', 'special'
  final double requiredValue;
  final int xpBonus;
  final DateTime createdAt;

  Badge({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.badgeType,
    required this.requiredValue,
    required this.xpBonus,
    required this.createdAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      badgeType: json['badge_type'] as String,
      requiredValue: (json['required_value'] as num).toDouble(),
      xpBonus: json['xp_bonus'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
