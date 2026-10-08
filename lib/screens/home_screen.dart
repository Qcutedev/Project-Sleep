import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../models/sleep_result.dart';
import '../services/history_service.dart';
import '../services/profile_service.dart';
import '../services/sleep_stats.dart';
import '../widgets/sleep_trend_chart.dart';
import '../widgets/home_pet.dart';
import '../widgets/quality_badge.dart';
import '../widgets/stat_chip.dart';
import '../widgets/profile_avatar.dart';
import '../services/route_observer.dart';
import 'assessment_screen.dart';
import 'about_screen.dart';
import 'profile_screen.dart';
import 'result_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final HistoryService _historyService = HistoryService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<SleepResult> _history = [];
  bool _loading = true;

  String _trendRange = '7d'; // '7d' | '1m'
  bool _showAllRecent = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    final s = S.current;
    if (hour < 12) return s.goodMorning;
    if (hour < 18) return s.goodAfternoon;
    return s.goodEvening;
  }

  IconData get _greetingIcon {
    final hour = DateTime.now().hour;
    if (hour < 5) return Icons.bedtime_rounded;
    if (hour < 12) return Icons.wb_twilight;
    if (hour < 17) return Icons.wb_sunny_rounded;
    if (hour < 20) return Icons.cloud_rounded;
    return Icons.nights_stay_rounded;
  }

  double get _avgDuration {
    if (_history.isEmpty) return 0;
    final recent = _history.length > 7
        ? _history.sublist(_history.length - 7)
        : _history;
    final total = recent.fold<double>(0, (sum, r) => sum + r.input.sleepDuration);
    return total / recent.length;
  }

  int get _streak => checkInStreak(_history);

  int get _trendWindow => _trendRange == '7d' ? 7 : 30;

  Future<void> _startAssessment() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AssessmentScreen()),
    );
    _loadHistory();
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StatsScreen()),
    );
  }

  Future<void> _confirmDeleteResult(SleepResult result) async {
    final s = S.current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteCheckInTitle),
        content: Text(
          s.deleteCheckInBody(s.quality(result.quality), _formatDate(result.timestamp)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.poor),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _historyService.deleteResult(result);
      _loadHistory();
    }
  }

  Widget _buildDrawer() {
    final s = S.of(context);
    return Drawer(
      backgroundColor: AppTheme.surfaceColor(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _openProfile();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: ValueListenableBuilder<UserProfile>(
                  valueListenable: ProfileService.instance.profile,
                  builder: (context, profile, _) {
                    return Row(
                      children: [
                        ProfileAvatar(profile: profile, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name.isEmpty
                                    ? 'SleepWise AI'
                                    : profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryColor(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.viewProfile,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Divider(height: 1, color: AppTheme.borderColor(context)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: AppTheme.primary),
              title: Text(s.home, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor(context))),
              trailing: const Icon(Icons.check, color: AppTheme.primary, size: 18),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: Icon(Icons.bar_chart_rounded, color: AppTheme.textSecondaryColor(context)),
              title: Text(s.fullHistory, style: TextStyle(color: AppTheme.textPrimaryColor(context))),
              onTap: () {
                Navigator.of(context).pop();
                _openStats();
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_rounded, color: AppTheme.textSecondaryColor(context)),
              title: Text(s.settings, style: TextStyle(color: AppTheme.textPrimaryColor(context))),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Spacer(),
            Divider(height: 1, color: AppTheme.borderColor(context)),
            ListTile(
              leading: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor(context)),
              title: Text(s.about, style: TextStyle(color: AppTheme.textPrimaryColor(context))),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildHeader(context),
            if (!_loading) _buildStatsCard(context),
            if (!_loading && _history.isNotEmpty) _buildTrendChart(context),
            if (!_loading && _history.isNotEmpty) _buildRecentList(context),
            if (!_loading && _history.isEmpty) _buildEmptyState(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        // การ์ดสถิติทับขึ้นมา 24 พอดีกับค่านี้ เท้าของมาสคอตจึงอยู่บนขอบบนของการ์ด
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            // เว้นที่ด้านล่างให้มาสคอตเดิน
            padding: const EdgeInsets.only(bottom: HomePet.laneHeight),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    tooltip: s.menu,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    _greetingIcon,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ValueListenableBuilder<UserProfile>(
                      valueListenable: ProfileService.instance.profile,
                      builder: (context, profile, _) {
                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.name.isEmpty
                                    ? _greeting
                                    : s.greetingWithName(
                                        _greeting, profile.name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Tooltip(
                              message: s.profile,
                              child: GestureDetector(
                                onTap: _openProfile,
                                child: ProfileAvatar(
                                  profile: profile,
                                  size: 40,
                                  borderColor: Colors.white,
                                  borderWidth: 2,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                s.readyForCheck,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startAssessment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
                child: Text(s.startAssessment),
              ),
            ],
          ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: HomePet.laneHeight,
            child: HomePet(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final s = S.of(context);
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.25 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatChip(
                label: s.avgDuration,
                value: _history.isEmpty ? '—' : s.avgDurationValue(_avgDuration.toStringAsFixed(1)),
              ),
              StatChip(
                label: s.streak,
                value: _history.isEmpty ? '—' : s.streakDays(_streak),
              ),
              StatChip(
                label: s.lastQuality,
                value: _history.isEmpty ? '—' : s.quality(_history.last.quality),
                valueColor: _history.isEmpty
                    ? null
                    : AppTheme.qualityColor(_history.last.quality),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeToggle(BuildContext context) {
    final s = S.of(context);
    Widget rangeButton(String key, String label) {
      final selected = _trendRange == key;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _trendRange = key),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textMutedColor(context),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMutedColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          rangeButton('7d', s.range7Days),
          rangeButton('1m', s.range1Month),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context) {
    final s = S.of(context);
    final window = _trendWindow;
    // นับช่วงเวลาตามวันในปฏิทินจริง (ไม่ใช่ n ครั้งล่าสุด) และรวมเป็น 1 จุดต่อวัน
    final today = dateOnly(DateTime.now());
    // "7 วัน" = สัปดาห์นี้ เรียงจันทร์ → อาทิตย์ (วันที่ยังมาไม่ถึงเว้นว่างไว้)
    final start = _trendRange == '7d'
        ? DateTime(today.year, today.month, today.day - (today.weekday - 1))
        : DateTime(today.year, today.month, today.day - (window - 1));
    final days = groupByDay(_history)
        .where((d) => !d.day.isBefore(start) && !d.day.isAfter(today))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // แตะหัวข้อ (หรือตัวกราฟ) เพื่อเปิดหน้าสถิติแบบละเอียด
              InkWell(
                onTap: _openStats,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.sleepTrend, style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor(context),
                    )),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppTheme.textMutedColor(context),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 140, child: _buildRangeToggle(context)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openStats,
            child: SleepTrendChart(
              days: days,
              start: start,
              windowDays: window,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList(BuildContext context) {
    final s = S.of(context);
    final visibleCount = _showAllRecent ? 30 : 7;
    final recent = _history.reversed.take(visibleCount).toList();
    final hasMore = !_showAllRecent && _history.length > 7;
    final borderColor = AppTheme.borderColor(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.recentCheckIns, style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor(context),
          )),
          const SizedBox(height: 8),
          for (final r in recent)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ResultScreen(result: r)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatDate(r.timestamp),
                                style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor(context)),
                              ),
                            ),
                            QualityBadge(quality: r.quality),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: AppTheme.textMutedColor(context)),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDeleteResult(r);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 18, color: AppTheme.poor),
                            const SizedBox(width: 8),
                            Text(s.delete, style: const TextStyle(color: AppTheme.poor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAllRecent = true),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: Text(s.showMore),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ),
            ),
          if (_showAllRecent && _history.length > 7)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAllRecent = false),
                  icon: const Icon(Icons.expand_less_rounded, size: 18),
                  label: Text(s.showLess, style: TextStyle(color: AppTheme.textMutedColor(context))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMutedColor(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.bedtime_outlined, color: AppTheme.textMutedColor(context), size: 32),
            const SizedBox(height: 8),
            Text(
              s.noCheckInsYet,
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor(context)),
            ),
            const SizedBox(height: 4),
            Text(
              s.noCheckInsHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor(context)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return S.current.relativeDate(dt);
  }
}
