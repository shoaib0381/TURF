import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf/features/friends/data/social_repository.dart';
import 'package:turf/features/friends/domain/models/friendship.dart';
import 'package:turf/features/profile/domain/models/profile.dart';

final socialRepositoryProvider = Provider((ref) => SocialRepository());

final friendsProvider = FutureProvider<List<Friendship>>((ref) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getFriends();
});

final pendingRequestsProvider = FutureProvider<List<Friendship>>((ref) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getPendingRequests();
});

final outgoingRequestsProvider = FutureProvider<List<Friendship>>((ref) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getOutgoingRequests();
});

final discoverUsersProvider = FutureProvider<List<Profile>>((ref) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getDiscoverUsers();
});
