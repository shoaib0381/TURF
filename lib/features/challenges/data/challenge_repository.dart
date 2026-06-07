import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/challenges/domain/models/challenge.dart';
import 'package:turf/features/challenges/domain/models/challenge_participant.dart';

class ChallengeRepository {
  final SupabaseClient _supabase;

  ChallengeRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  Future<List<Challenge>> getActiveChallenges() async {
    final now = DateTime.now().toIso8601String();
    final response = await _supabase
        .from('challenges')
        .select()
        .eq('is_public', true)
        .lte('starts_at', now)
        .gt('ends_at', now)
        .order('ends_at', ascending: true);

    return (response as List).map((e) => Challenge.fromJson(e)).toList();
  }

  Future<List<ChallengeParticipant>> getMyChallenges() async {
    final response = await _supabase
        .from('challenge_participants')
        .select('*, challenges(*)')
        .eq('user_id', _currentUserId)
        .order('joined_at', ascending: false);

    return (response as List).map((e) => ChallengeParticipant.fromJson(e)).toList();
  }

  Future<List<ChallengeParticipant>> getChallengeLeaderboard(String challengeId) async {
    final response = await _supabase
        .from('challenge_participants')
        .select('*, profiles(*)')
        .eq('challenge_id', challengeId)
        .order('current_value', ascending: false);

    return (response as List).map((e) => ChallengeParticipant.fromJson(e)).toList();
  }

  Future<void> joinChallenge(String challengeId) async {
    await _supabase.from('challenge_participants').insert({
      'challenge_id': challengeId,
      'user_id': _currentUserId,
    });
  }

  Future<void> leaveChallenge(String challengeId) async {
    await _supabase
        .from('challenge_participants')
        .delete()
        .eq('challenge_id', challengeId)
        .eq('user_id', _currentUserId);
  }

  Future<void> createChallenge(Challenge challenge) async {
    final response = await _supabase.from('challenges').insert(challenge.toJson()).select('id').single();
    
    // Auto join the creator
    await joinChallenge(response['id'] as String);
  }
}
