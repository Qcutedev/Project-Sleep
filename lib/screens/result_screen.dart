import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../models/sleep_result.dart';
import '../services/sleep_stats.dart';
import '../widgets/quality_badge.dart';

/// แสดงผลลัพธ์การประเมิน 1 ครั้ง
///
/// ใช้คำว่า "Model Prediction" / "Factors associated with the prediction" /
/// "General Recommendation" ตาม project context ข้อ 15 (Healthcare Disclaimer)
/// หลีกเลี่ยงคำว่า diagnosis / cause โดยเจตนา
///
/// ดีไซน์ชุดเดียวกับหน้า Alarm / Sounds: การ์ดหัวไล่สีม่วง + การ์ดพื้นขาวมุมโค้ง 20
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

  Color _accentPurple(BuildContext context) =>
      AppTheme.isDark(context) ? AppTheme.accent : AppTheme.primary;

  Color _tint(BuildContext context) => AppTheme.isDark(context)
      ? AppTheme.primary.withValues(alpha: 0.18)
      : AppTheme.primaryLight;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildHeader(context, result),
            const SizedBox(height: 16),
            _buildInputsCard(context, result),
            const SizedBox(height: 16),
            _buildFactorsCard(context, result),
            const SizedBox(height: 16),
            _buildRecommendationCard(context, result),
            const SizedBox(height: 16),
            _buildDisclaimerCard(context),
            const SizedBox(height: 24),
            _buildHomeButton(context),
          ],
        ),
      ),
    );
  }

  /// การ์ดหัวไล่สีม่วง: ปุ่มย้อนกลับ + วันที่ของผล + วงแหวนคะแนน + ระดับคุณภาพ
  Widget _buildHeader(BuildContext context, SleepResult result) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.95),
            AppTheme.primary.withValues(alpha: 0.65),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.result,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      s.relativeDate(result.timestamp),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _buildScoreRing(),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.sleepQualityLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    QualityBadge(quality: result.quality, fontSize: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRing() {
    return SizedBox(
      width: 124,
      height: 124,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 124,
                height: 124,
                child: CircularProgressIndicator(
                  value: _progressAnimation.value,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_progressAnimation.value * 100).round()}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _cardTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimaryColor(context),
      ),
    );
  }

  Widget _iconTile(BuildContext context, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _tint(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: _accentPurple(context), size: 18),
    );
  }

  /// ข้อมูลที่ผู้ใช้กรอกตอนประเมินครั้งนี้ — มีประโยชน์ตอนเปิดดูผลย้อนหลัง
  Widget _buildInputsCard(BuildContext context, SleepResult result) {
    final s = S.of(context);
    final input = result.input;

    Widget stat(IconData icon, String value, String label) {
      return Expanded(
        child: Column(
          children: [
            _iconTile(context, icon),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor(context)),
            ),
          ],
        ),
      );
    }

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, s.yourInputs),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stat(
                Icons.bedtime_outlined,
                s.hoursValue(input.sleepDuration.toStringAsFixed(1)),
                s.inputSleep,
              ),
              stat(
                Icons.psychology_outlined,
                '${input.stressLevel} / 10',
                s.inputStress,
              ),
              stat(
                Icons.directions_walk,
                s.minutesShort(input.physicalActivity),
                s.inputActivity,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactorsCard(BuildContext context, SleepResult result) {
    final s = S.of(context);
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, s.factorsTitle),
          const SizedBox(height: 4),
          for (final factor in result.factors)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  _iconTile(context, factorIcon(factor)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.factor(factor),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textPrimaryColor(context),
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

  Widget _buildRecommendationCard(BuildContext context, SleepResult result) {
    final s = S.of(context);
    final purple = _accentPurple(context);
    final isDark = AppTheme.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: isDark ? 0.28 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lightbulb_outline, size: 21, color: purple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.generalRecommendation,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: purple),
                ),
                const SizedBox(height: 4),
                Text(
                  s.recommendation(result.recommendation),
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context) {
    final warningText = AppTheme.warningTextColor(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningBgColor(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: warningText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).resultDisclaimer,
              style: TextStyle(fontSize: 12, height: 1.5, color: warningText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.75)]),
          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // เด้งกลับไปหน้า Home ตรงๆ (ข้าม Assessment/Loading ที่ค้างอยู่ใน stack)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_outlined, size: 19, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  S.of(context).backToHome,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
