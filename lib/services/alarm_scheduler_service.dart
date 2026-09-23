import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import '../models/alarm.dart';

/// คำนวณเวลาปลุกครั้งถัดไปตาม repeat days จริง และจัดการ native alarm (ผ่านแพ็กเกจ alarm)
///
/// เนื่องจากแพ็กเกจ alarm ตั้งได้แค่ครั้งเดียวต่อ 1 id (ไม่รองรับ repeat ในตัว)
/// ถ้าปลุกอันหนึ่งเลือกหลายวัน จะสร้าง native alarm แยกกันหนึ่งอันต่อหนึ่งวันที่เลือก
/// โดยใช้สูตร id = (alarm.id * 10) + weekday เพื่อไม่ให้ id ชนกัน
class AlarmScheduler {
  static int nativeIdFor(int alarmId, int weekday) => alarmId * 10 + weekday;

  /// หา DateTime ของ "วันซ้ำ" (weekday) ครั้งถัดไปที่ยังไม่ผ่านไป เทียบกับเวลาที่ตั้ง
  static DateTime nextOccurrenceForWeekday(TimeOfDay time, int weekday, {DateTime? now}) {
    final n = now ?? DateTime.now();
    var d = DateTime(n.year, n.month, n.day, time.hour, time.minute);
    while (d.weekday != weekday || !d.isAfter(n)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  static DateTime _nextOneTimeOccurrence(TimeOfDay time, {DateTime? now}) {
    final n = now ?? DateTime.now();
    var d = DateTime(n.year, n.month, n.day, time.hour, time.minute);
    if (!d.isAfter(n)) d = d.add(const Duration(days: 1));
    return d;
  }

  /// หาเวลาปลุกครั้งถัดไปของปลุกอันนี้ (ใช้แสดงผลใน notification/UI)
  /// คืนค่า null ถ้าปลุกนี้ปิดอยู่
  static DateTime? nextOccurrenceForAlarm(SleepAlarm alarm) {
    if (!alarm.isEnabled) return null;
    if (alarm.repeatDays.isEmpty) {
      return _nextOneTimeOccurrence(alarm.wakeTime);
    }
    DateTime? earliest;
    for (final day in alarm.repeatDays) {
      final dt = nextOccurrenceForWeekday(alarm.wakeTime, day);
      if (earliest == null || dt.isBefore(earliest)) earliest = dt;
    }
    return earliest;
  }

  /// ตั้ง native alarm ทั้งหมดของปลุกอันนี้ตามค่า isEnabled/repeatDays ปัจจุบัน
  static Future<void> scheduleAlarm(SleepAlarm alarm) async {
    if (!alarm.isEnabled) {
      await cancelAlarm(alarm);
      return;
    }
    if (alarm.repeatDays.isEmpty) {
      await _setNative(alarm.id, _nextOneTimeOccurrence(alarm.wakeTime));
    } else {
      for (final day in alarm.repeatDays) {
        await _setNative(
          nativeIdFor(alarm.id, day),
          nextOccurrenceForWeekday(alarm.wakeTime, day),
        );
      }
    }
  }

  static Future<void> _setNative(int nativeId, DateTime dateTime) async {
    final settings = AlarmSettings(
      id: nativeId,
      dateTime: dateTime,
      assetAudioPath: null,
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: const Duration(seconds: 5),
      ),
      notificationSettings: const NotificationSettings(
        title: 'Sleep Cycle Alarm',
        body: 'Time to wake up!',
        stopButton: 'Stop',
      ),
    );
    await Alarm.set(alarmSettings: settings);
  }

  /// ยกเลิก native alarm ทั้งหมดของปลุกอันนี้ (ใช้ตอนปิด/ลบปลุก)
  static Future<void> cancelAlarm(SleepAlarm alarm) async {
    if (alarm.repeatDays.isEmpty) {
      await Alarm.stop(alarm.id);
    } else {
      for (final day in alarm.repeatDays) {
        await Alarm.stop(nativeIdFor(alarm.id, day));
      }
    }
  }

  /// เรียกทุกครั้งที่เปิดหน้ารายการปลุก:
  /// - ปลุกครั้งเดียว (ไม่ repeat) ที่เวลาผ่านไปแล้ว -> ปิดอัตโนมัติ
  /// - ปลุกแบบ repeat -> คำนวณ/ตั้งเวลาครั้งถัดไปใหม่เสมอ (ปลอดภัยเรียกซ้ำได้)
  static Future<List<SleepAlarm>> reconcile(List<SleepAlarm> alarms) async {
    final now = DateTime.now();
    for (final a in alarms) {
      if (!a.isEnabled) continue;
      if (a.repeatDays.isEmpty) {
        final dt = DateTime(now.year, now.month, now.day, a.wakeTime.hour, a.wakeTime.minute);
        if (dt.isBefore(now)) {
          a.isEnabled = false;
          await cancelAlarm(a);
        }
      } else {
        await scheduleAlarm(a);
      }
    }
    return alarms;
  }
}