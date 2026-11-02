import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepwise_ai/models/alarm.dart';
import 'package:sleepwise_ai/services/alarm_scheduler_service.dart';

void main() {
  const wake = TimeOfDay(hour: 7, minute: 0);

  group('findByNativeId', () {
    final once = SleepAlarm(id: 111, wakeTime: wake, snoozeMinutes: 15);
    final repeat = SleepAlarm(
      id: 222,
      wakeTime: wake,
      repeatDays: {1, 5},
      snoozeMinutes: 20,
    );
    final alarms = [once, repeat];

    test('finds a one-time alarm by its own id', () {
      expect(AlarmScheduler.findByNativeId(alarms, 111), once);
    });

    test('finds a repeating alarm from any of its weekday ids', () {
      expect(AlarmScheduler.findByNativeId(alarms, 2221), repeat);
      expect(AlarmScheduler.findByNativeId(alarms, 2225), repeat);
    });

    test('does not match a weekday the alarm does not repeat on', () {
      expect(AlarmScheduler.findByNativeId(alarms, 2223), isNull);
    });

    test('returns null when nothing matches', () {
      expect(AlarmScheduler.findByNativeId(alarms, 999), isNull);
      expect(AlarmScheduler.findByNativeId(const [], 111), isNull);
    });
  });
}
