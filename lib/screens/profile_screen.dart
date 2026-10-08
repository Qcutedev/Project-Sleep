import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/sleep_result.dart';
import '../services/history_service.dart';
import '../services/profile_service.dart';
import '../services/sleep_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';

/// หน้าโปรไฟล์: รูป ชื่อ สรุปการเช็กอิน และข้อมูลที่ใช้เติมแบบประเมิน
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profiles = ProfileService.instance;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  List<SleepResult> _history = [];
  bool _pickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _profiles.profile.value.name;
    _ageController.text = _profiles.profile.value.age;
    _loadHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await HistoryService().getHistory();
    if (!mounted) return;
    setState(() => _history = history);
  }

  Future<void> _pickPhoto() async {
    if (_pickingPhoto) return;
    setState(() => _pickingPhoto = true);
    try {
      await _profiles.pickPhoto();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.current.photoPickFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(title: Text(s.profile)),
      body: ValueListenableBuilder<UserProfile>(
        valueListenable: _profiles.profile,
        builder: (context, profile, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _buildHeaderCard(context, profile),
              const SizedBox(height: 16),
              _buildStatsCard(context),
              const SizedBox(height: 16),
              _buildAvatarCard(context, profile),
              const SizedBox(height: 16),
              _buildDetailsCard(context, profile),
              const SizedBox(height: 14),
              Text(
                s.profileStoredLocally,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMutedColor(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, UserProfile profile) {
    final s = S.of(context);
    final details = [
      if (int.tryParse(profile.age) != null) s.ageYears(int.parse(profile.age)),
      if (profile.gender == 'male') s.male,
      if (profile.gender == 'female') s.female,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
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
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ProfileAvatar(
                  profile: profile,
                  size: 104,
                  borderColor: Colors.white,
                  borderWidth: 3,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.name.isEmpty ? s.noNameYet : profile.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: profile.name.isEmpty ? 0.8 : 1,
              ),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              details,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _cardTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimaryColor(context),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final s = S.of(context);
    final average = _history.isEmpty
        ? null
        : _history.fold<int>(0, (sum, r) => sum + r.displayScore) /
            _history.length;
    return _card(
      context,
      child: Row(
        children: [
          _statColumn(context, '${_history.length}', s.profileCheckIns),
          _statDivider(context),
          _statColumn(
            context,
            _history.isEmpty ? '—' : s.streakDays(checkInStreak(_history)),
            s.streak,
          ),
          _statDivider(context),
          _statColumn(
            context,
            average == null ? '—' : average.round().toString(),
            s.averageScore,
          ),
        ],
      ),
    );
  }

  Widget _statDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppTheme.borderColor(context),
    );
  }

  Widget _statColumn(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.isDark(context)
                    ? AppTheme.accent
                    : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(BuildContext context, UserProfile profile) {
    final s = S.of(context);
    final hasAvatar = profile.avatarType != AvatarType.none;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, s.profilePicture),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickingPhoto ? null : _pickPhoto,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(s.choosePhoto),
                  ),
                ),
              ),
              if (hasAvatar) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _profiles.removeAvatar,
                  style: TextButton.styleFrom(foregroundColor: AppTheme.poor),
                  child: Text(s.removePhoto),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            s.chooseAvatar,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final id in ProfileAvatar.presetIds)
                _presetOption(
                  context,
                  id,
                  selected: profile.avatarType == AvatarType.preset &&
                      profile.avatarValue == id,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetOption(BuildContext context, String id,
      {required bool selected}) {
    return GestureDetector(
      onTap: () => _profiles.setPresetAvatar(id),
      child: ProfileAvatar(
        profile: UserProfile(avatarType: AvatarType.preset, avatarValue: id),
        size: 50,
        borderWidth: 3,
        borderColor: selected
            ? (AppTheme.isDark(context) ? AppTheme.accent : AppTheme.primary)
            : Colors.transparent,
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, UserProfile profile) {
    final s = S.of(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textMuted = AppTheme.textMutedColor(context);
    final border = AppTheme.borderColor(context);

    InputDecoration decoration(String label, String hint) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textMuted),
          hintText: hint,
          hintStyle: TextStyle(color: textMuted),
          border: InputBorder.none,
        );

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, s.yourDetails),
          const SizedBox(height: 2),
          Text(
            s.profileNote,
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 6),
          _fieldRow(
            context,
            icon: Icons.person_outline,
            child: TextField(
              controller: _nameController,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: textPrimary),
              decoration: decoration(s.displayName, s.displayNameHint)
                  .copyWith(counterText: ''),
              onChanged: _profiles.setName,
            ),
          ),
          Divider(height: 1, color: border),
          _fieldRow(
            context,
            icon: Icons.cake_outlined,
            child: TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              maxLength: 3,
              style: TextStyle(color: textPrimary),
              decoration: decoration(s.age, s.ageHint)
                  .copyWith(counterText: ''),
              onChanged: _profiles.setAge,
            ),
          ),
          Divider(height: 1, color: border),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.wc_outlined,
                size: 20,
                color: AppTheme.textSecondaryColor(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.gender,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _genderToggle(context, profile.gender),
        ],
      ),
    );
  }

  Widget _fieldRow(BuildContext context,
      {required IconData icon, required Widget child}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondaryColor(context)),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }

  Widget _genderToggle(BuildContext context, String value) {
    final s = S.of(context);
    final options = {'male': s.male, 'female': s.female};
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMutedColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final option in options.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => _profiles.setGender(option.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: value == option.key
                        ? AppTheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: value == option.key
                          ? Colors.white
                          : AppTheme.textMutedColor(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
