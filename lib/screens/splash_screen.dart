import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'main_shell.dart';

/// หน้าเปิดแอป: ท้องฟ้ากลางคืน โลโก้ที่ขยับได้ลอยขึ้นมา
/// ชื่อแอปขึ้นทีละตัวอักษร จบด้วยการจางเข้าหน้าหลัก
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ความยาวทั้งหมดก่อนเข้าหน้าหลัก ทุกช่วงเวลาข้างล่างอ้างอิงค่านี้
  static const int _totalMs = 4500;
  static const String _title = 'SleepWise AI';

  late final AnimationController _intro; // เล่นครั้งเดียว
  late final AnimationController _ambient; // ดาวกะพริบ เมฆลอย ดาวตก วนซ้ำ

  late final Animation<double> _sky;
  late final List<Animation<double>> _letters;
  late final Animation<double> _subtitle;

  Animation<double> _between(int startMs, int endMs, Curve curve) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(startMs / _totalMs, endMs / _totalMs, curve: curve),
      );

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _NightSkyPainter.loopSeconds),
    )..repeat();

    _sky = _between(0, 700, Curves.easeOut);
    _letters = List.generate(_title.length, (i) {
      final start = 1000 + i * 45;
      return _between(start, start + 450, Curves.easeOutCubic);
    });
    _subtitle = _between(1750, 2200, Curves.easeIn);

    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goHome();
    });
    _intro.forward();
  }

  void _goHome() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      // มีหน้าอื่น (เช่นหน้าปลุกดัง) ทับอยู่บน Splash แล้ว:
      // เปลี่ยนเฉพาะ Splash ที่อยู่ข้างล่าง ห้ามไปแทนที่หน้าบนสุด
      Navigator.of(context).replace(
        oldRoute: route,
        newRoute: MaterialPageRoute(builder: (context) => const MainShell()),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondary) => const MainShell(),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Widget _buildTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_title.length, (i) {
        final char = _title[i];
        // ช่องว่างไม่ต้องอนิเมท แค่เว้นระยะ
        if (char == ' ') return const SizedBox(width: 10);
        final v = _letters[i].value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - v)),
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
    final s = S.of(context);
    return Scaffold(
      backgroundColor: _NightSkyPainter.topColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _NightSkyPainter(fadeIn: _sky, ambient: _ambient),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                // ย่อทั้งชุดลงบนจอเตี้ยหรือแคบ แทนที่จะล้น
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedBuilder(
                    animation: _intro,
                    // โลโก้วาดใหม่เองทุกเฟรมผ่าน painter ไม่ต้องสร้าง widget ใหม่
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: const Size.square(_LogoPainter.boxSize),
                        painter: _LogoPainter(intro: _intro, ambient: _ambient),
                      ),
                    ),
                    builder: (context, logo) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          logo!,
                          _buildTitle(),
                          const SizedBox(height: 8),
                          Opacity(
                            opacity: _subtitle.value,
                            child: Text(
                              s.splashSubtitle,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// โลโก้ของแอปที่วาดด้วยโค้ดให้เหมือน assets/images/logo.png
/// เพื่อให้แต่ละชิ้นขยับแยกกันได้: วงกลมลอยขึ้นลง พระจันทร์โยกเหมือนเปล
/// ดาวในโลโก้กะพริบ และมีประกายดาวโคจรรอบ
class _LogoPainter extends CustomPainter {
  static const double boxSize = 220;
  static const double _radius = 66;
  static const int _introMs = _SplashScreenState._totalMs;

  // ตำแหน่งในไฟล์โลโก้ต้นฉบับ (1024 px วงกลมรัศมี 487 จุดกลาง 512,512)
  static const double _unit = _radius / 487;

  final Animation<double> intro;
  final Animation<double> ambient;

  _LogoPainter({required this.intro, required this.ambient})
      : super(repaint: Listenable.merge([intro, ambient]));

  double _between(int startMs, int endMs, Curve curve) {
    final ms = intro.value * _introMs;
    final u = ((ms - startMs) / (endMs - startMs)).clamp(0.0, 1.0);
    return curve.transform(u);
  }

  static Offset _fromSource(double x, double y) =>
      Offset((x - 512) * _unit, (y - 512) * _unit);

  @override
  void paint(Canvas canvas, Size size) {
    final a = ambient.value;
    final discIn = _between(100, 900, Curves.easeOutBack);
    final discFade = _between(100, 450, Curves.easeIn);
    final moonIn = _between(450, 1250, Curves.easeOutCubic);
    final orbitIn = _between(1300, 1900, Curves.easeOut);

    // ลอยขึ้นลงช้าๆ 3 ครั้งต่อรอบของฉากหลัง
    final bob = 4 * math.sin(2 * math.pi * 3 * a) * discIn.clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 36 * (1 - discIn) + bob);

    // ประกายดาวโคจรเป็นวงรีเอียง ครึ่งหนึ่งของรอบอยู่หลังวงกลม
    final orbitAngle = 2 * math.pi * 2 * a;
    final behind = math.sin(orbitAngle) < 0;
    if (behind) _paintOrbit(canvas, orbitAngle, orbitIn);

    canvas.save();
    canvas.scale(0.6 + 0.4 * discIn);
    final fade = discFade.clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      _radius,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -_radius),
          const Offset(0, _radius),
          [
            const Color(0xFF4F46E5).withValues(alpha: fade),
            const Color(0xFF7C3AED).withValues(alpha: fade),
          ],
        ),
    );

    _paintMoon(canvas, a, moonIn);
    _paintLogoStar(canvas, a, _fromSource(732, 290), 36 * _unit, 0, 0.95);
    _paintLogoStar(canvas, a, _fromSource(812, 410), 22 * _unit, 1, 0.8);
    _paintLogoStar(canvas, a, _fromSource(702, 770), 25 * _unit, 2, 0.75);
    canvas.restore();

    if (!behind) _paintOrbit(canvas, orbitAngle, orbitIn);
    canvas.restore();
  }

  void _paintMoon(Canvas canvas, double a, double moonIn) {
    if (moonIn <= 0) return;
    final center = _fromSource(470, 512);
    canvas.save();
    // ตอนเข้า พระจันทร์หมุนขึ้นมาตามแนวโค้งรอบจุดกลางโลโก้
    canvas.rotate(-1.2 * (1 - moonIn));
    canvas.translate(center.dx, center.dy);
    // จากนั้นโยกไปมาเบาๆ รอบตัวเอง
    canvas.rotate(0.09 * math.sin(2 * math.pi * 2 * a));
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 230 * _unit)),
      Path()
        ..addOval(Rect.fromCircle(
          center: _fromSource(625, 450) - center,
          radius: 213 * _unit,
        )),
    );
    canvas.drawPath(
      crescent,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * moonIn)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      crescent,
      Paint()..color = Colors.white.withValues(alpha: moonIn),
    );
    canvas.restore();
  }

  void _paintLogoStar(
    Canvas canvas,
    double a,
    Offset center,
    double radius,
    int index,
    double maxAlpha,
  ) {
    // โผล่ทีละดวงแบบเด้งนิดๆ แล้วกะพริบคนละจังหวะ
    final start = 800 + index * 160;
    final pop = _between(start, start + 400, Curves.easeOutBack);
    if (pop <= 0) return;
    final twinkle =
        0.5 + 0.5 * math.sin(2 * math.pi * ((5 + index) * a + index / 3));
    final r = radius * pop * (0.8 + 0.3 * twinkle);
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final d = i.isEven ? r : r * 0.45;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * d;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(
          alpha: maxAlpha * pop.clamp(0.0, 1.0) * (0.55 + 0.45 * twinkle),
        ),
    );
  }

  void _paintOrbit(Canvas canvas, double angle, double orbitIn) {
    if (orbitIn <= 0) return;
    canvas.save();
    canvas.rotate(-0.35);
    // หางเป็นจุดเล็กๆ ไล่จางตามหลังประกายดาว
    for (var i = 4; i >= 0; i--) {
      final at = angle - i * 0.13;
      final point = Offset(
        _radius * 1.3 * math.cos(at),
        _radius * 0.4 * math.sin(at),
      );
      final alpha = orbitIn * (i == 0 ? 1.0 : 0.5 - i * 0.1);
      final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
      if (i > 0) {
        canvas.drawCircle(point, 1.8 - i * 0.3, paint);
        continue;
      }
      const r = 5.0;
      canvas.drawPath(
        Path()
          ..moveTo(point.dx, point.dy - r)
          ..quadraticBezierTo(point.dx, point.dy, point.dx + r, point.dy)
          ..quadraticBezierTo(point.dx, point.dy, point.dx, point.dy + r)
          ..quadraticBezierTo(point.dx, point.dy, point.dx - r, point.dy)
          ..quadraticBezierTo(point.dx, point.dy, point.dx, point.dy - r)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => false;
}

class _Star {
  final double x; // สัดส่วนของความกว้างจอ
  final double y; // สัดส่วนของความสูงจอ
  final double radius;
  final double phase;
  final int speed; // จำนวนครั้งที่กะพริบต่อรอบ ต้องเป็นจำนวนเต็มเพื่อให้วนต่อกันพอดี

  const _Star(this.x, this.y, this.radius, this.phase, this.speed);
}

/// ฉากหลังท้องฟ้ากลางคืน: ไล่สี ดาวกะพริบ ดาวตก และเมฆด้านล่าง
class _NightSkyPainter extends CustomPainter {
  static const int loopSeconds = 10;
  static const Color topColor = Color(0xFF191548);

  // ตำแหน่งดาวสุ่มครั้งเดียวด้วย seed คงที่ เปิดแอปกี่ครั้งก็หน้าตาเหมือนเดิม
  static final List<_Star> _stars = () {
    final random = math.Random(11);
    return List.generate(
      48,
      (_) => _Star(
        random.nextDouble(),
        random.nextDouble() * 0.82,
        0.6 + random.nextDouble() * 1.3,
        random.nextDouble(),
        1 + random.nextInt(3),
      ),
    );
  }();

  final Animation<double> fadeIn;
  final Animation<double> ambient;

  _NightSkyPainter({required this.fadeIn, required this.ambient})
      : super(repaint: Listenable.merge([fadeIn, ambient]));

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          const [topColor, Color(0xFF3A34A0), Color(0xFF6A5BE0)],
          const [0.0, 0.55, 1.0],
        ),
    );

    final t = ambient.value;
    final appear = fadeIn.value;

    for (final star in _stars) {
      final twinkle =
          0.5 + 0.5 * math.sin(2 * math.pi * (star.speed * t + star.phase));
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        Paint()
          ..color =
              Colors.white.withValues(alpha: appear * (0.25 + 0.65 * twinkle)),
      );
    }

    // ดาวตก 2 ดวง ออกคนละช่วงของรอบ
    _paintShootingStar(canvas, size, t, 0.04, const Offset(0.90, 0.06),
        const Offset(0.50, 0.24));
    _paintShootingStar(canvas, size, t, 0.11, const Offset(0.44, 0.03),
        const Offset(0.06, 0.20));

    final drift = math.sin(2 * math.pi * t);
    final h = size.height;
    final w = size.width;
    _paintCloud(canvas, Offset(w * 0.18 + 10 * drift, h * 0.93), 4.2, 0.10);
    _paintCloud(canvas, Offset(w * 0.80 - 12 * drift, h * 0.96), 5.0, 0.08);
    _paintCloud(canvas, Offset(w * 0.52 + 6 * drift, h * 1.01), 6.0, 0.07);
  }

  void _paintShootingStar(
    Canvas canvas,
    Size size,
    double t,
    double start,
    Offset from,
    Offset to,
  ) {
    // สัดส่วนของรอบที่ดาวตกแต่ละดวงใช้ (0.24 ของ 10 วินาที = ตกช้าๆ 2.4 วินาที)
    const length = 0.24;
    final u = (t - start) / length;
    if (u <= 0 || u >= 1) return;
    final a = Offset(from.dx * size.width, from.dy * size.height);
    final b = Offset(to.dx * size.width, to.dy * size.height);
    final head = Offset.lerp(a, b, u)!;
    final direction = (b - a) / (b - a).distance;
    final tail = head - direction * 70;
    final opacity = math.sin(math.pi * u) * 0.9;

    canvas.drawLine(
      tail,
      head,
      Paint()
        ..shader = ui.Gradient.linear(tail, head, [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: opacity),
        ])
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      head,
      2.2,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
  }

  void _paintCloud(Canvas canvas, Offset c, double scale, double alpha) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    // รวมเป็น path เดียว ไม่อย่างนั้นสีโปร่งใสจะซ้อนกันเป็นรอยเข้ม
    final cloud = Path()
      ..addOval(Rect.fromCircle(center: const Offset(-12, 0), radius: 9))
      ..addOval(Rect.fromCircle(center: const Offset(0, -6), radius: 12))
      ..addOval(Rect.fromCircle(center: const Offset(14, 0), radius: 9))
      ..addRRect(RRect.fromLTRBR(-21, -2, 23, 9, const Radius.circular(9)));
    canvas.drawPath(
      cloud,
      Paint()..color = Colors.white.withValues(alpha: alpha * fadeIn.value),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NightSkyPainter oldDelegate) => false;
}
