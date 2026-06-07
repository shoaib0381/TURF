import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:turf/features/notifications/domain/models/notification.dart';
import 'package:turf/features/notifications/presentation/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationRepositoryProvider).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF00E676)),
            onPressed: () {
              ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
        error: (e, _) => Center(child: Text('Error loading notifications', style: const TextStyle(color: Colors.red))),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text("You have no notifications.", style: TextStyle(color: Colors.white54)));
          }

          return RefreshIndicator(
            color: const Color(0xFF00E676),
            backgroundColor: const Color(0xFF1C1C1E),
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () {
                    // Mark single as read (even though we marked all as read on init, good practice)
                    if (!notification.isRead) {
                      ref.read(notificationRepositoryProvider).markAsRead(notification.id);
                    }
                    _handleNotificationTap(context, notification);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    switch (notification.type) {
      case 'friend_request':
        // Navigate to friends screen, requests tab
        context.push('/home/friends');
        break;
      case 'territory_stolen':
        // Navigate to map (ideally centered on the territory)
        context.push('/home/map');
        break;
      case 'challenge_invite':
        // Navigate to challenges
        context.push('/home/challenges');
        break;
      case 'badge_earned':
        // Navigate to profile
        context.push('/home/profile');
        break;
      case 'goal_completed':
        // Navigate to goals
        context.push('/home/profile'); // Assuming goals are on profile for now
        break;
      case 'leaderboard_rank':
        context.push('/home/leaderboard');
        break;
      default:
        break;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? const Color(0xFF141414) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? Colors.white10 : const Color(0xFF00E676).withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIconData(notification.type), color: _getIconColor(notification.type), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.content,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(timeago.format(notification.createdAt), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String type) {
    switch (type) {
      case 'friend_request': return Icons.person_add;
      case 'territory_stolen': return Icons.flag;
      case 'challenge_invite': return Icons.emoji_events;
      case 'badge_earned': return Icons.military_tech;
      case 'goal_completed': return Icons.check_circle;
      case 'leaderboard_rank': return Icons.leaderboard;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'friend_request': return const Color(0xFF00B0FF);
      case 'territory_stolen': return const Color(0xFFFF453A);
      case 'challenge_invite': return const Color(0xFFFF9100);
      case 'badge_earned': return const Color(0xFFFFD600);
      case 'goal_completed': return const Color(0xFF00E676);
      case 'leaderboard_rank': return const Color(0xFFE040FB);
      default: return Colors.white;
    }
  }
}
