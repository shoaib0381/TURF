import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf/features/goals/data/goal_repository.dart';
import 'package:turf/features/goals/domain/models/fitness_goal.dart';

final goalRepositoryProvider = Provider((ref) => GoalRepository());

final myGoalsProvider = FutureProvider<List<FitnessGoal>>((ref) async {
  return ref.watch(goalRepositoryProvider).getMyGoals();
});
