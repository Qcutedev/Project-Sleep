import 'package:flutter/material.dart';

/// ตัวเลือกเวลาเข้านอนที่แนะนำ คำนวณจาก sleep cycle โดยประมาณ (ไม่ใช่กฎตายตัว)
class BedtimeOption {
  final TimeOfDay bedtime;
  final Duration sleepDuration;
  final int cycles;
  final bool isRecommended;

  const BedtimeOption({
    required this.bedtime,
    required this.sleepDuration,
    required this.cycles,
    this.isRecommended = false,
  });

  String get durationLabel {
    final h = sleepDuration.inHours;
    final m = sleepDuration.inMinutes % 60;
    if (m == 0) return '${h}h sleep';
    return '${h}h ${m}m sleep';
  }
}

/// ข้อมูล Alarm หนึ่งอันที่ผู้ใช้ตั้งไว้ (รองรับหลายอันพร้อมกัน)
class SleepAlarm {
  final int id; // unique id ของปลุกอันนี้ (ไม่เปลี่ยนหลังสร้างแล้ว)
  TimeOfDay wakeTime;
  TimeOfDay? bedtime;
  bool isEnabled;
  Set<int> repeatDays; // 1 = Mon ... 7 = Sun (ตรงกับ DateTime.weekday)
  int snoozeMinutes;

  SleepAlarm({
    required this.id,
    required this.wakeTime,
    this.bedtime,
    this.isEnabled = true,
    Set<int>? repeatDays,
    this.snoozeMinutes = 10,
  }) : repeatDays = repeatDays ?? {};

  static const List<String> dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<String> dayNamesShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  /// ข้อความสรุป repeat แสดงในหน้ารายการ เช่น "Every day", "Weekdays", "Mon, Wed" หรือ "Once"
  String get repeatSummary {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 && repeatDays.containsAll({1, 2, 3, 4, 5})) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 && repeatDays.containsAll({6, 7})) {
      return 'Weekends';
    }
    final sorted = repeatDays.toList()..sort();
    return sorted.map((d) => dayNamesShort[d - 1]).join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wakeHour': wakeTime.hour,
        'wakeMinute': wakeTime.minute,
        'bedHour': bedtime?.hour,
        'bedMinute': bedtime?.minute,
        'isEnabled': isEnabled,
        'repeatDays': repeatDays.toList(),
        'snoozeMinutes': snoozeMinutes,
      };

  factory SleepAlarm.fromJson(Map<String, dynamic> json) {
    return SleepAlarm(
      id: json['id'] as int,
      wakeTime: TimeOfDay(
        hour: json['wakeHour'] as int,
        minute: json['wakeMinute'] as int,
      ),
      bedtime: json['bedHour'] != null
          ? TimeOfDay(
              hour: json['bedHour'] as int,
              minute: json['bedMinute'] as int,
            )
          : null,
      isEnabled: json['isEnabled'] as bool? ?? true,
      repeatDays: Set<int>.from(json['repeatDays'] as List? ?? const []),
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 10,
    );
  }
}

/// คำนวณตัวเลือกเวลาเข้านอนแบบ sleep cycle (ประมาณการ 90 นาที/cycle)
/// เป็นเพียงค่าประมาณ ไม่ใช่กฎตายตัว — ใช้เพื่อช่วยวางแผนเท่านั้น
List<BedtimeOption> calculateBedtimeOptions(TimeOfDay wakeTime, {DateTime? now}) {
  final currentTime = now ?? DateTime.now();
  const cycleMinutes = 90;
  const cycleOptions = [6, 5, 4, 3, 2, 1];
  const maxOptionsToShow = 3;

  var wakeDateTime = DateTime(
    currentTime.year,
    currentTime.month,
    currentTime.day,
    wakeTime.hour,
    wakeTime.minute,
  );
  if (!wakeDateTime.isAfter(currentTime)) {
    wakeDateTime = wakeDateTime.add(const Duration(days: 1));
  }

  final availableMinutes = wakeDateTime.difference(currentTime).inMinutes;

  final rawOptions = cycleOptions.map((cycles) {
    final sleepMinutes = cycles * cycleMinutes;
    final bedDateTime = wakeDateTime.subtract(Duration(minutes: sleepMinutes));
    return (cycles: cycles, sleepMinutes: sleepMinutes, bedDateTime: bedDateTime);
  }).toList();

  final validOptions = rawOptions
      .where((o) => o.bedDateTime.isAfter(currentTime))
      .take(maxOptionsToShow)
      .toList();

  if (validOptions.isEmpty) {
    return [
      BedtimeOption(
        bedtime: TimeOfDay(hour: currentTime.hour, minute: currentTime.minute),
        sleepDuration: Duration(minutes: availableMinutes),
        cycles: (availableMinutes / cycleMinutes).floor(),
        isRecommended: true,
      ),
    ];
  }

  final options = validOptions.map((o) {
    final bt = o.bedDateTime;
    return BedtimeOption(
      bedtime: TimeOfDay(hour: bt.hour, minute: bt.minute),
      sleepDuration: Duration(minutes: o.sleepMinutes),
      cycles: o.cycles,
    );
  }).toList();

  options[0] = BedtimeOption(
    bedtime: options[0].bedtime,
    sleepDuration: options[0].sleepDuration,
    cycles: options[0].cycles,
    isRecommended: true,
  );

  return options;
}

String formatTimeOfDay(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}