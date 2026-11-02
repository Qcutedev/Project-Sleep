import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../services/onboarding_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

/// หน้าแนะนำแอปตอนเปิดครั้งแรก: ต้อนรับและเลือกภาษา, อธิบายแอปและ disclaimer, ตั้งอายุและเพศ
/// ทุกค่าข้ามได้ และแก้ภายหลังได้ที่หน้าโปรไฟล์กับ Settings
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 3;

  final PageController _pages = PageController();
  int _page = 0;
  double _age = 25;
  String _gender = ''; // '' = ยังไม่เลือก ตรงกับค่าใน ProfileService
  bool _finishing = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _setLanguage(String code) async {
    AppLanguage.notifier.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppLanguage.prefsKey, code);
  }

  void _next() {
    _pages.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish({required bool saveProfile}) async {
    if (_finishing) return;
    _finishing = true;
    if (saveProfile) {
      await ProfileService.instance.setAge(_age.round().toString());
      if (_gender.isNotEmpty) await ProfileService.instance.setGender(_gender);
    }
    await OnboardingService.complete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isLast = _page == _pageCount - 1;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
                child: TextButton(
                  onPressed: () => _finish(saveProfile: false),
                  child: Text(s.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildWelcomePage(context, s),
                  _buildHowItWorksPage(context, s),
                  _buildProfilePage(context, s),
                ],
              ),
            ),
            Semantics(
              label: s.onboardingPageOf(_page + 1, _pageCount),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppTheme.primary
                            : AppTheme.borderColor(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: _PrimaryButton(
                label: isLast ? s.onboardingStart : s.onboardingNext,
                onTap: isLast ? () => _finish(saveProfile: true) : _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(BuildContext context, S s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/images/logo.png',
              width: 112,
              height: 112,
              excludeFromSemantics: true,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          s.onboardingWelcomeTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          s.onboardingWelcomeBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          s.language,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMutedColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _languageOption(context, 'th', 'ไทย')),
            const SizedBox(width: 10),
            Expanded(child: _languageOption(context, 'en', 'English')),
          ],
        ),
      ],
    );
  }

  Widget _languageOption(BuildContext context, String code, String label) {
    return _Choice(
      label: label,
      selected: AppLanguage.notifier.value == code,
      onTap: () => _setLanguage(code),
    );
  }

  Widget _buildHowItWorksPage(BuildContext context, S s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      children: [
        Text(
          s.onboardingHowTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 20),
        _Feature(
          icon: Icons.edit_note_rounded,
          title: s.onboardingStep1Title,
          body: s.onboardingStep1Body,
        ),
        const SizedBox(height: 16),
        _Feature(
          icon: Icons.insights_rounded,
          title: s.onboardingStep2Title,
          body: s.onboardingStep2Body,
        ),
        const SizedBox(height: 16),
        _Feature(
          icon: Icons.alarm_rounded,
          title: s.onboardingStep3Title,
          body: s.onboardingStep3Body,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.warningBgColor(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppTheme.warningTextColor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.onboardingDisclaimer,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppTheme.warningTextColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePage(BuildContext context, S s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      children: [
        Text(
          s.onboardingProfileTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.onboardingProfileBody,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                s.age,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
            ),
            Text(
              s.yearsValue(_age.round()),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: _age,
          min: 10,
          max: 90,
          divisions: 80,
          label: s.yearsValue(_age.round()),
          onChanged: (v) => setState(() => _age = v),
        ),
        const SizedBox(height: 16),
        Text(
          s.gender,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Choice(
                label: s.male,
                selected: _gender == 'male',
                onTap: () => setState(() => _gender = 'male'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Choice(
                label: s.female,
                selected: _gender == 'female',
                onTap: () => setState(() => _gender = 'female'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Feature({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.primary.withValues(alpha: 0.18)
                : AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.accent : AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = isDark ? AppTheme.accent : AppTheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                    ? AppTheme.primary.withValues(alpha: 0.18)
                    : AppTheme.primaryLight)
                : AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : AppTheme.borderColor(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? accent : AppTheme.textPrimaryColor(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppTheme.primary,
                AppTheme.primary.withValues(alpha: 0.75),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
