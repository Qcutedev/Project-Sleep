import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _starsController; // ควบคุมดาวตกที่ลอยเฉียงอยู่ข้างหลังโลโก้ (วนซ้ำตลอด)

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _subtitleOpacity;

  // ตัวอักษรของชื่อแอป แยกทีละตัวเพื่อค่อยๆ ลอยขึ้น+จางเข้าไม่พร้อมกัน (ฟีลผ่อนคลาย ไม่เด้ง)
  static const String _title = 'SleepWise AI';
  late final List<Animation<double>> _letterRise; // ลอยขึ้นเบาๆ จากด้านล่างนิดเดียว
  late final List<Animation<double>> _letterOpacity; // จางเข้าเบาๆ

  @override
  void initState() {
    super.initState();

    // ความยาว animation ทั้งหมด: 3.4 วินาที
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );

    // โลโก้: เด้งใหญ่แบบสปริง (elasticOut เด้งเกินแล้วดีดกลับ เห็นชัดมาก)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2647, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.1176, curve: Curves.easeIn),
      ),
    );

    // ดาวตก: ลอยเฉียงลงมาช้าๆ กระจุกอยู่หลังโลโก้ วนซ้ำต่อเนื่อง (เริ่มหลังเด้งเข้ามาเสร็จพอดี)
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    const logoEntranceMs = 900; // ตรงกับ 0.2647 * 3400ms ของ _logoScale ด้านบน
    Future.delayed(const Duration(milliseconds: logoEntranceMs), () {
      if (mounted) _starsController.repeat();
    });

    // ชื่อแอป: ลอยขึ้นเบาๆ + จางเข้าทีละตัวอักษร ให้ฟีลผ่อนคลายสบาย (ไม่เด้งแล้ว)
    const titleStartMs = 900.0; // เริ่มหลังโลโก้เด้งเกือบเสร็จ
    const letterStaggerMs = 80.0; // ระยะห่างเวลาที่แต่ละตัวเริ่มลอยขึ้น (ไล่กันนุ่มๆ เป็นคลื่น)
    const riseDurationMs = 650.0; // ระยะเวลาที่แต่ละตัวใช้ลอยขึ้น+จางเข้า
    const riseDistance = 14.0; // ระยะลอยขึ้นสั้นๆ เบาๆ ไม่ต้องเยอะ

    _letterRise = List.generate(_title.length, (i) {
      final startMs = titleStartMs + i * letterStaggerMs;
      final start = (startMs / 3400.0).clamp(0.0, 1.0);
      final end = ((startMs + riseDurationMs) / 3400.0).clamp(0.0, 1.0);
      return Tween<double>(begin: riseDistance, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _letterOpacity = List.generate(_title.length, (i) {
      final startMs = titleStartMs + i * letterStaggerMs;
      final start = (startMs / 3400.0).clamp(0.0, 1.0);
      final end = ((startMs + riseDurationMs) / 3400.0).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    // ตัวอักษรตัวสุดท้ายลอยขึ้นเสร็จตอนไหน (ใช้กะเวลาให้ subtitle ขึ้นหลังจากนั้น)
    final lastLetterEndMs = titleStartMs + (_title.length - 1) * letterStaggerMs + riseDurationMs;
    final subtitleStart = ((lastLetterEndMs + 300) / 3400.0).clamp(0.0, 0.95);

    // คำบรรยายใต้ชื่อ: fade เข้าช้าสุด หลังตัวอักษรลอยขึ้นครบแล้วจริงๆ
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(subtitleStart, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // ไปหน้า Home ก็ต่อเมื่อ animation ลอยขึ้นครบทุกตัวแล้วจริงๆ เท่านั้น (ไม่ใช้เวลาคงที่เดา)
    // แล้วค้างหน้านี้ไว้อีกพักให้ดูคำบรรยายจบก่อน
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(milliseconds: 1600), () {
          if (mounted) {
            final route = ModalRoute.of(context);
            if (route != null && !route.isCurrent) {
              // มีหน้าอื่น (เช่นหน้าปลุกดัง) ทับอยู่บน Splash แล้ว:
              // เปลี่ยนเฉพาะ Splash ที่อยู่ข้างล่าง ห้ามไปแทนที่หน้าบนสุด
              Navigator.of(context).replace(
                oldRoute: route,
                newRoute: MaterialPageRoute(builder: (context) => const MainShell()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainShell()),
              );
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _starsController.dispose();
    super.dispose();
  }

  Widget _buildTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_title.length, (i) {
        final char = _title[i];
        // ช่องว่างไม่ต้องอนิเมท แค่เว้นระยะ
        if (char == ' ') {
          return const SizedBox(width: 10);
        }
        return Opacity(
          opacity: _letterOpacity[i].value,
          child: Transform.translate(
            offset: Offset(0, _letterRise[i].value),
            child: Text(
              char,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A3FBF), // สี indigo/violet หลักของธีม
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, _starsController]),
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // โลโก้ - เด้งเข้ามาแบบสปริง มีดาวตกลอยเฉียงช้าๆ กระจุกอยู่หลังโลโก้
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // จุดกึ่งกลางเส้นทาง (สว่างชัดสุด) ของแต่ละดวงอยู่คนละด้านของโลโก้:
                      // ดวง 1 = ด้านบน, 2 = บนขวา, 3 = ล่างขวา, 4 = ล่างซ้าย, 5 = บนซ้าย
                      _buildShootingStar(phase: 0.0, start: const Offset(78, -15), end: const Offset(142, 75), length: 22),
                      _buildShootingStar(phase: 0.2, start: const Offset(154, 40), end: const Offset(218, 130), length: 26),
                      _buildShootingStar(phase: 0.4, start: const Offset(125, 130), end: const Offset(189, 220), length: 20),
                      _buildShootingStar(phase: 0.6, start: const Offset(31, 130), end: const Offset(95, 220), length: 28),
                      _buildShootingStar(phase: 0.8, start: const Offset(2, 40), end: const Offset(66, 130), length: 24),
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 140,
                            height: 140,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // ชื่อแอป - ลอยขึ้นเบาๆ + จางเข้าทีละตัวอักษร ฟีลผ่อนคลายสบาย
                _buildTitle(),
                const SizedBox(height: 8),
                // คำบรรยาย - fade เข้าช้าสุด
                Opacity(
                  opacity: _subtitleOpacity.value,
                  child: Text(
                    S.of(context).splashSubtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ดาวตกที่ลอยเฉียงลงมาช้าๆ จางเข้า-จางออก วนซ้ำต่อเนื่อง
  /// [start]/[end] กำหนดเส้นทางตรงๆ เลย เพื่อคุมให้ "จุดที่สว่างชัดที่สุด" ของแต่ละดวง
  /// อยู่คนละตำแหน่งล้อมรอบโลโก้ (บน/บนขวา/ล่างขวา/ล่างซ้าย/บนซ้าย) แม้ทุกดวงจะตกทิศทางเดียวกัน
  Widget _buildShootingStar({
    required double phase,
    required Offset start,
    required Offset end,
    required double length,
  }) {
    final localT = (_starsController.value + phase) % 1.0;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final head = Offset.lerp(start, end, localT)!;

    // จางเข้าตอนเริ่มโผล่ จางออกตอนใกล้จบรอบ ให้ดูต่อเนื่องไม่วูบวาบ
    double opacity;
    if (localT < 0.15) {
      opacity = localT / 0.15;
    } else if (localT > 0.8) {
      opacity = (1 - localT) / 0.2;
    } else {
      opacity = 1.0;
    }
    opacity = opacity.clamp(0.0, 1.0) * 0.75;

    return CustomPaint(
      size: const Size(220, 220),
      painter: _ShootingStarPainter(
        head: head,
        angle: angle,
        length: length,
        opacity: opacity,
      ),
    );
  }
}

/// วาดเส้นดาวตก: หางจางไล่ระดับ + จุดสว่างที่หัวดาว
class _ShootingStarPainter extends CustomPainter {
  final Offset head;
  final double angle;
  final double length;
  final double opacity;

  _ShootingStarPainter({
    required this.head,
    required this.angle,
    required this.length,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final tail = Offset(
      head.dx - math.cos(angle) * length,
      head.dy - math.sin(angle) * length,
    );

    final linePaint = Paint()
      ..shader = ui.Gradient.linear(
        tail,
        head,
        [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: opacity),
        ],
      )
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tail, head, linePaint);

    final headPaint = Paint()..color = Colors.white.withValues(alpha: opacity);
    canvas.drawCircle(head, 2.2, headPaint);
  }

  @override
  bool shouldRepaint(covariant _ShootingStarPainter oldDelegate) => true;
}
