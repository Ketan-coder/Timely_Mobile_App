import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timely/auth/auth_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

//  This class handles manually tracked notifications
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
    debugPrint('[INIT] Initializing Notification Service...');
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    debugPrint('[INIT] Timezone set to: ${tz.local}');

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    final initialized = await _notificationsPlugin.initialize(
        initializationSettings);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    debugPrint('[INIT] Requesting exact alarms permission...');
    debugPrint('[INIT] Notification plugin initialized: $initialized');

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
    debugPrint('[SCHEDULE] Scheduling Notification → ID: $id');
    debugPrint('[SCHEDULE] Title: $title');
    debugPrint('[SCHEDULE] Body: $body');
    debugPrint('[SCHEDULE] Scheduled Date (raw): $scheduledDate');
    debugPrint('[SCHEDULE] Scheduled Date (tz): $tzDate');

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

      debugPrint('[SCHEDULE] Notification scheduled successfully.');
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      debugPrint('[DEBUG] Total Pending Notifications: ${pending.length}');
      for (var n in pending) {
        debugPrint('[DEBUG] Pending → ID: ${n.id}, Title: ${n.title}, Body: ${n
            .body}');
      }
    } catch (e) {
      debugPrint('[ERROR] Failed to schedule notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint('[CANCEL] Notification ID $id cancelled.');
  }

  static Future<void> requestExactAlarmsPermission() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? granted = await androidImplementation?.requestExactAlarmsPermission();
    if (granted == true) {
      debugPrint('[PERMISSION] Exact alarms permission granted.');
    } else {
      debugPrint('[PERMISSION] Exact alarms permission not granted.');
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
    debugPrint('[CHANNEL] Notification channel created.');
  }

  static Future<void> testImmediateNotification() async {
    debugPrint('[TEST] Showing immediate test notification...');
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
    String channelDescription = 'Channel for scheduled notifications',
    bool showWhen = true,
    bool onGoing = false,
    bool autoCancel = true,
    bool enableVibration = true,
    bool playSound = true,
    Int64List? vibrationPattern,
    List<AndroidNotificationAction>? actions = const []
  }) async {
    final now = DateTime.now();
    final delay = scheduledDate.difference(now);

    if (delay.isNegative) {
      debugPrint(
          '[SCHEDULE] Scheduled time is in the past. Skipping notification.');
      return;
    }

    debugPrint(
        '[SCHEDULE] Notification will show in ${delay.inSeconds} seconds');

    Future.delayed(delay, () async {
      debugPrint('[SCHEDULE] Showing scheduled notification now...');
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
          showWhen: showWhen,
          ongoing: onGoing,
          autoCancel: autoCancel,
          enableVibration: enableVibration,
          vibrationPattern: vibrationPattern ?? Int64List.fromList([0, 500, 200, 500]), // Custom vibration pattern
          playSound: playSound,
          actions: actions,
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
    debugPrint('[MANUAL] Added ID $id for scheduled show at $scheduledDate');
  }

  // ✅ Periodically check pending ones
  static void startManualNotificationMonitor({Duration interval = const Duration(seconds: 5)}) {
    Timer.periodic(interval, (timer) async {
      final now = DateTime.now();
      for (var n in _manualNotifications) {
        if (!n.isShown && n.scheduledDate.isBefore(now)) {
          final isCompleted = await AuthService.checkIfReminderIsCompleted(
              n.id);
          debugPrint('[MANUAL] Checking reminder ${n.id} status...');
          debugPrint('[MANUAL] Reminder ${n.id} status: ${isCompleted
              ? 'Completed'
              : 'Not Completed'}');
          n.channelName == "Reminders" ? debugPrint('[YES]') : debugPrint(
              '[NO]');
          // If the reminder is not completed, show the notification
          if (!isCompleted) {
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
                  showWhen: n.channelName == "Reminders" ? true : false,
                  ongoing: n.channelName == "Reminders" ? true : false,
                  autoCancel: n.channelName == "Reminders" ? false : true,
                  enableVibration: n.channelName == "Reminders" ? true : false,
                  vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
                  // Custom vibration pattern
                  playSound: n.channelName == "Reminders" ? true : false,
                  category: AndroidNotificationCategory.reminder,
                  actions: [
                    // AndroidNotificationAction(
                    //   'Complete',
                    //   'Complete',
                    //   showsUserInterface: true,
                    // ),
                    AndroidNotificationAction(
                      'DISMISS',
                      'Dismiss',
                      showsUserInterface: true,
                    ),
                  ],
                ),
              ),
            );
            debugPrint('[MANUAL] Notification shown → ID: ${n.id}');
            n.isShown = true;
          } else {
            debugPrint(
                '[MANUAL] Reminder ${n.id} already completed. Skipping...');
            n.isShown = true;
          }
        }
      }

      _manualNotifications.removeWhere((n) => n.isShown);
    });

    debugPrint('[MONITOR] Started manual notification checker every ${interval
        .inSeconds} seconds.');
  }
}