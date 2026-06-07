import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/profile/domain/models/badge.dart';
import 'package:turf/features/profile/domain/models/user_badge.dart';

class BadgeRepository {
  final SupabaseClient _supabase;

  BadgeRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<List<Badge>> getAllBadges() async {
    final response = await _supabase.from('badges').select().order('required_value', ascending: true);
    return (response as List).map((e) => Badge.fromJson(e)).toList();
  }

  Future<List<UserBadge>> getUserBadges(String userId) async {
    final response = await _supabase
        .from('user_badges')
        .select('*, badges(*)')
        .eq('user_id', userId)
        .order('earned_at', ascending: false);

    return (response as List).map((e) => UserBadge.fromJson(e)).toList();
  }
}
