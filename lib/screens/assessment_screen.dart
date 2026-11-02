import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../models/sleep_assessment_input.dart';
import '../services/long_sleep_rule.dart';
import '../services/sleep_stats.dart';
import 'loading_screen.dart';

/// หน้ากรอกข้อมูล lifestyle ก่อนส่งไปทำนายคุณภาพการนอน
///
/// Feature ที่ใช้ตอนนี้ (ตาม dataset จริงจากเพื่อน) มี 5 อย่าง:
/// Sleep Duration, Stress Level, Physical Activity Level, Age, Gender
///
/// Age / Gender จะถูกดึงมาจากหน้า Settings > Profile มาเติมให้อัตโนมัติ
/// (เพราะสองค่านี้ไม่ค่อยเปลี่ยนรายวัน) แต่ยังแก้ในฟอร์มนี้ได้ตามปกติ
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  static const _kLastBedtime = 'assessment_last_bedtime';
  static const _kLastWakeTime = 'assessment_last_wake_time';

  // ค่าเริ่มต้นได้ 7 ชม. เท่าค่าเดิมของสไลเดอร์
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 0);
  double _stressLevel = 5;
  double _physicalActivity = 30;
  double _age = 25;
  String _gender = 'Male';
  String _durationUnit = 'hours'; // มาจาก Settings

  @override
  void initState() {
    super.initState();
    _loadProfileDefaults();
  }

  /// ดึงค่า Age / Gender / Duration unit ที่ตั้งไว้ในหน้า Settings
  /// มาเติมให้อัตโนมัติ ถ้าผู้ใช้ยังไม่เคยตั้งค่าไว้ ก็ใช้ค่า default เดิม
  Future<void> _loadProfileDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final savedAge = prefs.getString('settings_age');
    final savedGender = prefs.getString('settings_gender');
    final savedUnit = prefs.getString('settings_duration_unit') ?? 'hours';
    final lastBedtime = parseClockTime(prefs.getString(_kLastBedtime));
    final lastWakeTime = parseClockTime(prefs.getString(_kLastWakeTime));

    setState(() {
      if (savedAge != null && savedAge.isNotEmpty) {
        final parsed = double.tryParse(savedAge);
        if (parsed != null) {
          _age = parsed.clamp(10, 90);
        }
      }
      if (savedGender == 'male') {
        _gender = 'Male';
      } else if (savedGender == 'female') {
        _gender = 'Female';
      }
      _durationUnit = savedUnit;
      if (lastBedtime != null) _bedtime = lastBedtime;
      if (lastWakeTime != null) _wakeTime = lastWakeTime;
    });
  }

  double get _sleepDuration => sleepHoursBetween(_bedtime, _wakeTime);

  Future<void> _pickTime({required bool isBedtime}) async {
    final s = S.current;
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedtime ? _bedtime : _wakeTime,
      helpText: isBedtime ? s.bedtime : s.wakeTime,
      cancelText: s.cancel,
      confirmText: s.ok,
      hourLabelText: s.hourLabel,
      minuteLabelText: s.minuteLabel,
      // ใช้แบบ 24 ชม. เพราะ AM/PM ในหน้านี้แปลไทยไม่ได้
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isBedtime) {
        _bedtime = picked;
      } else {
        _wakeTime = picked;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBedtime, formatClockTime(_bedtime));
    await prefs.setString(_kLastWakeTime, formatClockTime(_wakeTime));
  }

  void _submit() {
    final input = SleepAssessmentInput(
      sleepDuration: _sleepDuration,
      bedtime: formatClockTime(_bedtime),
      wakeTime: formatClockTime(_wakeTime),
      stressLevel: _stressLevel.round(),
      physicalActivity: _physicalActivity.round(),
      age: _age.round(),
      gender: _gender,
    );
    // ใช้ pushReplacement เพราะไม่อยากให้ผู้ใช้กด back แล้วเจอฟอร์มเดิมค้างอยู่
    // ระหว่างที่กำลังรอผลลัพธ์
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoadingScreen(input: input)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showMinutes = _durationUnit == 'minutes';
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.assessmentTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSleepTimesCard(context, showMinutes),
          const SizedBox(height: 16),
          _buildSliderCard(
            context: context,
            title: s.stressLevel,
            subtitle: s.stressLevelHint,
            icon: Icons.psychology_outlined,
            value: _stressLevel,
            min: 1,
            max: 10,
            divisions: 9,
            valueLabel: '${_stressLevel.round()} / 10',
            onChanged: (v) => setState(() => _stressLevel = v),
          ),
          const SizedBox(height: 16),
          _buildSliderCard(
            context: context,
            title: s.physicalActivity,
            subtitle: s.physicalActivityHint,
            icon: Icons.directions_walk,
            value: _physicalActivity,
            min: 0,
            max: 120,
            divisions: 24,
            valueLabel: s.minutesShort(_physicalActivity.round()),
            onChanged: (v) => setState(() => _physicalActivity = v),
          ),
          const SizedBox(height: 16),
          _buildSliderCard(
            context: context,
            title: s.age,
            subtitle: s.ageHint,
            icon: Icons.cake_outlined,
            value: _age,
            min: 10,
            max: 90,
            divisions: 80,
            valueLabel: s.yearsValue(_age.round()),
            onChanged: (v) => setState(() => _age = v),
          ),
          const SizedBox(height: 16),
          _buildGenderCard(context),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _submit,
            child: Text(s.analyze),
          ),
          const SizedBox(height: 8),
          Text(
            s.assessmentDisclaimer,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTimesCard(BuildContext context, bool showMinutes) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.isDark(context)
                      ? AppTheme.primary.withValues(alpha: 0.18)
                      : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bedtime_outlined, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.sleepDuration, style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor(context),
                    )),
                    Text(s.sleepTimesHint, style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMutedColor(context),
                    )),
                  ],
                ),
              ),
              // ค่าที่เก็บจริงยังเป็นชั่วโมงเสมอ (ตรงกับ feature ของโมเดล)
              // แค่เปลี่ยนตัวเลขที่โชว์ตามหน่วยที่ตั้งไว้ใน Settings
              Text(
                showMinutes
                    ? s.minutesShort((_sleepDuration * 60).round())
                    : s.hoursValue(_sleepDuration.toStringAsFixed(1)),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeTile(context, s.bedtime, _bedtime, Icons.nightlight_round, true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTimeTile(context, s.wakeTime, _wakeTime, Icons.wb_sunny_outlined, false),
              ),
            ],
          ),
          if (_sleepDuration > longSleepThresholdFor(_age.round())) ...[
            const SizedBox(height: 10),
            Text(
              s.sleepOverLimitNote(longSleepThresholdFor(_age.round()).round()),
              style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor(context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeTile(
    BuildContext context,
    String label,
    TimeOfDay time,
    IconData icon,
    bool isBedtime,
  ) {
    return Semantics(
      button: true,
      label: '$label ${formatClockTime(time)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickTime(isBedtime: isBedtime),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textMutedColor(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatClockTime(time),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.isDark(context)
                      ? AppTheme.primary.withValues(alpha: 0.18)
                      : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.gender,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(context, 'Male', s.male, Icons.male),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGenderOption(context, 'Female', s.female, Icons.female),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// [value] คือค่าที่ส่งให้โมเดล ('Male' / 'Female') ส่วน [label] คือข้อความที่แสดงตามภาษา
  Widget _buildGenderOption(BuildContext context, String value, String label, IconData icon) {
    final bool selected = _gender == value;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? (AppTheme.isDark(context)
                    ? AppTheme.primary.withValues(alpha: 0.18)
                    : AppTheme.primaryLight)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.borderColor(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? AppTheme.primary : AppTheme.textMutedColor(context)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppTheme.primary : AppTheme.textPrimaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.isDark(context)
                      ? AppTheme.primary.withValues(alpha: 0.18)
                      : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor(context),
                    )),
                    Text(subtitle, style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMutedColor(context),
                    )),
                  ],
                ),
              ),
              Text(valueLabel, style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              )),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              tickMarkShape: SliderTickMarkShape.noTickMark,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}