import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

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

  Future<void> _confirmResetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This will delete all your settings and assessment history. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.poor),
            child: const Text('Reset All Data'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All app data has been reset')),
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

    return Scaffold(
      backgroundColor: AppTheme.surfaceMutedColor(context),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _sectionTitle(context, 'Profile'),
          _placeholderNote(context, 'This info is used to auto-fill your Sleep Assessment'),
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
                      labelText: 'Display name',
                      labelStyle: TextStyle(color: textMuted),
                      hintText: 'e.g. Alex',
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
                      labelText: 'Age',
                      labelStyle: TextStyle(color: textMuted),
                      hintText: 'Used to auto-fill your sleep assessment',
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
                        child: Text('Gender', style: TextStyle(fontSize: 13, color: textPrimary)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 4, 16, 14),
                  child: _segmentedToggle(
                    context,
                    value: _gender,
                    options: const {'male': 'Male', 'female': 'Female'},
                    onChanged: (v) {
                      setState(() => _gender = v);
                      _saveString(_kGender, v);
                    },
                  ),
                ),
              ],
            ),
          ),

          _sectionTitle(context, 'Sleep Assessment Preferences'),
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
                        child: Text('Sleep duration unit', style: TextStyle(fontSize: 13, color: textPrimary)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 4, 16, 14),
                  child: _segmentedToggle(
                    context,
                    value: _durationUnit,
                    options: const {'hours': 'Hours', 'minutes': 'Minutes'},
                    onChanged: (v) {
                      setState(() => _durationUnit = v);
                      _saveString(_kDurationUnit, v);
                    },
                  ),
                ),
              ],
            ),
          ),

          _sectionTitle(context, 'Notifications'),
          _card(
            context,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.bedtime_outlined, color: textSecondary),
                  title: Text('Sleep reminder', style: TextStyle(fontSize: 13, color: textPrimary)),
                  subtitle: Text(
                    'Reminds you to go to bed every day at 10:00 PM',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                  value: _sleepReminder,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (v) async {
                    setState(() => _sleepReminder = v);
                    await _saveBool(_kSleepReminder, v);
                    if (v) {
                      await NotificationService().scheduleDaily(
                        id: NotificationService.sleepReminderId,
                        hour: 22,
                        minute: 0,
                        title: 'Time to sleep 🌙',
                        body: 'Head to bed now for better sleep quality tonight.',
                      );
                    } else {
                      await NotificationService().cancel(NotificationService.sleepReminderId);
                    }
                  },
                ),
                Divider(height: 1, color: border),
                SwitchListTile(
                  secondary: Icon(Icons.notifications_outlined, color: textSecondary),
                  title: Text('Daily reminder', style: TextStyle(fontSize: 13, color: textPrimary)),
                  subtitle: Text(
                    'Reminds you to complete your sleep assessment every day at 8:00 AM',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                  value: _dailyReminder,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (v) async {
                    setState(() => _dailyReminder = v);
                    await _saveBool(_kDailyReminder, v);
                    if (v) {
                      await NotificationService().scheduleDaily(
                        id: NotificationService.dailyReminderId,
                        hour: 8,
                        minute: 0,
                        title: 'Check in on your sleep 📝',
                        body: 'Complete today\'s sleep assessment — it only takes a minute.',
                      );
                    } else {
                      await NotificationService().cancel(NotificationService.dailyReminderId);
                    }
                  },
                ),
              ],
            ),
          ),

          _sectionTitle(context, 'Appearance'),
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
                    label: 'Light',
                    value: 'light',
                  ),
                  Divider(height: 1, color: border),
                  _radioRow(
                    context,
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark',
                    value: 'dark',
                  ),
                  Divider(height: 1, color: border),
                  _radioRow(
                    context,
                    icon: Icons.settings_suggest_outlined,
                    label: 'System default',
                    value: 'system',
                  ),
                ],
              ),
            ),
          ),

          _sectionTitle(context, 'Language'),
          _placeholderNote(context, 'App text stays in English for now — this choice is saved for later'),
          _card(
            context,
            child: RadioGroup<String>(
              groupValue: _language,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _language = v);
                _saveString(_kLanguage, v);
              },
              child: Column(
                children: [
                  _radioRow(
                    context,
                    icon: Icons.language_rounded,
                    label: 'Thai',
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

          _sectionTitle(context, 'Privacy'),
          _card(
            context,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrivacyLine(text: 'Data you enter is used only to run the sleep assessment.', color: textSecondary),
                  const SizedBox(height: 8),
                  _PrivacyLine(text: 'This app is an educational prototype.', color: textSecondary),
                  const SizedBox(height: 8),
                  _PrivacyLine(text: 'It is not a medical diagnostic system.', color: textSecondary),
                ],
              ),
            ),
          ),

          _sectionTitle(context, 'About'),
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
                            Text('Version $_appVersion', style: TextStyle(fontSize: 11, color: textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CPE310 — Healthcare AI Project',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A prototype mobile app that estimates sleep quality from a short '
                    'daily check-in, built as a class project to explore how a simple '
                    'ML model can be paired with a friendly, easy-to-use interface.',
                    style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          _sectionTitle(context, 'Reset App Data'),
          _card(
            context,
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: AppTheme.poor),
              title: const Text(
                'Reset All Data',
                style: TextStyle(color: AppTheme.poor, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: Text(
                'Deletes settings and all saved check-ins from this device',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              onTap: _confirmResetAllData,
            ),
          ),

          _sectionTitle(context, 'App Information'),
          _card(
            context,
            child: Column(
              children: [
                _infoRow(context, 'App name', 'SleepWise AI'),
                Divider(height: 1, color: border),
                _infoRow(context, 'Version', _appVersion),
                Divider(height: 1, color: border),
                _infoRow(context, 'Developer / Team', 'SleepWise AI Team'),
                Divider(height: 1, color: border),
                _infoRow(context, 'Course', 'CPE310'),
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
