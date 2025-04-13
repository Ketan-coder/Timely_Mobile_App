import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({Key? key}) : super(key: key);

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'test_channel', // ID
      'Test', // Name
      description: 'Channel for reminder notifications', // Description
      importance: Importance.max, // Importance level
    );
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    try {
      await _notificationsPlugin.initialize(initializationSettings);
      await _requestPermissions(); // Request permissions during initialization
      await _createNotificationChannel();
      setState(() {
        _initialized = true;
      });
      debugPrint('[INFO] Notification service initialized successfully.');
    } catch (e) {
      debugPrint('[ERROR] Notification initialization failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) {
      debugPrint('[INFO] Notifications permissions granted.');
    } else if (status.isDenied) {
      debugPrint('[WARN] Notifications permissions denied.');
      // You might want to show a dialog explaining why you need permissions
    } else if (status.isPermanentlyDenied) {
      debugPrint(
        '[WARN] Notifications permissions permanently denied. Please enable in app settings.',
      );
      openAppSettings(); // Opens the app settings page
    }
  }

  Future<void> _scheduleNotification() async {
    if (!_initialized) {
      debugPrint('[WARN] Notification service not initialized.');
      return;
    }

    try {
      final scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(seconds: 30));

      final AndroidNotificationDetails androidNotificationDetails =
          const AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Channel for reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        1001,
        '🔔 Test Notification',
        'This was scheduled 30 seconds ago.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Channel for reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      debugPrint('[Scheduled] Notification at: $scheduledDate');
      debugPrint('Device time: ${DateTime.now()}');
    } catch (e) {
      debugPrint('[ERROR] Notification scheduling failed: $e');
    }
  }

  Future<void> _cancelNotification() async {
    await _notificationsPlugin.cancel(1001);
    debugPrint('[Cancelled] Notification ID: 1001');
  }

  Future<void> _cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('[Cancelled] All Notifications');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Tester')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _scheduleNotification,
              child: const Text('📆 Schedule Test Notification (30s)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cancelNotification,
              child: const Text('❌ Cancel Notification ID 1001'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cancelAllNotifications,
              child: const Text('❌ Cancel All Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}
