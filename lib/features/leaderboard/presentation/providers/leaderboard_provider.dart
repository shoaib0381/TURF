import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/leaderboard/data/leaderboard_repository.dart';
import 'package:turf/features/leaderboard/domain/models/leaderboard_entry.dart';

final leaderboardRepositoryProvider = Provider((ref) => LeaderboardRepository());

final leaderboardTypeProvider = StateProvider<String>((ref) => 'weekly_distance');
final leaderboardScopeProvider = StateProvider<String>((ref) => 'global'); // 'global' or 'friends'

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final type = ref.watch(leaderboardTypeProvider);
  final scope = ref.watch(leaderboardScopeProvider);

  if (scope == 'global') {
    return repo.getGlobalLeaderboard(type);
  } else {
    return repo.getFriendsLeaderboard(type);
  }
});
