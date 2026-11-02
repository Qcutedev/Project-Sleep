# โครงสร้างโปรเจค

เอกสารนี้อธิบายว่าอะไรอยู่ตรงไหน ข้อมูลไหลอย่างไร และจุดไหนผูกกันอยู่จนแก้ที่เดียวแล้วต้องแก้อีกที่

## ภาพรวม

```
C:\Project SLEEP\            โฟลเดอร์ที่เปิดใน VS Code (ไม่ใช่ git repo)
└── sleepwise_ai\            git repo และโปรเจค Flutter
    ├── lib\                 โค้ดแอป
    ├── assets\              icons, images, sounds (mp3 4 ไฟล์)
    ├── android\ ios\ ...    โค้ดเฉพาะแพลตฟอร์ม (ใช้งานจริงแค่ Android)
    ├── backend\             FastAPI + ไฟล์โมเดล + เทสต์ (deploy อยู่บน Render)
    ├── test\                เทสต์ของแอป
    ├── .github\workflows\   CI รัน analyze และเทสต์ทุก PR
    └── docs\                เอกสารชุดนี้
```

- Flutter 3.47 (Dart SDK ^3.13), Android `minSdk 24`, package `com.qcutedev.sleepwise`
- ไม่มีโค้ดเทรนโมเดลหรือ dataset ในโปรเจค มีแค่ไฟล์โมเดลที่เทรนแล้ว `backend/model/sleep_quality_model.pkl`

## หน้าจอ (`lib/screens/`)

| ไฟล์ | หน้าที่ |
|---|---|
| `splash_screen.dart` | อนิเมชันเปิดแอป 2 วินาที แตะเพื่อข้ามได้ (ท้องฟ้ากลางคืน โลโก้ที่ขยับได้ และชื่อแอป) แล้วจางเข้า `OnboardingScreen` หรือ `MainShell` โลโก้ในหน้านี้วาดด้วยโค้ดใน `_LogoPainter` ตามสัดส่วนของ `assets/images/logo.png` ถ้าเปลี่ยนโลโก้ต้องแก้ทั้งสองที่ สีพื้น `#191548` ตรงกับ `launch_background.xml` |
| `onboarding_screen.dart` | หน้าแนะนำแอปตอนเปิดครั้งแรก 3 หน้า ข้ามได้: ต้อนรับและเลือกภาษา, อธิบายแอปและ disclaimer, ตั้งอายุและเพศ |
| `main_shell.dart` | เปลือกหลัก มี bottom navigation 3 แท็บ (Home / Alarm / Sounds) เก็บ state ด้วย `IndexedStack` และถือ `SoundPlayerController` ตัวเดียวของทั้งแอป |
| `home_screen.dart` | หัวทักทายพร้อมชื่อและรูปโปรไฟล์ (มุมขวาบน กดแล้วเปิดหน้าโปรไฟล์), การ์ดสถิติ, กราฟแนวโน้ม, รายการเช็กอินล่าสุด, เมนู drawer |
| `assessment_screen.dart` | ฟอร์มกรอกเวลาเข้านอน เวลาตื่น และค่าอื่น แล้วส่งต่อให้ `LoadingScreen` ชั่วโมงนอนคำนวณจากสองเวลา สูงสุด 10 ชม. |
| `loading_screen.dart` | เรียก backend, บันทึกผลลงประวัติ, แล้วสลับไป `ResultScreen` ถ้ารอเกิน 6 วินาทีจะบอกว่าเซิร์ฟเวอร์กำลังเริ่มทำงาน ถ้าไม่สำเร็จจะแยกข้อความตามประเภท พร้อมปุ่มลองใหม่และกลับหน้าหลัก |
| `result_screen.dart` | ผลการประเมิน 1 ครั้ง (ใช้ทั้งผลใหม่และผลย้อนหลัง) มีการ์ด "คำแนะนำตามคะแนน" ต่อท้ายคำแนะนำทั่วไปจาก backend |
| `stats_screen.dart` | สถิติการนอนแบบละเอียด เปิดจากกราฟหน้า Home หรือเมนู "ประวัติทั้งหมด" เก็บเฉพาะส่วนที่ใช้ state ของหน้า (หัว แท็บ กราฟ รายการเช็กอิน) การ์ดอื่นอยู่ใน `widgets/stats_cards.dart` |
| `profile_screen.dart` | รูปโปรไฟล์ (รูปจากเครื่องหรืออวตารสำเร็จรูป), ชื่อ อายุ เพศ, สรุปจำนวนเช็กอิน/วันต่อเนื่อง/คะแนนเฉลี่ย ใช้ widget `ProfileAvatar` ใน `widgets/profile_avatar.dart` |
| `settings_screen.dart` | ทางเข้าหน้าโปรไฟล์, หน่วยเวลา, เป้าหมายการนอน, การแจ้งเตือน, ธีม, ภาษา, ส่งออกประวัติ, รีเซ็ตข้อมูล |
| `about_screen.dart` | ข้อมูลแอป ข้อมูลโมเดล การใช้ข้อมูล และ disclaimer ตัวเลขของโมเดลต้องตรงกับ [MODEL_CARD.md](MODEL_CARD.md) |
| `alarm_list_screen.dart` | รายการปลุก (แท็บ Alarm) |
| `alarm_edit_screen.dart` | สร้าง/แก้ไขปลุก เลือกเวลาเข้านอนตามรอบการนอน |
| `alarm_ringing_screen.dart` | หน้าเต็มจอตอนปลุกดัง (หยุด / เลื่อนปลุก) |
| `sounds_screen.dart` | รายการเสียง (แท็บ Sounds) นำเข้าไฟล์เสียงเองได้ |
| `now_playing_screen.dart` | หน้าเล่นเสียงเต็มจอ |

