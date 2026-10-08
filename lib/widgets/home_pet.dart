import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  static const double _halfWidth = 38;
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
  double facing = 1; // ทิศที่กำลังเดินไป: 1 = ขวา, -1 = ซ้าย (ตัวหันหน้าตรงเสมอ)
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
  static const Color _outline = Color(0xFF1A1A1A);
  static const Color _eye = Color(0xFF45B5F0);
  static const Color _blush = Color(0xFFFBC4D8);
  static const Color _tongue = Color(0xFFFF9DB8);

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
    final bounce = math.sin(p.walkPhase).abs() * 1.3 * p.walking;
    final breath = math.sin(p.clock * 2.2);
    final hopY = -15 * p.hop;
    final upright = 1 - lie;

    canvas.save();
    canvas.translate(p.x, size.height);

    // เงาเล็กลงตอนกระโดด และกว้างขึ้นตอนนอนแผ่
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -0.5),
        width: _lerp(26, 52, lie) * (1 - 0.35 * p.hop),
        height: 5,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );

    canvas.save();
    canvas.translate(0, hopY);
    canvas.scale(_scale);
    // เดินสองขาแบบโยกตัวซ้ายขวา
    canvas.rotate(0.07 * step);

    // ตอนนอน ตัวโผล่ออกมาด้านหลังหัวทางฝั่งตรงข้ามกับที่หันไป
    final side = -p.facing;
    final bodyCenter = Offset(
      side * 11 * lie,
      _lerp(-10, -6.5, lie) + 1.5 * sit - bounce * 0.6,
    );
    final bodyHeight = _lerp(15, 12, lie) * (1 + (p.asleep ? 0.05 * breath : 0));

    _paintTail(canvas, bodyCenter + Offset(side * _lerp(8.5, 9, lie), 3), side);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bodyCenter, width: 18, height: bodyHeight),
      const Radius.circular(7.5),
    );
    canvas.drawRRect(body, _fur);
    canvas.drawRRect(body, _stroke(1.8));

    // เท้าสองข้าง ยกสลับกันตอนเดิน ยื่นมาข้างหน้าตอนนั่ง
    if (upright > 0.05) {
      for (final s in const [-1.0, 1.0]) {
        final lift = math.max(0.0, s * step) * 3.2;
        final foot = Rect.fromCenter(
          center: Offset(
            s * _lerp(4.6, 6.5, sit),
            -2.4 - lift * upright - 0.9 * sit,
          ),
          width: _lerp(7.5, 8.5, sit) * upright,
          height: _lerp(5, 6.5, sit) * upright,
        );
        canvas.drawOval(foot, _fur);
        canvas.drawOval(foot, _stroke(1.8));
      }
    }

    // แขนสั้นๆ แกว่งตอนเดิน ชูขึ้นตอนดีใจ
    if (upright > 0.05) {
      for (final s in const [-1.0, 1.0]) {
        final raise = p.happy * 6 + p.hop * 2;
        final arm = Rect.fromCenter(
          center: bodyCenter + Offset(s * 9.2, -1.5 - raise + s * step * 1.6),
          width: 6.2 * upright,
          height: 4.6 * upright,
        );
        canvas.drawOval(arm, _fur);
        canvas.drawOval(arm, _stroke(1.8));
      }
    }

    final headCenter = Offset(
      p.facing * 0.8 * p.walking,
      _lerp(-25, -11, lie) + 2.2 * sit - bounce + (p.asleep ? breath * 0.4 : 0),
    );
    _paintHead(canvas, headCenter, lie);
    _paintFace(canvas, headCenter + Offset(p.facing * 1.3 * p.walking, 0), lie);

    canvas.restore();

    final top = Offset(0, hopY - 40 * _scale);
    if (p.asleep && lie > 0.8) {
      _paintZs(canvas, Offset(p.facing * 12 * _scale, -26 * _scale));
    }
    if (p.heart >= 0) _paintHeart(canvas, top, p.heart);

    canvas.restore();
  }

  /// หัวกับหูสองข้างรวมเป็นรูปทรงเดียว เส้นขอบจึงต่อเนื่องกันเหมือนในภาพต้นแบบ
  void _paintHead(Canvas canvas, Offset head, double lie) {
    final p = pose;
    // หูกางออกข้างและกระพือเบาๆ ชูขึ้นเหมือนปีกตอนกระโดด แผ่ลงพื้นตอนนอน
    final wave = math.sin(p.clock * 2.6) * 0.07 * (1 - lie);
    final flap = math.sin(p.walkPhase * 2 - 0.8) * 0.13 * p.walking;
    final lift = p.hop * 0.75 + p.happy * 0.25;
    final droop = _lerp(0.34, 0.42, lie) + wave + flap - lift;

    var shape = Path()
      ..addOval(Rect.fromCenter(center: head, width: 31, height: 23));
    for (final s in const [-1.0, 1.0]) {
      shape = Path.combine(
        PathOperation.union,
        shape,
        _earPath(head + Offset(s * 10.5, -5.5), s, droop),
      );
    }
    canvas.drawPath(shape, _fur);
    canvas.drawPath(shape, _stroke(1.8));

    // รอยพับที่โคนหู
    for (final s in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(head.dx + s * 12.2, head.dy - 3.5)
          ..quadraticBezierTo(
            head.dx + s * 13.6,
            head.dy - 0.5,
            head.dx + s * 13,
            head.dy + 2.5,
          ),
        _stroke(1.4),
      );
    }
  }

  Path _earPath(Offset root, double side, double droop) {
    const length = 21.0;
    final ear = Path()
      ..moveTo(-3, -4.5)
      ..cubicTo(length * 0.35, -7.5, length * 0.95, -8.5, length, -1)
      ..cubicTo(length * 1.04, 7, length * 0.45, 6.5, -3, 4.5)
      ..close();
    final matrix = Matrix4.identity()
      ..translateByDouble(root.dx, root.dy, 0, 1)
      ..scaleByDouble(side, 1, 1, 1)
      ..rotateZ(droop);
    return ear.transform(matrix.storage);
  }

  /// หางม้วนเป็นวงเหมือนซินนามอนโรล
  void _paintTail(Canvas canvas, Offset center, double side) {
    final wagSpeed = pose.happy > 0 ? 20.0 : 5.0;
    final wag = math.sin(pose.clock * wagSpeed) * (pose.asleep ? 0.03 : 0.22);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(side, 1);
    canvas.rotate(wag);
    canvas.drawCircle(const Offset(3.5, -1), 4.6, _fur);
    canvas.drawCircle(const Offset(3.5, -1), 4.6, _stroke(1.8));
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(3.8, -0.8), radius: 2.1),
      0.6,
      4.3,
      false,
      _stroke(1.4),
    );
    canvas.restore();
  }

  void _paintFace(Canvas canvas, Offset head, double lie) {
    final p = pose;
    final blush = Paint()..color = _blush;
    for (final s in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: head + Offset(s * 10.3, 4.6),
          width: 6.4,
          height: 3.8,
        ),
        blush,
      );
    }

    final closed = math.max(p.blink, lie);
    for (final s in const [-1.0, 1.0]) {
      final eye = head + Offset(s * 7.4, 0.6);
      if (closed > 0.6) {
        // ตาหลับเป็นเส้นสีฟ้าเฉียงลงด้านนอก
        canvas.drawLine(
          eye + Offset(-s * 2.4, -0.4),
          eye + Offset(s * 2.4, 0.9),
          _stroke(1.9, _eye),
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: eye, width: 3.3, height: 4.6 * (1 - closed)),
          Paint()..color = _eye,
        );
      }
    }

    final mouth = head + const Offset(0, 4.4);
    if (p.happy > 0.15) {
      // อ้าปากยิ้มเห็นลิ้น
      final open = Path()
        ..moveTo(mouth.dx - 2.6, mouth.dy - 0.6)
        ..lineTo(mouth.dx + 2.6, mouth.dy - 0.6)
        ..quadraticBezierTo(mouth.dx + 1.6, mouth.dy + 4.6, mouth.dx, mouth.dy + 4.6)
        ..quadraticBezierTo(mouth.dx - 1.6, mouth.dy + 4.6, mouth.dx - 2.6, mouth.dy - 0.6)
        ..close();
      canvas.drawPath(open, Paint()..color = _tongue);
      canvas.drawPath(open, _stroke(1.3));
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(mouth.dx - 2.9, mouth.dy - 0.3)
          ..quadraticBezierTo(mouth.dx - 1.5, mouth.dy + 2.3, mouth.dx, mouth.dy)
          ..quadraticBezierTo(mouth.dx + 1.5, mouth.dy + 2.3, mouth.dx + 2.9, mouth.dy - 0.3),
        _stroke(1.4),
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
