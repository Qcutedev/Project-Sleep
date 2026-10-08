# โครงสร้างโปรเจค

เอกสารนี้อธิบายว่าอะไรอยู่ตรงไหน ข้อมูลไหลอย่างไร และจุดไหนผูกกันอยู่จนแก้ที่เดียวแล้วต้องแก้อีกที่

## ภาพรวม

```
C:\Project SLEEP\            โฟลเดอร์ที่เปิดใน VS Code (ไม่ใช่ git repo)
└── sleepwise_ai\            git repo และโปรเจค Flutter
    ├── lib\                 โค้ดแอป
    ├── assets\              icons, images, sounds (mp3 4 ไฟล์)
    ├── android\ ios\ ...    โค้ดเฉพาะแพลตฟอร์ม (ใช้งานจริงแค่ Android)
    ├── backend\             FastAPI + ไฟล์โมเดล (deploy อยู่บน Render)
    ├── test\                มีแค่ widget_test.dart
    └── docs\                เอกสารชุดนี้
```

- Flutter 3.47 (Dart SDK ^3.13), Android `minSdk 24`, package `com.example.sleepwise_ai`
- ไม่มีโค้ดเทรนโมเดลหรือ dataset ในโปรเจค มีแค่ไฟล์โมเดลที่เทรนแล้ว `backend/model/sleep_quality_model.pkl`

## หน้าจอ (`lib/screens/`)

| ไฟล์ | หน้าที่ |
|---|---|
| `splash_screen.dart` | อนิเมชันเปิดแอป ราว 5 วินาที แล้วสลับไป `MainShell` |
| `main_shell.dart` | เปลือกหลัก มี bottom navigation 3 แท็บ (Home / Alarm / Sounds) เก็บ state ด้วย `IndexedStack` และถือ `SoundPlayerController` ตัวเดียวของทั้งแอป |
| `home_screen.dart` | หัวทักทาย, การ์ดสถิติ, กราฟแนวโน้ม, รายการเช็กอินล่าสุด, เมนู drawer |
| `assessment_screen.dart` | ฟอร์มกรอกข้อมูล 5 ค่า แล้วส่งต่อให้ `LoadingScreen` |
| `loading_screen.dart` | เรียก backend, บันทึกผลลงประวัติ, แล้วสลับไป `ResultScreen` |
| `result_screen.dart` | ผลการประเมิน 1 ครั้ง (ใช้ทั้งผลใหม่และผลย้อนหลัง) |
| `stats_screen.dart` | สถิติการนอนแบบละเอียด เปิดจากกราฟหน้า Home หรือเมนู "ประวัติทั้งหมด" |
| `settings_screen.dart` | โปรไฟล์, หน่วยเวลา, การแจ้งเตือน, ธีม, ภาษา, รีเซ็ตข้อมูล |
| `about_screen.dart` | ข้อมูลแอปและ disclaimer |
| `alarm_list_screen.dart` | รายการปลุก (แท็บ Alarm) |
| `alarm_edit_screen.dart` | สร้าง/แก้ไขปลุก เลือกเวลาเข้านอนตามรอบการนอน |
| `alarm_ringing_screen.dart` | หน้าเต็มจอตอนปลุกดัง (หยุด / เลื่อนปลุก) |
| `sounds_screen.dart` | รายการเสียง (แท็บ Sounds) นำเข้าไฟล์เสียงเองได้ |
| `now_playing_screen.dart` | หน้าเล่นเสียงเต็มจอ |

เส้นทางหลักของการประเมิน: `Home → Assessment → Loading → Result` โดย Assessment และ Loading ใช้ `pushReplacement` ปุ่ม "กลับหน้าหลัก" ใน Result ใช้ `popUntil(isFirst)`

## บริการ (`lib/services/`)

