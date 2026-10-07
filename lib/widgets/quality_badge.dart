import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// ป้ายสีเล็กๆ แสดงคำว่า Good / Fair / Poor
/// ใช้ซ้ำทั้งในหน้า Home (รายการล่าสุด) และหน้า Result
class QualityBadge extends StatelessWidget {
  final String quality;
  final double fontSize;

  const QualityBadge({super.key, required this.quality, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.qualityColor(quality);
    final bg = AppTheme.qualityBgColor(quality);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        S.of(context).quality(quality),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
