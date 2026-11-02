import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/sleep_result.dart';
import '../services/sleep_advice.dart';
import '../services/sleep_stats.dart';
import '../theme/app_theme.dart';
import 'stat_chip.dart';

/// การ์ดเนื้อหาของหน้า Stats ที่ไม่ใช้ state ของหน้า รับข้อมูลทางพารามิเตอร์อย่างเดียว

// ต้องมีอย่างน้อยเท่านี้ในแต่ละกลุ่ม ถึงจะแสดงข้อสังเกตเปรียบเทียบ
// (น้อยกว่านี้ค่าเฉลี่ยแกว่งมากจนชวนเข้าใจผิด)
const int _minGroupSize = 3;

double averageScoreOf(Iterable<SleepResult> results) =>
    results.fold<double>(0, (sum, r) => sum + r.displayScore) / results.length;

/// การ์ดพื้นฐานของหน้า Stats
Widget statsCard(
  BuildContext context, {
  required Widget child,
  EdgeInsets? padding,
}) {
  return Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(18),
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

Widget statsCardTitle(BuildContext context, String text) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppTheme.textPrimaryColor(context),
    ),
  );
}

Color _accentPurple(BuildContext context) =>
    AppTheme.isDark(context) ? AppTheme.accent : AppTheme.primary;

Widget _iconTile(BuildContext context, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppTheme.isDark(context)
          ? AppTheme.primary.withValues(alpha: 0.18)
          : AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: _accentPurple(context), size: 18),
  );
}

Widget _insightCell(BuildContext context, String label, double avgScore) {
  final s = S.of(context);
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.primary.withValues(
        alpha: AppTheme.isDark(context) ? 0.14 : 0.06,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          avgScore.round().toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.qualityColor(qualityForScore(avgScore)),
            height: 1.1,
          ),
        ),
        Text(
          s.averageScore,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            color: AppTheme.textMutedColor(context),
          ),
        ),
      ],
    ),
  );
}

/// คะแนนสูงสุด ต่ำสุด และจำนวนครั้งที่เช็กอินในช่วงที่เลือก
class StatsSummaryCard extends StatelessWidget {
  final List<SleepResult> results;

  const StatsSummaryCard({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scores = results.map((r) => r.displayScore);
    final best = results.reduce(
      (a, b) => a.displayScore >= b.displayScore ? a : b,
    );
    final worst = results.reduce(
      (a, b) => a.displayScore <= b.displayScore ? a : b,
    );

    return statsCard(
      context,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatChip(
            label: s.highest,
            value: scores.reduce(math.max).toString(),
            valueColor: AppTheme.qualityColor(best.quality),
          ),
          StatChip(
            label: s.lowest,
            value: scores.reduce(math.min).toString(),
            valueColor: AppTheme.qualityColor(worst.quality),
          ),
          StatChip(label: s.checkIns, value: s.timesCount(results.length)),
        ],
      ),
    );
  }
}

/// สัดส่วนระดับคุณภาพการนอนในช่วงที่เลือก
class QualityBreakdownCard extends StatelessWidget {
  final List<SleepResult> results;

