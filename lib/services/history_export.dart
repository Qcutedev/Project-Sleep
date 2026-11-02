import 'dart:convert';
import '../models/sleep_result.dart';

/// แปลงประวัติเป็น CSV ใช้ค่าดิบภาษาอังกฤษตามที่เก็บในเครื่อง เพื่อให้นำไปวิเคราะห์ต่อได้
///
/// อ่านจาก `toStorageJson()` จึงได้ข้อมูลตรงกับที่เก็บจริง ค่าที่ผลเก่าไม่มีจะเป็นช่องว่าง
String historyToCsv(List<SleepResult> history) {
  const columns = [
    'timestamp',
    'score',
    'quality',
    'sleep_duration',
    'bedtime',
    'wake_time',
    'stress_level',
    'physical_activity',
    'age',
    'gender',
    'factors',
    'recommendation',
  ];

  final rows = <String>[columns.join(',')];
  for (final result in history) {
    final json = result.toStorageJson();
    rows.add(columns.map((column) {
      final value = json[column];
      if (value == null) return '';
      if (value is List) return _escape(value.join('; '));
      return _escape(value.toString());
    }).join(','));
  }
  // ขึ้นบรรทัดแบบ CRLF ตามมาตรฐาน CSV
  return '${rows.join('\r\n')}\r\n';
}

/// ไฟล์ CSV เป็น UTF-8 พร้อม BOM เพื่อให้ Excel อ่านภาษาอื่นนอกจากอังกฤษได้ถูกต้อง
List<int> csvBytes(String csv) => [0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];

String _escape(String value) {
  if (value.contains(RegExp(r'[",\r\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// ชื่อไฟล์ เช่น sleepwise-history-2026-11-02.csv
String historyFileName(DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'sleepwise-history-${now.year}-${two(now.month)}-${two(now.day)}.csv';
}
