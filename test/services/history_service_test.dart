import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleepwise_ai/models/sleep_result.dart';
import 'package:sleepwise_ai/services/history_service.dart';
import '../helpers/sample_results.dart';

void main() {
  late HistoryService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = HistoryService();
  });

  test('starts empty', () async {
    expect(await service.getHistory(), isEmpty);
  });

  test('keeps one result per day, replacing the earlier one', () async {
    await service.saveDailyResult(sampleResult(at: DateTime(2026, 10, 1, 8), score: 40));
    await service.saveDailyResult(sampleResult(at: DateTime(2026, 10, 1, 20), score: 70));
    await service.saveDailyResult(sampleResult(at: DateTime(2026, 10, 2, 8), score: 50));

    final history = await service.getHistory();
    expect(history.map((r) => r.score), [70, 50]);
  });

  test('deletes only the matching result', () async {
    final first = sampleResult(at: DateTime(2026, 10, 1, 8), score: 40);
    await service.saveDailyResult(first);
    await service.saveDailyResult(sampleResult(at: DateTime(2026, 10, 2, 8), score: 50));

    await service.deleteResult(first);

    final history = await service.getHistory();
    expect(history.map((r) => r.score), [50]);
  });

  test('returns an empty list when the stored data cannot be read', () async {
    SharedPreferences.setMockInitialValues({'sleep_history_v1': 'not json'});
    expect(await service.getHistory(), isEmpty);
  });

  group('SleepResult storage format', () {
    test('survives a round trip', () {
      final original = sampleResult(
        at: DateTime(2026, 10, 1, 8, 30),
        score: 72,
        sleep: 6.5,
        stress: 7,
        activity: 15,
        age: 40,
        gender: 'Female',
      );
      final copy = SleepResult.fromStorageJson(original.toStorageJson());

      expect(copy.score, 72);
      expect(copy.timestamp, original.timestamp);
      expect(copy.input.sleepDuration, 6.5);
      expect(copy.input.stressLevel, 7);
      expect(copy.input.physicalActivity, 15);
      expect(copy.input.age, 40);
      expect(copy.input.gender, 'Female');
    });

    test('reads old records that stored confidence instead of score', () {
      final json = sampleResult(at: DateTime(2026, 10, 1)).toStorageJson()
        ..remove('score')
        ..['confidence'] = 0.5;
      expect(SleepResult.fromStorageJson(json).score, 51);
    });
  });
}
