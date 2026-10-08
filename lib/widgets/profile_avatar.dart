import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

/// รูปโปรไฟล์วงกลม ใช้ทุกที่ที่แสดงโปรไฟล์ (Home, drawer, Settings, Profile)
///
/// ลำดับการแสดง: รูปจากเครื่อง → อวตารสำเร็จรูป → ตัวอักษรแรกของชื่อ → ไอคอนคน
class ProfileAvatar extends StatelessWidget {
  /// id ของอวตารสำเร็จรูปทั้งหมด เรียงตามลำดับที่แสดงให้เลือก
  static const List<String> presetIds = [
    'pup',
    'moon',
    'star',
    'cloud',
    'sun',
    'planet',
  ];

  final UserProfile profile;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 40,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: borderColor,
      ),
      child: ClipOval(child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    switch (profile.avatarType) {
      case AvatarType.photo:
        return Image.file(
          File(profile.avatarValue),
          fit: BoxFit.cover,
          // ไฟล์อาจหายไป (เช่นล้างข้อมูลแอป) ให้ถอยไปใช้ตัวอักษรแทนที่จะเป็นช่องว่าง
          errorBuilder: (context, error, stack) => _fallback(),
        );
      case AvatarType.preset:
        return CustomPaint(painter: _PresetPainter(profile.avatarValue));
      case AvatarType.none:
        return _fallback();
    }
  }

  Widget _fallback() {
    final name = profile.name.trim();
    final inner = size - borderWidth * 2;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent, AppTheme.primaryDark],
        ),
      ),
      child: Center(
        child: name.isEmpty
            ? Icon(Icons.person_rounded, color: Colors.white, size: inner * 0.6)
            : Text(
                name.characters.first.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: inner * 0.46,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
      ),
    );
  }
}

/// อวตารสำเร็จรูป วาดด้วยโค้ดในกรอบ 100x100 แล้วย่อขยายตามขนาดจริง
/// ทุกตัวมีหน้าหลับตาแบบเดียวกันให้เข้าชุดกับธีมการนอน
class _PresetPainter extends CustomPainter {
  final String id;

  const _PresetPainter(this.id);

