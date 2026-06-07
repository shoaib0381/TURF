import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/notifications/domain/models/notification.dart';

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  /// Fetch user notifications
  Future<List<AppNotification>> getNotifications({int limit = 50}) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _currentUserId)
        .eq('is_read', false);
  }

  /// Stream unread count
  Stream<int> streamUnreadCount() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId)
        .map((data) => data.where((n) => n['is_read'] == false).length);
  }
}
