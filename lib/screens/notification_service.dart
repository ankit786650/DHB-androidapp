import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required bool playSound,
    String payload = '', required UILocalNotificationDateInterpretation,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'med_channel',
          'Medication Reminders',
          channelDescription: 'Channel for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: playSound,
          sound: playSound ? RawResourceAndroidNotificationSound('alarm_sound') : null, // alarm_sound.mp3 in res/raw
        ),
        iOS: DarwinNotificationDetails(
          presentSound: playSound,
          sound: playSound ? 'alarm_sound.mp3' : null, // alarm_sound.mp3 in Xcode project
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      // Do NOT add uiLocalNotificationDateInterpretation or dateInterpretation unless your plugin version supports it!
      // If you want to support recurring notifications, use matchDateTimeComponents.
    );
  }
}