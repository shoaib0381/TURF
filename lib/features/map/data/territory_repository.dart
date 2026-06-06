import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/map/domain/models/territory.dart';

class TerritoryRepository {
  final SupabaseClient _supabase;

  TerritoryRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Stream<List<Territory>> streamTerritoriesInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) {
    return _supabase
        .from('territories')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter in memory as Supabase Realtime doesn't support complex range filters easily on stream
          return data
              .map((e) => Territory.fromJson(e))
              .where((t) =>
                  t.center.latitude >= minLat &&
                  t.center.latitude <= maxLat &&
                  t.center.longitude >= minLng &&
                  t.center.longitude <= maxLng)
              .toList();
        });
  }

  Future<void> captureTerritory(String territoryId, int xpEarned) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Call award_xp function directly if possible, or we insert and let backend handle it.
    // The instructions said: "Capture button: insert into territory_captures table, update territories.owner_id to current user"

    // 1. Insert into territory_captures
    await _supabase.from('territory_captures').insert({
      'territory_id': territoryId,
      'user_id': userId,
      'xp_earned': xpEarned,
      // session_id is nullable in phase 1, so we omit it for direct captures
    });

    // 2. Update territories table
    // 3. Award XP (Wait, Phase 1 said: "Create a Postgres function: award_xp(p_user_id uuid, p_xp int4)")
    
    // We update the territory first
    await _supabase.from('territories').update({
      'owner_id': userId,
      'captured_at': DateTime.now().toIso8601String(),
    }).eq('id', territoryId);

    // Call RPC to award XP
    await _supabase.rpc('award_xp', params: {
      'p_user_id': userId,
      'p_xp': xpEarned,
    });
  }
}
