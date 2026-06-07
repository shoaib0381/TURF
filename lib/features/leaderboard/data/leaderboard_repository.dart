import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/leaderboard/domain/models/leaderboard_entry.dart';

class LeaderboardRepository {
  final SupabaseClient _supabase;

  LeaderboardRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  Future<List<LeaderboardEntry>> getGlobalLeaderboard(String type) async {
    final response = await _supabase
        .from('leaderboard_entries')
        .select('*, profiles(*)')
        .eq('leaderboard_type', type)
        .order('rank', ascending: true)
        .limit(100);

    return (response as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  Future<List<LeaderboardEntry>> getFriendsLeaderboard(String type) async {
    // 1. Get friend IDs
    final friendsResponse = await _supabase
        .from('friendships')
        .select('user_id_1, user_id_2')
        .or('user_id_1.eq.$_currentUserId,user_id_2.eq.$_currentUserId')
        .eq('status', 'accepted');

    final friendIds = <String>{_currentUserId}; // Include self
    for (var row in friendsResponse) {
      final u1 = row['user_id_1'] as String;
      final u2 = row['user_id_2'] as String;
      friendIds.add(u1 == _currentUserId ? u2 : u1);
    }

    // 2. Fetch leaderboard entries for these IDs
    final response = await _supabase
        .from('leaderboard_entries')
        .select('*, profiles(*)')
        .eq('leaderboard_type', type)
        .inFilter('user_id', friendIds.toList())
        .order('value', ascending: false) // Order by value desc since rank is global
        .limit(100);

    return (response as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }
}
