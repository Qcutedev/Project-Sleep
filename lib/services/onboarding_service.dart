import 'package:shared_preferences/shared_preferences.dart';

/// จำว่าผู้ใช้ผ่านหน้าแนะนำแอปแล้วหรือยัง
class OnboardingService {
  OnboardingService._();

  static const _kDone = 'onboarding_done';
  static const _kHistory = 'sleep_history_v1';

  /// อ่านครั้งเดียวตอนเริ่มแอป (ใน main) หน้า Splash จะได้เลือกหน้าถัดไปได้ทันที
  static bool shouldShow = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_kDone) ?? false;
    // คนที่ใช้แอปอยู่ก่อนมีหน้านี้มีประวัติแล้ว ไม่ต้องแนะนำซ้ำ
    final hasHistory = (prefs.getString(_kHistory) ?? '').isNotEmpty;
    shouldShow = !done && !hasHistory;
  }

  static Future<void> complete() async {
    shouldShow = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDone, true);
  }
}
