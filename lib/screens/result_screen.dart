import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/sleep_result.dart';

/// แสดงผลลัพธ์การประเมิน 1 ครั้ง
///
/// ใช้คำว่า "Model Prediction" / "Factors associated with the prediction" /
/// "General Recommendation" ตาม project context ข้อ 15 (Healthcare Disclaimer)
/// หลีกเลี่ยงคำว่า diagnosis / cause โดยเจตนา
class ResultScreen extends StatefulWidget {
  final SleepResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final targetScore = widget.result.displayScore / 100;

    // วงกลมค่อยๆ ไล่จาก 0 ขึ้นไปจนถึงค่าจริง แบบมีหน่วงปลาย (easeOutCubic)
    _progressAnimation = Tween<double>(begin: 0.0, end: targetScore).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // หน่วงเริ่ม animation นิดหน่อย ให้คนดูทันตอนเข้าหน้า
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // สีเฉพาะสำหรับ hero header / ปุ่มเท่านั้น (โทนม่วงอ่อน) — เวอร์ชัน light
  static const Color _buttonStart = Color(0xFF4B43C7);
  static const Color _buttonEnd = Color(0xFF5B51D4);

  Color _accentPurple(BuildContext context) =>
      AppTheme.isDark(context) ? AppTheme.accent : const Color(0xFF554BD0);

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final color = AppTheme.qualityColor(result.quality);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                    child: Column(
                      children: [
                        _buildScoreCard(context, result, color),
                        const SizedBox(height: 14),
                        _buildRecommendationCard(context, result),
                        const SizedBox(height: 20),
                        _buildDisclaimerCard(context),
                        const Spacer(),
                        _buildHomeButton(context),
                      ],
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

  /// Header เรียบง่าย: ปุ่มย้อนกลับ + หัวข้อ + subtitle + เส้นขีดตกแต่งเล็กๆ
  Widget _buildHeader(BuildContext context) {
    final purple = _accentPurple(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
      decoration: BoxDecoration(
        color: AppTheme.isDark(context)
            ? AppTheme.bg(context)
            : const Color(0xFFF4F2FC), // light mode คงสีม่วงอ่อนนิดๆ ไว้เหมือนเดิม
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor(context),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Icon(Icons.arrow_back, size: 17, color: AppTheme.textPrimaryColor(context)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor(context),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bedtime_outlined, size: 13, color: purple),
                      const SizedBox(width: 6),
                      Text(
                        'Night check-in',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: purple),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              'Result',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              "Tonight's sleep quality",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor(context).withValues(alpha: 0.65),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Container(
              width: 42,
              height: 3,
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, SleepResult result, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 158,
            height: 158,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 158,
                      height: 158,
                      child: CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 13,
                        backgroundColor: AppTheme.borderColor(context),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          result.quality,
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, color: color),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${(_progressAnimation.value * 100).round()}/100',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Factors associated\nwith this result',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final factor in result.factors)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.isDark(context)
                              ? AppTheme.primary.withValues(alpha: 0.16)
                              : AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 13, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                factor,
                                style: TextStyle(fontSize: 11, color: AppTheme.textPrimaryColor(context)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, SleepResult result) {
    final purple = _accentPurple(context);
    final isDark = AppTheme.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(colors: [Color(0xFFEAE7FF), Color(0xFFF1EFFF)]),
        color: isDark ? AppTheme.primary.withValues(alpha: 0.14) : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.primary.withValues(alpha: 0.28) : const Color(0xFFE1DDF9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lightbulb_outline, size: 21, color: purple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              result.recommendation,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: AppTheme.textPrimaryColor(context)),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 22, color: purple),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.warningBgColor(context),
        border: Border.all(color: isDark ? AppTheme.darkWarningText.withValues(alpha: 0.3) : const Color(0xFFFFE9BE)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.warningTextColor(context).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, size: 21, color: AppTheme.warningTextColor(context)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'This is a model prediction from an educational prototype, not a medical diagnosis.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: AppTheme.warningTextColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            // เด้งกลับไปหน้า Home ตรงๆ (ข้าม Assessment/Loading ที่ค้างอยู่ใน stack)
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_buttonStart, _buttonEnd]),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: _buttonStart.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_outlined, size: 17, color: Colors.white),
                SizedBox(width: 8),
                Text('Back to home', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
