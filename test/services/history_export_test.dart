import 'package:flutter_test/flutter_test.dart';
import 'package:sleepwise_ai/models/sleep_assessment_input.dart';
import 'package:sleepwise_ai/models/sleep_result.dart';
import 'package:sleepwise_ai/services/history_export.dart';

SleepResult _result({List<String> factors = const ['High stress level']}) {
  return SleepResult(
    quality: 'Fair',
    score: 60,
    factors: factors,
    recommendation: 'Try this, then that.',
    timestamp: DateTime(2026, 10, 1, 8, 30),
    input: const SleepAssessmentInput(
      sleepDuration: 7.5,
      stressLevel: 8,
      physicalActivity: 15,
      age: 25,
      gender: 'Female',
    ),
  );
}

void main() {
  group('historyToCsv', () {
    test('writes a header even with no history', () {
      expect(historyToCsv(const []), startsWith('timestamp,score,quality,'));
    });

    test('writes one row per result with raw values', () {
      final lines = historyToCsv([_result()]).trim().split('\r\n');
      expect(lines, hasLength(2));
      expect(lines[1], contains('2026-10-01T08:30:00.000,60,Fair,7.5,'));
      expect(lines[1], contains(',8,15,25,Female,High stress level,'));
    });

    test('leaves missing values empty', () {
      final row = historyToCsv([_result()]).trim().split('\r\n')[1];
      expect(row, contains(',7.5,,,8,'));
    });

    test('quotes commas and doubles quotes', () {
      final csv = historyToCsv([
        _result(factors: ['one "two"', 'three']),
      ]);
      expect(csv, contains('"Try this, then that."'));
      expect(csv, contains('"one ""two""; three"'));
    });
  });

  test('csvBytes starts with a UTF-8 BOM so Excel reads it correctly', () {
    expect(csvBytes('a').take(3), [0xEF, 0xBB, 0xBF]);
  });

  test('historyFileName pads the date', () {
    expect(historyFileName(DateTime(2026, 3, 5)), 'sleepwise-history-2026-03-05.csv');
  });
}
