import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ✅ This class handles manually tracked notifications
class _PendingNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String channelId;
  final String channelName;
  final String channelDescription;
  bool isShown;

  _PendingNotification( {
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    this.isShown = false,
  });
}


class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final List<_PendingNotification> _manualNotifications = [];

  static Future<void> initialize() async {
    print('[INIT] Initializing Notification Service...');
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    print('[INIT] Timezone set to: ${tz.local}');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    final initialized = await _notificationsPlugin.initialize(initializationSettings);
    await _notificationsPlugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.requestExactAlarmsPermission();
    print('[INIT] Requesting exact alarms permission...');
    print('[INIT] Notification plugin initialized: $initialized');

    await requestExactAlarmsPermission();
    await createNotificationChannel();
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    print('[SCHEDULE] Scheduling Notification → ID: $id');
    print('[SCHEDULE] Title: $title');
    print('[SCHEDULE] Body: $body');
    print('[SCHEDULE] Scheduled Date (raw): $scheduledDate');
    print('[SCHEDULE] Scheduled Date (tz): $tzDate');

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Channel for reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('[SCHEDULE] Notification scheduled successfully.');
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      print('[DEBUG] Total Pending Notifications: ${pending.length}');
      for (var n in pending) {
        print('[DEBUG] Pending → ID: ${n.id}, Title: ${n.title}, Body: ${n.body}');
      }
    } catch (e) {
      print('[ERROR] Failed to schedule notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    print('[CANCEL] Notification ID $id cancelled.');
  }

  static Future<void> requestExactAlarmsPermission() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? granted = await androidImplementation?.requestExactAlarmsPermission();
    if (granted == true) {
      print('[PERMISSION] Exact alarms permission granted.');
    } else {
      print('[PERMISSION] Exact alarms permission not granted.');
    }
  }

  static Future<void> createNotificationChannel() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'reminder_channel',
        'Reminders',
        description: 'Channel for reminder notifications',
        importance: Importance.max,
      ),
    );
    print('[CHANNEL] Notification channel created.');
  }

  static Future<void> testImmediateNotification() async {
    print('[TEST] Showing immediate test notification...');
    await _notificationsPlugin.show(
      99,
      'Immediate Test',
      'This should appear instantly 🔔',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test',
          channelDescription: 'Test notification channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> scheduleUsingShow({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  required String channelId,
  required String channelName,
}) async {
  final now = DateTime.now();
  final delay = scheduledDate.difference(now);

  if (delay.isNegative) {
    print('[SCHEDULE] Scheduled time is in the past. Skipping notification.');
    return;
  }

  print('[SCHEDULE] Notification will show in ${delay.inSeconds} seconds');

  Future.delayed(delay, () async {
    print('[SCHEDULE] Showing scheduled notification now...');
    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Channel for scheduled notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  });
}


  // ✅ Add manual notification to check periodically
  static void addManualNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    _manualNotifications.add(_PendingNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
    ));
    print('[MANUAL] Added ID $id for scheduled show at $scheduledDate');
  }

  // ✅ Periodically check pending ones
  static void startManualNotificationMonitor({Duration interval = const Duration(seconds: 5)}) {
    Timer.periodic(interval, (timer) async {
      final now = DateTime.now();
      for (var n in _manualNotifications) {
        if (!n.isShown && n.scheduledDate.isBefore(now)) {
          await _notificationsPlugin.show(
            n.id,
            n.title,
            n.body,
             NotificationDetails(
              android: AndroidNotificationDetails(
                n.channelId,
                n.channelName,
                channelDescription: n.channelDescription,
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
          print('[MANUAL] Notification shown → ID: ${n.id}');
          n.isShown = true;
        }
      }

      _manualNotifications.removeWhere((n) => n.isShown);
    });

    print('[MONITOR] Started manual notification checker every ${interval.inSeconds} seconds.');
  }
}