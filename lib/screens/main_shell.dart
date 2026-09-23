import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_player_controller.dart';
import '../widgets/mini_player_bar.dart';
import 'home_screen.dart';
import 'alarm_list_screen.dart';
import 'sounds_screen.dart';

/// เปลือกหลักของแอป (Shell) — มี bottom navigation bar ค้างอยู่ตลอด
/// สลับไปมาระหว่าง Home / Sleep Alarm / Sleep Sounds โดยไม่ต้องรีโหลดหน้าใหม่ทุกครั้ง
/// (ใช้ IndexedStack เก็บ state ของแต่ละหน้าไว้เบื้องหลัง)
///
/// SoundPlayerController ถูกสร้างไว้ที่นี่ (ระดับบนสุด) แทนที่จะอยู่ใน SoundsScreen
/// เพื่อให้ mini-player bar โผล่ขึ้นมาได้ทุกแท็บ ไม่ใช่แค่ตอนอยู่หน้า Sounds เท่านั้น
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  late final SoundPlayerController _soundController;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _soundController = SoundPlayerController();
    _pages = [
      const HomeScreen(),
      const AlarmListScreen(),
      SoundsScreen(controller: _soundController),
    ];
  }

  @override
  void dispose() {
    _soundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _soundController,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MiniPlayerBar(controller: _soundController),
              NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: AppTheme.surfaceColor(context),
                  indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
                  height: 64,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textMutedColor(context),
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textMutedColor(context),
                      size: 24,
                    );
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  elevation: 0,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.alarm_outlined),
                      selectedIcon: Icon(Icons.alarm_rounded),
                      label: 'Alarm',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.music_note_outlined),
                      selectedIcon: Icon(Icons.music_note_rounded),
                      label: 'Sounds',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}