import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_theme.dart';

/// สิ่งที่มาสคอตกำลังทำอยู่
enum PetMode { walk, idle, sit, sleep, hop, happy }

/// มาสคอตตัวเล็กที่เดินไปมาบนขอบการ์ดสถิติของหน้า Home
///
/// สุ่มสลับท่าทางเอง (เดิน ยืน นั่ง กระโดด นอนหลับ) และกระโดดดีใจเมื่อถูกแตะ
/// วาดด้วย CustomPaint ทั้งหมด วางในแถบที่กว้างเต็มและสูง [laneHeight]
/// โดยเท้าของมาสคอตอยู่ที่ขอบล่างของแถบพอดี
class HomePet extends StatefulWidget {
  static const double laneHeight = 46;

  /// ท่าเริ่มต้น ใช้กำหนดท่าตายตัวตอนตรวจหน้าตา ปกติปล่อยว่างให้เริ่มด้วยการเดิน
  final PetMode? initialMode;

  const HomePet({super.key, this.initialMode});

  @override
  State<HomePet> createState() => _HomePetState();
}

class _HomePetState extends State<HomePet> with SingleTickerProviderStateMixin {
  // ครึ่งความกว้างของตัว ใช้กันไม่ให้เดินเลยขอบแถบ
  static const double _halfWidth = 30;
  static const double _walkSpeed = 24; // พิกเซลต่อวินาที

  final _pose = _PetPose();
  final _random = math.Random();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _laneWidth = 0;
  bool _started = false;

