import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/sleep_result.dart';
import '../services/sleep_stats.dart';
import '../theme/app_theme.dart';
import 'stat_chip.dart';

/// เวลาเข้านอนเฉลี่ยและความคลาดเคลื่อน ไม่แสดงอะไรเลยถ้าข้อมูลยังไม่พอ
/// (ประวัติเก่าไม่มีเวลาเข้านอน) รวมระยะห่างด้านบนไว้ในตัว จะได้หายไปทั้งก้อน
class BedtimeConsistencyCard extends StatelessWidget {
  final List<SleepResult> results;

  const BedtimeConsistencyCard({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final data = bedtimeConsistency(results);
    if (data == null) return const SizedBox.shrink();

    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
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
              s.bedtimeConsistencyTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.bedtimeNights(data.nights),
              style: TextStyle(fontSize: 11.5, color: AppTheme.textMutedColor(context)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StatChip(
                    label: s.averageBedtime,
                    value: formatClockTime(data.averageBedtime),
                  ),
                ),
                Expanded(
                  child: StatChip(
                    label: s.bedtimeSpread,
                    value: s.bedtimeSpreadValue(data.spreadMinutes),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              s.bedtimeNote,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppTheme.textMutedColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
