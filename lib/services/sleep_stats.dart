import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/sleep_result.dart';

/// ค่าที่เลือกแสดงบนกราฟแนวโน้ม
enum TrendMetric { score, duration, stress, activity }

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// จำนวนวันตามปฏิทินจาก [from] ถึง [to] (ไม่สนเวลาในวัน)
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// ระดับคุณภาพจากคะแนน 1-100 ใช้เกณฑ์เดียวกับ backend
/// (คะแนนโมเดล >= 8 = Good, >= 5 = Fair เมื่อแปลงเป็นสเกล 1-100)
/// ใช้เฉพาะกับค่าเฉลี่ยของหลายครั้ง — ผลครั้งเดียวให้ใช้ป้ายจากโมเดลโดยตรง
String qualityForScore(double score) {
  if (score >= 80) return 'Good';
  if (score >= 21) return 'Fair';
  return 'Poor';
}

/// ไอคอนประจำปัจจัยแต่ละข้อ (อิงข้อความภาษาอังกฤษที่ backend ส่งมา)
IconData factorIcon(String rawFactor) {
  switch (rawFactor) {
    case 'Short sleep duration':
      return Icons.bedtime_outlined;
    case 'High stress level':
      return Icons.psychology_outlined;
    case 'Low physical activity':
      return Icons.directions_walk;
    case 'No major risk factors found':
      return Icons.check_circle_outline;
    default:
      return Icons.insights_outlined;
  }
}

/// ผลการเช็กอินทั้งหมดของ 1 วัน รวมเป็นจุดเดียวบนกราฟ (ใช้ค่าเฉลี่ยของวันนั้น)
class DailySleep {
  final DateTime day;
  final List<SleepResult> results;

  const DailySleep({required this.day, required this.results});

  double _avg(num Function(SleepResult r) pick) =>
      results.fold<double>(0, (sum, r) => sum + pick(r)) / results.length;

  double get avgScore => _avg((r) => r.displayScore);
  double get avgDuration => _avg((r) => r.input.sleepDuration);
  double get avgStress => _avg((r) => r.input.stressLevel);
  double get avgActivity => _avg((r) => r.input.physicalActivity);

  String get quality =>
      results.length == 1 ? results.first.quality : qualityForScore(avgScore);

  double valueFor(TrendMetric metric) {
    switch (metric) {
      case TrendMetric.score:
        return avgScore;
      case TrendMetric.duration:
        return avgDuration;
      case TrendMetric.stress:
        return avgStress;
      case TrendMetric.activity:
        return avgActivity;
    }
  }
}

/// รวมประวัติเป็นรายวัน เรียงจากวันเก่าไปวันใหม่
List<DailySleep> groupByDay(Iterable<SleepResult> history) {
  final byDay = <DateTime, List<SleepResult>>{};
  for (final r in history) {
    byDay.putIfAbsent(dateOnly(r.timestamp), () => []).add(r);
  }
  final days = byDay.entries
      .map((e) => DailySleep(day: e.key, results: e.value))
      .toList()
    ..sort((a, b) => a.day.compareTo(b.day));
  return days;
}

/// ข้อความแสดงค่าของ [metric] พร้อมหน่วย เช่น "72", "7.0 ชม.", "5/10", "30 นาที"
String formatMetric(S s, TrendMetric metric, double value) {
  switch (metric) {
    case TrendMetric.score:
      return value.round().toString();
    case TrendMetric.duration:
      return s.hoursValue(value.toStringAsFixed(1));
    case TrendMetric.stress:
      final text = value == value.roundToDouble()
          ? value.round().toString()
          : value.toStringAsFixed(1);
      return '$text/10';
    case TrendMetric.activity:
      return s.minutesShort(value.round());
  }
}
