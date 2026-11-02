/// ข้อมูลที่ผู้ใช้กรอกในหน้า Assessment
///
/// Feature ชุดนี้อ้างอิงจาก dataset จริงที่เพื่อนส่งมา (5 อย่าง):
/// Sleep Duration, Stress Level, Physical Activity Level, Age, Gender
/// ถ้าเพื่อนแก้ feature เพิ่มเติมภายหลัง ให้แก้ field ในไฟล์นี้ที่เดียว
/// ไม่กระทบหน้าจออื่น นอกจากฟอร์มกรอกข้อมูลในหน้า Assessment
class SleepAssessmentInput {
  final double sleepDuration; // ชั่วโมง
  final int stressLevel; // ระดับ 1-10
  final int physicalActivity; // นาที/วัน
  final int age; // ปี
  final String gender; // 'Male' หรือ 'Female'

  // เวลาเข้านอน/ตื่นแบบ 'HH:mm' ใช้ดูความสม่ำเสมอในเครื่องเท่านั้น โมเดลไม่ได้ใช้
  // เป็น null ในประวัติเก่าก่อนมีฟีเจอร์นี้
  final String? bedtime;
  final String? wakeTime;

  const SleepAssessmentInput({
    required this.sleepDuration,
    required this.stressLevel,
    required this.physicalActivity,
    required this.age,
    required this.gender,
    this.bedtime,
    this.wakeTime,
  });

  /// แปลงเป็น JSON เพื่อส่งให้ FastAPI ตาม API contract เบื้องต้น
  /// (ตอนเพื่อนส่ง contract จริงมา ให้แก้ key ตรงนี้ให้ตรงกัน)
  Map<String, dynamic> toJson() => {
        'sleep_duration': sleepDuration,
        'stress_level': stressLevel,
        'physical_activity': physicalActivity,
        'age': age,
        'gender': gender,
      };
}
