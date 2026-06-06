import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // In a real app, this would wake up, fetch location, and update Supabase.
    // However, continuous tracking is better handled by Foreground Services.
    // This serves as the background execution boilerplate requested.
    
    if (task == "location_update_task") {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // We could insert into Supabase here
      print("Background location fetch: ${position.latitude}, ${position.longitude}");
      
      // Update notification
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'tracking_channel',
        'Live Tracking',
        channelDescription: 'Ongoing activity tracking',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
      
      await flutterLocalNotificationsPlugin.show(
        888,
        'TURF - Tracking Active',
        'Fetching in background...',
        platformDetails,
      );
    }
    return Future.value(true);
  });
}

class BackgroundTrackingService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> startTrackingTask() async {
    await Workmanager().registerPeriodicTask(
      "1",
      "location_update_task",
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    
    // Show immediate notification
    await showTrackingNotification("TURF - Tracking your activity", "0.0 km | 00:00");
  }

  static Future<void> stopTrackingTask() async {
    await Workmanager().cancelByUniqueName("1");
    await flutterLocalNotificationsPlugin.cancel(888);
  }

  static Future<void> showTrackingNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tracking_channel',
      'Live Tracking',
      channelDescription: 'Ongoing activity tracking',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      888,
      title,
      body,
      platformDetails,
    );
  }
}
