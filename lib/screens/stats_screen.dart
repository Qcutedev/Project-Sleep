import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/sleep_result.dart';
import '../services/history_service.dart';
import '../services/sleep_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/quality_badge.dart';
import '../widgets/sleep_trend_chart.dart';
import '../widgets/stat_chip.dart';
import 'result_screen.dart';

enum _Range { week, month, threeMonths, all }

/// หน้าสถิติการนอนแบบละเอียด (เปิดจากกราฟในหน้า Home หรือเมนู "ประวัติทั้งหมด")
///
/// ทุกอย่างคำนวณจากประวัติที่เก็บในเครื่องอยู่แล้ว ไม่ได้เรียก backend เพิ่ม
/// ข้อความในส่วน "ข้อสังเกต" ใช้คำว่า "สัมพันธ์" โดยเจตนา ไม่ใช่สาเหตุ/การวินิจฉัย
/// (ตาม Healthcare Disclaimer ของโปรเจค)
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // ต้องมีอย่างน้อยเท่านี้ในแต่ละกลุ่ม ถึงจะแสดงข้อสังเกตเปรียบเทียบ
  // (น้อยกว่านี้ค่าเฉลี่ยแกว่งมากจนชวนเข้าใจผิด)
  static const int _minGroupSize = 3;
  // ต้องมีข้อมูลอย่างน้อยเท่านี้วัน ถึงจะแสดงกราฟเฉลี่ยตามวันในสัปดาห์
  static const int _minDaysForWeekday = 7;
  static const int _collapsedListCount = 10;

  final HistoryService _historyService = HistoryService();
  List<SleepResult> _history = [];
  bool _loading = true;

  _Range _range = _Range.week;
  TrendMetric _metric = TrendMetric.score;
  bool _showAllCheckIns = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _historyService.getHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  DateTime get _today => dateOnly(DateTime.now());

  int get _windowDays {
    switch (_range) {
      case _Range.week:
        return 7;
      case _Range.month:
        return 30;
      case _Range.threeMonths:
        return 90;
      case _Range.all:
        if (_history.isEmpty) return 7;
        final first = _history
            .map((r) => r.timestamp)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        return math.max(7, daysBetween(first, _today) + 1);
    }
  }

  DateTime get _start {
    final t = _today;
    // ช่วง 7 วัน = สัปดาห์นี้ เรียงจันทร์ → อาทิตย์
    if (_range == _Range.week) {
      return DateTime(t.year, t.month, t.day - (t.weekday - 1));
    }
    return DateTime(t.year, t.month, t.day - (_windowDays - 1));
  }

  List<SleepResult> _resultsBetween(DateTime from, DateTime toInclusive) {
    return _history.where((r) {
      final d = dateOnly(r.timestamp);
      return !d.isBefore(from) && !d.isAfter(toInclusive);
    }).toList();
  }

  static double _avgScore(Iterable<SleepResult> results) =>
      results.fold<double>(0, (sum, r) => sum + r.displayScore) / results.length;

  /// ส่วนต่างคะแนนเฉลี่ยเทียบกับช่วงก่อนหน้าที่ยาวเท่ากัน (null = เทียบไม่ได้)
  int? _changeVsPrevious(List<SleepResult> current) {
    if (_range == _Range.all || current.isEmpty) return null;
    final start = _start;
    final prevStart = DateTime(start.year, start.month, start.day - _windowDays);
    final prevEnd = DateTime(start.year, start.month, start.day - 1);
    final previous = _resultsBetween(prevStart, prevEnd);
    if (previous.isEmpty) return null;
    return (_avgScore(current) - _avgScore(previous)).round();
  }

  Color _tint(BuildContext context) => AppTheme.isDark(context)
      ? AppTheme.primary.withValues(alpha: 0.18)
      : AppTheme.primaryLight;

  Color _accentPurple(BuildContext context) =>
      AppTheme.isDark(context) ? AppTheme.accent : AppTheme.primary;

  @override
  Widget build(BuildContext context) {
    final results = _resultsBetween(_start, _today);
    final days = groupByDay(results);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _buildHeader(context, results),
                  const SizedBox(height: 20),
                  _buildRangeTabs(context),
                  const SizedBox(height: 20),
                  if (results.isEmpty)
                    _buildEmptyState(context)
                  else ...[
                    _buildChartCard(context, days),
                    const SizedBox(height: 16),
                    _buildSummaryCard(context, results),
                    const SizedBox(height: 16),
                    _buildQualityCard(context, results),
                    const SizedBox(height: 16),
                    _buildFactorsCard(context, results),
                    const SizedBox(height: 16),
                    if (days.length >= _minDaysForWeekday) ...[
                      _buildWeekdayCard(context, days),
                      const SizedBox(height: 16),
                    ],
                    _buildInsightsCard(context, results),
                    const SizedBox(height: 16),
                    _buildCheckInList(context, results),
                  ],
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeader(BuildContext context, List<SleepResult> results) {
    final s = S.of(context);
    final change = _changeVsPrevious(results);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 26),
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
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.sleepStats,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            s.averageScore,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                results.isEmpty ? '—' : _avgScore(results).round().toString(),
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              if (change != null) Flexible(child: _buildChangeChip(s, change)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeChip(S s, int change) {
    final IconData icon;
    final String text;
    if (change > 0) {
      icon = Icons.trending_up_rounded;
      text = s.changeUp(change);
    } else if (change < 0) {
      icon = Icons.trending_down_rounded;
      text = s.changeDown(-change);
    } else {
      icon = Icons.trending_flat_rounded;
      text = s.changeNone;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- range tabs

  Widget _buildRangeTabs(BuildContext context) {
    final s = S.of(context);
    final options = [
      (_Range.week, s.range7Days),
      (_Range.month, s.range1Month),
      (_Range.threeMonths, s.range3Months),
      (_Range.all, s.rangeAll),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: options.map((opt) {
          final selected = _range == opt.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _range = opt.$1;
                _showAllCheckIns = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    opt.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------- shared pieces

  Widget _card(BuildContext context, {required Widget child, EdgeInsets? padding}) {
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

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bar_chart_rounded, size: 34, color: AppTheme.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).noDataInRange,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMutedColor(context)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- chart

  Widget _buildChartCard(BuildContext context, List<DailySleep> days) {
    final s = S.of(context);
    final options = [
      (TrendMetric.score, s.metricScore),
      (TrendMetric.duration, s.metricSleep),
      (TrendMetric.stress, s.metricStress),
      (TrendMetric.activity, s.metricActivity),
    ];

    return _card(
      context,
      padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMutedColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: options.map((opt) {
                final selected = _metric == opt.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _metric = opt.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          opt.$2,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppTheme.textMutedColor(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          SleepTrendChart(
            days: days,
            start: _start,
            windowDays: _windowDays,
            metric: _metric,
            interactive: true,
            height: 200,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- summary

  Widget _buildSummaryCard(BuildContext context, List<SleepResult> results) {
    final s = S.of(context);
    final scores = results.map((r) => r.displayScore);
    final best = results.reduce((a, b) => a.displayScore >= b.displayScore ? a : b);
    final worst = results.reduce((a, b) => a.displayScore <= b.displayScore ? a : b);

    return _card(
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
          StatChip(
            label: s.checkIns,
            value: s.timesCount(results.length),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- quality breakdown

  Widget _buildQualityCard(BuildContext context, List<SleepResult> results) {
    final s = S.of(context);
    const levels = ['Good', 'Fair', 'Poor'];
    final counts = {
      for (final level in levels)
        level: results.where((r) => r.quality.toLowerCase() == level.toLowerCase()).length,
    };

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, s.qualityBreakdown),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                for (final level in levels)
                  if (counts[level]! > 0)
                    Expanded(
                      flex: counts[level]!,
                      child: Container(height: 12, color: AppTheme.qualityColor(level)),
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
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor(context)),
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

  // ---------------------------------------------------------------- common factors

  Widget _buildFactorsCard(BuildContext context, List<SleepResult> results) {
    final s = S.of(context);
    final counts = <String, int>{};
    for (final r in results) {
      for (final f in r.factors) {
        // ข้อความ "ไม่พบปัจจัยเสี่ยง" ไม่ใช่ปัจจัย จึงไม่นับรวม
        if (f == 'No major risk factors found') continue;
        counts[f] = (counts[f] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, s.commonFactors),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                s.noRiskFactorsInRange,
                style: TextStyle(fontSize: 12.5, color: AppTheme.textMutedColor(context)),
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
                                  style: TextStyle(fontSize: 13.5, color: AppTheme.textPrimaryColor(context)),
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
                              valueColor: AlwaysStoppedAnimation<Color>(_accentPurple(context)),
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

  // ---------------------------------------------------------------- by weekday

  Widget _buildWeekdayCard(BuildContext context, List<DailySleep> days) {
    final s = S.of(context);
    const barMaxHeight = 70.0;

    // 1 = Mon ... 7 = Sun
    final byWeekday = <int, List<double>>{};
    for (final d in days) {
      byWeekday.putIfAbsent(d.day.weekday, () => []).add(d.avgScore);
    }

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, s.scoreByWeekday),
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
                          height: avg == null ? 4 : math.max(4, barMaxHeight * avg / 100),
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
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textMutedColor(context)),
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

  // ---------------------------------------------------------------- insights

  Widget _buildInsightsCard(BuildContext context, List<SleepResult> results) {
    final s = S.of(context);

    // เกณฑ์แบ่งกลุ่มใช้ค่าเดียวกับที่ backend ใช้ตัดสิน "ปัจจัย" แต่ละข้อ
    final comparisons = [
      (s.sleepDuration, s.insightSleepHigh, s.insightSleepLow,
          (SleepResult r) => r.input.sleepDuration >= 6.5),
      (s.stressLevel, s.insightStressLow, s.insightStressHigh,
          (SleepResult r) => r.input.stressLevel < 7),
      (s.physicalActivity, s.insightActivityHigh, s.insightActivityLow,
          (SleepResult r) => r.input.physicalActivity >= 20),
    ];

    final rows = <Widget>[];
    for (final c in comparisons) {
      final groupA = results.where(c.$4).toList();
      final groupB = results.where((r) => !c.$4(r)).toList();
      if (groupA.length < _minGroupSize || groupB.length < _minGroupSize) continue;
      rows.add(Padding(
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
                Expanded(child: _insightCell(context, c.$2, _avgScore(groupA))),
                const SizedBox(width: 10),
                Expanded(child: _insightCell(context, c.$3, _avgScore(groupB))),
              ],
            ),
          ],
        ),
      ));
    }

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, s.insightsTitle),
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
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: AppTheme.textMutedColor(context)),
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
              style: TextStyle(fontSize: 11, height: 1.4, color: AppTheme.textMutedColor(context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _insightCell(BuildContext context, String label, double avgScore) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: AppTheme.isDark(context) ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor(context)),
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
            style: TextStyle(fontSize: 10.5, color: AppTheme.textMutedColor(context)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- check-in list

  Widget _buildCheckInList(BuildContext context, List<SleepResult> results) {
    final s = S.of(context);
    final newestFirst = results.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final hasMore = newestFirst.length > _collapsedListCount;
    final visible = _showAllCheckIns
        ? newestFirst
        : newestFirst.take(_collapsedListCount).toList();
    final border = AppTheme.borderColor(context);

    return _card(
      context,
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, s.checkInsInRange),
          const SizedBox(height: 8),
          for (final r in visible)
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ResultScreen(result: r)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: border, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${s.relativeDate(r.timestamp)} · ${_formatTime(r.timestamp)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor(context)),
                      ),
                    ),
                    Text(
                      r.displayScore.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    QualityBadge(quality: r.quality),
                    Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMutedColor(context)),
                  ],
                ),
              ),
            ),
          if (hasMore)
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showAllCheckIns = !_showAllCheckIns),
                icon: Icon(
                  _showAllCheckIns ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                ),
                label: Text(_showAllCheckIns ? s.showLess : s.showMore),
                style: TextButton.styleFrom(foregroundColor: _accentPurple(context)),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
