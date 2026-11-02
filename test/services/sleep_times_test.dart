import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepwise_ai/models/sleep_assessment_input.dart';
import 'package:sleepwise_ai/models/sleep_result.dart';
import 'package:sleepwise_ai/services/sleep_stats.dart';

SleepResult _result(String? bedtime, {int day = 1}) => SleepResult(
      quality: 'Fair',
      score: 60,
      factors: const [],
      recommendation: '',
      timestamp: DateTime(2026, 10, day),
      input: SleepAssessmentInput(
        sleepDuration: 7,
        stressLevel: 5,
        physicalActivity: 30,
        age: 25,
        gender: 'Male',
        bedtime: bedtime,
        wakeTime: bedtime == null ? null : '06:00',
      ),
    );

void main() {
  group('sleepHoursBetween', () {
    TimeOfDay t(int h, [int m = 0]) => TimeOfDay(hour: h, minute: m);

    test('handles a night across midnight', () {
      expect(sleepHoursBetween(t(23), t(6)), 7);
      expect(sleepHoursBetween(t(22, 30), t(6, 45)), 8.3);
    });

    test('handles sleep after midnight and daytime sleep', () {
      expect(sleepHoursBetween(t(1), t(7)), 6);
      expect(sleepHoursBetween(t(13), t(15)), 2);
    });

    test('gives 0 when both times are the same', () {
      expect(sleepHoursBetween(t(7), t(7)), 0);
    });
  });

  group('parseClockTime', () {
    test('reads HH:mm and round-trips', () {
      final time = parseClockTime('06:05');
      expect(time, const TimeOfDay(hour: 6, minute: 5));
      expect(formatClockTime(time!), '06:05');
    });

    test('rejects bad text', () {
      for (final bad in [null, '', '6', 'a:b', '24:00', '12:60']) {
        expect(parseClockTime(bad), isNull, reason: '$bad');
      }
    });
  });

  group('bedtimeConsistency', () {
    test('needs at least 3 nights with a bedtime', () {
      expect(bedtimeConsistency([_result('23:00'), _result('23:30'), _result(null)]), isNull);
    });

    test('ignores old results without a bedtime', () {
      final data = bedtimeConsistency([
        _result('23:00'),
        _result('23:00'),
        _result('23:00'),
        _result(null),
      ]);
      expect(data!.nights, 3);
      expect(data.spreadMinutes, 0);
    });

    test('averages correctly across midnight', () {
      final data = bedtimeConsistency([_result('23:00'), _result('00:00'), _result('01:00')]);
      expect(data!.averageBedtime, const TimeOfDay(hour: 0, minute: 0));
      expect(data.spreadMinutes, 49);
    });
  });

  group('storage', () {
    test('keeps the times, and does not send them to the model', () {
      final result = _result('23:00');
      final copy = SleepResult.fromStorageJson(result.toStorageJson());
      expect(copy.input.bedtime, '23:00');
      expect(copy.input.wakeTime, '06:00');
      expect(result.input.toJson().containsKey('bedtime'), isFalse);
      expect(result.input.toJson().containsKey('wake_time'), isFalse);
    });

    test('reads old records without the times', () {
      final json = _result(null).toStorageJson();
      expect(json.containsKey('bedtime'), isFalse);
      expect(SleepResult.fromStorageJson(json).input.bedtime, isNull);
    });
  });
}
