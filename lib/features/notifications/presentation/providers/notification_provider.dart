import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf/features/notifications/data/notification_repository.dart';
import 'package:turf/features/notifications/domain/models/notification.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications();
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.streamUnreadCount();
});
