import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sleep_assessment_input.dart';
import '../models/sleep_result.dart';

/// Interface กลางที่หน้าจอใช้เรียก FastAPI
abstract class SleepApiService {
  Future<SleepResult> predict(SleepAssessmentInput input);
}

class RealSleepApiService implements SleepApiService {
  final String baseUrl; // เช่น 'https://your-fastapi-server.com'

  RealSleepApiService({required this.baseUrl});

  @override
  Future<SleepResult> predict(SleepAssessmentInput input) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SleepResult.fromJson(json, input: input);
    } else {
      throw Exception(
          'Prediction request failed (status ${response.statusCode})');
    }
  }
}
