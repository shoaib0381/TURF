class FitnessGoal {
  final String id;
  final String userId;
  final String goalType; // 'weekly_distance', 'monthly_distance', 'weekly_sessions', 'weight_loss', 'streak'
  final double targetValue;
  final double currentValue;
  final String? unit;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool completed;
  final DateTime createdAt;

  FitnessGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.targetValue,
    required this.currentValue,
    this.unit,
    required this.startsAt,
    required this.endsAt,
    required this.completed,
    required this.createdAt,
  });

  factory FitnessGoal.fromJson(Map<String, dynamic> json) {
    return FitnessGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalType: json['goal_type'] as String,
      targetValue: (json['target_value'] as num).toDouble(),
      currentValue: (json['current_value'] as num).toDouble(),
      unit: json['unit'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'goal_type': goalType,
      'target_value': targetValue,
      'current_value': currentValue,
      if (unit != null) 'unit': unit,
      'starts_at': startsAt.toIso8601String().substring(0, 10), // date type in DB
      'ends_at': endsAt.toIso8601String().substring(0, 10),
      'completed': completed,
    };
  }
}
