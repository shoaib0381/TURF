import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/goals/domain/models/fitness_goal.dart';

class GoalRepository {
  final SupabaseClient _supabase;

  GoalRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  Future<List<FitnessGoal>> getMyGoals() async {
    final response = await _supabase
        .from('fitness_goals')
        .select()
        .eq('user_id', _currentUserId)
        .order('ends_at', ascending: true);

    return (response as List).map((e) => FitnessGoal.fromJson(e)).toList();
  }

  Future<void> createGoal(FitnessGoal goal) async {
    await _supabase.from('fitness_goals').insert(goal.toJson());
  }

  Future<void> deleteGoal(String goalId) async {
    await _supabase.from('fitness_goals').delete().eq('id', goalId).eq('user_id', _currentUserId);
  }

  Future<void> markComplete(String goalId) async {
    await _supabase
        .from('fitness_goals')
        .update({'completed': true})
        .eq('id', goalId)
        .eq('user_id', _currentUserId);
  }
}
