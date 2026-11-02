import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepwise_ai/l10n/app_strings.dart';
import 'package:sleepwise_ai/services/sleep_stats.dart';
import '../helpers/sample_results.dart';

void main() {
  group('qualityForScore matches the backend limits', () {
    test('80 and above is Good', () {
      expect(qualityForScore(80), 'Good');
      expect(qualityForScore(100), 'Good');
    });

    test('21 up to 80 is Fair', () {
      expect(qualityForScore(79.9), 'Fair');
      expect(qualityForScore(21), 'Fair');
    });

    test('below 21 is Poor', () {
      expect(qualityForScore(20.9), 'Poor');
      expect(qualityForScore(1), 'Poor');
    });
  });

  group('checkInStreak', () {
    test('is 0 with no history', () {
      expect(checkInStreak(const []), 0);
    });

    test('counts consecutive days back from the latest check-in', () {
      final history = [
        sampleResult(at: DateTime(2026, 10, 1, 8)),
        sampleResult(at: DateTime(2026, 10, 3, 8)),
        sampleResult(at: DateTime(2026, 10, 4, 23)),
        sampleResult(at: DateTime(2026, 10, 5, 1)),
      ];
      expect(checkInStreak(history), 3);
    });

    test('counts several check-ins on one day once', () {
      final history = [
        sampleResult(at: DateTime(2026, 10, 5, 8)),
        sampleResult(at: DateTime(2026, 10, 5, 20)),
      ];
      expect(checkInStreak(history), 1);
    });
  });

  group('daysBetween', () {
    test('ignores the time of day', () {
      expect(daysBetween(DateTime(2026, 10, 1, 23), DateTime(2026, 10, 2, 1)), 1);
    });

    test('works across a month end', () {
      expect(daysBetween(DateTime(2026, 1, 31), DateTime(2026, 3, 1)), 29);
    });
  });

  group('groupByDay', () {
    final days = groupByDay([
      sampleResult(at: DateTime(2026, 10, 2, 8), score: 90, sleep: 8),
      sampleResult(at: DateTime(2026, 10, 1, 8), score: 40, quality: 'Fair'),
      sampleResult(at: DateTime(2026, 10, 1, 20), score: 60, quality: 'Fair'),
    ]);

    test('sorts days from old to new', () {
      expect(days.map((d) => d.day), [DateTime(2026, 10, 1), DateTime(2026, 10, 2)]);
    });

    test('averages several check-ins on one day', () {
      expect(days.first.avgScore, 50);
      expect(days.first.valueFor(TrendMetric.duration), 7);
    });

    test('uses the model label for one check-in, and the limits for an average', () {
      expect(days.last.quality, 'Fair');
      expect(days.first.quality, qualityForScore(50));
    });
  });

  group('formatMetric', () {
    setUp(() => AppLanguage.notifier.value = 'en');

    test('shows each metric with its unit', () {
      final s = S.current;
      expect(formatMetric(s, TrendMetric.score, 71.6), '72');
      expect(formatMetric(s, TrendMetric.duration, 7), '7.0 hrs');
      expect(formatMetric(s, TrendMetric.stress, 5), '5/10');
      expect(formatMetric(s, TrendMetric.stress, 5.5), '5.5/10');
      expect(formatMetric(s, TrendMetric.activity, 30), '30 min');
    });
  });

  test('factorIcon uses a neutral icon for text it does not know', () {
    expect(factorIcon('High stress level'), Icons.psychology_outlined);
    expect(factorIcon('Something new'), Icons.insights_outlined);
  });
}