| ไฟล์ | หน้าที่ |
|---|---|
| `sleep_api_service.dart` | `POST {baseUrl}/predict` |
| `history_service.dart` | เก็บ/อ่าน/ลบผลการประเมินในเครื่อง |
| `sleep_stats.dart` | ฟังก์ชันคำนวณสถิติ: รวมผลรายวัน (`DailySleep`, `groupByDay`), `qualityForScore`, `factorIcon`, `formatMetric` |
| `alarm_storage_service.dart` | เก็บรายการปลุก |
| `alarm_scheduler_service.dart` | ตั้ง/ยกเลิกปลุกจริงผ่านแพ็กเกจ `alarm` |
| `alarm_notification_service.dart` | แจ้งเตือนค้าง "ตั้งปลุกแล้ว" (notification id 900) |
| `notification_service.dart` | เตือนเข้านอน (id 1, 22:00) และเตือนประจำวัน (id 2, 08:00) |
| `sound_service.dart` | เสียงในแอป 4 เสียง, นำเข้าไฟล์เสียง, รายการโปรด |
| `sound_player_controller.dart` | สถานะการเล่นเสียงกลาง (`ChangeNotifier`) ใช้ `just_audio` |
| `device_service.dart` | เรียกโค้ด Android ผ่าน MethodChannel `sleepwise/device` (ถามยี่ห้อเครื่อง, เปิดหน้าสิทธิ์ของแอป) คู่กับ `MainActivity.kt` |
| `route_observer.dart` | `RouteObserver` ให้หน้า Home โหลดประวัติใหม่เมื่อกลับมา |

## ส่วนอื่นใน `lib/`

- `l10n/app_strings.dart` — ข้อความทั้งหมดของแอปทั้งสองภาษา และตัวสลับภาษา ดู [CONVENTIONS.md](CONVENTIONS.md)
- `theme/app_theme.dart` — สี ธีมสว่าง/มืด และตัวสลับธีม
- `models/` — `sleep_assessment_input`, `sleep_result`, `alarm` (รวมฟังก์ชันคำนวณเวลาเข้านอน), `sound_item`
  - `sound_track.dart` ไม่มีไฟล์ไหนเรียกใช้ เป็นของเก่าที่ค้างอยู่
- `widgets/` — `quality_badge`, `stat_chip`, `mini_player_bar`, `sleep_trend_chart` (กราฟที่ใช้ร่วมกันทั้ง Home และ Stats), `sleeping_mascot` (มาสคอตนอนหลับในหน้า Loading วาดด้วย `CustomPaint` ไม่มีไฟล์รูป)

## การเริ่มแอป (`lib/main.dart`)

ลำดับใน `main()`: `Alarm.init()` → `NotificationService().init()` (ขอสิทธิ์แจ้งเตือนและปลุกตรงเวลา) → โหลดธีมและภาษาจาก SharedPreferences → `runApp`

- `SleepWiseApp` ฟัง `Alarm.ringing` ตลอด เมื่อปลุกดังจะ push `AlarmRingingScreen` ผ่าน `navigatorKey` ไม่ว่าอยู่หน้าไหน
- `MaterialApp.builder` ครอบทุกหน้าด้วย `LanguageScope` เพื่อให้สลับภาษาแล้ว rebuild ทันที

## ข้อมูลที่เก็บในเครื่อง

ทุกอย่างอยู่ใน SharedPreferences ไม่มีฐานข้อมูล ไม่มีบัญชีผู้ใช้ ไม่มีการส่งประวัติขึ้นเซิร์ฟเวอร์

| key | เนื้อหา |
|---|---|
| `sleep_history_v1` | JSON รายการผลการประเมิน เรียงเก่าไปใหม่ |
| `sleep_alarms_v1` | รายการปลุก |
| `imported_sounds`, `favorite_sound_ids` | เสียงที่นำเข้าและรายการโปรด |
| `settings_display_name`, `settings_age`, `settings_gender`, `settings_duration_unit` | โปรไฟล์และหน่วยเวลา |
| `settings_sleep_reminder`, `settings_daily_reminder` | สวิตช์การแจ้งเตือน |
| `settings_appearance`, `settings_language` | ธีม (`light`/`dark`/`system`) และภาษา (`en`/`th`) |
| `xiaomi_alarm_tip_shown` | เคยแสดงคำแนะนำสิทธิ์ของ Xiaomi แล้วหรือยัง |

"รีเซ็ตข้อมูลทั้งหมด" ใน Settings เรียก `prefs.clear()` ซึ่งล้างทุก key ข้างบน

ข้อมูลในประวัติเก็บค่าดิบภาษาอังกฤษจาก backend เสมอ (`quality` เป็น `Good`/`Fair`/`Poor`, ข้อความ factors และ recommendation เป็นอังกฤษ) แล้วแปลตอนแสดงผล ห้ามเก็บข้อความที่แปลแล้วลงประวัติ

## Backend (`backend/`)

FastAPI ไฟล์หลัก `backend/api/main.py` โหลดโมเดลครั้งเดียวตอนเริ่มระบบ

**`POST /predict`** รับ:

```json
{ "sleep_duration": 7, "stress_level": 5, "physical_activity": 30, "age": 25, "gender": "Male" }
```

ตอบ: `sleep_quality`, `score` (1–100), `factors` (รายการข้อความ), `recommendation`