  const QualityBreakdownCard({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const levels = ['Good', 'Fair', 'Poor'];
    final counts = {
      for (final level in levels)
        level: results
            .where((r) => r.quality.toLowerCase() == level.toLowerCase())
            .length,
    };

    return statsCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsCardTitle(context, s.qualityBreakdown),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                for (final level in levels)
                  if (counts[level]! > 0)
                    Expanded(
                      flex: counts[level]!,
                      child: Container(
                        height: 12,
                        color: AppTheme.qualityColor(level),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final level in levels)
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.qualityColor(level),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${s.quality(level)} · ${counts[level]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ปัจจัยที่พบบ่อยในช่วงที่เลือก
class CommonFactorsCard extends StatelessWidget {
  final List<SleepResult> results;

  const CommonFactorsCard({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final counts = <String, int>{};
    for (final r in results) {
      for (final f in r.factors) {
        // ข้อความ "ไม่พบปัจจัยเสี่ยง" ไม่ใช่ปัจจัย จึงไม่นับรวม
        if (f == 'No major risk factors found') continue;
        counts[f] = (counts[f] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return statsCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsCardTitle(context, s.commonFactors),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                s.noRiskFactorsInRange,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textMutedColor(context),
                ),
              ),
            )
          else
            for (final entry in sorted)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    _iconTile(context, factorIcon(entry.key)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.factor(entry.key),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppTheme.textPrimaryColor(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.timesCount(entry.value),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondaryColor(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: entry.value / results.length,
                              minHeight: 5,
                              backgroundColor: AppTheme.borderColor(context),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _accentPurple(context),
                              ),
                            ),
                          ),
                        ],
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

/// คะแนนเฉลี่ยแยกตามวันในสัปดาห์
class WeekdayScoreCard extends StatelessWidget {
  final List<DailySleep> days;

  const WeekdayScoreCard({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const barMaxHeight = 70.0;

    // 1 = Mon ... 7 = Sun
    final byWeekday = <int, List<double>>{};
    for (final d in days) {
      byWeekday.putIfAbsent(d.day.weekday, () => []).add(d.avgScore);
    }

    return statsCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsCardTitle(context, s.scoreByWeekday),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final values = byWeekday[i + 1];
              final avg = values == null
                  ? null
                  : values.reduce((a, b) => a + b) / values.length;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      avg == null ? '–' : avg.round().toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: avg == null
                            ? AppTheme.textMutedColor(context)
                            : AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: barMaxHeight,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 18,
                          height: avg == null
                              ? 4
                              : math.max(4, barMaxHeight * avg / 100),
                          decoration: BoxDecoration(
                            color: avg == null
                                ? AppTheme.borderColor(context)
                                : AppTheme.qualityColor(qualityForScore(avg)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.dayNamesShort[i],
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textMutedColor(context),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// เปรียบเทียบคะแนนระหว่างกลุ่ม ใช้คำว่า "สัมพันธ์" โดยเจตนา ไม่ใช่สาเหตุหรือการวินิจฉัย
/// (ตาม Healthcare Disclaimer ของโปรเจค)
class InsightsCard extends StatelessWidget {
  final List<SleepResult> results;

  const InsightsCard({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // เกณฑ์แบ่งกลุ่มใช้ค่าเดียวกับที่ backend ใช้ตัดสิน "ปัจจัย" แต่ละข้อ
    final comparisons = [
      (
        s.sleepDuration,
        s.insightSleepHigh,
        s.insightSleepLow,
        (SleepResult r) => r.input.sleepDuration >= 6.5,
      ),
      (
        s.stressLevel,
        s.insightStressLow,
        s.insightStressHigh,
        (SleepResult r) => r.input.stressLevel < 7,
      ),
      (
        s.physicalActivity,
        s.insightActivityHigh,
        s.insightActivityLow,
        (SleepResult r) => r.input.physicalActivity >= 20,
      ),
    ];

    final rows = <Widget>[];
    for (final c in comparisons) {
      final groupA = results.where(c.$4).toList();
      final groupB = results.where((r) => !c.$4(r)).toList();
      if (groupA.length < _minGroupSize || groupB.length < _minGroupSize) {
        continue;
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.$1,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _insightCell(context, c.$2, averageScoreOf(groupA)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _insightCell(context, c.$3, averageScoreOf(groupB)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return statsCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsCardTitle(context, s.insightsTitle),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  _iconTile(context, Icons.insights_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.insightsLocked,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppTheme.textMutedColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...rows,
            const SizedBox(height: 14),
            Text(
              s.insightsNote,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppTheme.textMutedColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// คำแนะนำระยะยาวจากแนวโน้มในช่วงที่เลือก (ตรรกะอยู่ที่ sleep_advice.dart)
class LongTermAdviceCard extends StatelessWidget {
  final List<DailySleep> days;

  const LongTermAdviceCard({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tips = longTermAdvice(days);

    return statsCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsCardTitle(context, s.longTermTitle),
          if (tips == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  _iconTile(context, Icons.event_note_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.longTermLocked(minDaysForLongTerm),
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppTheme.textMutedColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const SizedBox(height: 2),
            Text(
              s.longTermBasedOn(days.length),
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.textMutedColor(context),
              ),
            ),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _iconTile(context, tip.icon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.longTermText(tip),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Text(
              s.longTermNote,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppTheme.textMutedColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
