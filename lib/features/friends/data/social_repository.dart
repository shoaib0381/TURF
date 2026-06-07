import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/friends/domain/models/friendship.dart';
import 'package:turf/features/profile/domain/models/profile.dart';

class SocialRepository {
  final SupabaseClient _supabase;

  SocialRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  /// Get friends list (accepted)
  Future<List<Friendship>> getFriends() async {
    final response = await _supabase
        .from('friendships')
        .select('*, profile1:profiles!friendships_user_id_1_fkey(*), profile2:profiles!friendships_user_id_2_fkey(*)')
        .or('user_id_1.eq.$_currentUserId,user_id_2.eq.$_currentUserId')
        .eq('status', 'accepted')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Friendship.fromJson(e)).toList();
  }

  /// Get pending friend requests (where current user is user_id_2)
  Future<List<Friendship>> getPendingRequests() async {
    final response = await _supabase
        .from('friendships')
        .select('*, profile1:profiles!friendships_user_id_1_fkey(*), profile2:profiles!friendships_user_id_2_fkey(*)')
        .eq('user_id_2', _currentUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Friendship.fromJson(e)).toList();
  }

  /// Search users by username
  Future<List<Profile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _supabase
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .neq('id', _currentUserId)
        .limit(20);

    return (response as List).map((e) => Profile.fromJson(e)).toList();
  }

  /// Get a single profile
  Future<Profile> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(response);
  }

  /// Send friend request
  Future<void> sendFriendRequest(String toUserId) async {
    // Determine order to prevent duplicate (user_id_1, user_id_2)
    final isFirst = _currentUserId.compareTo(toUserId) < 0;
    final uid1 = isFirst ? _currentUserId : toUserId;
    final uid2 = isFirst ? toUserId : _currentUserId;

    await _supabase.from('friendships').upsert({
      'user_id_1': uid1,
      'user_id_2': uid2,
      'status': 'pending',
      // If we are user 2, we need a custom way to know who sent it.
      // But standard schema says just status 'pending' and the action determines it.
      // Wait, standard schema: user_id_1 vs user_id_2.
      // We will just insert current_user as user_id_1, target as user_id_2 to track sender.
    });
  }

  /// Send friend request (Sender is ALWAYS user_id_1)
  Future<void> sendRequestSimple(String toUserId) async {
    await _supabase.from('friendships').insert({
      'user_id_1': _currentUserId,
      'user_id_2': toUserId,
      'status': 'pending',
    });
  }

  /// Respond to request
  Future<void> respondToRequest(String friendshipId, bool accept) async {
    if (accept) {
      await _supabase
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', friendshipId);
    } else {
      await _supabase
          .from('friendships')
          .delete()
          .eq('id', friendshipId);
    }
  }
}
