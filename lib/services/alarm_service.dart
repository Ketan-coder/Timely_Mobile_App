import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timely/components/custom_snack_bar.dart';
import 'package:timely/services/notification_service.dart';


@pragma('vm:entry-point')
Future<void> printHello() async {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  debugPrint("[$now] Hello, world! isolate=$isolateId function='$printHello'");
}

// This is the top-level function that AndroidAlarmManager will call.  It *must*
// have one of the allowed signatures.  We'll use Function(int, Map<String, dynamic>).
@pragma('vm:entry-point')
Future<void> _alarmCallback(int id, Map<String, dynamic> data) async {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  final String title = data['title'] as String;
  final String body = data['body'] as String;
  //final DateTime alertTime = data['alertTime'] as DateTime;
  DateTime? alertTime;
  if (data['alertTime'] != null) {
    alertTime =
        DateTime.parse(data['alertTime'] as String); // Parse if not null
  } else {
    alertTime = now; //Or set to a default value
  }

  debugPrint("[$now] Alarm with ID $id triggered! isolate=$isolateId");

  // Call the function that actually schedules the notification, passing the data.
  _scheduleNotification(id, title, body, alertTime);
}

// This function now contains the notification scheduling logic.
Future<void> _scheduleNotification(int id, String title, String body,
    DateTime alertTime) async {
  // Initialize the notification plugin (if needed, and only once)
  NotificationService.addManualNotification(id: id,
      title: title,
      body: body,
      scheduledDate: alertTime,
      channelId: 'reminder_channel',
      channelName: 'Reminders',
      channelDescription: 'For Reminder Notifications');
}


@pragma('vm:entry-point')
class AlarmService {
  static const String channelId = 'reminder_channel';
  static const String channelName = 'Reminders';
  static const String channelDescription = 'Channel for Reminder Notifications';

  void setAlarm(DateTime alarmTime, int alarmId, Function alarmCallback,
      String title, String body) async {
    try {
      debugPrint('Attempting to set alarm...');
      debugPrint('Alarm Time: $alarmTime');
      debugPrint('Alarm ID: $alarmId');
      debugPrint('Callback Function: ${alarmCallback.runtimeType}');
      if (!kIsWeb && Platform.isAndroid) {
        bool result = await AndroidAlarmManager.oneShotAt(
          alarmTime,
          alarmId,
          _alarmCallback, // Use the tear-off for the callback function
          alarmClock: true,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          allowWhileIdle: true,
          params: <String, dynamic>{ // Pass the data as a Map
            'title': title,
            'body': body,
            'alertTime': alarmTime.toIso8601String(),
          },
        );

        if (result) {
          debugPrint(
              'Alarm successfully set for: $alarmTime with ID: $alarmId');
        } else {
          debugPrint('Failed to set alarm for: $alarmTime with ID: $alarmId');
        }
      }
    } catch (e) {
      debugPrint('Error while setting alarm: $e');
    }
  }

  void cancelAlarm(int alarmId) async {
    await AndroidAlarmManager.cancel(alarmId);
    debugPrint('Alarm with ID $alarmId cancelled');
  }
}
