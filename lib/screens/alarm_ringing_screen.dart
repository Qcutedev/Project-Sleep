import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import '../theme/app_theme.dart';
import '../services/alarm_notification_service.dart';

/// หน้าที่ปรากฏขึ้นเต็มจอเมื่อนาฬิกาปลุกดังจริง
/// กด Stop เพื่อหยุดเสียง หรือกด Snooze เพื่อเลื่อนปลุกออกไปสักครู่แล้วปลุกใหม่
/// ธีมเดียวกับหน้า Now Playing (ม่วงเข้ม)
class AlarmRingingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;
  final int snoozeMinutes;

  const AlarmRingingScreen({
    super.key,
    required this.alarmSettings,
    this.snoozeMinutes = 5,
  });

  Future<void> _stop(BuildContext context) async {
    await Alarm.stop(alarmSettings.id);
    // ปลุกดังจบแล้ว (ผู้ใช้ตื่นแล้ว) เอา notification "ตั้งปลุกไว้" ที่ค้างอยู่ออก
    await AlarmNotificationService.instance.cancel();
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze(BuildContext context) async {
    // หยุดเสียงปลุกรอบนี้ก่อน แล้วตั้งปลุกใหม่ที่ id เดิม เวลา = ตอนนี้ + snoozeMinutes
    await Alarm.stop(alarmSettings.id);

    final newDateTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
    final snoozedSettings = alarmSettings.copyWith(dateTime: newDateTime);
    await Alarm.set(alarmSettings: snoozedSettings);

    // อัปเดต notification ค้างไว้ให้ตรงกับเวลาปลุกใหม่หลัง snooze
    await AlarmNotificationService.instance.showSnoozeNotification(newDateTime);

    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.isDark(context) ? AppTheme.primaryDark : AppTheme.primary;
    final time = TimeOfDay.fromDateTime(alarmSettings.dateTime);
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false, // กันปุ่ม back หนีหน้านี้โดยไม่กด Stop หรือ Snooze
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.alarm_rounded, color: Colors.white, size: 68),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Time to wake up',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  timeLabel,
                  style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _stop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: bgColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Stop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => _snooze(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Snooze $snoozeMinutes min',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