เส้นทางหลักของการประเมิน: `Home → Assessment → Loading → Result` โดย Assessment และ Loading ใช้ `pushReplacement` ปุ่ม "กลับหน้าหลัก" ใน Result ใช้ `popUntil(isFirst)`

## บริการ (`lib/services/`)

| ไฟล์ | หน้าที่ |
|---|---|
| `api_config.dart` | อ่าน URL ของ backend จาก `SLEEP_API_BASE_URL` |
| `sleep_api_service.dart` | `POST {baseUrl}/predict` หมดเวลาที่ 90 วินาที โยน `SleepApiException` ตามประเภทความผิดพลาด และ `warmUp()` เรียก `/health` ตอนเปิดแอป |
| `onboarding_service.dart` | จำว่าผ่านหน้าแนะนำแอปแล้วหรือยัง คนที่มีประวัติอยู่แล้วจะไม่เห็นหน้านี้ |
| `history_export.dart` | แปลงประวัติเป็น CSV (UTF-8 พร้อม BOM, ค่าดิบภาษาอังกฤษ) หน้า Settings บันทึกผ่านกล่องเลือกไฟล์ของระบบ จึงไม่ต้องขอสิทธิ์ |
| `weekly_summary.dart` | เป้าหมายการนอน (`SleepGoalService`) และสรุปสัปดาห์ (`weeklySummary`) ตัวเลขเทียบกับสัปดาห์ก่อนต้องมีอย่างน้อย 3 วันในแต่ละสัปดาห์ |
| `history_service.dart` | เก็บ/อ่าน/ลบผลการประเมินในเครื่อง เก็บได้วันละ 1 ผล (`saveDailyResult` ลบผลของวันเดียวกันก่อนบันทึก) |
| `sleep_stats.dart` | ฟังก์ชันคำนวณสถิติ: รวมผลรายวัน (`DailySleep`, `groupByDay`), `qualityForScore`, `factorIcon`, `formatMetric`, ชั่วโมงนอนจากสองเวลา (`sleepHoursBetween`), ความสม่ำเสมอของเวลาเข้านอน (`bedtimeConsistency` ต้องมีอย่างน้อย 3 คืน) |
| `sleep_advice.dart` | ตรรกะคำแนะนำฝั่งแอป (ไม่มีข้อความในไฟล์ แปลผ่าน `S`): `adviceForResult` (ตามคะแนนและค่าที่กรอก), `longTermAdvice` (ตามแนวโน้มรายวัน ต้องมีอย่างน้อย 5 วัน), `recommendedSleepHours` (ช่วงชั่วโมงนอนตามอายุ) |
| `alarm_storage_service.dart` | เก็บรายการปลุก |
| `alarm_scheduler_service.dart` | ตั้ง/ยกเลิกปลุกจริงผ่านแพ็กเกจ `alarm` |
| `alarm_notification_service.dart` | แจ้งเตือนค้าง "ตั้งปลุกแล้ว" (notification id 900) |
| `notification_service.dart` | เตือนเข้านอน (id 1, 22:00) และเตือนประจำวัน (id 2, 08:00) |
| `profile_service.dart` | อ่าน/บันทึกโปรไฟล์ เลือกรูปด้วย `file_picker` แล้วคัดลอกเข้าโฟลเดอร์ `profile/` ของแอป แจ้งทุกหน้าผ่าน `ProfileService.instance.profile` (`ValueNotifier`) |
| `sound_service.dart` | เสียงในแอป 4 เสียง, นำเข้าไฟล์เสียง, รายการโปรด |
| `sound_player_controller.dart` | สถานะการเล่นเสียงกลาง (`ChangeNotifier`) ใช้ `just_audio` |
| `device_service.dart` | เรียกโค้ด Android ผ่าน MethodChannel `sleepwise/device` (ถามยี่ห้อเครื่อง, เปิดหน้าสิทธิ์ของแอป) คู่กับ `MainActivity.kt` |
| `route_observer.dart` | `RouteObserver` ให้หน้า Home โหลดประวัติใหม่เมื่อกลับมา |

