import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/sleep_result.dart';
import '../services/sleep_stats.dart';
import '../services/weekly_summary.dart';
import '../theme/app_theme.dart';
import 'stat_chip.dart';

/// สรุปสัปดาห์นี้เทียบกับเป้าหมายการนอน ไม่แสดงอะไรเลยถ้าสัปดาห์นี้ยังไม่มีข้อมูล
/// รวมระยะห่างด้านล่างไว้ในตัว จะได้หายไปทั้งก้อน
class WeeklySummaryCard extends StatefulWidget {
  final List<SleepResult> history;

  const WeeklySummaryCard({super.key, required this.history});

  @override
  State<WeeklySummaryCard> createState() => _WeeklySummaryCardState();
}

class _WeeklySummaryCardState extends State<WeeklySummaryCard> {
  double _goal = SleepGoalService.defaultHours;

  @override
  void initState() {
    super.initState();
    SleepGoalService.load().then((goal) {
      if (mounted) setState(() => _goal = goal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = weeklySummary(widget.history, _goal, DateTime.now());
    if (summary == null) return const SizedBox.shrink();

    final s = S.of(context);
    final isDark = AppTheme.isDark(context);
    final accent = isDark ? AppTheme.accent : AppTheme.primary;
    final muted = AppTheme.textMutedColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.weeklySummaryTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StatChip(
                    label: s.averageScore,
                    value: summary.avgScore.round().toString(),
                    valueColor: AppTheme.qualityColor(qualityForScore(summary.avgScore)),
                  ),
                ),
                Expanded(
                  child: StatChip(
                    label: s.avgDuration,
                    value: s.hoursValue(summary.avgHours.toStringAsFixed(1)),
                  ),
                ),
                Expanded(
                  child: StatChip(
                    label: s.checkIns,
                    value: s.timesCount(summary.daysCheckedIn),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              s.goalProgress(
                summary.daysMetGoal,
                summary.daysCheckedIn,
                _goal.toStringAsFixed(_goal == _goal.roundToDouble() ? 0 : 1),
              ),
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor(context)),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: summary.daysMetGoal / summary.daysCheckedIn,
                minHeight: 6,
                backgroundColor: AppTheme.borderColor(context),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                semanticsLabel: s.sleepGoalTitle,
              ),
            ),
            if (summary.scoreChange != null) ...[
              const SizedBox(height: 12),
              Text(
                s.weeklyChange(summary.scoreChange!),
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor(context)),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              s.weeklyNote,
              style: TextStyle(fontSize: 11, height: 1.4, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
