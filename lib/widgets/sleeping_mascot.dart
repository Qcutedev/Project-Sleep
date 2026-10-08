import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// มาสคอตของแอป: ตัวสีขาวหูยาวกางสองข้าง หางม้วน หลับอยู่บนหมอน
/// (หน้าตาตามตัวละคร Cinnamoroll ที่เจ้าของโปรเจคเลือก ตัวเดียวกับ `HomePet`)
/// ใช้เป็นอนิเมชันระหว่างรอผลวิเคราะห์
///
/// วาดด้วย CustomPaint ทั้งหมด ไม่มีไฟล์รูปหรือแพ็กเกจอนิเมชัน
/// ทุกการขยับคำนวณจากเวลาในรอบ 12 วินาทีรอบเดียว จึงวนซ้ำได้ไม่สะดุด
class SleepingMascot extends StatefulWidget {
  final double width;

  /// วงกลมพื้นหลัง พระจันทร์ ดาว และเมฆ ปิดได้เมื่อวางบนฉากที่มีของพวกนี้อยู่แล้ว
  final bool showBackdrop;

  /// บังคับใช้ชุดสีสำหรับพื้นเข้ม ไม่ว่าธีมของแอปเป็นแบบไหน (เช่นบนหน้า Splash)
  final bool forceDark;

  const SleepingMascot({
    super.key,
    this.width = 260,
    this.showBackdrop = true,
    this.forceDark = false,
  });

  @override
  State<SleepingMascot> createState() => _SleepingMascotState();
}

