import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/alarm_ringing_screen.dart';
import 'services/route_observer.dart';
import 'services/notification_service.dart'; // 👈 เพิ่ม

/// ใช้ navigate ไปหน้า Alarm Ringing ได้จากทุกที่ในแอป
/// แม้ตอนนั้นผู้ใช้จะอยู่หน้าไหนก็ตาม (ไม่ใช่แค่หน้า Alarm)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ต้อง init ก่อนใช้งานฟีเจอร์ปลุกจริงใดๆ ทั้งหมด
  await Alarm.init();

  // init ระบบแจ้งเตือน (Sleep reminder / Daily reminder ในหน้า Settings)
  await NotificationService().init(); // 👈 เพิ่ม

  // โหลดค่า Appearance ที่บันทึกไว้ (จากหน้า Settings) ก่อนเปิดแอป
  // กัน UI กระพริบธีมผิดแวบแรกที่เปิด
  final prefs = await SharedPreferences.getInstance();
  final savedAppearance = prefs.getString('settings_appearance') ?? 'light';
  AppTheme.themeNotifier.value = switch (savedAppearance) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };

  runApp(const SleepWiseApp());
}

class SleepWiseApp extends StatefulWidget {
  const SleepWiseApp({super.key});

  @override
  State<SleepWiseApp> createState() => _SleepWiseAppState();
}

class _SleepWiseAppState extends State<SleepWiseApp> {
  bool _ringingScreenOpen = false;

  @override
  void initState() {
    super.initState();
    // ฟังตลอดเวลาที่แอปเปิดอยู่ ไม่ว่าผู้ใช้อยู่หน้าไหน
    // เมื่อถึงเวลาปลุกจริง จะเด้งไปหน้า AlarmRingingScreen ทันที
    Alarm.ringing.listen((alarmSet) {
      if (alarmSet.alarms.isEmpty || _ringingScreenOpen) return;
      final alarm = alarmSet.alarms.first;
      _ringingScreenOpen = true;
      navigatorKey.currentState
          ?.push(
            MaterialPageRoute(
              builder: (_) => AlarmRingingScreen(alarmSettings: alarm),
            ),
          )
          .then((_) => _ringingScreenOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'SleepWise AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          navigatorObservers: [routeObserver],
          home: const SplashScreen(),
        );
      },
    );
  }
}