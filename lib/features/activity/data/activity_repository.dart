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
    } catch (e) {
      print('Error saving activity session: $e');
      rethrow;
    }
  }
}
