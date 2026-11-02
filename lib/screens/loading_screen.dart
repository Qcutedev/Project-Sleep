import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../models/sleep_assessment_input.dart';
import '../services/api_config.dart';
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
  // รอนานเกินเท่านี้ มักเป็นเพราะเซิร์ฟเวอร์กำลังเริ่มเครื่อง จึงบอกผู้ใช้ให้รู้ตัว
  static const _slowAfter = Duration(seconds: 6);

  final SleepApiService _api = RealSleepApiService(baseUrl: ApiConfig.baseUrl);
  final HistoryService _historyService = HistoryService();

  bool _hasError = false;
  bool _isSlow = false;
  SleepApiErrorKind? _errorKind;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    _runPrediction();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  Future<void> _runPrediction() async {
    setState(() {
      _hasError = false;
      _isSlow = false;
      _errorKind = null;
    });
    _slowTimer?.cancel();
    _slowTimer = Timer(_slowAfter, () {
      if (mounted) setState(() => _isSlow = true);
    });
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
    } on SleepApiException catch (e) {
      _showError(e.kind);
    } catch (_) {
      _showError(null);
    } finally {
      _slowTimer?.cancel();
    }
  }

  void _showError(SleepApiErrorKind? kind) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _errorKind = kind;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Center(
        child: !_hasError
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SleepingMascot(),
                    const SizedBox(height: 12),
                    Text(
                      s.analyzingPattern,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    if (_isSlow) ...[
                      const SizedBox(height: 8),
                      Text(
                        s.serverWakingUp,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppTheme.textMutedColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_errorIcon(_errorKind), color: AppTheme.poor, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      s.apiErrorMessage(_errorKind),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textPrimaryColor(context)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _runPrediction,
                      child: Text(s.tryAgain),
                    ),
                    const SizedBox(height: 4),
                    // ประเมินถูกส่งมาด้วย pushReplacement หน้าก่อนหน้านี้จึงเป็นหน้า Home
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(s.backToHome),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  IconData _errorIcon(SleepApiErrorKind? kind) {
    switch (kind) {
      case SleepApiErrorKind.noConnection:
        return Icons.wifi_off_rounded;
      case SleepApiErrorKind.timeout:
        return Icons.hourglass_bottom_rounded;
      case SleepApiErrorKind.server:
      case SleepApiErrorKind.badResponse:
        return Icons.cloud_off_rounded;
      case null:
        return Icons.error_outline;
    }
  }
}
