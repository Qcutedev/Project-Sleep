import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sleep_result.dart';
import 'sleep_stats.dart';

/// ตรรกะคำแนะนำทั้งหมด (ไม่มี UI และไม่มีข้อความ) แล้วให้หน้าจอแปลงเป็นข้อความผ่าน `S`
///
/// หลักการ: ใช้แนวทางสุขอนามัยการนอนทั่วไป (sleep hygiene) เท่านั้น
/// ไม่ใช่คำแนะนำทางการแพทย์ และไม่ระบุสาเหตุของผลที่ได้
/// คำแนะนำคำนวณฝั่งแอปจากข้อมูลที่ผู้ใช้กรอก ไม่ได้มาจากโมเดลหรือ backend

// ---------------------------------------------------------------- ช่วงเวลานอนที่แนะนำ

/// ช่วงชั่วโมงนอนที่แนะนำทั่วไปตามอายุ (ปัดเป็นชั่วโมงเต็ม)
({int low, int high}) recommendedSleepHours(int age) {
  if (age < 18) return (low: 8, high: 10);
  if (age >= 65) return (low: 7, high: 8);
  return (low: 7, high: 9);
}

// ---------------------------------------------------------------- คำแนะนำหลังประเมิน 1 ครั้ง

/// ระดับคะแนน 1-100 ที่แบ่งละเอียดกว่า Good/Fair/Poor เพื่อให้คำแนะนำตรงกับคะแนนมากขึ้น
enum ScoreBand { high, mid, low, veryLow }

ScoreBand scoreBandFor(int score) {
  if (score >= 80) return ScoreBand.high;
  if (score >= 50) return ScoreBand.mid;
  if (score >= 21) return ScoreBand.low;
  return ScoreBand.veryLow;
}

enum AdviceKind {
  durationShort,
  durationLong,
  stressHigh,
  activityLow,
  windDown,
  keepRoutine,
}

class AdviceTip {
  final AdviceKind kind;

  /// ช่วงชั่วโมงนอนที่แนะนำ ใช้กับ durationShort / durationLong
  final int low;
  final int high;

  const AdviceTip(this.kind, {this.low = 0, this.high = 0});

  IconData get icon {
    switch (kind) {
      case AdviceKind.durationShort:
      case AdviceKind.durationLong:
        return Icons.bedtime_outlined;
      case AdviceKind.stressHigh:
        return Icons.psychology_outlined;
      case AdviceKind.activityLow:
        return Icons.directions_walk;
      case AdviceKind.windDown:
        return Icons.nights_stay_outlined;
      case AdviceKind.keepRoutine:
        return Icons.event_repeat_outlined;
    }
  }
}

/// คำแนะนำจากข้อมูลที่กรอกในการประเมินครั้งนั้น เรียงตามความสำคัญ
List<AdviceTip> adviceForResult(SleepResult result) {
  final input = result.input;
  final range = recommendedSleepHours(input.age);
  final band = scoreBandFor(result.displayScore);
  final tips = <AdviceTip>[];

  if (input.sleepDuration < range.low) {
    tips.add(AdviceTip(AdviceKind.durationShort, low: range.low, high: range.high));
  } else if (input.sleepDuration > range.high) {
    tips.add(AdviceTip(AdviceKind.durationLong, low: range.low, high: range.high));
  }
  if (input.stressLevel >= 7) tips.add(const AdviceTip(AdviceKind.stressHigh));
  if (input.physicalActivity < 20) tips.add(const AdviceTip(AdviceKind.activityLow));

  // คะแนนไม่สูงแต่ข้อมูลที่กรอกไม่เข้าเกณฑ์ข้อไหนเลย ให้คำแนะนำพื้นฐานแทน
  if (band != ScoreBand.high) tips.add(const AdviceTip(AdviceKind.windDown));
  if (tips.isEmpty) tips.add(const AdviceTip(AdviceKind.keepRoutine));
  return tips;
}

// ---------------------------------------------------------------- คำแนะนำระยะยาว

/// ต้องเช็กอินอย่างน้อยกี่วัน (คนละวัน) ถึงจะแสดงคำแนะนำระยะยาว
/// น้อยกว่านี้แนวโน้มแกว่งง่ายจนชวนเข้าใจผิด
const int minDaysForLongTerm = 5;

/// จำนวนวันขั้นต่ำก่อนจะพูดถึงคะแนนที่ต่ำต่อเนื่อง
const int _minDaysForLowSpell = 10;

