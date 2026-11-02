import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepwise_ai/models/alarm.dart';
import 'package:sleepwise_ai/services/alarm_scheduler_service.dart';

void main() {
  const wake = TimeOfDay(hour: 7, minute: 0);

  group('calculateBedtimeOptions', () {
    test('offers at most 3 options, most sleep first, and marks the first', () {
      final options = calculateBedtimeOptions(wake, now: DateTime(2026, 10, 1, 20));

      expect(options, hasLength(3));
      expect(options.map((o) => o.cycles), [6, 5, 4]);
      expect(formatTimeOfDay(options[0].bedtime), '22:00');
      expect(options[0].isRecommended, isTrue);
      expect(options[1].isRecommended, isFalse);
    });

    test('skips bedtimes that have already passed', () {
      final options = calculateBedtimeOptions(wake, now: DateTime(2026, 10, 1, 23));
      expect(options.first.cycles, 5);
      expect(formatTimeOfDay(options.first.bedtime), '23:30');
    });

    test('falls back to now when there is no time for a full cycle', () {
      final options = calculateBedtimeOptions(wake, now: DateTime(2026, 10, 2, 6, 30));
      expect(options, hasLength(1));
      expect(options.single.sleepDuration, const Duration(minutes: 30));
      expect(options.single.cycles, 0);
      expect(options.single.isRecommended, isTrue);
    });
  });

  group('SleepAlarm JSON', () {
    test('survives a round trip', () {
      final alarm = SleepAlarm(
        id: 5,
        wakeTime: wake,
        bedtime: const TimeOfDay(hour: 22, minute: 30),
        isEnabled: false,
        repeatDays: {1, 3},
        snoozeMinutes: 15,
      );
      final copy = SleepAlarm.fromJson(alarm.toJson());

      expect(copy.id, 5);
      expect(copy.wakeTime, wake);
      expect(copy.bedtime, const TimeOfDay(hour: 22, minute: 30));
      expect(copy.isEnabled, isFalse);
      expect(copy.repeatDays, {1, 3});
      expect(copy.snoozeMinutes, 15);
    });

    test('uses defaults for missing optional fields', () {
      final copy = SleepAlarm.fromJson({'id': 5, 'wakeHour': 7, 'wakeMinute': 0});
      expect(copy.bedtime, isNull);
      expect(copy.isEnabled, isTrue);
      expect(copy.repeatDays, isEmpty);
      expect(copy.snoozeMinutes, 10);
    });
  });

  group('next occurrence', () {
    test('uses today when the time has not passed', () {
      final thursday = DateTime(2026, 10, 1, 6);
      expect(
        AlarmScheduler.nextOccurrenceForWeekday(wake, DateTime.thursday, now: thursday),
        DateTime(2026, 10, 1, 7),
      );
    });

    test('moves a week ahead when the time has passed', () {
      final thursday = DateTime(2026, 10, 1, 8);
      expect(
        AlarmScheduler.nextOccurrenceForWeekday(wake, DateTime.thursday, now: thursday),
        DateTime(2026, 10, 8, 7),
      );
    });

    test('is null for a disabled alarm', () {
      final alarm = SleepAlarm(id: 1, wakeTime: wake, isEnabled: false);
      expect(AlarmScheduler.nextOccurrenceForAlarm(alarm), isNull);
    });
  });

  test('native ids stay separate for each weekday', () {
    expect(AlarmScheduler.nativeIdFor(12, 1), 121);
    expect(AlarmScheduler.nativeIdFor(12, 7), 127);
  });
}
