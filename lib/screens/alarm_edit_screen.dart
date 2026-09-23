import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/alarm.dart';
import '../services/alarm_notification_service.dart';
import '../services/alarm_storage_service.dart';
import '../services/alarm_scheduler_service.dart';

/// หน้าสร้าง/แก้ไขปลุก 1 อัน (ถ้าส่ง existingAlarm มา = โหมดแก้ไข, ถ้าไม่ส่ง = โหมดสร้างใหม่)
class AlarmEditScreen extends StatefulWidget {
  final SleepAlarm? existingAlarm;
  const AlarmEditScreen({super.key, this.existingAlarm});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late TimeOfDay _wakeTime;
  BedtimeOption? _selectedOption;
  late int _snoozeMinutes;
  late Set<int> _repeatDays;

  bool get _isEditing => widget.existingAlarm != null;

  List<BedtimeOption> get _bedtimeOptions => calculateBedtimeOptions(_wakeTime);

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAlarm;
    _wakeTime = existing?.wakeTime ?? const TimeOfDay(hour: 7, minute: 0);
    _snoozeMinutes = existing?.snoozeMinutes ?? 10;
    _repeatDays = Set<int>.from(existing?.repeatDays ?? {});
    if (existing?.bedtime != null) {
      final match = _bedtimeOptions.where((o) =>
          o.bedtime.hour == existing!.bedtime!.hour &&
          o.bedtime.minute == existing.bedtime!.minute);
      _selectedOption = match.isNotEmpty ? match.first : null;
    }
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _wakeTime = picked;
        _selectedOption = null;
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_repeatDays.contains(day)) {
        _repeatDays.remove(day);
      } else {
        _repeatDays.add(day);
      }
    });
  }

  Future<void> _saveAlarm() async {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bedtime before saving')),
      );
      return;
    }

    final id = widget.existingAlarm?.id ?? AlarmStorageService.instance.generateId();
    final alarm = SleepAlarm(
      id: id,
      wakeTime: _wakeTime,
      bedtime: _selectedOption!.bedtime,
      isEnabled: true,
      repeatDays: _repeatDays,
      snoozeMinutes: _snoozeMinutes,
    );

    if (widget.existingAlarm != null) {
      await AlarmScheduler.cancelAlarm(widget.existingAlarm!);
    }

    await AlarmScheduler.scheduleAlarm(alarm);
    await AlarmStorageService.instance.upsertAlarm(alarm);

    final all = await AlarmStorageService.instance.loadAlarms();
    await AlarmNotificationService.instance.syncWithAlarms(all);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _deleteAlarm() async {
    final existing = widget.existingAlarm;
    if (existing == null) return;
    await AlarmScheduler.cancelAlarm(existing);
    await AlarmStorageService.instance.deleteAlarm(existing.id);

    final all = await AlarmStorageService.instance.loadAlarms();
    await AlarmNotificationService.instance.syncWithAlarms(all);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final options = _bedtimeOptions;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildBedtimeOptionsSection(context, options),
            const SizedBox(height: 24),
            _buildAlarmSettingsCard(context),
            const SizedBox(height: 28),
            _buildSaveButton(context),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              _buildDeleteButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              Text(
                _isEditing ? 'Edit Alarm' : 'New Alarm',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'When do you want to wake up?',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickWakeTime,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Text(
                  formatTimeOfDay(_wakeTime),
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
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

  Widget _buildBedtimeOptionsSection(BuildContext context, List<BedtimeOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended bedtime',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 12),
        ...options.map((opt) => _buildBedtimeTile(context, opt)),
      ],
    );
  }

  Widget _buildBedtimeTile(BuildContext context, BedtimeOption option) {
    final isSelected = _selectedOption?.bedtime == option.bedtime;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedOption = option),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.08),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 16 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.nightlight_round,
                  color: isSelected ? Colors.white : AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTimeOfDay(option.bedtime),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.durationLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textPrimaryColor(context).withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (option.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: isSelected ? 1 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 13, color: isSelected ? Colors.white : AppTheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        'Best',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isSelected)
                Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmSettingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repeat',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = i + 1;
              final isSelected = _repeatDays.contains(day);
              return InkWell(
                onTap: () => _toggleDay(day),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    SleepAlarm.dayLabels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.textPrimaryColor(context).withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No days selected = one-time alarm only',
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.textPrimaryColor(context).withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.06)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.snooze, size: 17, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Snooze',
                    style: TextStyle(fontSize: 13.5, color: AppTheme.textPrimaryColor(context).withValues(alpha: 0.75)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _snoozeMinutes,
                    icon: Icon(Icons.expand_more, size: 18, color: AppTheme.primary),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor(context)),
                    items: const [5, 10, 15, 20].map((m) => DropdownMenuItem(value: m, child: Text('$m min'))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _snoozeMinutes = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
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
            onTap: _saveAlarm,
            child: Center(
              child: Text(
                _isEditing ? 'Save Changes' : 'Set Alarm',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _deleteAlarm,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text('Delete Alarm', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
      ),
    );
  }
}