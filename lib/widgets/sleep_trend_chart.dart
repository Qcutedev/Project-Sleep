import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/sleep_stats.dart';
import '../theme/app_theme.dart';

/// กราฟเส้นแนวโน้มการนอน 1 จุดต่อ 1 วัน ใช้ร่วมกันทั้งหน้า Home และหน้าสถิติ
///
/// แกน X คือวันตามปฏิทินจริงนับจาก [start] ยาว [windowDays] วัน
/// วันที่ไม่ได้เช็กอินจะเว้นว่างไว้ (เส้นลากข้ามไป) ไม่ถูกบีบให้ชิดกัน
/// จุดแต่ละวันมีสีตามระดับคุณภาพการนอนของวันนั้น
class SleepTrendChart extends StatelessWidget {
  final List<DailySleep> days; // เฉพาะวันที่อยู่ในช่วง [start, start + windowDays)
  final DateTime start;
  final int windowDays;
  final TrendMetric metric;
  final bool interactive; // true = แตะจุดเพื่อดูค่าได้
  final double height;

  const SleepTrendChart({
    super.key,
    required this.days,
    required this.start,
    required this.windowDays,
    this.metric = TrendMetric.score,
    this.interactive = false,
    this.height = 150,
  });

  double get _maxY {
    switch (metric) {
      case TrendMetric.score:
        return 100;
      case TrendMetric.duration:
        return 12;
      case TrendMetric.stress:
        return 10;
      case TrendMetric.activity:
        final peak = days.fold<double>(0, (m, d) => math.max(m, d.avgActivity));
        return math.max(120, (peak / 30).ceil() * 30).toDouble();
    }
  }

  double get _yInterval {
    switch (metric) {
      case TrendMetric.score:
        return 25;
      case TrendMetric.duration:
        return 3;
      case TrendMetric.stress:
        return 5;
      case TrendMetric.activity:
        return _maxY / 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mutedColor = AppTheme.textMutedColor(context);

    if (days.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            s.noDataInRange,
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
        ),
      );
    }

    final byOffset = {for (final d in days) daysBetween(start, d.day): d};
    final offsets = byOffset.keys.toList()..sort();
    final isWeekView = windowDays <= 7;
    final labelStep = isWeekView ? 1 : (windowDays / 5).ceil();
    final dense = days.length > 31;
    final dotRing = AppTheme.surfaceColor(context);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (windowDays - 1).toDouble(),
          minY: 0,
          maxY: _maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: interactive,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => AppTheme.isDark(context)
                  ? AppTheme.darkSurfaceMuted
                  : AppTheme.textPrimary,
              getTooltipItems: (spots) => spots.map((spot) {
                final day = byOffset[spot.x.round()];
                if (day == null) return null;
                return LineTooltipItem(
                  '${day.day.day}/${day.day.month} · ${s.quality(day.quality)}\n',
                  TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  children: [
                    TextSpan(
                      text: formatMetric(s, metric, spot.y),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _yInterval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 10, color: mutedColor),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (value != index.toDouble() ||
                      index < 0 ||
                      index >= windowDays ||
                      index % labelStep != 0) {
                    return const SizedBox.shrink();
                  }
                  final date =
                      DateTime(start.year, start.month, start.day + index);
                  final label = isWeekView
                      ? s.dayNamesShort[date.weekday - 1]
                      : '${date.day}/${date.month}';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 10, color: mutedColor),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppTheme.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  final day = byOffset[spot.x.round()];
                  final color = day == null
                      ? AppTheme.primary
                      : AppTheme.qualityColor(day.quality);
                  return FlDotCirclePainter(
                    radius: dense ? 2.5 : 4,
                    color: color,
                    strokeWidth: dense ? 0 : 2,
                    strokeColor: dotRing,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
              spots: [
                for (final offset in offsets)
                  FlSpot(offset.toDouble(), byOffset[offset]!.valueFor(metric)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