  PetMode _mode = PetMode.walk;
  double _modeTime = 0;
  double _modeDuration = 3;
  double _clock = 0;
  double _nextBlink = 2;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ถ้าผู้ใช้ปิดอนิเมชันในตั้งค่าของเครื่อง ให้มาสคอตนั่งนิ่งๆ
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
      _pose
        ..sit = 1
        ..notify();
    } else if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pose.dispose();
    super.dispose();
  }

  void _enter(PetMode mode) {
    _mode = mode;
    _modeTime = 0;
    _modeDuration = switch (mode) {
      PetMode.walk => 2.5 + _random.nextDouble() * 3.5,
      PetMode.idle => 1.5 + _random.nextDouble() * 2,
      PetMode.sit => 3 + _random.nextDouble() * 3,
      PetMode.sleep => 7 + _random.nextDouble() * 5,
      PetMode.hop => 0.6,
      PetMode.happy => 1.3,
    };
    if (mode == PetMode.walk && _random.nextBool()) {
      _pose.facing = -_pose.facing;
    }
  }

  PetMode _pickNext() {
    // ตื่นจากการนอนแล้วยืนงงๆ ก่อน และดีใจเสร็จก็ยืนต่อ
    if (_mode == PetMode.sleep || _mode == PetMode.happy) return PetMode.idle;

    // ดึกแล้วมาสคอตก็ง่วง จะนอนบ่อยกว่าตอนกลางวัน
    final hour = DateTime.now().hour;
    final sleepy = hour >= 22 || hour < 5;
    final roll = _random.nextDouble();
    if (roll < (sleepy ? 0.4 : 0.1)) return PetMode.sleep;

    if (_mode == PetMode.walk) {
      final next = _random.nextDouble();
      if (next < 0.4) return PetMode.idle;
      if (next < 0.7) return PetMode.sit;
      if (next < 0.85) return PetMode.hop;
      return PetMode.walk;
    }
    final next = _random.nextDouble();
    if (next < 0.65) return PetMode.walk;
    if (next < 0.8) return PetMode.hop;
    return _mode == PetMode.sit ? PetMode.idle : PetMode.sit;
  }

  void _onTick(Duration elapsed) {
    // จำกัดช่วงเวลาต่อเฟรม กันมาสคอตวาร์ปตอนแอปกลับมาจากเบื้องหลัง
    final dt = math.min(
      (elapsed - _lastTick).inMicroseconds / 1e6,
      0.05,
    );
    _lastTick = elapsed;
    if (_laneWidth <= 0) return;

    _clock += dt;
    _modeTime += dt;
    if (_modeTime >= _modeDuration) _enter(_pickNext());

    final pose = _pose;
    final minX = _halfWidth;
    final maxX = math.max(minX, _laneWidth - _halfWidth);

    if (_mode == PetMode.walk) {
      pose.x += pose.facing * _walkSpeed * dt;
      if (pose.x >= maxX) {
        pose.x = maxX;
        pose.facing = -1;
      } else if (pose.x <= minX) {
        pose.x = minX;
        pose.facing = 1;
      }
      pose.walkPhase += dt * 9;
    }
    pose.x = pose.x.clamp(minX, maxX);

    // ค่าท่าทางค่อยๆ เลื่อนเข้าหาเป้าหมาย จะได้ไม่เปลี่ยนท่าแบบกระตุก
    double approach(double value, double target, double rate) =>
        value + (target - value) * math.min(1, dt * rate);
    pose.walking = approach(pose.walking, _mode == PetMode.walk ? 1 : 0, 8);
    pose.sit = approach(pose.sit, _mode == PetMode.sit ? 1 : 0, 6);
    pose.lie = approach(pose.lie, _mode == PetMode.sleep ? 1 : 0, 4);

    final u = (_modeTime / _modeDuration).clamp(0.0, 1.0);
    pose.hop = switch (_mode) {
      PetMode.hop => math.sin(math.pi * u),
      // ดีใจ: กระโดดสองทีติดกัน
      PetMode.happy => math.sin(math.pi * ((u * 2) % 1)).abs() * (1 - 0.3 * u),
      _ => 0,
    };
    pose.happy = _mode == PetMode.happy ? math.sin(math.pi * u) : 0;
    pose.heart = _mode == PetMode.happy ? u : -1;
    pose.asleep = _mode == PetMode.sleep;
    pose.clock = _clock;

    // กะพริบตาเป็นช่วงๆ
    if (_clock >= _nextBlink + 0.16) {
      _nextBlink = _clock + 2 + _random.nextDouble() * 3;
    }
    final blinkU = (_clock - _nextBlink) / 0.16;
    pose.blink = (blinkU >= 0 && blinkU <= 1) ? math.sin(math.pi * blinkU) : 0;

    pose.notify();
  }

  void _onTapDown(TapDownDetails details) {
    if ((details.localPosition.dx - _pose.x).abs() > _halfWidth) return;
    if (_mode == PetMode.happy) return;
    _enter(PetMode.happy);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _laneWidth = constraints.maxWidth;
        if (!_started && _laneWidth > 0) {
          _started = true;
          _pose.x = _laneWidth * 0.3;
          final initial = widget.initialMode;
          if (initial != null) {
            _enter(initial);
            _pose.facing = 1;
            // ท่าตายตัวเริ่มที่ท่านั้นเลย ไม่ต้องค่อยๆ เลื่อนเข้า
            _pose
              ..sit = initial == PetMode.sit ? 1 : 0
              ..lie = initial == PetMode.sleep ? 1 : 0
              ..walking = initial == PetMode.walk ? 1 : 0
              ..asleep = initial == PetMode.sleep;
          }
        }
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: _onTapDown,
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(_laneWidth, HomePet.laneHeight),
              painter: _PetPainter(_pose),
            ),
          ),
        );
      },
    );
  }
}

/// ค่าท่าทางของมาสคอตในเฟรมปัจจุบัน painter วาดใหม่ทุกครั้งที่ [notify]
class _PetPose extends ChangeNotifier {
  double x = 0;
  double facing = 1; // 1 = หันขวา, -1 = หันซ้าย
  double walkPhase = 0;
  double walking = 0; // 0..1
  double sit = 0; // 0..1
  double lie = 0; // 0..1
  double hop = 0; // 0..1 ความสูงของการกระโดด
  double happy = 0; // 0..1
  double heart = -1; // ความคืบหน้าของหัวใจที่ลอยขึ้น, -1 = ไม่มี
  double blink = 0; // 0 = ลืมตา, 1 = หลับตา
  double clock = 0;
  bool asleep = false;

