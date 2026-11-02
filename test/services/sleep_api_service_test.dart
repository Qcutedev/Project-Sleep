import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sleepwise_ai/models/sleep_assessment_input.dart';
import 'package:sleepwise_ai/services/sleep_api_service.dart';

const _input = SleepAssessmentInput(
  sleepDuration: 7,
  stressLevel: 5,
  physicalActivity: 30,
  age: 25,
  gender: 'Male',
);

RealSleepApiService _service(MockClientHandler handler) =>
    RealSleepApiService(baseUrl: 'http://test', client: MockClient(handler));

Matcher _throwsKind(SleepApiErrorKind kind) => throwsA(
      isA<SleepApiException>().having((e) => e.kind, 'kind', kind),
    );

void main() {
  group('predict', () {
    test('sends the five inputs and parses a successful response', () async {
      late Map<String, dynamic> sent;
      final api = _service((request) async {
        expect(request.url.path, '/predict');
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'sleep_quality': 'Fair',
            'score': 60,
            'factors': ['No major risk factors found'],
            'recommendation': 'Try keeping a consistent sleep schedule.',
          }),
          200,
        );
      });

      final result = await api.predict(_input);

      expect(sent.keys.toSet(), {
        'sleep_duration',
        'stress_level',
        'physical_activity',
        'age',
        'gender',
      });
      expect(result.quality, 'Fair');
      expect(result.score, 60);
    });

    test('maps a dropped connection to noConnection', () {
      final api = _service((_) async => throw http.ClientException('offline'));
      expect(api.predict(_input), _throwsKind(SleepApiErrorKind.noConnection));
    });

    test('maps a non-200 status to server', () {
      final api = _service((_) async => http.Response('oops', 503));
      expect(api.predict(_input), _throwsKind(SleepApiErrorKind.server));
    });

    test('maps invalid JSON to badResponse', () {
      final api = _service((_) async => http.Response('<html>', 200));
      expect(api.predict(_input), _throwsKind(SleepApiErrorKind.badResponse));
    });

    test('maps a response without a score to badResponse', () {
      final api = _service((_) async => http.Response('{"factors":[]}', 200));
      expect(api.predict(_input), _throwsKind(SleepApiErrorKind.badResponse));
    });

    test('maps a request that never finishes to timeout', () {
      final never = Completer<http.Response>();
      final api = RealSleepApiService(
        baseUrl: 'http://test',
        client: MockClient((_) => never.future),
        timeout: const Duration(milliseconds: 10),
      );
      expect(api.predict(_input), _throwsKind(SleepApiErrorKind.timeout));
    });
  });

  group('warmUp', () {
    test('calls /health', () async {
      Uri? called;
      final api = _service((request) async {
        called = request.url;
        return http.Response('{"status":"ok"}', 200);
      });
      await api.warmUp();
      expect(called?.path, '/health');
    });

    test('ignores failures', () async {
      final api = _service((_) async => throw http.ClientException('offline'));
      await expectLater(api.warmUp(), completes);
    });
  });
}
