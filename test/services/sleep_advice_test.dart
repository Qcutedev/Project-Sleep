import 'package:flutter_test/flutter_test.dart';
import 'package:sleepwise_ai/services/sleep_advice.dart';
import 'package:sleepwise_ai/services/sleep_stats.dart';
import '../helpers/sample_results.dart';

void main() {
  group('recommendedSleepHours', () {
    test('changes with age', () {
      expect(recommendedSleepHours(17), (low: 8, high: 10));
      expect(recommendedSleepHours(18), (low: 7, high: 9));
      expect(recommendedSleepHours(64), (low: 7, high: 9));
      expect(recommendedSleepHours(65), (low: 7, high: 8));
    });
  });

  test('scoreBandFor uses the limits 80, 50, and 21', () {
    expect(scoreBandFor(80), ScoreBand.high);
    expect(scoreBandFor(79), ScoreBand.mid);
    expect(scoreBandFor(50), ScoreBand.mid);
    expect(scoreBandFor(49), ScoreBand.low);
    expect(scoreBandFor(21), ScoreBand.low);
    expect(scoreBandFor(20), ScoreBand.veryLow);
  });

  group('adviceForResult', () {
    final at = DateTime(2026, 10, 1);
    List<AdviceKind> kinds({
      int score = 90,
      double sleep = 8,
      int stress = 3,
      int activity = 45,
      int age = 25,
    }) {
      final result = sampleResult(
        at: at,
        score: score,
        sleep: sleep,
        stress: stress,
        activity: activity,
        age: age,
      );
      return adviceForResult(result).map((t) => t.kind).toList();
    }

    test('keeps the routine when nothing needs attention', () {
      expect(kinds(), [AdviceKind.keepRoutine]);
    });

    test('flags short sleep from the age range, not the 6.5 hour limit', () {
      expect(kinds(sleep: 6.7), contains(AdviceKind.durationShort));
      expect(kinds(sleep: 7.5, age: 16), contains(AdviceKind.durationShort));
    });

    test('flags long sleep above the age range', () {
      expect(kinds(sleep: 9.5), contains(AdviceKind.durationLong));
    });

    test('flags stress at 7 and activity under 20 minutes', () {
      expect(kinds(stress: 7), contains(AdviceKind.stressHigh));
      expect(kinds(stress: 6), isNot(contains(AdviceKind.stressHigh)));
      expect(kinds(activity: 19), contains(AdviceKind.activityLow));
      expect(kinds(activity: 20), isNot(contains(AdviceKind.activityLow)));
    });

    test('adds the wind-down tip when the score is not high', () {
      expect(kinds(score: 79), contains(AdviceKind.windDown));
      expect(kinds(score: 80), isNot(contains(AdviceKind.windDown)));
    });
  });

  group('longTermAdvice', () {
    List<DailySleep> days(List<int> scores, {double sleep = 8, int stress = 3}) {
      return groupByDay([
        for (var i = 0; i < scores.length; i++)
          sampleResult(
            at: DateTime(2026, 10, 1 + i),
            score: scores[i],
            sleep: sleep,
            stress: stress,
            activity: 45,
          ),
      ]);
    }

    Iterable<LongTermKind> kinds(List<DailySleep> input) =>
        longTermAdvice(input)!.map((t) => t.kind);

    test('needs at least 5 days', () {
      expect(longTermAdvice(days([60, 60, 60, 60])), isNull);
      expect(longTermAdvice(days([60, 60, 60, 60, 60])), isNotNull);
    });

    test('reports a rising, falling, or steady trend', () {
      expect(kinds(days([40, 40, 50, 70, 70])), contains(LongTermKind.trendUp));
      expect(kinds(days([70, 70, 50, 40, 40])), contains(LongTermKind.trendDown));
      expect(kinds(days([60, 60, 60, 60, 60])), contains(LongTermKind.trendStable));
    });

    test('mentions a low spell only after 10 days', () {
      expect(kinds(days(List.filled(9, 30))), isNot(contains(LongTermKind.lowSpell)));
      expect(kinds(days(List.filled(10, 30))), contains(LongTermKind.lowSpell));
    });

    test('flags a short average and high stress', () {
      final input = days(List.filled(5, 60), sleep: 5, stress: 8);
      expect(kinds(input), containsAll([LongTermKind.shortAverage, LongTermKind.stressHigh]));
    });
  });
}
