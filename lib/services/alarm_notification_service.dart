import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm.dart';
import 'alarm_scheduler_service.dart';

/// จัดการ local notification ที่บอกว่า "มีนาฬิกาปลุกตั้งอยู่"
/// ต่างจาก notification ตอนปลุกดัง (อันนั้นจัดการโดย package `alarm` เอง)
/// อันนี้เป็นแค่ notification เตือนความจำ สรุปสถานะปลุกทั้งหมดที่เปิดอยู่ตอนนี้
class AlarmNotificationService {
  AlarmNotificationService._();
  static final AlarmNotificationService instance = AlarmNotificationService._();

  static const int _setNotificationId = 900;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      await iosImpl.requestPermissions(alert: true, badge: true, sound: false);
    }

    _initialized = true;
  }

  /// เรียกทุกครั้งที่รายการปลุกเปลี่ยน (สร้าง/แก้/ลบ/เปิด-ปิด)
  /// จะคำนวณเองว่าควรโชว์หรือปิด notification โดยดูจากปลุกที่ "เปิดอยู่" ทั้งหมด
  /// - ไม่มีปลุกที่เปิดอยู่เลย -> ปิด notification
  /// - มีอย่างน้อย 1 อัน -> โชว์/อัปเดต notification ให้บอกปลุกถัดไปที่ใกล้ที่สุด
  Future<void> syncWithAlarms(List<SleepAlarm> alarms) async {
    final enabled = alarms.where((a) => a.isEnabled).toList();
    if (enabled.isEmpty) {
      await cancel();
      return;
    }

    DateTime? earliest;
    for (final a in enabled) {
      final dt = AlarmScheduler.nextOccurrenceForAlarm(a);
      if (dt != null && (earliest == null || dt.isBefore(earliest))) {
        earliest = dt;
      }
    }

    if (earliest == null) {
      await cancel();
      return;
    }

    await init();
    final timeStr = '${earliest.hour.toString().padLeft(2, '0')}:${earliest.minute.toString().padLeft(2, '0')}';
    final body = enabled.length > 1
        ? 'Next alarm at $timeStr • ${enabled.length} alarms active'
        : 'Next alarm at $timeStr';

    const androidDetails = AndroidNotificationDetails(
      'alarm_set_channel',
      'Alarm Set',
      channelDescription: 'Notifies you that a wake-up alarm has been set',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: '@drawable/ic_stat_notification',
    );
    const iosDetails = DarwinNotificationDetails(presentSound: false);

    await _plugin.show(
      id: _setNotificationId,
      title: '⏰ Alarm set',
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// แสดง notification ชั่วคราวหลังกด snooze
  /// แยกจาก syncWithAlarms เพราะเวลาที่ snooze ไม่ได้บันทึกลง storage ถ้าคำนวณจาก
  /// รายการปลุกปกติจะได้เวลาผิด (ยังเป็นเวลาเดิมก่อน snooze)
  Future<void> showSnoozeNotification(DateTime wakeDateTime) async {
    await init();
    final timeStr =
        '${wakeDateTime.hour.toString().padLeft(2, '0')}:${wakeDateTime.minute.toString().padLeft(2, '0')}';

    const androidDetails = AndroidNotificationDetails(
      'alarm_set_channel',
      'Alarm Set',
      channelDescription: 'Notifies you that a wake-up alarm has been set',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: '@drawable/ic_stat_notification',
    );
    const iosDetails = DarwinNotificationDetails(presentSound: false);

    await _plugin.show(
      id: _setNotificationId,
      title: '⏰ Alarm set',
      body: 'Snoozed until $timeStr',
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// ยกเลิก notification นี้โดยตรง (ใช้ตอนไม่เหลือปลุกที่เปิดอยู่เลย)
  Future<void> cancel() async {
    await _plugin.cancel(id: _setNotificationId);
  }
}