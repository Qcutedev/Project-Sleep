import 'sleep_assessment_input.dart';

/// ผลลัพธ์การประเมินคุณภาพการนอน 1 ครั้ง
///
/// เก็บทั้งผลจาก model (quality, score, factors, recommendation)
/// และข้อมูล input ที่ใช้ทำนายไว้ด้วย เพื่อเอาไปแสดงกราฟ/ประวัติย้อนหลังได้
class SleepResult {
  final String quality; // 'Good' | 'Fair' | 'Poor' (ตรงกับ label จาก model)
  final int score; // คะแนนจาก model ที่ backend แปลงเป็น scale 1-100
  final List<String> factors; // ปัจจัยที่สัมพันธ์กับผลลัพธ์ (ไม่ใช่สาเหตุ/การวินิจฉัย)
  final String recommendation; // คำแนะนำทั่วไปเกี่ยวกับ sleep hygiene
  final DateTime timestamp;
  final SleepAssessmentInput input;

  const SleepResult({
    required this.quality,
    required this.score,
    required this.factors,
    required this.recommendation,
    required this.timestamp,
    required this.input,
  });

  int get displayScore => score;

  factory SleepResult.fromJson(
    Map<String, dynamic> json, {
    required SleepAssessmentInput input,
  }) {
    return SleepResult(
      quality: json['sleep_quality'] as String? ?? 'Fair',
      score: (json['score'] as num).round(),
      factors: (json['factors'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      recommendation: json['recommendation'] as String? ??
          'Try keeping a consistent sleep schedule.',
      timestamp: DateTime.now(),
      input: input,
    );
  }

  /// เก็บ/อ่านจาก local storage (SharedPreferences) สำหรับหน้า History/Home
  Map<String, dynamic> toStorageJson() => {
        'quality': quality,
        'score': score,
        'factors': factors,
        'recommendation': recommendation,
        'timestamp': timestamp.toIso8601String(),
        'sleep_duration': input.sleepDuration,
        'stress_level': input.stressLevel,
        'physical_activity': input.physicalActivity,
        'age': input.age,
        'gender': input.gender,
      };

  factory SleepResult.fromStorageJson(Map<String, dynamic> json) {
    return SleepResult(
      quality: json['quality'] as String,
        score: ((json['score'] as num?) ??
            ((((json['confidence'] as num?)?.toDouble() ?? 0) * 99) + 1))
          .round(),
      factors: (json['factors'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      recommendation: json['recommendation'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      input: SleepAssessmentInput(
        sleepDuration: (json['sleep_duration'] as num).toDouble(),
        stressLevel: json['stress_level'] as int,
        physicalActivity: json['physical_activity'] as int,
        age: json['age'] as int,
        gender: json['gender'] as String,
      ),
    );
  }
}