  static const Color _gold = Color(0xFFF5C454);
  static const Color _blush = Color(0xFFFFB3C7);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    switch (id) {
      case 'moon':
        _moon(canvas);
      case 'star':
        _star(canvas);
      case 'cloud':
        _cloud(canvas);
      case 'sun':
        _sun(canvas);
      case 'planet':
        _planet(canvas);
      default:
        _pup(canvas);
    }
    canvas.restore();
  }

  void _background(Canvas canvas, Color top, Color bottom) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
  }

  Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// หน้าหลับตา: ตาโค้งสองข้าง ปากเล็ก และแก้มชมพู
  void _face(Canvas canvas, Offset c, Color color, {double scale = 1}) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    final blush = Paint()..color = _blush.withValues(alpha: 0.85);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-17, 7), width: 9, height: 5.5),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(17, 7), width: 9, height: 5.5),
      blush,
    );
    final stroke = _line(color, 2.6);
    for (final x in const [-10.0, 10.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x - 4.5, 0)
          ..quadraticBezierTo(x, 4.5, x + 4.5, 0),
        stroke,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(-3, 7)
        ..quadraticBezierTo(0, 10, 3, 7),
      _line(color, 2.2),
    );
    canvas.restore();
  }

  void _dots(Canvas canvas, List<Offset> points) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (final p in points) {
      canvas.drawCircle(p, 1.6, paint);
    }
  }

  void _pup(Canvas canvas) {
    _background(canvas, const Color(0xFFE4E1FF), const Color(0xFFC3BEF7));
    final fur = Paint()..color = Colors.white;
    final outline = _line(AppTheme.primary, 3);
    for (final mirror in const [1.0, -1.0]) {
      canvas.save();
      canvas.translate(50, 44);
      canvas.scale(mirror, 1);
      canvas.rotate(0.55);
      final ear = Path()
        ..moveTo(16, -8)
        ..cubicTo(34, -18, 52, -14, 50, 0)
        ..cubicTo(50, 14, 30, 12, 16, 8)
        ..close();
      canvas.drawPath(ear, fur);
      canvas.drawPath(ear, outline);
      canvas.restore();
    }
    final head = Rect.fromCenter(
      center: const Offset(50, 56),
      width: 62,
      height: 50,
    );
    canvas.drawOval(head, fur);
    canvas.drawOval(head, outline);
    _face(canvas, const Offset(50, 56), AppTheme.primary);
  }

  void _moon(Canvas canvas) {
    _background(canvas, const Color(0xFF4F46E5), const Color(0xFF7C3AED));
    _dots(canvas, const [Offset(76, 24), Offset(84, 46), Offset(20, 22)]);
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: const Offset(46, 52), radius: 30)),
      Path()..addOval(Rect.fromCircle(center: const Offset(66, 42), radius: 26)),
    );
    canvas.drawPath(crescent, Paint()..color = Colors.white);
    // หน้าอยู่บนส่วนหนาของเสี้ยวพระจันทร์ จึงวาดแค่ตากับแก้มข้างเดียว
    canvas.drawPath(
      Path()
        ..moveTo(26, 56)
        ..quadraticBezierTo(30, 60, 34, 56),
      _line(AppTheme.primary, 2.6),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(28, 65), width: 8, height: 5),
      Paint()..color = _blush,
    );
  }

  void _star(Canvas canvas) {
    _background(canvas, const Color(0xFF231E66), const Color(0xFF3F389F));
    _dots(canvas, const [Offset(18, 26), Offset(82, 30), Offset(78, 80)]);
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? 36.0 : 19.0;
      final p = Offset(50 + r * math.cos(angle), 54 + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    // เส้นขอบสีเดียวกับตัวดาวช่วยทำให้ปลายแฉกมน
    canvas.drawPath(path, _line(_gold, 9));
    canvas.drawPath(path, Paint()..color = _gold);
    _face(canvas, const Offset(50, 56), const Color(0xFF8A5A00), scale: 0.85);
  }

  void _cloud(Canvas canvas) {
    _background(canvas, const Color(0xFFA9D4FF), const Color(0xFF7FB5F5));
    final cloud = Path()
      ..addOval(Rect.fromCircle(center: const Offset(30, 58), radius: 17))
      ..addOval(Rect.fromCircle(center: const Offset(50, 46), radius: 23))
      ..addOval(Rect.fromCircle(center: const Offset(72, 58), radius: 17))
      ..addRRect(RRect.fromLTRBR(14, 54, 88, 76, const Radius.circular(11)));
    canvas.drawPath(cloud, Paint()..color = Colors.white);
    _face(canvas, const Offset(50, 58), const Color(0xFF3C6FB5));
  }

  void _sun(Canvas canvas) {
    _background(canvas, const Color(0xFFFFE9B8), const Color(0xFFFFCF87));
    final ray = _line(const Color(0xFFF59A2F), 5);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        const Offset(50, 52) + direction * 33,
        const Offset(50, 52) + direction * 40,
        ray,
      );
    }
    canvas.drawCircle(const Offset(50, 52), 27, Paint()..color = _gold);
    _face(canvas, const Offset(50, 52), const Color(0xFF8A5A00));
  }

  void _planet(Canvas canvas) {
    _background(canvas, const Color(0xFF191548), const Color(0xFF3A34A0));
    _dots(canvas, const [Offset(20, 24), Offset(80, 22), Offset(84, 78)]);
    final ring = Rect.fromCenter(
      center: Offset.zero,
      width: 88,
      height: 26,
    );
    final ringPaint = _line(const Color(0xFFCFCBFF), 4);
    canvas.save();
    canvas.translate(50, 54);
    canvas.rotate(-0.3);
    // ครึ่งหลังของวงแหวนอยู่ใต้ดาว ครึ่งหน้าทับดาว
    canvas.drawArc(ring, math.pi, math.pi, false, ringPaint);
    canvas.restore();
    canvas.drawCircle(
      const Offset(50, 54),
      25,
      Paint()..color = const Color(0xFF9B8CFF),
    );
    canvas.save();
    canvas.translate(50, 54);
    canvas.rotate(-0.3);
    canvas.drawArc(ring, 0, math.pi, false, ringPaint);
    canvas.restore();
    _face(canvas, const Offset(50, 48), const Color(0xFF2B2670), scale: 0.8);
  }

  @override
  bool shouldRepaint(covariant _PresetPainter oldDelegate) =>
      oldDelegate.id != id;
}
