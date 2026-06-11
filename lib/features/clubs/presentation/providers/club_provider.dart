import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf/features/clubs/data/club_repository.dart';
import 'package:turf/features/clubs/domain/models/club.dart';
import 'package:turf/features/clubs/domain/models/club_member.dart';
import 'package:turf/features/clubs/domain/models/club_request.dart';
import 'package:turf/features/clubs/domain/models/club_activity.dart';

final clubRepositoryProvider = Provider((ref) => ClubRepository());

final myClubsProvider = StreamProvider<List<Club>>((ref) {
  final repo = ref.watch(clubRepositoryProvider);
  return repo.getMyClubs();
});

final discoverClubsProvider = FutureProvider<List<Club>>((ref) async {
  final repo = ref.watch(clubRepositoryProvider);
  return repo.getPublicClubs();
});

final clubDetailProvider = FutureProvider.family<Club, String>((ref, clubId) async {
  final repo = ref.watch(clubRepositoryProvider);
  return repo.getClub(clubId);
});

final clubMembersProvider = StreamProvider.family<List<ClubMember>, String>((ref, clubId) {
  final repo = ref.watch(clubRepositoryProvider);
  return repo.getClubMembers(clubId);
});

final clubActivitiesProvider = StreamProvider.family<List<ClubActivity>, String>((ref, clubId) {
  final repo = ref.watch(clubRepositoryProvider);
  return repo.getClubActivities(clubId);
});

final clubRequestsProvider = FutureProvider.family<List<ClubRequest>, String>((ref, clubId) async {
  final repo = ref.watch(clubRepositoryProvider);
  return repo.getPendingRequests(clubId);
});
