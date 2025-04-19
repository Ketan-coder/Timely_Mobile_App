import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timely/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> printHello(
  int alarmId,
  String title,
  String body,
  String channelId,
  String channelName,
  DateTime alarmTime,
) async {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  print("[$now] Hello, world! isolate=${isolateId} function='$printHello'");
  NotificationService.scheduleUsingShow(
    id: alarmId,
    title: title,
    body: body,
    scheduledDate: alarmTime,
    channelId: channelId,
    channelName: channelName,
    channelDescription: 'Alarm Notification',
    onGoing: true,
    autoCancel: false,
    enableVibration: true,
    playSound: true,
    vibrationPattern: Int64List.fromList([0, 500, 200, 500]), // Custom vibration pattern
    actions: [
      AndroidNotificationAction(
        'SNOOZE',
        'Snooze',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        'DISMISS',
        'Dismiss',
        showsUserInterface: true,
      ),
    ],
  );
}

@pragma('vm:entry-point')
class AlarmService {
  static const String channelId = 'alarm_channel';
  static const String channelName = 'Alarm Channel';
  static const String channelDescription = 'Channel for Alarm Notifications';

  void setAlarm(DateTime alarmTime, int alarmId, Function alarmCallback, String title, String body) async {
    try {
      print('Attempting to set alarm...');
      print('Alarm Time: $alarmTime');
      print('Alarm ID: $alarmId');
      print('Callback Function: ${printHello.runtimeType}');

      bool result = await AndroidAlarmManager.oneShotAt(
        alarmTime,
        alarmId,
        (int id) => printHello(
          id,
          title,
          body,
          channelId,
          channelName,
          alarmTime,
        ), // Use the tear-off for the callback function
        alarmClock: true,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );

      if (result) {
        print('Alarm successfully set for: $alarmTime with ID: $alarmId');
      } else {
        print('Failed to set alarm for: $alarmTime with ID: $alarmId');
      }
    } catch (e) {
      print('Error while setting alarm: $e');
    }
  }

  void cancelAlarm() {
    // Cancel the scheduled alarm
    // This is a placeholder implementation; actual cancellation logic goes here
    print('Alarm cancelled');
  }
}
