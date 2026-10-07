import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/device_service.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../models/alarm.dart';
import '../services/alarm_storage_service.dart';
import '../services/alarm_scheduler_service.dart';
import '../services/alarm_notification_service.dart';
import 'alarm_edit_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  List<SleepAlarm> _alarms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _sortByWakeTime(List<SleepAlarm> alarms) => alarms.sort((a, b) =>
      (a.wakeTime.hour * 60 + a.wakeTime.minute)
          .compareTo(b.wakeTime.hour * 60 + b.wakeTime.minute));

  Future<void> _load() async {
    // 1) แสดงรายการจากที่เก็บในเครื่องทันที (อ่านไฟล์เล็กๆ ไม่ต้องรอระบบปลุก)
    var alarms = await AlarmStorageService.instance.loadAlarms();
    _sortByWakeTime(alarms);
    if (!mounted) return;
    setState(() {
      _alarms = alarms;
      _loading = false;
    });

    // 2) แล้วค่อยตรวจ/ตั้งปลุกจริงและ notification เบื้องหลัง
    // ถ้าขั้นนี้พังหรือค้าง หน้ารายการก็ยังใช้งานได้ ไม่ติดวงกลมหมุน
    try {
      alarms = await AlarmScheduler.reconcile(alarms)
          .timeout(const Duration(seconds: 10));
      await AlarmStorageService.instance.saveAlarms(alarms);
    } catch (_) {
      // ตั้งปลุกจริงไม่สำเร็จ — ยังต้องไป sync notification ต่อ ไม่ให้ขั้นนี้ขวางกัน
    }
    // notification "ตั้งปลุกแล้ว" ทำแยกอีก try เสมอ ไม่ว่าขั้นบนจะสำเร็จหรือไม่
    try {
      await AlarmNotificationService.instance
          .syncWithAlarms(alarms)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
    _sortByWakeTime(alarms);
    if (!mounted) return;
    setState(() => _alarms = alarms);
  }

  Future<void> _toggle(SleepAlarm alarm, bool value) async {
    setState(() => alarm.isEnabled = value);
    if (value) {
      await AlarmScheduler.scheduleAlarm(alarm);
    } else {
      await AlarmScheduler.cancelAlarm(alarm);
    }
    await AlarmStorageService.instance.upsertAlarm(alarm);
    await AlarmNotificationService.instance.syncWithAlarms(_alarms);
  }

  Future<void> _delete(SleepAlarm alarm) async {
    await AlarmScheduler.cancelAlarm(alarm);
    await AlarmStorageService.instance.deleteAlarm(alarm.id);
    setState(() => _alarms.removeWhere((a) => a.id == alarm.id));
    await AlarmNotificationService.instance.syncWithAlarms(_alarms);
  }

  Future<void> _openEditor([SleepAlarm? alarm]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AlarmEditScreen(existingAlarm: alarm)),
    );
    if (changed == true) {
      _load();
      _maybeShowXiaomiTip();
    }
  }

  /// มือถือ Xiaomi/Redmi บล็อกการเด้งหน้าปลุกตอนจอดับไว้เป็นค่าเริ่มต้น
  /// แสดงคำแนะนำพร้อมปุ่มพาไปเปิดสิทธิ์ แค่ครั้งเดียวหลังตั้งปลุกสำเร็จ
  Future<void> _maybeShowXiaomiTip() async {
    const key = 'xiaomi_alarm_tip_shown';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return;
    if (!await DeviceService.isXiaomi()) return;
    if (!mounted) return;
    await prefs.setBool(key, true);
    if (!mounted) return;
    final s = S.current;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(s.xiaomiTipTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.xiaomiTipBody),
              const SizedBox(height: 12),
              Text('• ${s.xiaomiTipStep1}'),
              const SizedBox(height: 4),
              Text('• ${s.xiaomiTipStep2}'),
              const SizedBox(height: 12),
              Text(s.xiaomiTipStep3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.later)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.openSettings)),
        ],
      ),
    );
    if (open == true) await DeviceService.openAppPermissions();
  }

  int get _activeCount => _alarms.where((a) => a.isEnabled).length;

  void _showInfoSheet(BuildContext context) {
    final s = S.current;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.textPrimaryColor(ctx).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.nightlight_round, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    s.aboutSleepCycleAlarm,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(ctx),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              s.sleepCycleInfo1,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: AppTheme.textPrimaryColor(ctx).withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                s.sleepCycleInfo2,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppTheme.textPrimaryColor(ctx).withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 22),
                  if (_alarms.isEmpty)
                    _buildEmptyState(context)
                  else
                    ..._alarms.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildTile(context, a),
                        )),
                ],
              ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _openEditor(),
          backgroundColor: AppTheme.primary,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nightlight_round, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // scaleDown: ขนาดเท่าเดิมถ้าพอดี ย่อลงเองเฉพาะจอแคบ ไม่ตัดขึ้นบรรทัดใหม่
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.sleepCycleAlarm,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _alarms.isEmpty
                      ? s.noAlarmsSet
                      : s.alarmsActive(_activeCount, _alarms.length),
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showInfoSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.alarm_off_rounded, size: 40, color: AppTheme.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 18),
          Text(
            s.noAlarmsYet,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor(context).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.noAlarmsHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textPrimaryColor(context).withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, SleepAlarm alarm) {
    final enabled = alarm.isEnabled;
    final s = S.of(context);

    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 26),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(s.deleteAlarmTitle),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.delete, style: TextStyle(color: Colors.red.shade400)),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _delete(alarm),
      child: InkWell(
        onTap: () => _openEditor(alarm),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: enabled
                    ? AppTheme.primary.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: enabled ? 18 : 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: enabled
                          ? AppTheme.primary
                          : AppTheme.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.alarm_rounded,
                      color: enabled ? Colors.white : AppTheme.primary.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      formatTimeOfDay(alarm.wakeTime),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? AppTheme.textPrimaryColor(context)
                            : AppTheme.textPrimaryColor(context).withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Switch(
                    value: enabled,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (v) => _toggle(alarm, v),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ...List.generate(7, (i) {
                    final day = i + 1;
                    final isSelected = alarm.repeatDays.contains(day);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: enabled ? 1 : 0.3)
                              : AppTheme.primary.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s.dayLetters[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimaryColor(context).withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    );
                  }),
                  // ป้ายสรุปวันซ้ำ: ชิดขวาเหมือนเดิม แต่ถ้ายาวเกินพื้นที่จะตัดด้วย … แทนการล้นกรอบ
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alarm.repeatSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary.withValues(alpha: enabled ? 1 : 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}