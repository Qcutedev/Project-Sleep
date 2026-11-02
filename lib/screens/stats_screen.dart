import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/sleep_result.dart';
import '../services/history_service.dart';
import '../services/sleep_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/quality_badge.dart';
import '../widgets/sleep_trend_chart.dart';
import '../widgets/stats_cards.dart';
import 'result_screen.dart';

enum _Range { week, month, threeMonths, all }

/// หน้าสถิติการนอนแบบละเอียด (เปิดจากกราฟในหน้า Home หรือเมนู "ประวัติทั้งหมด")
///
/// ทุกอย่างคำนวณจากประวัติที่เก็บในเครื่องอยู่แล้ว ไม่ได้เรียก backend เพิ่ม
/// การ์ดที่ไม่ใช้ state ของหน้าอยู่ใน `widgets/stats_cards.dart`
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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

  /// ส่วนต่างคะแนนเฉลี่ยเทียบกับช่วงก่อนหน้าที่ยาวเท่ากัน (null = เทียบไม่ได้)
  int? _changeVsPrevious(List<SleepResult> current) {
    if (_range == _Range.all || current.isEmpty) return null;
    final start = _start;
    final prevStart = DateTime(start.year, start.month, start.day - _windowDays);
    final prevEnd = DateTime(start.year, start.month, start.day - 1);
    final previous = _resultsBetween(prevStart, prevEnd);
    if (previous.isEmpty) return null;
    return (averageScoreOf(current) - averageScoreOf(previous)).round();
  }

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
                    StatsSummaryCard(results: results),
                    const SizedBox(height: 16),
                    QualityBreakdownCard(results: results),
                    const SizedBox(height: 16),
                    CommonFactorsCard(results: results),
                    const SizedBox(height: 16),
                    if (days.length >= _minDaysForWeekday) ...[
                      WeekdayScoreCard(days: days),
                      const SizedBox(height: 16),
                    ],
                    InsightsCard(results: results),
                    const SizedBox(height: 16),
                    LongTermAdviceCard(days: days),
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
                results.isEmpty ? '—' : averageScoreOf(results).round().toString(),
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

    return statsCard(
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

    return statsCard(
      context,
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsCardTitle(context, s.checkInsInRange),
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
