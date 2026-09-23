import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

/// จัดการบันทึก/โหลดรายการปลุกทั้งหมดแบบถาวร (persist ข้ามการปิดแอป)
class AlarmStorageService {
  AlarmStorageService._();
  static final AlarmStorageService instance = AlarmStorageService._();

  static const _storageKey = 'sleep_alarms_v1';

  Future<List<SleepAlarm>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    return raw
        .map((s) => SleepAlarm.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAlarms(List<SleepAlarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = alarms.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  /// เพิ่มปลุกใหม่ หรืออัปเดตปลุกเดิม (แมตช์ด้วย id)
  Future<void> upsertAlarm(SleepAlarm alarm) async {
    final alarms = await loadAlarms();
    final idx = alarms.indexWhere((a) => a.id == alarm.id);
    if (idx >= 0) {
      alarms[idx] = alarm;
    } else {
      alarms.add(alarm);
    }
    await saveAlarms(alarms);
  }

  Future<void> deleteAlarm(int id) async {
    final alarms = await loadAlarms();
    alarms.removeWhere((a) => a.id == id);
    await saveAlarms(alarms);
  }

  /// สร้าง id ใหม่ที่ไม่ซ้ำ ใช้ตอนสร้างปลุกอันใหม่
  int generateId() => DateTime.now().millisecondsSinceEpoch.remainder(1000000);
}