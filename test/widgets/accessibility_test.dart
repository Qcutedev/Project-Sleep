import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepwise_ai/l10n/app_strings.dart';
import 'package:sleepwise_ai/models/sleep_assessment_input.dart';
import 'package:sleepwise_ai/models/sleep_result.dart';
import 'package:sleepwise_ai/screens/result_screen.dart';
import 'package:sleepwise_ai/services/sleep_stats.dart';
import 'package:sleepwise_ai/widgets/sleep_trend_chart.dart';

SleepResult _result(DateTime at, int score) => SleepResult(
      quality: 'Fair',
      score: score,
      factors: const ['High stress level'],
      recommendation: 'Try keeping a consistent sleep schedule.',
      timestamp: at,
      input: const SleepAssessmentInput(
        sleepDuration: 7,
        stressLevel: 8,
        physicalActivity: 30,
        age: 25,
        gender: 'Male',
      ),
    );

Widget _app(Widget child) => MaterialApp(
      builder: (context, page) => LanguageScope(child: page!),
      home: Scaffold(body: child),
    );

void main() {
  setUp(() => AppLanguage.notifier.value = 'en');

  testWidgets('the trend chart describes its values', (tester) async {
    final handle = tester.ensureSemantics();
    final days = groupByDay([
      _result(DateTime(2026, 10, 1), 40),
      _result(DateTime(2026, 10, 2), 90),
      _result(DateTime(2026, 10, 3), 60),
    ]);

    await tester.pumpWidget(_app(
      SleepTrendChart(days: days, start: DateTime(2026, 10, 1), windowDays: 7),
    ));
    await tester.pump();

    expect(
      find.semantics.byLabel('Score chart, 3 days. Latest 60, highest 90, lowest 40.'),
      findsOne,
    );
    handle.dispose();
  });

  testWidgets('the score ring reads the final score during its animation', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_app(ResultScreen(result: _result(DateTime(2026, 10, 1), 72))));
    await tester.pump();

    expect(find.semantics.byLabel('Score 72 out of 100'), findsOne);

    await tester.pump(const Duration(seconds: 2));
    handle.dispose();
  });
}
