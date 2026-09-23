import 'package:flutter/material.dart';
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

  Future<void> _load() async {
    var alarms = await AlarmStorageService.instance.loadAlarms();
    alarms = await AlarmScheduler.reconcile(alarms);
    await AlarmStorageService.instance.saveAlarms(alarms);
    await AlarmNotificationService.instance.syncWithAlarms(alarms);
    alarms.sort((a, b) =>
        (a.wakeTime.hour * 60 + a.wakeTime.minute)
            .compareTo(b.wakeTime.hour * 60 + b.wakeTime.minute));
    if (!mounted) return;
    setState(() {
      _alarms = alarms;
      _loading = false;
    });
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
    if (changed == true) _load();
  }

  int get _activeCount => _alarms.where((a) => a.isEnabled).length;

  void _showInfoSheet(BuildContext context) {
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
                Text(
                  'About Sleep Cycle Alarm',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor(ctx),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This feature helps you plan your bedtime and wake-up time '
              'using the sleep cycle concept as a guideline, so you wake up '
              'when your body is more likely to feel ready. It does not '
              'replace or change the app\'s AI sleep quality prediction '
              'system in any way.',
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
                'A sleep cycle includes Light Sleep, Deep Sleep, and REM, '
                'and typically lasts around 90 minutes. This is only an '
                'estimate for planning purposes, not a fixed number — '
                'getting enough sleep still matters more than trying to '
                'wake up at an exact cycle boundary.',
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
                const Text(
                  'Sleep Cycle Alarm',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _alarms.isEmpty
                      ? 'No alarms set'
                      : '$_activeCount of ${_alarms.length} active',
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
            'No alarms yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor(context).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the + button to set your first sleep alarm',
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
          title: const Text('Delete this alarm?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
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
                          SleepAlarm.dayLabels[i],
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
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alarm.repeatSummary,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary.withValues(alpha: enabled ? 1 : 0.5),
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