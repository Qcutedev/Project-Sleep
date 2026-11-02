import 'sleep_stats.dart';

/// กฎลดคะแนนเมื่อนอนนานเกินเกณฑ์ ตามความเห็นของแพทย์ที่เจ้าของโปรเจคปรึกษา
///
/// โมเดลให้คะแนนเท่ากันตั้งแต่นอน 8 ถึง 24 ชม. เพราะ random forest ทำนายนอกช่วงข้อมูลฝึกไม่ได้
/// จึงต้องใช้กฎเสริมหลังได้คะแนนจากโมเดล และคิดฝั่งแอปเพราะยังไม่รู้วิธี deploy backend บน Render
/// ถ้าย้ายกฎนี้ไป backend ต้องลบที่นี่ด้วย ไม่อย่างนั้นคะแนนจะถูกลดสองรอบ
const double longSleepDoctorLimitHours = 10;

/// อายุ 65 ปีขึ้นไปเริ่มลดเร็วกว่า ตามเพดานช่วงแนะนำใน `recommendedSleepHours` เป็นค่าร่าง ไม่ได้มาจากแพทย์
const double longSleepSeniorLimitHours = 8;

/// คะแนนที่ลดต่อชั่วโมงที่เกินเกณฑ์ เป็นค่าร่างที่ยังไม่ได้ให้แพทย์ตรวจ
const double longSleepPenaltyPerHour = 20;

/// แพทย์บอกว่านอนเกิน 10 ชม. คะแนนต้องไม่ใกล้ 100 จึงตั้งเพดานให้ต่ำกว่าเกณฑ์ Good (80) เสมอ
const int longSleepScoreCap = 79;

/// ชั่วโมงนอนที่เริ่มลดคะแนนตามอายุ
double longSleepThresholdFor(int age) =>
    age >= 65 ? longSleepSeniorLimitHours : longSleepDoctorLimitHours;

/// เก็บเป็นอังกฤษในประวัติแล้วแปลตอนแสดงผล เหมือนปัจจัยที่มาจาก backend
const String longSleepFactor = 'Long sleep duration';

const String _noFactors = 'No major risk factors found';

// ข้อความ "รักษากิจวัตรเดิม" ของระดับ Good ขัดกับปัจจัยนอนนาน จึงใช้ข้อความกลางที่มีคำแปลแล้ว
const String _longSleepRecommendation = 'Try keeping a consistent sleep schedule.';

/// คืนผลที่ปรับแล้วเมื่อนอนเกินเกณฑ์ ถ้าไม่เกินจะคืนค่าเดิมทุกช่อง
({int score, String quality, List<String> factors, String recommendation})
    applyLongSleepRule({
  required double sleepHours,
  required int age,
  required int score,
  required String quality,
  required List<String> factors,
  required String recommendation,
}) {
  final threshold = longSleepThresholdFor(age);
  if (sleepHours <= threshold) {
    return (
      score: score,
      quality: quality,
      factors: factors,
      recommendation: recommendation,
    );
  }
  final penalty = (sleepHours - threshold) * longSleepPenaltyPerHour;
  final ceiling = sleepHours > longSleepDoctorLimitHours ? longSleepScoreCap : 100;
  final adjusted = (score - penalty).round().clamp(1, ceiling);
  return (
    score: adjusted,
    quality: qualityForScore(adjusted.toDouble()),
    factors: [
      longSleepFactor,
      ...factors.where((f) => f != _noFactors),
    ],
    recommendation: _longSleepRecommendation,
  );
}
