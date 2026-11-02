import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/sleep_result.dart';

/// ค่าที่เลือกแสดงบนกราฟแนวโน้ม
enum TrendMetric { score, duration, stress, activity }

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// จำนวนวันที่เช็กอินติดต่อกัน นับย้อนจากวันล่าสุดที่มีการเช็กอิน
int checkInStreak(List<SleepResult> history) {
  if (history.isEmpty) return 0;
  final days = history.map((r) => dateOnly(r.timestamp)).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
  var streak = 1;
  for (var i = 0; i < days.length - 1; i++) {
    if (daysBetween(days[i + 1], days[i]) != 1) break;
    streak++;
  }
  return streak;
}

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
    case 'Long sleep duration':
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

/// ชั่วโมงนอนจากเวลาเข้านอนถึงเวลาตื่น ปัด 0.1 ชม. รองรับการนอนข้ามเที่ยงคืน
double sleepHoursBetween(TimeOfDay bedtime, TimeOfDay wakeTime) {
  final bed = bedtime.hour * 60 + bedtime.minute;
  final wake = wakeTime.hour * 60 + wakeTime.minute;
  final minutes = (wake - bed) % (24 * 60);
  return (minutes / 6).round() / 10;
}

/// แปลง 'HH:mm' เป็นเวลา คืน null ถ้าข้อความไม่ถูกต้อง
TimeOfDay? parseClockTime(String? text) {
  if (text == null) return null;
  final parts = text.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String formatClockTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

/// ความสม่ำเสมอของเวลาเข้านอน
class BedtimeConsistency {
  final TimeOfDay averageBedtime;
  final int spreadMinutes; // ส่วนเบี่ยงเบนมาตรฐาน
  final int nights;

  const BedtimeConsistency({
    required this.averageBedtime,
    required this.spreadMinutes,
    required this.nights,
  });
}

/// ต้องมีเวลาเข้านอนอย่างน้อยเท่านี้ ถึงจะแสดงตัวเลข (น้อยกว่านี้ชวนเข้าใจผิด)
const int minNightsForConsistency = 3;

/// คำนวณจากผลที่มีเวลาเข้านอน คืน null ถ้าข้อมูลไม่พอ
///
/// นับนาทีเริ่มจากเที่ยงวัน เพราะเวลาเข้านอนมักคร่อมเที่ยงคืน
/// ถ้านับจากเที่ยงคืน ค่าเฉลี่ยของ 23:00 กับ 01:00 จะกลายเป็น 12:00 ซึ่งผิด
BedtimeConsistency? bedtimeConsistency(Iterable<SleepResult> results) {
  const day = 24 * 60;
  const noon = 12 * 60;
  final minutes = <int>[];
  for (final r in results) {
    final time = parseClockTime(r.input.bedtime);
    if (time != null) minutes.add((time.hour * 60 + time.minute - noon) % day);
  }
  if (minutes.length < minNightsForConsistency) return null;

  final mean = minutes.reduce((a, b) => a + b) / minutes.length;
  final variance = minutes.fold<double>(
        0,
        (sum, m) => sum + (m - mean) * (m - mean),
      ) /
      minutes.length;
  final average = (mean.round() + noon) % day;
  return BedtimeConsistency(
    averageBedtime: TimeOfDay(hour: average ~/ 60, minute: average % 60),
    spreadMinutes: math.sqrt(variance).round(),
    nights: minutes.length,
  );
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