**`GET /health`** ตอบ `{"status":"ok"}`

กติกาใน backend ที่แอปพึ่งพา:

| เรื่อง | กติกา |
|---|---|
| คะแนน | คะแนนดิบของโมเดลถูกบีบให้อยู่ในช่วง 4–9 แล้วแปลงเป็น 1–100 |
| ระดับคุณภาพ | คะแนนดิบ ≥ 8 = Good, ≥ 5 = Fair, ต่ำกว่านั้น = Poor |
| ปัจจัย | นอน < 6.5 ชม. → `Short sleep duration`, ความเครียด ≥ 7 → `High stress level`, กิจกรรม < 20 นาที → `Low physical activity`, ไม่เข้าข้อไหนเลย → `No major risk factors found` |
| คำแนะนำ | ข้อความตายตัว 3 แบบตามระดับคุณภาพ |

ปัจจัยและคำแนะนำเป็นกฎ if/else ไม่ได้มาจากโมเดล

## จุดที่ผูกกัน (แก้ที่หนึ่งต้องแก้อีกที่)

1. **ข้อความ factors / recommendation ใน `backend/api/main.py`** ผูกกับตารางแปลไทย `_factorsTh` และ `_recommendationsTh` ใน `app_strings.dart` และกับ `factorIcon` ใน `sleep_stats.dart` ทั้งหมดจับคู่ด้วยข้อความอังกฤษแบบตรงตัว ถ้าเปลี่ยนหรือเพิ่มข้อความใน backend แล้วไม่แก้ฝั่งแอป ข้อความจะแสดงเป็นอังกฤษและใช้ไอคอนกลาง
2. **เกณฑ์ระดับคุณภาพใน backend** ผูกกับ `qualityForScore` ใน `sleep_stats.dart` (80 ขึ้นไป = Good, 21 ขึ้นไป = Fair) ซึ่งถอดมาจากเกณฑ์คะแนนดิบ 8 และ 5 ใช้กำหนดสีของจุดบนกราฟในวันที่เช็กอินหลายครั้ง และสีของแท่ง/ตัวเลขในหน้า Stats
3. **เกณฑ์ปัจจัยใน backend (6.5 / 7 / 20)** ผูกกับเกณฑ์แบ่งกลุ่มในการ์ด "ข้อสังเกต" ของ `stats_screen.dart` และข้อความ `insightSleepHigh` ฯลฯ ใน `app_strings.dart`
4. **ค่าเพศที่ส่งให้โมเดล** ต้องเป็น `Male` / `Female` เสมอ ข้อความที่แสดงแปลได้ แต่ค่าที่ส่งห้ามแปล
5. **ชื่อเสียงในแอป** แปลตาม `id` ของเสียงใน `_builtInSoundNamesTh` ถ้าเพิ่มเสียงใน `SoundService.builtInSounds` ต้องเพิ่มคำแปลด้วย
6. **`MainActivity.kt` กับ `device_service.dart`** ใช้ชื่อ channel และชื่อ method เดียวกัน

## พฤติกรรมที่ควรรู้

- **กราฟแนวโน้ม**: 1 จุดต่อ 1 วัน (ค่าเฉลี่ยของวันนั้น) แกน X เป็นวันในปฏิทินจริง วันที่ไม่ได้เช็กอินเว้นว่าง ช่วง "สัปดาห์นี้" เริ่มวันจันทร์เสมอ ช่วงอื่นนับย้อนจากวันนี้
- **ปลุกแบบซ้ำหลายวัน**: แพ็กเกจ `alarm` ตั้งได้ครั้งเดียวต่อ 1 id จึงสร้างปลุกจริงแยกวันละอัน ใช้ id = `alarm.id * 10 + weekday`
- **ปลุกครั้งเดียวที่เวลาผ่านไปแล้ว** จะถูกปิดอัตโนมัติเมื่อเปิดหน้ารายการปลุก
- **การเล่นเสียง**: ห้าม `await player.play()` เพราะ Future จะไม่จบจนกว่าเสียงจะหยุด (ดูคอมเมนต์ใน `sound_player_controller.dart`)
- **`LoadingScreen` หน่วงเทียม 0.6 วินาที** เพื่อให้เห็นอนิเมชัน
- **`MainActivity` เปิด `setShowWhenLocked` และ `setTurnScreenOn`** เพื่อให้หน้าปลุกขึ้นทับหน้าล็อก แต่บนมือถือบางยี่ห้อยังต้องเปิดสิทธิ์เพิ่ม ดู [BUILD.md](BUILD.md)
