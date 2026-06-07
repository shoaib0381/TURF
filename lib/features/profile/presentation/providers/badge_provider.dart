import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf/features/profile/data/badge_repository.dart';
import 'package:turf/features/profile/domain/models/badge.dart';
import 'package:turf/features/profile/domain/models/user_badge.dart';

final badgeRepositoryProvider = Provider((ref) => BadgeRepository());

final allBadgesProvider = FutureProvider<List<Badge>>((ref) async {
  return ref.watch(badgeRepositoryProvider).getAllBadges();
});

final userBadgesProvider = FutureProvider.family<List<UserBadge>, String>((ref, userId) async {
  return ref.watch(badgeRepositoryProvider).getUserBadges(userId);
});
