import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/sleep_assessment_input.dart';
import '../services/sleep_api_service.dart';
import '../services/history_service.dart';
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


  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runPrediction();
  }

  Future<void> _runPrediction() async {
    setState(() => _errorMessage = null);
    try {
      // ดีเลย์เทียมสั้นๆ เพื่อให้ loading animation แสดงผลอย่างเป็นธรรมชาติ
      // (โมเดลจริงตอบเร็วมากจนบางทีแทบไม่เห็น animation เลย)
      final resultFuture = _api.predict(widget.input);
      final delayFuture = Future.delayed(const Duration(milliseconds: 600));
      final result = await resultFuture;
      await delayFuture;
      await _historyService.addResult(result);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _errorMessage == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SleepingPillowAnimation(),
                  const SizedBox(height: 20),
                  Text(
                    'Analyzing your sleep pattern',
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
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _runPrediction,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// มาสคอตหมอนน่ารักๆ หลับตา + ตัวอักษร Z ลอยขึ้นจากมุมหมอนวนซ้ำไปเรื่อยๆ
/// เหมือนเวลาตัวละครนอนหลับในการ์ตูน
class _SleepingPillowAnimation extends StatefulWidget {
  const _SleepingPillowAnimation();

  @override
  State<_SleepingPillowAnimation> createState() => _SleepingPillowAnimationState();
}

class _SleepingPillowAnimationState extends State<_SleepingPillowAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 160,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value; // 0.0 - 1.0 วนซ้ำตลอด

          // หมอนโยกขึ้นลงเบาๆ เหมือนจังหวะหายใจตอนหลับ
          final bob = math.sin(2 * math.pi * t) * 4;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // ดวงจันทร์เสี้ยว ใกล้ๆ ด้านบนหมอน
              const Positioned(
                left: 42,
                top: 2,
                child: _CrescentMoon(size: 34),
              ),
              // ดาวกระจายอยู่ข้างๆ ดวงจันทร์ (ระยิบระยับเบาๆ ตามจังหวะ)
              _buildStar(left: 84, top: 8, size: 11, phase: 0.0, t: t),
              _buildStar(left: 20, top: 18, size: 8, phase: 0.5, t: t),
              _buildStar(left: 76, top: 34, size: 7, phase: 0.25, t: t),
              // ตัวหมอน
              Transform.translate(
                offset: Offset(0, bob + 10),
                child: const _PillowShape(),
              ),
              // ตัว Z สามตัว ลอยขึ้นจากมุมขวาบนของหมอน ทีละตัว วนซ้ำ
              for (int i = 0; i < 3; i++) _buildFloatingZ(context, i, t),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStar({
    required double left,
    required double top,
    required double size,
    required double phase,
    required double t,
  }) {
    final twinkle = (math.sin(2 * math.pi * (t + phase)) + 1) / 2; // 0..1
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: 0.35 + twinkle * 0.55,
        child: _StarShape(size: size),
      ),
    );
  }

  Widget _buildFloatingZ(BuildContext context, int index, double t) {
    // แต่ละตัวเริ่ม "ลอย" ที่จังหวะต่างกัน (stagger) แล้ววนซ้ำตลอด
    final localT = (t + index / 3) % 1.0;

    // ลอยขึ้นเรื่อยๆ จากจุดเริ่ม ไปทางขวาบนเล็กน้อย
    final dx = 34.0 + localT * 22;
    final dy = -18.0 - localT * 46;

    // โผล่มาแล้วค่อยๆ จางหายตอนลอยขึ้นสูง (bump curve)
    final opacity = math.sin(math.pi * localT).clamp(0.0, 1.0);

    // ตัวเล็กตอนเริ่ม แล้วค่อยๆ ใหญ่ขึ้นตอนลอยสูง
    final scale = 0.5 + localT * 0.9;

    return Positioned(
      left: 100 + dx,
      top: 46 + dy,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: const Text(
            'Z',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// วาดรูปหมอนแบบมินิมอล หลับตา ยิ้มน้อยๆ ให้เข้าธีมสีม่วงของแอป
class _PillowShape extends StatelessWidget {
  const _PillowShape();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 88,
      child: CustomPaint(
        painter: _PillowPainter(isDark: AppTheme.isDark(context)),
      ),
    );
  }
}

class _PillowPainter extends CustomPainter {
  final bool isDark;
  _PillowPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(36),
      topRight: const Radius.circular(36),
      bottomLeft: const Radius.circular(36),
      bottomRight: const Radius.circular(36),
    );

    // เงาใต้หมอน
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height + 4),
        width: size.width * 0.7,
        height: 14,
      ),
      shadowPaint,
    );

    // ตัวหมอน (สีม่วงพาสเทลอ่อน ให้เข้าธีม)
    final pillowPaint = Paint()
      ..color = isDark ? AppTheme.darkSurfaceMuted : AppTheme.primaryLight;
    canvas.drawRRect(rrect, pillowPaint);

    final borderPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    // ตาหลับ (โค้งยิ้มคว่ำเบาๆ) x2
    final eyePaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    void drawEye(double cx) {
      final path = Path()
        ..moveTo(cx - 8, size.height * 0.44)
        ..quadraticBezierTo(cx, size.height * 0.52, cx + 8, size.height * 0.44);
      canvas.drawPath(path, eyePaint);
    }

    drawEye(size.width * 0.34);
    drawEye(size.width * 0.66);

    // ยิ้มน้อยๆ
    final smilePaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(size.width * 0.44, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.67,
        size.width * 0.56, size.height * 0.62,
      );
    canvas.drawPath(smilePath, smilePaint);

    // แก้มชมพูจางๆ x2
    final cheekPaint = Paint()..color = AppTheme.poor.withValues(alpha: 0.18);
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.58), 6, cheekPaint);
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.58), 6, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant _PillowPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// ดวงจันทร์เสี้ยวเล็กๆ ประดับข้างๆ หมอน
class _CrescentMoon extends StatelessWidget {
  final double size;
  const _CrescentMoon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CrescentMoonPainter()),
    );
  }
}

class _CrescentMoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.primaryDark;
    final path = Path()
      ..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()
      ..addOval(Rect.fromLTWH(size.width * 0.32, -size.height * 0.06, size.width, size.height));
    final crescent = Path.combine(PathOperation.difference, path, cutout);
    canvas.drawPath(crescent, paint);
  }

  @override
  bool shouldRepaint(covariant _CrescentMoonPainter oldDelegate) => false;
}

/// ดาว 4 แฉกเล็กๆ ประดับรอบหมอน
class _StarShape extends StatelessWidget {
  final double size;
  const _StarShape({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _StarPainter()),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.fair;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..quadraticBezierTo(w * 0.5, h * 0.5, w, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.5, w * 0.5, h)
      ..quadraticBezierTo(w * 0.5, h * 0.5, 0, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.5, w * 0.5, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => false;
}