## ส่วนอื่นใน `lib/`

- `l10n/app_strings.dart` — ข้อความทั้งหมดของแอปทั้งสองภาษา และตัวสลับภาษา ดู [CONVENTIONS.md](CONVENTIONS.md)
- `theme/app_theme.dart` — สี ธีมสว่าง/มืด และตัวสลับธีม
- `models/` — `sleep_assessment_input`, `sleep_result`, `alarm` (รวมฟังก์ชันคำนวณเวลาเข้านอน), `sound_item`
- `widgets/` — `quality_badge`, `stat_chip`, `mini_player_bar`, `sleep_trend_chart` (กราฟที่ใช้ร่วมกันทั้ง Home และ Stats), `stats_cards` (การ์ดของหน้า Stats ที่ไม่ใช้ state), `weekly_summary_card`, `bedtime_consistency_card`, `sleeping_mascot` (มาสคอตนอนหลับในหน้า Loading วาดด้วย `CustomPaint` ไม่มีไฟล์รูป)

## การเริ่มแอป (`lib/main.dart`)

ลำดับใน `main()`: `Alarm.init()` → `NotificationService().init()` (ขอสิทธิ์แจ้งเตือนและปลุกตรงเวลา) → โหลดธีมและภาษาจาก SharedPreferences → โหลดโปรไฟล์ → `OnboardingService.load()` → `runApp`

- `SleepWiseApp` ฟัง `Alarm.ringing` ตลอด เมื่อปลุกดังจะ push `AlarmRingingScreen` ผ่าน `navigatorKey` ไม่ว่าอยู่หน้าไหน โดยหาเวลาเลื่อนปลุกจากปลุกต้นทาง (`AlarmScheduler.findByNativeId`) ถ้าหาไม่พบใช้ 5 นาที
- `MaterialApp.builder` ครอบทุกหน้าด้วย `LanguageScope` เพื่อให้สลับภาษาแล้ว rebuild ทันที

## ข้อมูลที่เก็บในเครื่อง

ทุกอย่างอยู่ใน SharedPreferences ไม่มีฐานข้อมูล ไม่มีบัญชีผู้ใช้ ไม่มีการส่งประวัติขึ้นเซิร์ฟเวอร์

| key | เนื้อหา |
|---|---|
| `sleep_history_v1` | JSON รายการผลการประเมิน เรียงเก่าไปใหม่ ผลใหม่มี `bedtime` และ `wake_time` แบบ `HH:mm` เพิ่มมา ซึ่งไม่ส่งให้โมเดล และผลเก่าไม่มีสองค่านี้ |
| `onboarding_done` | ผ่านหน้าแนะนำแอปแล้วหรือยัง |
| `assessment_last_bedtime`, `assessment_last_wake_time` | เวลาล่าสุดที่กรอก ใช้เติมฟอร์มครั้งถัดไป |
| `settings_sleep_goal_hours` | เป้าหมายชั่วโมงนอนต่อคืน ค่าเริ่มต้น 8 |
| `sleep_alarms_v1` | รายการปลุก |
| `imported_sounds`, `favorite_sound_ids` | เสียงที่นำเข้าและรายการโปรด |
| `settings_display_name`, `settings_age`, `settings_gender`, `settings_duration_unit` | โปรไฟล์และหน่วยเวลา (สาม key แรกแก้ผ่าน `ProfileService` และ `assessment_screen.dart` อ่านไปเติมฟอร์ม) |
| `profile_avatar_type`, `profile_avatar_value` | ชนิดรูปโปรไฟล์ (`none`/`preset`/`photo`) และ id ของอวตารหรือ path ของไฟล์รูป |
| `settings_sleep_reminder`, `settings_daily_reminder` | สวิตช์การแจ้งเตือน |
| `settings_appearance`, `settings_language` | ธีม (`light`/`dark`/`system`) และภาษา (`en`/`th`) |
| `xiaomi_alarm_tip_shown` | เคยแสดงคำแนะนำสิทธิ์ของ Xiaomi แล้วหรือยัง |

