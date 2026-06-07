import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf/features/challenges/data/challenge_repository.dart';
import 'package:turf/features/challenges/domain/models/challenge.dart';
import 'package:turf/features/challenges/domain/models/challenge_participant.dart';

final challengeRepositoryProvider = Provider((ref) => ChallengeRepository());

final activeChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.getActiveChallenges();
});

final myChallengesProvider = FutureProvider<List<ChallengeParticipant>>((ref) async {
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.getMyChallenges();
});

final challengeLeaderboardProvider = FutureProvider.family<List<ChallengeParticipant>, String>((ref, challengeId) async {
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.getChallengeLeaderboard(challengeId);
});
