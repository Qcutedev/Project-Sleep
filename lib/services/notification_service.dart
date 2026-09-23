import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final _plugin = FlutterLocalNotificationsPlugin();

  static const int sleepReminderId = 1;
  static const int dailyReminderId = 2;

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    // v20+ ต้องระบุชื่อพารามิเตอร์ 'settings:'
    await _plugin.initialize(settings: initSettings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // ขอสิทธิ์แจ้งเตือน (Android 13+)
    await androidImpl?.requestNotificationsPermission();

    // ขอสิทธิ์ตั้งปลุกแบบตรงเวลา (Android 12+)
    await androidImpl?.requestExactAlarmsPermission();
  }

  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // v20+ ทุกพารามิเตอร์ต้องระบุชื่อ
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleepwise_reminders',
          'SleepWise Reminders',
          channelDescription: 'การแจ้งเตือนของ SleepWise AI',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // เตือนซ้ำทุกวัน เวลาเดิม
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);
}