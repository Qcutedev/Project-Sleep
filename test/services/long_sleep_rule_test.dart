import 'package:flutter_test/flutter_test.dart';
import 'package:sleepwise_ai/models/sleep_assessment_input.dart';
import 'package:sleepwise_ai/models/sleep_result.dart';
import 'package:sleepwise_ai/services/long_sleep_rule.dart';

const _backendGood = {
  'sleep_quality': 'Good',
  'score': 96,
  'factors': ['No major risk factors found'],
  'recommendation': 'Keep up your current routine — consistency is what helps most.',
};

SleepResult _resultFor(
  double hours, {
  Map<String, dynamic> json = _backendGood,
  int age = 25,
}) {
  return SleepResult.fromJson(
    json,
    input: SleepAssessmentInput(
      sleepDuration: hours,
      stressLevel: 5,
      physicalActivity: 30,
      age: age,
      gender: 'Male',
    ),
  );
}

void main() {
  test('leaves the backend result unchanged at exactly 10 hours', () {
    final result = _resultFor(10);
    expect(result.score, 96);
    expect(result.quality, 'Good');
    expect(result.factors, ['No major risk factors found']);
    expect(result.recommendation, _backendGood['recommendation']);
  });

  test('lowers the score more the longer the sleep runs past 10 hours', () {
    expect(_resultFor(11).score, 76);
    expect(_resultFor(12).score, 56);
    expect(_resultFor(14).score, 16);
  });

  test('never stays near 100 past 10 hours', () {
    expect(_resultFor(10.1).score, longSleepScoreCap);
    expect(_resultFor(10.5).score, longSleepScoreCap);
    expect(_resultFor(10.1).quality, 'Fair');
  });

  test('starts lowering at 8 hours from age 65', () {
    expect(_resultFor(8, age: 65).score, 96);
    expect(_resultFor(9, age: 65).score, 76);
    expect(_resultFor(9, age: 64).score, 96);
    expect(_resultFor(10.1, age: 65).score, 54);
  });

  test('keeps the 10 hour limit for people under 18', () {
    expect(_resultFor(10, age: 15).score, 96);
    expect(_resultFor(11, age: 15).score, 76);
  });

  test('never goes below the lowest score', () {
    expect(_resultFor(24).score, 1);
  });

  test('derives the quality label from the lowered score', () {
    expect(_resultFor(10.5).quality, 'Fair');
    expect(_resultFor(11).quality, 'Fair');
    expect(_resultFor(14).quality, 'Poor');
  });

  test('replaces the no-factor message and keeps other factors', () {
    expect(_resultFor(11).factors, [longSleepFactor]);
    final stressed = _resultFor(11, json: {
      ..._backendGood,
      'factors': ['High stress level'],
    });
    expect(stressed.factors, [longSleepFactor, 'High stress level']);
  });

  test('drops the keep-your-routine recommendation', () {
    expect(
      _resultFor(10.5).recommendation,
      'Try keeping a consistent sleep schedule.',
    );
  });

  test('does not lower the score again when read back from history', () {
    final saved = _resultFor(12);
    final restored = SleepResult.fromStorageJson(saved.toStorageJson());
    expect(restored.score, saved.score);
    expect(restored.factors, saved.factors);
  });
}
