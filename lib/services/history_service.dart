import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sleep_result.dart';
import 'sleep_stats.dart';

/// เก็บผลการประเมินแต่ละครั้งไว้ในเครื่อง (local storage)
/// ใช้ package shared_preferences ซึ่งเก็บเป็น key-value ง่ายๆ
/// ไม่ต้องมี database หรือ backend เพิ่ม เหมาะกับ prototype
///
/// ใช้ข้อมูลนี้วาดกราฟเทรนด์และคำนวณ streak ในหน้า Home
class HistoryService {
  static const _storageKey = 'sleep_history_v1';

  /// บันทึกผลลัพธ์ใหม่ โดยเก็บผลได้วันละ 1 รายการ
  /// ถ้าวันเดียวกันมีผลอยู่แล้ว (รวมถึงข้อมูลเก่าที่มีหลายรายการต่อวัน)
  /// จะถูกลบและแทนที่ด้วยผลใหม่
  Future<void> saveDailyResult(SleepResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    final day = dateOnly(result.timestamp);
    history.removeWhere((r) => dateOnly(r.timestamp) == day);
    history.add(result);
    final jsonList = history.map((r) => r.toStorageJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// อ่านประวัติทั้งหมด เรียงจากเก่าไปใหม่
  Future<List<SleepResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => SleepResult.fromStorageJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // ถ้าข้อมูลเก่าอ่านไม่ได้ (เช่นแก้โครงสร้างระหว่างพัฒนา) ให้เริ่มใหม่
      // แทนที่จะทำให้ทั้งแอปพัง
      return [];
    }
  }

  /// ลบผลลัพธ์ 1 รายการ (ใช้เมื่อกดถังขยะที่รายการใน Recent check-ins)
  /// ใช้ timestamp เทียบหาว่าเป็นรายการไหน เพราะแต่ละครั้งมีเวลาไม่ซ้ำกัน
  Future<void> deleteResult(SleepResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.removeWhere((r) => r.timestamp == result.timestamp);
    final jsonList = history.map((r) => r.toStorageJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// ลบประวัติทั้งหมด (ใช้ตอนเทส หรือถ้าอยากมีปุ่ม reset)
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
