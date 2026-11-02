import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleepwise_ai/models/sleep_assessment_input.dart';
import 'package:sleepwise_ai/models/sleep_result.dart';
import 'package:sleepwise_ai/services/weekly_summary.dart';

SleepResult _result(DateTime at, {int score = 60, double sleep = 7}) => SleepResult(
      quality: 'Fair',
      score: score,
      factors: const [],
      recommendation: '',
      timestamp: at,
      input: SleepAssessmentInput(
        sleepDuration: sleep,
        stressLevel: 5,
        physicalActivity: 30,
        age: 25,
        gender: 'Male',
      ),
    );

void main() {
  // พฤหัสบดี สัปดาห์นี้เริ่มจันทร์ 5 ต.ค. 2026
  final now = DateTime(2026, 10, 8, 12);
  DateTime day(int d) => DateTime(2026, 10, d, 8);

  group('weeklySummary', () {
    test('is null with no check-ins this week', () {
      expect(weeklySummary([_result(day(4))], 8, now), isNull);
    });

    test('averages only this week, starting on Monday', () {
      final summary = weeklySummary([
        _result(day(4), score: 10, sleep: 1),
        _result(day(5), score: 60, sleep: 7),
        _result(day(8), score: 80, sleep: 9),
      ], 8, now)!;

      expect(summary.daysCheckedIn, 2);
      expect(summary.avgScore, 70);
      expect(summary.avgHours, 8);
      expect(summary.daysMetGoal, 1);
    });

    test('counts reaching the goal exactly', () {
      final summary = weeklySummary([_result(day(8), sleep: 8)], 8, now)!;
      expect(summary.daysMetGoal, 1);
    });

    test('compares weeks only with at least 3 days in each', () {
      final thisWeek = [
        _result(day(5), score: 70),
        _result(day(6), score: 70),
        _result(day(7), score: 70),
      ];
      final lastWeek = [
        _result(day(1), score: 50),
        _result(day(2), score: 50),
      ];
      expect(weeklySummary([...lastWeek, ...thisWeek], 8, now)!.scoreChange, isNull);

      final more = [...lastWeek, _result(day(3), score: 50), ...thisWeek];
      expect(weeklySummary(more, 8, now)!.scoreChange, 20);
    });

    test('ignores anything after today', () {
      final summary = weeklySummary([
        _result(day(8), score: 60),
        _result(day(9), score: 100),
      ], 8, now)!;
      expect(summary.daysCheckedIn, 1);
      expect(summary.avgScore, 60);
    });
  });

  group('SleepGoalService', () {
    test('uses the default until a goal is saved', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SleepGoalService.load(), SleepGoalService.defaultHours);

      await SleepGoalService.save(7.5);
      expect(await SleepGoalService.load(), 7.5);
    });
  });
}
