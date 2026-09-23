import 'package:flutter/material.dart';

/// ไฟล์นี้เก็บสีและสไตล์ทั้งหมดของแอปไว้ที่เดียว
/// อยากเปลี่ยนธีมทั้งแอป แก้ที่นี่ที่เดียวพอ ไม่ต้องไล่แก้ทุกหน้า
class AppTheme {
  // ---------- ตัวสลับธีมทั้งแอป (Light / Dark / System) ----------
  // ฟังหมด global ทุกที่ที่ MaterialApp รับฟังอยู่ แล้วสลับสีทันทีไม่ต้องรีสตาร์ทแอป
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  // ---------- สีหลัก โทนม่วง-อินดิโก (สื่อถึงกลางคืน/ความสงบ) ----------
  static const Color primary = Color(0xFF4B44C9);
  static const Color primaryDark = Color(0xFF3A34A0);
  static const Color primaryLight = Color(0xFFEEEDFE);
  static const Color accent = Color(0xFF7A72E8);

  static const Color background = Color(0xFFF6F5FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F0FA);

  static const Color textPrimary = Color(0xFF211F35);
  static const Color textSecondary = Color(0xFF6E6B85);
  static const Color textMuted = Color(0xFF9C99B0);
  static const Color border = Color(0xFFE6E4F2);

  // สีตามระดับคุณภาพการนอน ใช้ทั้งหน้า Result และ Home
  static const Color good = Color(0xFF2E9E6C);
  static const Color goodBg = Color(0xFFE3F5EC);
  static const Color fair = Color(0xFFB4740E);
  static const Color fairBg = Color(0xFFFBF0DC);
  static const Color poor = Color(0xFFC44536);
  static const Color poorBg = Color(0xFFFBE7E4);

  static const Color warningBg = Color(0xFFFAEEDA);
  static const Color warningText = Color(0xFF633806);

  // ---------- ชุดสีเวอร์ชัน Dark ----------
  static const Color darkBackground = Color(0xFF14131F);
  static const Color darkSurface = Color(0xFF1E1D2E);
  static const Color darkSurfaceMuted = Color(0xFF262536);

  static const Color darkTextPrimary = Color(0xFFEDECF7);
  static const Color darkTextSecondary = Color(0xFFB2AFC7);
  static const Color darkTextMuted = Color(0xFF7D7A96);
  static const Color darkBorder = Color(0xFF32304A);
  static const Color darkWarningBg = Color(0xFF3A2F14);
  static const Color darkWarningText = Color(0xFFE8C77A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.15),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: accent,
        secondary: accent,
        surface: darkSurface,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: darkTextSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: darkTextMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextSecondary,
          side: const BorderSide(color: darkBorder),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: darkBorder,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.15),
      ),
    );
  }

  /// สีตามระดับคุณภาพการนอน ใช้ตรงกลางบ่อยๆ เลยรวมไว้เป็นฟังก์ชันเดียว
  static Color qualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'good':
        return good;
      case 'fair':
        return fair;
      case 'poor':
        return poor;
      default:
        return textSecondary;
    }
  }

  static Color qualityBgColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'good':
        return goodBg;
      case 'fair':
        return fairBg;
      case 'poor':
        return poorBg;
      default:
        return surfaceMuted;
    }
  }

  // ---------- Helper: ดึงสีตามธีมปัจจุบัน (light/dark) ----------
  // ใช้แทน AppTheme.xxx ตรงๆ ในหน้าที่ต้องรองรับ Dark mode จริง
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color surfaceMutedColor(BuildContext context) =>
      isDark(context) ? darkSurfaceMuted : surfaceMuted;

  static Color textPrimaryColor(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryColor(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color textMutedColor(BuildContext context) =>
      isDark(context) ? darkTextMuted : textMuted;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorder : border;
      
  static Color warningBgColor(BuildContext context) =>
      isDark(context) ? darkWarningBg : warningBg;

  static Color warningTextColor(BuildContext context) =>
      isDark(context) ? darkWarningText : warningText;
}