"รีเซ็ตข้อมูลทั้งหมด" ใน Settings ยกเลิกปลุกจริงทั้งหมด (`AlarmScheduler.cancelAll`) และแจ้งเตือน "ตั้งปลุกแล้ว" ก่อน แล้วจึงเรียก `prefs.clear()` ซึ่งล้างทุก key ข้างบน ลำดับนี้สำคัญเพราะแพ็กเกจ `alarm` เก็บข้อมูลใน SharedPreferences เช่นกัน จากนั้นแจ้งหน้ารายการปลุกให้โหลดใหม่ (`externalChanges`) และเรียก `ProfileService.clearAfterReset()` เพื่อลบไฟล์รูปโปรไฟล์ เมื่อเปิดแอปครั้งถัดไปจะเห็นหน้าแนะนำแอปอีกครั้ง

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
| ปัจจัย | นอน < 6.5 ชม. → `Short sleep duration`, ความเครียด ≥ 7 → `High stress level`, กิจกรรม < 20 นาที → `Low physical activity`, ไม่เข้าข้อไหนเลย → `No major risk factors found` (แอปแสดงข้อความนี้ว่า "ไม่มีปัจจัยที่เกินเกณฑ์" เพื่อไม่ให้ขัดกับคำแนะนำตามช่วงอายุ) |
| คำแนะนำ | ข้อความตายตัว 3 แบบตามระดับคุณภาพ |

ปัจจัยและคำแนะนำเป็นกฎ if/else ไม่ได้มาจากโมเดล รายละเอียดของโมเดลอยู่ใน [MODEL_CARD.md](MODEL_CARD.md)

## จุดที่ผูกกัน (แก้ที่หนึ่งต้องแก้อีกที่)

1. **ข้อความ factors / recommendation ใน `backend/api/main.py`** ผูกกับตารางแปลไทย `_factorsTh` และ `_recommendationsTh` ใน `app_strings.dart` และกับ `factorIcon` ใน `sleep_stats.dart` ทั้งหมดจับคู่ด้วยข้อความอังกฤษแบบตรงตัว ถ้าเปลี่ยนหรือเพิ่มข้อความใน backend แล้วไม่แก้ฝั่งแอป ข้อความจะแสดงเป็นอังกฤษและใช้ไอคอนกลาง
2. **เกณฑ์ระดับคุณภาพใน backend** ผูกกับ `qualityForScore` ใน `sleep_stats.dart` (80 ขึ้นไป = Good, 21 ขึ้นไป = Fair) ซึ่งถอดมาจากเกณฑ์คะแนนดิบ 8 และ 5 ใช้กำหนดสีของจุดบนกราฟในวันที่เช็กอินหลายครั้ง และสีของแท่ง/ตัวเลขในหน้า Stats
3. **เกณฑ์ปัจจัยใน backend (6.5 / 7 / 20)** ผูกกับเกณฑ์แบ่งกลุ่มในการ์ด "ข้อสังเกต" ของ `stats_screen.dart` และข้อความ `insightSleepHigh` ฯลฯ ใน `app_strings.dart`
4. **ค่าเพศที่ส่งให้โมเดล** ต้องเป็น `Male` / `Female` เสมอ ข้อความที่แสดงแปลได้ แต่ค่าที่ส่งห้ามแปล
5. **ชื่อเสียงในแอป** แปลตาม `id` ของเสียงใน `_builtInSoundNamesTh` ถ้าเพิ่มเสียงใน `SoundService.builtInSounds` ต้องเพิ่มคำแปลด้วย
6. **`MainActivity.kt` กับ `device_service.dart`** ใช้ชื่อ channel และชื่อ method เดียวกัน

## พฤติกรรมที่ควรรู้

