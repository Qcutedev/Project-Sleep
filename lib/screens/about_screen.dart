import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// ตาม project context ข้อ 15: แอปต้องมีข้อความ disclaimer ว่าเป็น
/// ต้นแบบเพื่อการศึกษา ไม่ได้มีวัตถุประสงค์เพื่อวินิจฉัย/รักษา/ทดแทนแพทย์
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.about)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            s.aboutTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            s.aboutBody,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.warningBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.warningText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.aboutDisclaimer,
                    style: const TextStyle(fontSize: 12, color: AppTheme.warningText, height: 1.5),
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
