import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/auth/presentation/splash_screen.dart';
import 'package:turf/features/auth/presentation/onboarding_screen.dart';
import 'package:turf/features/auth/presentation/auth_screen.dart';
import 'package:turf/features/auth/presentation/profile_setup_screen.dart';
import 'package:turf/features/home/presentation/home_screen.dart';
import 'package:turf/features/map/presentation/map_screen.dart';
import 'package:turf/features/activity/presentation/activity_feed_screen.dart';
import 'package:turf/features/activity/presentation/live_activity_screen.dart';
import 'package:turf/features/activity/presentation/activity_detail_screen.dart';
import 'package:turf/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:turf/features/profile/presentation/profile_screen.dart';
import 'package:turf/features/profile/presentation/public_profile_screen.dart';
import 'package:turf/features/profile/presentation/settings_screen.dart';
import 'package:turf/features/challenges/presentation/challenge_detail_screen.dart';
import 'package:turf/features/friends/presentation/friends_screen.dart';
import 'package:turf/features/goals/presentation/goals_screen.dart';
import 'package:turf/features/notifications/presentation/notifications_screen.dart';
import 'package:turf/features/activity/presentation/countdown_screen.dart' as turf_countdown;
import 'package:turf/features/activity/presentation/activity_summary_screen.dart' as turf_summary;
import 'package:turf/features/activity/domain/models/activity_session.dart' as turf_models;
import 'package:turf/features/profile/domain/models/profile.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return HomeScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/home/map',
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: '/home/activity',
          builder: (context, state) => const ActivityFeedScreen(),
        ),
        GoRoute(
          path: '/home/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: '/home/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/activity/live',
      parentNavigatorKey: _rootNavigatorKey, // Full screen, no bottom nav
      builder: (context, state) => const LiveActivityScreen(),
    ),
    GoRoute(
      path: '/activity/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ActivityDetailScreen(),
    ),
    GoRoute(
      path: '/challenge/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChallengeDetailScreen(),
    ),
    GoRoute(
      path: '/profile/:userId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final profile = state.extra as Profile;
        return PublicProfileScreen(profile: profile);
      },
    ),
    GoRoute(
      path: '/friends',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FriendsScreen(),
    ),
    GoRoute(
      path: '/goals',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GoalsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),),
    GoRoute(
      path: '/activity/countdown',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const turf_countdown.CountdownScreen(),
    ),
    GoRoute(
      path: '/activity/summary',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final session = state.extra as turf_models.ActivitySession;
        return turf_summary.ActivitySummaryScreen(session: session);
      },
    ),
  ],
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthRoute = state.matchedLocation == '/auth' || state.matchedLocation == '/onboarding' || state.matchedLocation == '/splash';

    // Let splash and onboarding handle themselves or bypass auth check initially
    if (state.matchedLocation == '/splash' || state.matchedLocation == '/onboarding') {
      return null;
    }

    if (session == null && !isAuthRoute) {
      return '/auth';
    }

    if (session != null && isAuthRoute) {
      // User is logged in but trying to access auth pages
      // Ideally, check if profile exists here, but we'll let splash/auth screens do the deep check
      // For now, redirect to map
      return '/home/map';
    }

    return null;
  },
);