- **คำแนะนำฝั่งแอปไม่ได้มาจากโมเดลหรือ backend** คำนวณใน `sleep_advice.dart` จากคะแนนและค่าที่กรอก เกณฑ์ใช้ร่วมกับ backend (ความเครียด ≥ 7, กิจกรรม < 20 นาที) แต่เกณฑ์ชั่วโมงนอนใช้ช่วงตามอายุ (ต่ำกว่า 18 ปี 8–10, 18–64 ปี 7–9, 65 ปีขึ้นไป 7–8) ไม่ใช่ 6.5 ชม. แบบ backend ระดับคะแนนที่ใช้เลือกข้อความคือ 80+, 50–79, 21–49, ต่ำกว่า 21
- **ชั่วโมงนอนที่ส่งให้โมเดลสูงสุด 10 ชั่วโมง** (`maxSleepHours` ใน `sleep_stats.dart`) ถ้าเวลาที่กรอกเกินนี้ ฟอร์มจะแจ้งว่านับเป็น 10 ชม. ประวัติเก่าที่เคยบันทึกเกิน 10 ชม. ยังแสดงได้ปกติ

- **ประเมินวันละครั้ง**: ถ้าวันนี้มีผลแล้ว หัวหน้า Home เปลี่ยนเป็น "วันนี้ประเมินแล้ว" และปุ่มเป็น "ประเมินใหม่" กดแล้วมีกล่องถาม (ยกเลิก / ดูผล / ประเมินใหม่) ผลเดิมของวันนี้ถูกแทนที่ตอนบันทึกผลใหม่สำเร็จใน `LoadingScreen` เท่านั้น ถ้าวิเคราะห์ไม่สำเร็จผลเดิมยังอยู่ ประวัติเก่าก่อนมีระบบนี้อาจมีหลายผลต่อวัน กราฟจึงยังเฉลี่ยรายวันอยู่
- **กราฟแนวโน้ม**: 1 จุดต่อ 1 วัน (ค่าเฉลี่ยของวันนั้น) แกน X เป็นวันในปฏิทินจริง วันที่ไม่ได้เช็กอินเว้นว่าง ช่วง "สัปดาห์นี้" เริ่มวันจันทร์เสมอ ช่วงอื่นนับย้อนจากวันนี้
- **ปลุกแบบซ้ำหลายวัน**: แพ็กเกจ `alarm` ตั้งได้ครั้งเดียวต่อ 1 id จึงสร้างปลุกจริงแยกวันละอัน ใช้ id = `alarm.id * 10 + weekday`
- **ปลุกครั้งเดียวที่เวลาผ่านไปแล้ว** จะถูกปิดอัตโนมัติเมื่อเปิดหน้ารายการปลุก
- **การเล่นเสียง**: ห้าม `await player.play()` เพราะ Future จะไม่จบจนกว่าเสียงจะหยุด (ดูคอมเมนต์ใน `sound_player_controller.dart`)
- **มาสคอตบนหน้า Home** (`widgets/home_pet.dart`): เดินอยู่ในแถบสูง `HomePet.laneHeight` ที่ท้าย header ซึ่งขอบล่างตรงกับขอบบนของการ์ดสถิติ (header มี padding ล่าง 24 เท่ากับระยะที่การ์ดทับขึ้นมา ถ้าแก้ค่าใดค่าหนึ่งต้องแก้อีกค่า) ตัวหันหน้าตรง เดินสองขา (หน้าตาตามตัวละคร Cinnamoroll ที่เจ้าของโปรเจคเลือก) สุ่มสลับท่าเดิน ยืน นั่ง กระโดด นอน ช่วง 22:00–05:00 จะนอนบ่อยขึ้น แตะแล้วกระโดดดีใจ และนั่งนิ่งถ้าเครื่องปิดอนิเมชัน
- **`LoadingScreen` หน่วงเทียม 0.6 วินาที** เพื่อให้เห็นอนิเมชัน
- **`MainShell` เรียก `warmUp()` ตอนเปิดแอป** เพื่อปลุก Render ล่วงหน้าโดยไม่ต้องรอผล
- **`MainActivity` เปิด `setShowWhenLocked` และ `setTurnScreenOn`** เพื่อให้หน้าปลุกขึ้นทับหน้าล็อก แต่บนมือถือบางยี่ห้อยังต้องเปิดสิทธิ์เพิ่ม ดู [BUILD.md](BUILD.md)
