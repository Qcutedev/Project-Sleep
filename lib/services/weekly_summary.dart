import 'package:shared_preferences/shared_preferences.dart';
import '../models/sleep_result.dart';
import 'sleep_stats.dart';

/// เป้าหมายชั่วโมงนอนต่อคืน เก็บในเครื่อง
class SleepGoalService {
  SleepGoalService._();

  static const _key = 'settings_sleep_goal_hours';
  static const double defaultHours = 8;
  static const double minHours = 5;
  static const double maxHours = 10;

  static Future<double> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? defaultHours;
  }

  static Future<void> save(double hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, hours);
  }
}

/// สรุปสัปดาห์นี้ (เริ่มวันจันทร์ เหมือนช่วง "สัปดาห์นี้" ของหน้า Stats)
class WeeklySummary {
  final int daysCheckedIn;
  final double avgScore;
  final double avgHours;
  final int daysMetGoal;

  /// คะแนนเฉลี่ยต่างจากสัปดาห์ก่อนเท่าไร null = ข้อมูลไม่พอให้เปรียบเทียบ
  final int? scoreChange;

  const WeeklySummary({
    required this.daysCheckedIn,
    required this.avgScore,
    required this.avgHours,
    required this.daysMetGoal,
    required this.scoreChange,
  });
}

/// ต้องมีข้อมูลสัปดาห์ละกี่วันถึงจะแสดงตัวเลขเปรียบเทียบ ตามกติกาใน CONVENTIONS.md
const int minDaysForWeeklyChange = 3;

/// คืน null ถ้าสัปดาห์นี้ยังไม่มีการเช็กอิน
WeeklySummary? weeklySummary(
  List<SleepResult> history,
  double goalHours,
  DateTime now,
) {
  final today = dateOnly(now);
  final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
  final lastMonday = DateTime(monday.year, monday.month, monday.day - 7);

  final days = groupByDay(history);
  final thisWeek = days
      .where((d) => !d.day.isBefore(monday) && !d.day.isAfter(today))
      .toList();
  final lastWeek = days
      .where((d) => !d.day.isBefore(lastMonday) && d.day.isBefore(monday))
      .toList();
  if (thisWeek.isEmpty) return null;

  double avg(List<DailySleep> list, double Function(DailySleep d) pick) =>
      list.fold<double>(0, (sum, d) => sum + pick(d)) / list.length;

  final avgScore = avg(thisWeek, (d) => d.avgScore);
  final canCompare = thisWeek.length >= minDaysForWeeklyChange &&
      lastWeek.length >= minDaysForWeeklyChange;

  return WeeklySummary(
    daysCheckedIn: thisWeek.length,
    avgScore: avgScore,
    avgHours: avg(thisWeek, (d) => d.avgDuration),
    daysMetGoal: thisWeek.where((d) => d.avgDuration >= goalHours).length,
    scoreChange:
        canCompare ? (avgScore - avg(lastWeek, (d) => d.avgScore)).round() : null,
  );
}
