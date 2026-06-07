import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/activity/domain/models/activity_session.dart';
import 'package:turf/features/activity/domain/models/location_ping.dart';

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
      await _supabase.from('activity_sessions').insert(session.toJson());

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
    } catch (e) {
      print('Error saving activity session: $e');
      rethrow;
    }
  }
}
