import 'package:sleepwise_ai/models/sleep_assessment_input.dart';
import 'package:sleepwise_ai/models/sleep_result.dart';

/// สร้างผลการประเมินตัวอย่างสำหรับเทสต์ ใส่เฉพาะค่าที่เทสต์นั้นสนใจ
SleepResult sampleResult({
  required DateTime at,
  int score = 60,
  String quality = 'Fair',
  double sleep = 7,
  int stress = 5,
  int activity = 30,
  int age = 25,
  String gender = 'Male',
}) {
  return SleepResult(
    quality: quality,
    score: score,
    factors: const ['No major risk factors found'],
    recommendation: 'Try keeping a consistent sleep schedule.',
    timestamp: at,
    input: SleepAssessmentInput(
      sleepDuration: sleep,
      stressLevel: stress,
      physicalActivity: activity,
      age: age,
      gender: gender,
    ),
  );
}
