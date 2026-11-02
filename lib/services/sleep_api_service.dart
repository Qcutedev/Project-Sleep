import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sleep_assessment_input.dart';
import '../models/sleep_result.dart';

/// ประเภทของความผิดพลาด ให้หน้าจอเลือกข้อความที่บอกผู้ใช้ได้ตรงเรื่อง
enum SleepApiErrorKind { noConnection, timeout, server, badResponse }

class SleepApiException implements Exception {
  final SleepApiErrorKind kind;
  const SleepApiException(this.kind);

  @override
  String toString() => 'SleepApiException(${kind.name})';
}

/// Interface กลางที่หน้าจอใช้เรียก FastAPI
abstract class SleepApiService {
  Future<SleepResult> predict(SleepAssessmentInput input);
}

class RealSleepApiService implements SleepApiService {
  /// Render แผนฟรีใช้เวลาเริ่มเครื่อง 30-60 วินาที จึงต้องรอนานกว่านั้น
  /// ไม่อย่างนั้นคำขอแรกหลังเซิร์ฟเวอร์หลับจะล้มเหลวทุกครั้ง
  static const Duration requestTimeout = Duration(seconds: 90);

  final String baseUrl; // เช่น 'https://your-fastapi-server.com'
  final http.Client _client;
  final Duration _timeout;

  RealSleepApiService({
    required this.baseUrl,
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _timeout = timeout ?? requestTimeout;

  @override
  Future<SleepResult> predict(SleepAssessmentInput input) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(input.toJson()),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const SleepApiException(SleepApiErrorKind.timeout);
    } on http.ClientException {
      throw const SleepApiException(SleepApiErrorKind.noConnection);
    }

    if (response.statusCode != 200) {
      throw const SleepApiException(SleepApiErrorKind.server);
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SleepResult.fromJson(json, input: input);
    } on FormatException {
      throw const SleepApiException(SleepApiErrorKind.badResponse);
    } on TypeError {
      throw const SleepApiException(SleepApiErrorKind.badResponse);
    }
  }

  /// ปลุกเซิร์ฟเวอร์ล่วงหน้าตอนเปิดแอป เพื่อให้กดวิเคราะห์ครั้งแรกไม่ต้องรอเริ่มเครื่อง
  /// เรียกแล้วไม่ต้องรอผล และถ้าไม่สำเร็จก็ไม่เป็นไร เพราะ predict จะลองเองอีกครั้ง
  Future<void> warmUp() async {
    try {
      await _client.get(Uri.parse('$baseUrl/health')).timeout(_timeout);
    } catch (_) {}
  }
}
