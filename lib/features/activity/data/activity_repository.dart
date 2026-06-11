import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/activity/domain/models/activity_session.dart';
import 'package:turf/features/activity/domain/models/location_ping.dart';
import 'package:turf/features/goals/domain/models/fitness_goal.dart';

class ActivityRepository {
  final SupabaseClient _supabase;

  ActivityRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<void> batchInsertLocationPings(List<LocationPing> pings) async {
    if (pings.isEmpty) return;
    try {
      await _supabase.from('location_pings').insert(
            pings.map((p) => p.toJson()).toList(),
          );
    } catch (e) {
      // Typically in a production app we might cache failed pings locally and retry.
      print('Error batch inserting location pings: $e');
    }
  }

  Future<void> saveActivitySession(ActivitySession session) async {
    try {
      // 1. Insert session
      final sessionResponse = await _supabase.from('activity_sessions').insert(session.toJson()).select('id').single();
      final sessionId = sessionResponse['id'] as String;

      // 2. Award XP
      if (session.xpEarned > 0) {
        await _supabase.rpc('award_xp', params: {
          'p_user_id': session.userId,
          'p_xp': session.xpEarned,
        });
      }

      // 3. Update active challenge progress
      try {
        final activeParticipants = await _supabase
            .from('challenge_participants')
            .select('id, current_value, challenge_id, challenges!inner(challenge_type, activity_type, target_value, ends_at)')
            .eq('user_id', session.userId)
            .eq('completed', false);

        for (var p in activeParticipants) {
          final c = p['challenges'];
          final isExpired = DateTime.now().isAfter(DateTime.parse(c['ends_at']));
          if (isExpired) continue;

          if (c['activity_type'] == 'any' || c['activity_type'] == session.activityType) {
            double newValue = (p['current_value'] as num).toDouble();
            
            if (c['challenge_type'] == 'distance') newValue += session.distanceKm;
            else if (c['challenge_type'] == 'elevation') newValue += session.elevationGainM;
            else if (c['challenge_type'] == 'streak') newValue += 1; // 1 session = 1 streak count
            else if (c['challenge_type'] == 'speed' && session.avgSpeedKmh > newValue) newValue = session.avgSpeedKmh;

            final target = (c['target_value'] as num).toDouble();
            final completed = newValue >= target;

            await _supabase.from('challenge_participants').update({
              'current_value': newValue,
              'completed': completed,
              if (completed) 'completed_at': DateTime.now().toIso8601String(),
            }).eq('id', p['id']);
            
            if (completed) {
               // Assuming challenge completion awards XP
               final xpReward = c['xp_reward'] ?? 0;
               if (xpReward > 0) {
                 await _supabase.rpc('award_xp', params: {
                   'p_user_id': session.userId,
                   'p_xp': xpReward,
                 });
               }
            }
          }
        }
      } catch (e) {
        print('Error updating challenge progress: $e');
      }

      // 4. Update active fitness goals
      try {
        final activeGoals = await _supabase
            .from('fitness_goals')
            .select()
            .eq('user_id', session.userId)
            .eq('completed', false);

        for (var goalData in activeGoals) {
          final goal = FitnessGoal.fromJson(goalData);
          final isExpired = DateTime.now().isAfter(goal.endsAt);
          if (isExpired) continue;

          double newValue = goal.currentValue;
          if (goal.goalType == 'weekly_distance' || goal.goalType == 'monthly_distance') {
            newValue += session.distanceKm;
          } else if (goal.goalType == 'weekly_sessions' || goal.goalType == 'streak') {
            newValue += 1; // Basic increment
          }

          if (newValue > goal.currentValue) {
            final completed = newValue >= goal.targetValue;
            await _supabase.from('fitness_goals').update({
              'current_value': newValue,
              'completed': completed,
            }).eq('id', goal.id);

            // Send notification logic via edge function or trigger in production
          }
        }
      } catch (e) {
        print('Error updating fitness goals progress: $e');
      }

      // 5. Post to Club Activities
      try {
        final memberships = await _supabase
            .from('club_members')
            .select('club_id')
            .eq('user_id', session.userId);

        final clubActivities = (memberships as List).map((m) => {
          'club_id': m['club_id'],
          'session_id': sessionId,
          'user_id': session.userId,
        }).toList();

        if (clubActivities.isNotEmpty) {
          await _supabase.from('club_activities').insert(clubActivities);
        }
      } catch (e) {
        print('Error posting to club activities: $e');
      }
    } catch (e) {
      print('Error saving activity session: $e');
      rethrow;
    }
  }
}
