/// ที่อยู่ backend อ่านจาก `--dart-define=SLEEP_API_BASE_URL=...` ตอน build
/// ถ้าไม่ใส่จะใช้ 127.0.0.1 ซึ่งใช้บนมือถือจริงไม่ได้ ดูคำสั่งใน docs/BUILD.md
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'SLEEP_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
