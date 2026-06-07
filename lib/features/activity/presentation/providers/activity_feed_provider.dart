import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/activity/data/feed_repository.dart';
import 'package:turf/features/activity/domain/models/feed_activity.dart';

final feedRepositoryProvider = Provider((ref) => FeedRepository());

class ActivityFeedState {
  final List<FeedActivity> myActivities;
  final List<FeedActivity> friendsActivities;
  final bool isLoading;
  final bool hasNewFriendsActivity;

  ActivityFeedState({
    this.myActivities = const [],
    this.friendsActivities = const [],
    this.isLoading = false,
    this.hasNewFriendsActivity = false,
  });

  ActivityFeedState copyWith({
    List<FeedActivity>? myActivities,
    List<FeedActivity>? friendsActivities,
    bool? isLoading,
    bool? hasNewFriendsActivity,
  }) {
    return ActivityFeedState(
      myActivities: myActivities ?? this.myActivities,
      friendsActivities: friendsActivities ?? this.friendsActivities,
      isLoading: isLoading ?? this.isLoading,
      hasNewFriendsActivity: hasNewFriendsActivity ?? this.hasNewFriendsActivity,
    );
  }
}

class ActivityFeedNotifier extends Notifier<ActivityFeedState> {
  late final FeedRepository _repository;
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _subscription;

  @override
  ActivityFeedState build() {
    _repository = ref.watch(feedRepositoryProvider);
    ref.onDispose(() {
      _subscription?.unsubscribe();
    });
    _init();
    return ActivityFeedState();
  }

  void _init() {
    // Avoid running async init during build phase directly, push to next frame
    Future.microtask(() {
      loadInitialData();
      _subscribeToNewActivities();
    });
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final myActs = await _repository.getMyActivities(limit: 20);
      final friendActs = await _repository.getFriendsActivities(limit: 20);
      
      state = state.copyWith(
        myActivities: myActs,
        friendsActivities: friendActs,
        isLoading: false,
        hasNewFriendsActivity: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMoreMyActivities() async {
    if (state.isLoading) return;
    try {
      final nextBatch = await _repository.getMyActivities(
        offset: state.myActivities.length,
        limit: 20,
      );
      state = state.copyWith(
        myActivities: [...state.myActivities, ...nextBatch],
      );
    } catch (_) {}
  }

  Future<void> loadMoreFriendsActivities() async {
    if (state.isLoading) return;
    try {
      final nextBatch = await _repository.getFriendsActivities(
        offset: state.friendsActivities.length,
        limit: 20,
      );
      state = state.copyWith(
        friendsActivities: [...state.friendsActivities, ...nextBatch],
      );
    } catch (_) {}
  }

  void clearNewActivityBadge() {
    state = state.copyWith(hasNewFriendsActivity: false);
    loadInitialData(); // Refresh to get the new activity
  }

  void _subscribeToNewActivities() {
    _subscription = _supabase
        .channel('public:activity_sessions')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'activity_sessions',
          callback: (payload) {
            final newSessionUserId = payload.newRecord['user_id'] as String;
            if (newSessionUserId != _supabase.auth.currentUser?.id) {
              // It's possible a friend inserted it. For this phase, we just set the badge.
              // A full implementation would check if newSessionUserId is actually a friend.
              state = state.copyWith(hasNewFriendsActivity: true);
            }
          },
        )
        .subscribe();
  }

  Future<void> toggleLike(String sessionId, bool isLiking) async {
    try {
      await _repository.toggleLike(sessionId, isLiking);
      // Refresh to update local counts
      loadInitialData();
    } catch (_) {}
  }

  }

final activityFeedProvider = NotifierProvider<ActivityFeedNotifier, ActivityFeedState>(() {
  return ActivityFeedNotifier();
});