  void notify() => notifyListeners();
}

class _PetPainter extends CustomPainter {
  static const double _scale = 1.12;
  static const Color _outline = AppTheme.primaryDark;
  static const Color _face = Color(0xFF2B2670);
  static const Color _blush = Color(0xFFFFB3C7);
  static const Color _gold = Color(0xFFF5C454);
  static const Color _farLeg = Color(0xFFE6E3FB);

  final _PetPose pose;

  _PetPainter(this.pose) : super(repaint: pose);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  Paint get _fur => Paint()..color = Colors.white;

  Paint _stroke(double width, [Color color = _outline]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final p = pose;
    final lie = Curves.easeInOut.transform(p.lie.clamp(0.0, 1.0));
    final sit = Curves.easeInOut.transform(p.sit.clamp(0.0, 1.0));
    final step = math.sin(p.walkPhase) * p.walking;
    final bounce = math.sin(p.walkPhase * 2).abs() * 1.4 * p.walking;
    final breath = math.sin(p.clock * 2.2);
    final hopY = -15 * p.hop;

    canvas.save();
    canvas.translate(p.x, size.height);

    // เงาเล็กลงตอนกระโดด
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -0.5),
        width: (40 + 8 * lie) * (1 - 0.35 * p.hop),
        height: 5,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );

    canvas.save();
    canvas.translate(0, hopY);
    canvas.scale(_scale * p.facing, _scale);

    final legScale = 1 - lie;
    final headCenter = Offset(
      _lerp(9, 12, lie),
      _lerp(-25, -11.5, lie) - bounce + 1.5 * sit + (p.asleep ? breath * 0.5 : 0),
    );

    // ขาฝั่งไกลอยู่หลังตัว สีเข้มกว่านิดหนึ่งให้ดูมีมิติ
    // ตอนนั่ง ขาหลังพับเก็บใต้ตัวจึงไม่วาด
    _leg(canvas, -8, -step, legScale * (1 - sit), _farLeg);
    _leg(canvas, 7, step, legScale, _farLeg);

    // ลำตัวและหาง เอนลงด้านหลังตอนนั่ง
    canvas.save();
    canvas.translate(4, -9);
    canvas.rotate(-0.32 * sit);
    canvas.translate(-4, 9);
    final bodyCenter = Offset(-3, _lerp(-14, -8.5, lie) - bounce * 0.6 + 2 * sit);
    final wagSpeed = p.happy > 0 ? 22.0 : (p.walking > 0.5 ? 9.0 : 4.0);
    final wag = math.sin(p.clock * wagSpeed) * (p.asleep ? 0.05 : 0.35);
    final tailBase = bodyCenter + Offset(-13 - 2 * lie, -3 + 2 * lie);
    final tail = tailBase + Offset(-1.5 * math.cos(wag), -2 - 3.5 * math.sin(wag + 0.6));
    canvas.drawCircle(tail, 5, _fur);
    canvas.drawCircle(tail, 5, _stroke(2));
    final body = Rect.fromCenter(
      center: bodyCenter,
      width: _lerp(30, 35, lie),
      height: _lerp(19, 15, lie) * (1 + (p.asleep ? 0.05 * breath : 0)),
    );
    canvas.drawOval(body, _fur);
    canvas.drawOval(body, _stroke(2));
    canvas.restore();

    _leg(canvas, -12, step, legScale * (1 - sit), Colors.white);
    _leg(canvas, 3, -step, legScale, Colors.white);

    // หูปลิวขึ้นตอนกระโดด และแผ่ราบตอนนอน
    final flop = math.sin(p.walkPhase * 2 - 0.8) * 0.16 * p.walking;
    final lift = p.hop * 0.9;
    _ear(
      canvas,
      headCenter + const Offset(-8, -5),
      _lerp(2.15, 2.95, lie) + flop + lift,
      20,
    );
    _ear(
      canvas,
      headCenter + const Offset(9, -6),
      _lerp(0.95, 0.3, lie) - flop - lift,
      16,
    );

    canvas.drawCircle(headCenter, 13, _fur);
    canvas.drawCircle(headCenter, 13, _stroke(2));

    if (lie > 0.5) _cap(canvas, headCenter, (lie - 0.5) * 2);
    _paintFace(canvas, headCenter, lie);

    canvas.restore();

    // ตัว Z และหัวใจวาดนอกการกลับด้าน ไม่อย่างนั้นตอนหันซ้ายตัว Z จะกลับหัวกลับหาง
    final top = Offset(p.facing * 14 * _scale, hopY - 34 * _scale);
    if (p.asleep && lie > 0.8) {
      _paintZs(canvas, Offset(p.facing * 20 * _scale, -26 * _scale));
    }
    if (p.heart >= 0) _paintHeart(canvas, top, p.heart);

    canvas.restore();
  }

  void _leg(Canvas canvas, double x, double swing, double length, Color color) {
    if (length <= 0.05) return;
    canvas.save();
    canvas.translate(x, -8.5);
    canvas.rotate(swing * 0.5);
    final leg = RRect.fromLTRBR(-3.2, 0, 3.2, 8.5 * length, const Radius.circular(3.2));
    canvas.drawRRect(leg, Paint()..color = color);
    canvas.drawRRect(leg, _stroke(2));
    canvas.restore();
  }

  void _ear(Canvas canvas, Offset pivot, double angle, double length) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    final ear = Path()
      ..moveTo(-2, -3.5)
      ..cubicTo(length * 0.4, -7.5, length * 0.98, -7.5, length, -0.5)
      ..cubicTo(length * 1.02, 6.5, length * 0.4, 6, -2, 4)
      ..close();
    canvas.drawPath(ear, _fur);
    canvas.drawPath(ear, _stroke(2));
    canvas.restore();
  }

  /// หมวกนอน โผล่มาเฉพาะตอนหลับ
  void _cap(Canvas canvas, Offset head, double opacity) {
    final alpha = opacity.clamp(0.0, 1.0);
    final cap = Path()
      ..moveTo(head.dx - 9, head.dy - 9.5)
      ..quadraticBezierTo(head.dx - 9, head.dy - 17, head.dx - 12, head.dy - 22)
      ..cubicTo(head.dx - 2, head.dy - 24, head.dx + 7, head.dy - 19,
          head.dx + 8, head.dy - 10.5)
      ..quadraticBezierTo(head.dx, head.dy - 15, head.dx - 9, head.dy - 9.5)
      ..close();
    canvas.drawPath(
      cap,
      Paint()..color = const Color(0xFFB9B3FF).withValues(alpha: alpha),
    );
    canvas.drawPath(cap, _stroke(2, _outline.withValues(alpha: alpha)));
    final pom = Offset(head.dx - 13, head.dy - 22);
    canvas.drawCircle(pom, 3, Paint()..color = _gold.withValues(alpha: alpha));
    canvas.drawCircle(pom, 3, _stroke(1.6, _outline.withValues(alpha: alpha)));
  }

  void _paintFace(Canvas canvas, Offset head, double lie) {
    final p = pose;
    final blush = Paint()..color = _blush.withValues(alpha: 0.9);
    canvas.drawOval(
      Rect.fromCenter(center: head + const Offset(-6.5, 5.5), width: 6, height: 3.6),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(center: head + const Offset(10, 5.5), width: 5, height: 3.6),
      blush,
    );

    final closed = math.max(p.blink, lie);
    for (final dx in const [-2.5, 7.5]) {
      final eye = head + Offset(dx, 1);
      if (p.happy > 0.15) {
        // ตายิ้มตอนดีใจ
        canvas.drawPath(
          Path()
            ..moveTo(eye.dx - 2.4, eye.dy + 1)
            ..quadraticBezierTo(eye.dx, eye.dy - 2.4, eye.dx + 2.4, eye.dy + 1),
          _stroke(1.8, _face),
        );
      } else if (closed > 0.6) {
        canvas.drawPath(
          Path()
            ..moveTo(eye.dx - 2.4, eye.dy)
            ..quadraticBezierTo(eye.dx, eye.dy + 2.2, eye.dx + 2.4, eye.dy),
          _stroke(1.8, _face),
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: eye, width: 3, height: 4.2 * (1 - closed)),
          Paint()..color = _face,
        );
        canvas.drawCircle(
          eye + const Offset(0.6, -0.9),
          0.7,
          Paint()..color = Colors.white,
        );
      }
    }

    final mouth = head + const Offset(2.5, 5.2);
    if (p.happy > 0.15) {
      // อ้าปากยิ้ม
      canvas.drawArc(
        Rect.fromCenter(center: mouth, width: 5, height: 5),
        0,
        math.pi,
        true,
        Paint()..color = const Color(0xFFFF8FAB),
      );
      canvas.drawArc(
        Rect.fromCenter(center: mouth, width: 5, height: 5),
        0,
        math.pi,
        true,
        _stroke(1.4, _face),
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(mouth.dx - 2.6, mouth.dy)
          ..quadraticBezierTo(mouth.dx - 1.3, mouth.dy + 2, mouth.dx, mouth.dy)
          ..quadraticBezierTo(mouth.dx + 1.3, mouth.dy + 2, mouth.dx + 2.6, mouth.dy),
        _stroke(1.5, _face),
      );
    }
  }

  void _paintZs(Canvas canvas, Offset origin) {
    for (var i = 0; i < 3; i++) {
      final raw = pose.clock / 3 + i / 3;
      final u = raw - raw.floorToDouble();
      final opacity = (u / 0.15).clamp(0.0, 1.0) * ((1 - u) / 0.4).clamp(0.0, 1.0);
      if (opacity <= 0) continue;
      final wobble = math.sin(2 * math.pi * (u * 1.5 + i / 3));
      final s = 4 + 6 * u;
      canvas.save();
      canvas.translate(origin.dx + 12 * u + 2.5 * wobble, origin.dy - 26 * u);
      canvas.rotate(wobble * 0.14);
      canvas.drawPath(
        Path()
          ..moveTo(-s / 2, -s / 2)
          ..lineTo(s / 2, -s / 2)
          ..lineTo(-s / 2, s / 2)
          ..lineTo(s / 2, s / 2),
        _stroke(s * 0.28, Colors.white.withValues(alpha: opacity)),
      );
      canvas.restore();
    }
  }

  void _paintHeart(Canvas canvas, Offset origin, double u) {
    final opacity = (u / 0.15).clamp(0.0, 1.0) * ((1 - u) / 0.35).clamp(0.0, 1.0);
    if (opacity <= 0) return;
    final s = 5 + 3 * Curves.easeOutBack.transform(math.min(1, u * 3));
    canvas.save();
    canvas.translate(origin.dx + 3 * math.sin(u * 8), origin.dy - 20 * u);
    final heart = Path()
      ..moveTo(0, s * 0.9)
      ..cubicTo(-s * 1.5, -s * 0.1, -s * 0.7, -s * 1.1, 0, -s * 0.35)
      ..cubicTo(s * 0.7, -s * 1.1, s * 1.5, -s * 0.1, 0, s * 0.9)
      ..close();
    canvas.drawPath(
      heart,
      Paint()..color = const Color(0xFFFF7FA3).withValues(alpha: opacity),
    );
    canvas.drawPath(heart, _stroke(1.4, Colors.white.withValues(alpha: opacity)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PetPainter oldDelegate) =>
      oldDelegate.pose != pose;
}