enum LongTermKind {
  trendUp,
  trendDown,
  trendStable,
  irregular,
  shortAverage,
  longAverage,
  stressHigh,
  activityLow,
  lowSpell,
  steadyGood,
}

class LongTermTip {
  final LongTermKind kind;

  /// ค่าที่ใช้แทรกในข้อความ (ส่วนต่างคะแนน, ชั่วโมงเฉลี่ย, ฯลฯ ขึ้นกับ kind)
  final double value;
  final int low;
  final int high;

  const LongTermTip(this.kind, {this.value = 0, this.low = 0, this.high = 0});

  IconData get icon {
    switch (kind) {
      case LongTermKind.trendUp:
        return Icons.trending_up;
      case LongTermKind.trendDown:
        return Icons.trending_down;
      case LongTermKind.trendStable:
        return Icons.trending_flat;
      case LongTermKind.irregular:
        return Icons.event_repeat_outlined;
      case LongTermKind.shortAverage:
      case LongTermKind.longAverage:
        return Icons.bedtime_outlined;
      case LongTermKind.stressHigh:
        return Icons.psychology_outlined;
      case LongTermKind.activityLow:
        return Icons.directions_walk;
      case LongTermKind.lowSpell:
        return Icons.health_and_safety_outlined;
      case LongTermKind.steadyGood:
        return Icons.emoji_events_outlined;
    }
  }
}

/// คำแนะนำระยะยาวจากข้อมูลรายวันของช่วงที่เลือกบนหน้า Stats
/// คืน null ถ้ามีข้อมูลไม่ถึง [minDaysForLongTerm] วัน
List<LongTermTip>? longTermAdvice(List<DailySleep> days) {
  if (days.length < minDaysForLongTerm) return null;

  double avg(Iterable<double> v) => v.reduce((a, b) => a + b) / v.length;

  final scores = days.map((d) => d.avgScore).toList();
  final durations = days.map((d) => d.avgDuration).toList();
  final avgScore = avg(scores);
  final avgDuration = avg(durations);
  final avgStress = avg(days.map((d) => d.avgStress));
  final avgActivity = avg(days.map((d) => d.avgActivity));

  // อายุใช้ค่าของเช็กอินล่าสุด เพราะอายุเปลี่ยนได้ตามเวลา
  final age = days.last.results.last.input.age;
  final range = recommendedSleepHours(age);

  final tips = <LongTermTip>[];

  // แนวโน้ม: เทียบค่าเฉลี่ยครึ่งแรกกับครึ่งหลังของช่วง (ข้ามวันกลางถ้าจำนวนวันเป็นเลขคี่)
  final half = days.length ~/ 2;
  final change = avg(scores.sublist(days.length - half)) - avg(scores.sublist(0, half));
  if (change >= 5) {
    tips.add(LongTermTip(LongTermKind.trendUp, value: change));
  } else if (change <= -5) {
    tips.add(LongTermTip(LongTermKind.trendDown, value: -change));
  } else {
    tips.add(LongTermTip(LongTermKind.trendStable, value: avgScore));
  }

  // ความสม่ำเสมอ: ส่วนเบี่ยงเบนมาตรฐานของชั่วโมงนอนรายวัน
  final variance =
      durations.fold<double>(0, (sum, d) => sum + math.pow(d - avgDuration, 2)) /
          durations.length;
  final spread = math.sqrt(variance);
  if (spread >= 1.0) {
    tips.add(LongTermTip(LongTermKind.irregular, value: spread));
  }

  if (avgDuration < range.low) {
    tips.add(LongTermTip(LongTermKind.shortAverage,
        value: avgDuration, low: range.low, high: range.high));
  } else if (avgDuration > range.high) {
    tips.add(LongTermTip(LongTermKind.longAverage,
        value: avgDuration, low: range.low, high: range.high));
  }

  if (avgStress >= 7) tips.add(LongTermTip(LongTermKind.stressHigh, value: avgStress));
  if (avgActivity < 20) {
    tips.add(LongTermTip(LongTermKind.activityLow, value: avgActivity));
  }

  if (avgScore < 50 && days.length >= _minDaysForLowSpell) {
    tips.add(LongTermTip(LongTermKind.lowSpell, value: days.length.toDouble()));
  } else if (avgScore >= 80) {
    tips.add(const LongTermTip(LongTermKind.steadyGood));
  }

  return tips;
}
