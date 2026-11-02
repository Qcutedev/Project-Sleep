import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// ตาม project context ข้อ 15: แอปต้องมีข้อความ disclaimer ว่าเป็น
/// ต้นแบบเพื่อการศึกษา ไม่ได้มีวัตถุประสงค์เพื่อวินิจฉัย/รักษา/ทดแทนแพทย์
///
/// ตัวเลขเกี่ยวกับโมเดลในหน้านี้วัดจากไฟล์โมเดลจริง ดูที่มาใน docs/MODEL_CARD.md
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(title: Text(s.about)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _Section(
            icon: Icons.info_outline,
            title: s.aboutTitle,
            children: [_BodyText(s.aboutBody)],
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.psychology_outlined,
            title: s.aboutModelTitle,
            children: [
              _BodyText(s.aboutModelType),
              _BodyText(s.aboutModelInfluence),
              _BodyText(s.aboutModelRange),
              _BodyText(s.aboutModelRules),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.lock_outline,
            title: s.aboutDataTitle,
            children: [_BodyText(s.aboutDataBody)],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.warningBgColor(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: AppTheme.warningTextColor(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.aboutDisclaimer,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppTheme.warningTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.primary.withValues(alpha: 0.18)
                      : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark ? AppTheme.accent : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: AppTheme.textSecondaryColor(context),
        ),
      ),
    );
  }
}
