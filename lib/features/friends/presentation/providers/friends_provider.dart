import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf/features/friends/data/social_repository.dart';
import 'package:turf/features/friends/domain/models/friendship.dart';

final socialRepositoryProvider = Provider((ref) => SocialRepository());

final friendsProvider = FutureProvider<List<Friendship>>((ref) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getFriends();
});

final pendingRequestsProvider = FutureProvider<List<Friendship>>((ref) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getPendingRequests();
});
