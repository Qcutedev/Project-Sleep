import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../services/alarm_notification_service.dart';
import '../services/alarm_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kDisplayName = 'settings_display_name';
  static const _kAge = 'settings_age';
  static const _kGender = 'settings_gender';
  static const _kDurationUnit = 'settings_duration_unit';
  static const _kSleepReminder = 'settings_sleep_reminder';
  static const _kDailyReminder = 'settings_daily_reminder';
  static const _kAppearance = 'settings_appearance';
  static const _kLanguage = 'settings_language';

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  bool _loading = true;
  String _gender = ''; // '' = not set, 'male' / 'female'
  String _durationUnit = 'hours';
  bool _sleepReminder = false;
  bool _dailyReminder = false;
  String _appearance = 'light';
  String _language = 'en';

  static const String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nameController.text = prefs.getString(_kDisplayName) ?? '';
      _ageController.text = prefs.getString(_kAge) ?? '';
      _gender = prefs.getString(_kGender) ?? '';
      _durationUnit = prefs.getString(_kDurationUnit) ?? 'hours';
      _sleepReminder = prefs.getBool(_kSleepReminder) ?? false;
      _dailyReminder = prefs.getBool(_kDailyReminder) ?? false;
      _appearance = prefs.getString(_kAppearance) ?? 'light';
      _language = prefs.getString(_kLanguage) ?? 'en';
      _loading = false;
    });
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ข้อความใน notification ถูกกำหนดตอนตั้งเวลา จึงใช้ภาษาปัจจุบัน ณ ตอนนั้น
  Future<void> _scheduleSleepReminder() {
    final s = S.current;
    return NotificationService().scheduleDaily(
      id: NotificationService.sleepReminderId,
      hour: 22,
      minute: 0,
      title: s.sleepReminderNotifTitle,
      body: s.sleepReminderNotifBody,
    );
  }

  Future<void> _scheduleDailyReminder() {
    final s = S.current;
    return NotificationService().scheduleDaily(
      id: NotificationService.dailyReminderId,
      hour: 8,
      minute: 0,
      title: s.dailyReminderNotifTitle,
      body: s.dailyReminderNotifBody,
    );
  }

  Future<void> _changeLanguage(String value) async {
    setState(() => _language = value);
    AppLanguage.notifier.value = value;
    await _saveString(_kLanguage, value);
    // notification ที่ตั้งไว้ก่อนหน้ายังเป็นภาษาเดิม ต้องตั้งใหม่ให้ตรงกับภาษาที่เลือก
    if (_sleepReminder) await _scheduleSleepReminder();
    if (_dailyReminder) await _scheduleDailyReminder();
    final alarms = await AlarmStorageService.instance.loadAlarms();
    await AlarmNotificationService.instance.syncWithAlarms(alarms);
  }

  Future<void> _confirmResetAllData() async {
    final s = S.current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.resetDialogTitle),
        content: Text(s.resetDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.poor),
            child: Text(s.resetAllData),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await NotificationService().cancel(NotificationService.sleepReminderId);
      await NotificationService().cancel(NotificationService.dailyReminderId);
      if (!mounted) return;
      setState(() {
        _nameController.clear();
        _ageController.clear();
        _gender = '';
        _durationUnit = 'hours';
        _sleepReminder = false;
        _dailyReminder = false;
        _appearance = 'light';
        _language = 'en';
      });
      AppTheme.themeNotifier.value = ThemeMode.light;
      AppLanguage.notifier.value = 'en';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.current.resetDone)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final textMuted = AppTheme.textMutedColor(context);
    final border = AppTheme.borderColor(context);
    final s = S.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceMutedColor(context),
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _sectionTitle(context, s.profile),
          _placeholderNote(context, s.profileNote),
          _card(
            context,
            child: Column(
              children: [
                _iconRow(
                  context,
                  icon: Icons.person_outline,
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: s.displayName,
                      labelStyle: TextStyle(color: textMuted),
                      hintText: s.displayNameHint,
                      hintStyle: TextStyle(color: textMuted),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => _saveString(_kDisplayName, v),
                  ),
                ),
                Divider(height: 1, color: border),
                _iconRow(
                  context,
                  icon: Icons.cake_outlined,
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: s.age,
                      labelStyle: TextStyle(color: textMuted),
                      hintText: s.ageSettingsHint,
                      hintStyle: TextStyle(color: textMuted),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => _saveString(_kAge, v),
                  ),
                ),
                Divider(height: 1, color: border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.wc_outlined, size: 20, color: textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s.gender, style: TextStyle(fontSize: 13, color: textPrimary)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 4, 16, 14),
                  child: _segmentedToggle(
                    context,
                    value: _gender,
                    options: {'male': s.male, 'female': s.female},
                    onChanged: (v) {
                      setState(() => _gender = v);
                      _saveString(_kGender, v);
                    },
                  ),
                ),
              ],
            ),
          ),

          _sectionTitle(context, s.assessmentPreferences),
          _card(
            context,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 20, color: textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s.durationUnit, style: TextStyle(fontSize: 13, color: textPrimary)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 4, 16, 14),
                  child: _segmentedToggle(
                    context,
                    value: _durationUnit,
                    options: {'hours': s.hours, 'minutes': s.minutes},
                    onChanged: (v) {
                      setState(() => _durationUnit = v);
                      _saveString(_kDurationUnit, v);
                    },
                  ),
                ),
              ],
            ),
          ),

          _sectionTitle(context, s.notifications),
          _card(
            context,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.bedtime_outlined, color: textSecondary),
                  title: Text(s.sleepReminder, style: TextStyle(fontSize: 13, color: textPrimary)),
                  subtitle: Text(
                    s.sleepReminderSubtitle,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                  value: _sleepReminder,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (v) async {
                    setState(() => _sleepReminder = v);
                    await _saveBool(_kSleepReminder, v);
                    if (v) {
                      await _scheduleSleepReminder();
                    } else {
                      await NotificationService().cancel(NotificationService.sleepReminderId);
                    }
                  },
                ),
                Divider(height: 1, color: border),
                SwitchListTile(
                  secondary: Icon(Icons.notifications_outlined, color: textSecondary),
                  title: Text(s.dailyReminder, style: TextStyle(fontSize: 13, color: textPrimary)),
                  subtitle: Text(
                    s.dailyReminderSubtitle,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                  value: _dailyReminder,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (v) async {
                    setState(() => _dailyReminder = v);
                    await _saveBool(_kDailyReminder, v);
                    if (v) {
                      await _scheduleDailyReminder();
                    } else {
                      await NotificationService().cancel(NotificationService.dailyReminderId);
                    }
                  },
                ),
              ],
            ),
          ),

          _sectionTitle(context, s.appearance),
          _card(
            context,
            child: RadioGroup<String>(
              groupValue: _appearance,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _appearance = v);
                _saveString(_kAppearance, v);
                switch (v) {
                  case 'light':
                    AppTheme.themeNotifier.value = ThemeMode.light;
                    break;
                  case 'dark':
                    AppTheme.themeNotifier.value = ThemeMode.dark;
                    break;
                  case 'system':
                    AppTheme.themeNotifier.value = ThemeMode.system;
                    break;
                }
              },
              child: Column(
                children: [
                  _radioRow(
                    context,
                    icon: Icons.light_mode_outlined,
                    label: s.light,
                    value: 'light',
                  ),
                  Divider(height: 1, color: border),
                  _radioRow(
                    context,
                    icon: Icons.dark_mode_outlined,
                    label: s.dark,
                    value: 'dark',
                  ),
                  Divider(height: 1, color: border),
                  _radioRow(
                    context,
                    icon: Icons.settings_suggest_outlined,
                    label: s.systemDefault,
                    value: 'system',
                  ),
                ],
              ),
            ),
          ),

          _sectionTitle(context, s.language),
          _card(
            context,
            child: RadioGroup<String>(
              groupValue: _language,
              onChanged: (v) {
                if (v == null) return;
                _changeLanguage(v);
              },
              child: Column(
                children: [
                  _radioRow(
                    context,
                    icon: Icons.language_rounded,
                    label: 'ไทย',
                    value: 'th',
                  ),
                  Divider(height: 1, color: border),
                  _radioRow(
                    context,
                    icon: Icons.language_rounded,
                    label: 'English',
                    value: 'en',
                  ),
                ],
              ),
            ),
          ),

          _sectionTitle(context, s.privacy),
          _card(
            context,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrivacyLine(text: s.privacyLine1, color: textSecondary),
                  const SizedBox(height: 8),
                  _PrivacyLine(text: s.privacyLine2, color: textSecondary),
                  const SizedBox(height: 8),
                  _PrivacyLine(text: s.privacyLine3, color: textSecondary),
                ],
              ),
            ),
          ),

          _sectionTitle(context, s.about),
          _card(
            context,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bedtime_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SleepWise AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textPrimary)),
                            const SizedBox(height: 2),
                            Text(s.versionLabel(_appVersion), style: TextStyle(fontSize: 11, color: textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.projectName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.projectDescription,
                    style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          _sectionTitle(context, s.resetAppData),
          _card(
            context,
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: AppTheme.poor),
              title: Text(
                s.resetAllData,
                style: const TextStyle(color: AppTheme.poor, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: Text(
                s.resetAllDataSubtitle,
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              onTap: _confirmResetAllData,
            ),
          ),

          _sectionTitle(context, s.appInformation),
          _card(
            context,
            child: Column(
              children: [
                _infoRow(context, s.appNameLabel, 'SleepWise AI'),
                Divider(height: 1, color: border),
                _infoRow(context, s.version, _appVersion),
                Divider(height: 1, color: border),
                _infoRow(context, s.developerTeam, 'SleepWise AI Team'),
                Divider(height: 1, color: border),
                _infoRow(context, s.course, 'CPE310'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondaryColor(context),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _placeholderNote(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor(context), fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _iconRow(BuildContext context, {required IconData icon, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondaryColor(context)),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// แถวตัวเลือกแบบ Radio หนึ่งรายการ
  ///
  /// ไม่ต้องรับ groupValue/onChanged เองแล้ว — ค่าพวกนี้มาจาก
  /// `RadioGroup<String>` ที่ครอบอยู่ข้างนอก (ตาม API ใหม่ของ Flutter)
  Widget _radioRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return RadioListTile<String>(
      value: value,
      activeColor: AppTheme.primary,
      secondary: Icon(icon, color: AppTheme.textSecondaryColor(context)),
      title: Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor(context))),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor(context))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor(context))),
        ],
      ),
    );
  }

  Widget _segmentedToggle(
    BuildContext context, {
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMutedColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options.entries.map((e) {
          final selected = value == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textMutedColor(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PrivacyLine extends StatelessWidget {
  final String text;
  final Color color;
  const _PrivacyLine({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(Icons.check_circle_outline, size: 14, color: AppTheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: color, height: 1.4)),
        ),
      ],
    );
  }
}
