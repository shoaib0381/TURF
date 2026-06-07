import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/activity/domain/models/feed_activity.dart';

class FeedRepository {
  final SupabaseClient _supabase;

  FeedRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  /// Get personal activities
  Future<List<FeedActivity>> getMyActivities({int offset = 0, int limit = 20}) async {
    final response = await _supabase
        .from('activity_sessions')
        .select('*, profiles(*)')
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => FeedActivity.fromJson(e)).toList();
  }

  /// Get friends activities (requires joining with friendships)
  Future<List<FeedActivity>> getFriendsActivities({int offset = 0, int limit = 20}) async {
    // 1. Get friend IDs
    final friendsResponse = await _supabase
        .from('friendships')
        .select('user_id_1, user_id_2')
        .or('user_id_1.eq.$_currentUserId,user_id_2.eq.$_currentUserId')
        .eq('status', 'accepted');

    final friendIds = <String>{};
    for (var row in friendsResponse) {
      final u1 = row['user_id_1'] as String;
      final u2 = row['user_id_2'] as String;
      friendIds.add(u1 == _currentUserId ? u2 : u1);
    }

    if (friendIds.isEmpty) return [];

    // 2. Fetch activities for those IDs
    final response = await _supabase
        .from('activity_sessions')
        .select('*, profiles(*)')
        .inFilter('user_id', friendIds.toList())
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => FeedActivity.fromJson(e)).toList();
  }

  /// Toggle like on an activity
  Future<void> toggleLike(String sessionId, bool isLiking) async {
    // We update the metadata field to increment/decrement like_count
    // Note: In a real production app, you'd use a separate `activity_likes` table to track who liked what.
    // For this phase, we'll increment the JSONB counter via RPC or fetch-update
    
    // Using a simpler fetch-update for now:
    final activity = await _supabase
        .from('activity_sessions')
        .select('metadata')
        .eq('id', sessionId)
        .single();
        
    final metadata = Map<String, dynamic>.from(activity['metadata'] as Map? ?? {});
    int currentLikes = (metadata['like_count'] as num?)?.toInt() ?? 0;
    
    if (isLiking) {
      currentLikes++;
    } else {
      currentLikes = currentLikes > 0 ? currentLikes - 1 : 0;
    }
    
    metadata['like_count'] = currentLikes;
    
    await _supabase
        .from('activity_sessions')
        .update({'metadata': metadata})
        .eq('id', sessionId);
  }
}
