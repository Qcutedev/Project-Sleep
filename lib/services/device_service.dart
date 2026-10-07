import 'package:flutter/services.dart';

/// เรียกฟังก์ชันเฉพาะเครื่อง Android ผ่าน MainActivity (ช่องทางเดียวกับใน MainActivity.kt)
class DeviceService {
  static const MethodChannel _channel = MethodChannel('sleepwise/device');

  /// ยี่ห้อเครื่องตัวพิมพ์เล็ก เช่น 'xiaomi' ('' ถ้าอ่านไม่ได้)
  static Future<String> manufacturer() async {
    try {
      return await _channel.invokeMethod<String>('manufacturer') ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<bool> isXiaomi() async {
    final m = await manufacturer();
    return m == 'xiaomi' || m == 'redmi' || m == 'poco';
  }

  static Future<void> openAppPermissions() async {
    try {
      await _channel.invokeMethod('openAppPermissions');
    } catch (_) {}
  }
}
