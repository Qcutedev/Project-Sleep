import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../models/sleep_assessment_input.dart';
import '../services/sleep_api_service.dart';
import '../services/history_service.dart';
import '../widgets/sleeping_mascot.dart';
import 'result_screen.dart';

/// หน้าระหว่างรอผลจาก FastAPI จริง
class LoadingScreen extends StatefulWidget {
  final SleepAssessmentInput input;

  const LoadingScreen({super.key, required this.input});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  static const _apiBaseUrl = String.fromEnvironment(
    'SLEEP_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  final SleepApiService _api = RealSleepApiService(baseUrl: _apiBaseUrl);
  final HistoryService _historyService = HistoryService();


  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _runPrediction();
  }

  Future<void> _runPrediction() async {
    setState(() => _hasError = false);
    try {
      // ดีเลย์เทียมสั้นๆ เพื่อให้ loading animation แสดงผลอย่างเป็นธรรมชาติ
      // (โมเดลจริงตอบเร็วมากจนบางทีแทบไม่เห็น animation เลย)
      final resultFuture = _api.predict(widget.input);
      final delayFuture = Future.delayed(const Duration(milliseconds: 600));
      final result = await resultFuture;
      await delayFuture;
      await _historyService.saveDailyResult(result);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Center(
        child: !_hasError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SleepingMascot(),
                  const SizedBox(height: 12),
                  Text(
                    s.analyzingPattern,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.poor, size: 32),
                    const SizedBox(height: 12),
                    Text(s.somethingWentWrong, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _runPrediction,
                      child: Text(s.tryAgain),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