class _SleepingMascotState extends State<SleepingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _MascotPainter.loopSeconds),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ถ้าผู้ใช้ปิดอนิเมชันในตั้งค่าของเครื่อง ให้แสดงเป็นภาพนิ่ง
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.1;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.width *
            _MascotPainter.designHeight /
            _MascotPainter.designWidth,
        child: CustomPaint(
          painter: _MascotPainter(
            animation: _controller,
            isDark: widget.forceDark || AppTheme.isDark(context),
            showBackdrop: widget.showBackdrop,
          ),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  static const int loopSeconds = 12;
  static const double designWidth = 260;
  static const double designHeight = 220;

  // หายใจ 1 ครั้งใช้ 3 วินาที (4 ครั้งต่อรอบ)
  static const double _breathSeconds = 3;

  static const Color _blush = Color(0xFFFBC4D8);
  static const Color _gold = Color(0xFFF5C454);
  static const Color _ink = Color(0xFF1A1A1A); // เส้นขอบของตัวมาสคอต
  static const Color _eye = Color(0xFF45B5F0);
  static const Offset _head = Offset(130, 128);

  final Animation<double> animation;
  final bool isDark;
  final bool showBackdrop;

  _MascotPainter({
    required this.animation,
    required this.isDark,
    required this.showBackdrop,
  }) : super(repaint: animation);

  // สีเส้นของหมอนและตัว Z ตามธีม ส่วนตัวมาสคอตใช้ขาวขอบดำเสมอ
  Color get _line => isDark ? AppTheme.accent : AppTheme.primary;

  Paint get _furPaint => Paint()..color = Colors.white;

  Paint _ink3([double width = 3]) => _stroke(width, _ink);

  Paint _stroke(double width, [Color? color]) => Paint()
    ..color = color ?? _line
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static double _ease(double x) => x * x * (3 - 2 * x);

  /// จังหวะหายใจ 0..1 หายใจเข้าช้ากว่าหายใจออกเล็กน้อย
  static double _breath(double phase) {
    final p = phase - phase.floorToDouble();
    return p < 0.55 ? _ease(p / 0.55) : 1 - _ease((p - 0.55) / 0.45);
  }

  /// ความคืบหน้า 0..1 ของเหตุการณ์ที่เกิดช่วง [start, start + length] วินาที
  /// คืน null ถ้าอยู่นอกช่วง
  static double? _event(double seconds, double start, double length) {
    final u = (seconds - start) / length;
    return (u < 0 || u > 1) ? null : u;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / designWidth, size.height / designHeight);

    final t = animation.value;
    final seconds = t * loopSeconds;
    final breathPhase = seconds / _breathSeconds;
    final breath = _breath(breathPhase);
    // ส่วนที่นุ่ม (หู หาง) ขยับตามหลังตัวนิดหนึ่ง
    final lagBreath = _breath(breathPhase - 0.12);

    // เหตุการณ์นานๆ ครั้ง ให้ไม่ดูวนซ้ำ
    final earU = _event(seconds, 4.1, 0.7);
    final earTwitch = earU == null
        ? 0.0
        : math.sin(math.pi * earU) * math.sin(4 * math.pi * earU);
    final tailU = _event(seconds, 7.4, 1.3);
    final tailWag = tailU == null
        ? 0.0
        : math.sin(math.pi * tailU) * math.sin(6 * math.pi * tailU);
    final mumbleU = _event(seconds, 10.1, 1.0);
    final mumble = mumbleU == null
        ? 0.0
        : math.sin(math.pi * mumbleU) *
            (0.5 + 0.5 * math.sin(8 * math.pi * mumbleU));

    if (showBackdrop) _paintBackdrop(canvas, t);
    _paintPillow(canvas, breath);

    _paintTail(canvas, lagBreath, tailWag);
    _paintBody(canvas, breath);

    // หัว หู และหน้า ขยับขึ้นลงไปด้วยกัน
    canvas.save();
    canvas.translate(0, -2.5 * breath);
    _paintHead(canvas, lagBreath, earTwitch);
    _paintFace(canvas, breath, mumble, mumbleU != null);
    canvas.restore();

    _paintPaws(canvas);
    _paintZs(canvas, seconds);

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas, double t) {
    canvas.drawCircle(
      const Offset(130, 112),
      98,
      Paint()
        ..color = isDark
            ? AppTheme.accent.withValues(alpha: 0.10)
            : AppTheme.primary.withValues(alpha: 0.07),
    );

    // พระจันทร์เสี้ยว
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: const Offset(54, 46), radius: 15)),
      Path()..addOval(Rect.fromCircle(center: const Offset(62, 41), radius: 14)),
    );
    canvas.drawPath(moon, Paint()..color = _gold);

    _paintStar(canvas, const Offset(98, 30), 6, t, 0.0);
    _paintStar(canvas, const Offset(28, 92), 4.5, t, 0.35);
    _paintStar(canvas, const Offset(232, 96), 5, t, 0.7);

    final cloudPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.13) : Colors.white;
    final drift = math.sin(2 * math.pi * t);
    _paintCloud(canvas, Offset(206 + 5 * drift, 142), 0.8, cloudPaint);
    _paintCloud(canvas, Offset(138 - 4 * drift, 50), 0.62, cloudPaint);
  }

  void _paintStar(Canvas canvas, Offset c, double r, double t, double phase) {
    // กะพริบ 3 ครั้งต่อรอบ
    final twinkle = 0.5 + 0.5 * math.sin(2 * math.pi * (3 * t + phase));
    final rr = r * (0.75 + 0.25 * twinkle);
    final path = Path()
      ..moveTo(c.dx, c.dy - rr)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + rr, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + rr)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - rr, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - rr)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = _gold.withValues(alpha: 0.4 + 0.6 * twinkle),
    );
  }

  void _paintCloud(Canvas canvas, Offset c, double scale, Paint paint) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    // รวมเป็น path เดียว ไม่อย่างนั้นสีโปร่งใสในโหมดมืดจะซ้อนกันเป็นรอยเข้ม
    final cloud = Path()
      ..addOval(Rect.fromCircle(center: const Offset(-12, 0), radius: 9))
      ..addOval(Rect.fromCircle(center: const Offset(0, -6), radius: 12))
      ..addOval(Rect.fromCircle(center: const Offset(14, 0), radius: 9))
      ..addRRect(RRect.fromLTRBR(-21, -2, 23, 9, const Radius.circular(9)));
    canvas.drawPath(cloud, paint);
    canvas.restore();
  }

  void _paintPillow(Canvas canvas, double breath) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(130, 199), width: 172, height: 12),
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // หมอนยุบลงนิดหนึ่งตอนหายใจเข้า
    final top = 150 + 1.5 * breath;
    final pillow = Path()
      ..moveTo(44, top + 8)
      ..quadraticBezierTo(36, top - 4, 52, top)
      ..quadraticBezierTo(130, top - 5, 208, top)
      ..quadraticBezierTo(224, top - 4, 216, top + 8)
      ..quadraticBezierTo(221, 174, 216, 188)
      ..quadraticBezierTo(224, 200, 208, 196)
      ..quadraticBezierTo(130, 201, 52, 196)
      ..quadraticBezierTo(36, 200, 44, 188)
      ..quadraticBezierTo(39, 174, 44, top + 8)
      ..close();
    canvas.drawPath(
      pillow,
      Paint()
        ..color = isDark ? const Color(0xFF3B3786) : const Color(0xFFD5D2FA),
    );
    canvas.drawPath(pillow, _stroke(3));
    // รอยเย็บด้านล่าง
    canvas.drawPath(
      Path()
        ..moveTo(62, 188)
        ..quadraticBezierTo(130, 192, 198, 188),
      _stroke(2, _line.withValues(alpha: 0.35)),
    );
  }

  /// หางม้วนเป็นวงเหมือนซินนามอนโรล
  void _paintTail(Canvas canvas, double lagBreath, double wag) {
    canvas.save();
    canvas.translate(204, 112);
    canvas.rotate((-3 * lagBreath + 16 * wag) * math.pi / 180);
    const c = Offset(10, -12);
    canvas.drawCircle(c, 14, _furPaint);
    canvas.drawCircle(c, 14, _ink3());
    canvas.drawArc(
      Rect.fromCircle(center: c + const Offset(1, 0.5), radius: 6.5),
      0.6,
      4.3,
      false,
      _ink3(2.4),
    );
    canvas.restore();
  }

  void _paintBody(Canvas canvas, double breath) {
    // ยืดขึ้นและแคบลงตอนหายใจเข้า โดยยึดจุดที่ตัวแตะหมอนไว้
    canvas.save();
    canvas.translate(176, 152);
    canvas.scale(1 - 0.025 * breath, 1 + 0.09 * breath);
    canvas.translate(-176, -152);
    final body = Rect.fromCenter(
      center: const Offset(176, 122),
      width: 88,
      height: 60,
    );
    canvas.drawOval(body, _furPaint);
    canvas.drawOval(body, _ink3());
    canvas.restore();
  }

  Path _earPath(double side, double droop) {
    const length = 70.0;
    final ear = Path()
      ..moveTo(-10, -15)
      ..cubicTo(length * 0.35, -25, length * 0.95, -28.5, length, -3.5)
      ..cubicTo(length * 1.04, 23.5, length * 0.45, 22, -10, 15)
      ..close();
    final matrix = Matrix4.identity()
      ..translateByDouble(_head.dx + side * 35, _head.dy - 18, 0, 1)
      ..scaleByDouble(side, 1, 1, 1)
      ..rotateZ(droop);
    return ear.transform(matrix.storage);
  }

  /// หัวกับหูสองข้างรวมเป็นรูปทรงเดียว เส้นขอบจึงต่อเนื่องกันเหมือนในภาพต้นแบบ
  void _paintHead(Canvas canvas, double lagBreath, double earTwitch) {
    // หูแผ่ลงบนหมอน ยกขึ้นนิดหนึ่งตอนหายใจเข้า หูซ้ายกระดิกเป็นบางครั้ง
    final droop = 0.5 - 0.07 * lagBreath;
    var shape = Path()
      ..addOval(Rect.fromCenter(center: _head, width: 104, height: 76));
    shape = Path.combine(
      PathOperation.union,
      shape,
      _earPath(-1, droop - 0.22 * earTwitch),
    );
    shape = Path.combine(PathOperation.union, shape, _earPath(1, droop));
    canvas.drawPath(shape, _furPaint);
    canvas.drawPath(shape, _ink3());

    // รอยพับที่โคนหู
    for (final side in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(_head.dx + side * 41, _head.dy - 12)
          ..quadraticBezierTo(
            _head.dx + side * 45.5,
            _head.dy - 2,
            _head.dx + side * 43.5,
            _head.dy + 8,
          ),
        _ink3(2.4),
      );
    }
  }

  void _paintFace(Canvas canvas, double breath, double mumble, bool mumbling) {
    final blush = Paint()..color = _blush;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: _head + Offset(side * 34.5, 15.5),
          width: 21,
          height: 12.5,
        ),
        blush,
      );
      // ตาหลับเป็นเส้นสีฟ้าเฉียงลงด้านนอก
      final eye = _head + Offset(side * 25, 2);
      canvas.drawLine(
        eye + Offset(-side * 8, -1.3),
        eye + Offset(side * 8, 3),
        _stroke(5, _eye),
      );
    }

    final mouth = _head + const Offset(0, 14.5);
    if (mumbling) {
      // ละเมอ: ปากขยับเปิดปิด
      final open = Rect.fromCenter(
        center: mouth + const Offset(0, 2.5),
        width: 11,
        height: 4 + 7 * mumble,
      );
      canvas.drawOval(open, Paint()..color = const Color(0xFFFF9DB8));
      canvas.drawOval(open, _ink3(2.6));
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(mouth.dx - 9.5, mouth.dy - 1)
          ..quadraticBezierTo(mouth.dx - 5, mouth.dy + 7.5, mouth.dx, mouth.dy)
          ..quadraticBezierTo(
            mouth.dx + 5,
            mouth.dy + 7.5,
            mouth.dx + 9.5,
            mouth.dy - 1,
          ),
        _ink3(3.2),
      );
      // ฟองน้ำมูก พองตอนหายใจออก หดตอนหายใจเข้า
      final r = 2.5 + 7.5 * (1 - breath);
      final c = mouth + Offset(9 + r * 0.75, -3 + r * 0.45);
      canvas.drawCircle(
        c,
        r,
        Paint()..color = const Color(0xFFBFD9FF).withValues(alpha: 0.6),
      );
      canvas.drawCircle(
        c,
        r,
        _stroke(1.6, const Color(0xFF8DB8F5)),
      );
      if (r > 5) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 0.6),
          3.5,
          0.9,
          false,
          _stroke(1.6, Colors.white),
        );
      }
    }
  }

  void _paintPaws(Canvas canvas) {
    for (final side in const [-1.0, 1.0]) {
      final paw = Rect.fromCenter(
        center: Offset(_head.dx + side * 25, 162),
        width: 25,
        height: 16,
      );
      canvas.drawOval(paw, _furPaint);
      canvas.drawOval(paw, _ink3());
    }
  }

  void _paintZs(Canvas canvas, double seconds) {
    for (var i = 0; i < 3; i++) {
      // ออกมาทีละตัว ห่างกัน 1 วินาที แต่ละตัวลอยอยู่ 3 วินาที
      final raw = seconds / _breathSeconds + i / 3;
      final u = raw - raw.floorToDouble();
      final fadeIn = (u / 0.15).clamp(0.0, 1.0);
      final fadeOut = ((1 - u) / 0.4).clamp(0.0, 1.0);
      final opacity = fadeIn * fadeOut;
      if (opacity <= 0) continue;

      final wobble = math.sin(2 * math.pi * (u * 1.5 + i / 3));
      final x = 178 + 34 * u + 5 * wobble;
      final y = 72 - 58 * u;
      final s = 7 + 11 * u;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(wobble * 0.14);
      canvas.drawPath(
        Path()
          ..moveTo(-s / 2, -s / 2)
          ..lineTo(s / 2, -s / 2)
          ..lineTo(-s / 2, s / 2)
          ..lineTo(s / 2, s / 2),
        _stroke(
          s * 0.26,
          // บนพื้นเข้มใช้สีอ่อนกว่าเส้นขอบ ไม่อย่างนั้นตัว Z จะกลืนกับพื้นหลัง
          (isDark ? const Color(0xFFCFCBFF) : _line)
              .withValues(alpha: opacity),
        ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.showBackdrop != showBackdrop ||
      oldDelegate.animation != animation;
}
