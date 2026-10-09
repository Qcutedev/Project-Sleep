# รัน build และตรวจงาน

คำสั่งทั้งหมดรันจากโฟลเดอร์ `C:\Project SLEEP\sleepwise_ai`

## Backend

Backend ที่ใช้งานจริงอยู่บน Render:

```
https://project-sleep.onrender.com
```

- เป็นแผนฟรี เซิร์ฟเวอร์จะหลับเมื่อไม่มีคนเรียกใช้ราว 15 นาที คำขอแรกหลังจากนั้นใช้เวลา 30–60 วินาที เพราะต้องเริ่มเครื่องและโหลดโมเดลใหม่ คำขอถัดไปเร็วปกติ ถ้าเจ้าของโปรเจคถามว่าทำไมวิเคราะห์ครั้งแรกช้า นี่คือคำตอบ
- ตรวจว่า backend ใช้ได้ก่อน build:

```bash
curl -s -m 90 https://project-sleep.onrender.com/health
```

รัน backend ในเครื่อง (ไม่จำเป็นสำหรับงานปกติ):

```bash
cd backend
python -m pip install -r requirements.txt
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

## URL ของ backend ในแอป

แอปอ่าน URL จาก `--dart-define=SLEEP_API_BASE_URL=...` ตอน build (ดู `loading_screen.dart`) ถ้าไม่ใส่ ค่าเริ่มต้นคือ `http://127.0.0.1:8000` ซึ่งใช้บนมือถือจริงไม่ได้

`backend/README.md` เขียนว่าค่าเริ่มต้นคือ `http://10.0.2.2:8000` ซึ่งไม่ตรงกับโค้ด ให้ยึดโค้ด

## Build APK ให้เจ้าของโปรเจคทดสอบ

เจ้าของโปรเจคทดสอบบนมือถือจริงด้วย APK ทุกครั้งที่แก้โค้ดแอปเสร็จ ให้ทำตามนี้:

```bash
flutter analyze
flutter build apk --release --dart-define=SLEEP_API_BASE_URL=https://project-sleep.onrender.com
cp build/app/outputs/flutter-apk/app-release.apk "$USERPROFILE/OneDrive/Desktop/SleepWise-AI.apk"
```

- ไฟล์ผลลัพธ์ราว 82 MB การ build ใช้เวลา 1–2 นาที
- คัดลอกไปที่ Desktop ในชื่อ `SleepWise-AI.apk` ทับไฟล์เดิม แล้วบอกเจ้าของโปรเจค (Desktop ซิงค์กับ OneDrive จึงเปิดจากมือถือได้)
- ติดตั้งทับตัวเก่าได้ ข้อมูลในแอปไม่หาย
- ไม่มีที่ฝากไฟล์ออนไลน์ ให้ลิงก์ดาวน์โหลดไม่ได้ ให้ได้แค่ตำแหน่งไฟล์ในเครื่อง
- ห้าม commit ไฟล์ APK หรือโฟลเดอร์ `build/` (อยู่ใน `.gitignore` แล้ว)

คำเตือนเรื่อง Kotlin Gradle Plugin ของแพ็กเกจ `alarm` ตอน build เป็นเรื่องปกติ ไม่ต้องแก้

**ทรัพยากร Android ที่เรียกด้วยชื่อจาก Dart** (เช่น ไอคอน notification `@drawable/...`) ต้องเพิ่มชื่อไว้ใน `android/app/src/main/res/raw/keep.xml` การ build แบบ release ตัดทรัพยากรที่ไม่มีโค้ด Android อ้างถึงทิ้ง แล้ว notification จะไม่ขึ้นโดยไม่มีข้อความผิดพลาด (เคยเกิดกับ notification "ตั้งปลุกแล้ว") ตรวจได้ด้วย `aapt2 dump resources <apk>` แล้วหาชื่อทรัพยากรนั้น

## ตรวจงาน

### สิ่งที่ตรวจได้

1. **`flutter analyze`** ต้องขึ้น `No issues found!`
2. **เรนเดอร์หน้าจอในเทสต์เพื่อดูรูปและเช็กการล้น** ใช้เมื่อแก้ UI:
   - เขียนเทสต์ชั่วคราวใน `test/` ที่ pump หน้าจอใน `MaterialApp` ซึ่งมี `builder: (c, child) => LanguageScope(child: child!)`
   - ตั้ง `SharedPreferences.setMockInitialValues({...})` และใส่ประวัติตัวอย่างที่ key `sleep_history_v1` ด้วย `jsonEncode`
   - โหลดฟอนต์จริงด้วย `FontLoader('Roboto')` จาก `C:\Windows\Fonts\LeelawUI.ttf` และ `LeelaUIb.ttf` (มีตัวอักษรไทย) และ `FontLoader('MaterialIcons')` จาก `C:\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf` ถ้าไม่โหลด ข้อความจะเป็นสี่เหลี่ยมและความกว้างจะผิด
   - จับ `FlutterError.onError` เพื่อดูข้อความ `RenderFlex overflowed`
   - บันทึกรูปด้วย `matchesGoldenFile(...)` แล้วรัน `flutter test <ไฟล์> --update-goldens` จากนั้นเปิดดูรูป
   - ตรวจอย่างน้อย: ภาษาไทยและอังกฤษ, จอกว้าง 360 และ 320, โหมดสว่างและมืด
   - **ลบเทสต์ชั่วคราวและรูปทิ้งเมื่อเสร็จ** ห้าม commit (ผูกกับ path ของเครื่องนี้)
3. **เรียก backend จริงด้วย `curl`** เมื่อแก้อะไรที่เกี่ยวกับ API

### สิ่งที่ตรวจไม่ได้ และต้องบอกเจ้าของโปรเจคตรงๆ

- **รันบนมือถือหรือ emulator ไม่ได้** ทุกอย่างที่พึ่ง plugin ของเครื่องตรวจได้แค่อ่านโค้ด: ปลุกดัง, notification, สิทธิ์, การเล่นเสียง, การนำเข้าไฟล์, การแตะกราฟ
- หน้าที่เรนเดอร์ในเทสต์ไม่ได้เพราะเรียก plugin ตอนเริ่ม: รายการปลุก, Sounds, Now Playing, mini player, Loading
- เมื่อรายงานผล ให้แยกชัดว่าอะไร "ตรวจแล้ว" อะไร "ยังไม่ได้ลองบนเครื่องจริง" และขอให้เจ้าของโปรเจคลองส่วนนั้น

### สิ่งที่เห็นในรูปจากเทสต์แต่ไม่ใช่บั๊ก

- ข้อความในปุ่ม `ElevatedButton` เป็นสี่เหลี่ยม (ฟอนต์ของปุ่มไม่ได้โหลดในเทสต์)
- เงาเป็นแถบทึบ (เทสต์ปิดการเบลอเงา)
- แท็บที่เพิ่งกดสีไม่ตรงกับข้อความ ถ้า pump ไม่ครบเวลาอนิเมชัน ให้ pump เพิ่มอีกรอบ

### เทสต์ที่มีอยู่

`flutter test` มีแค่ `test/widget_test.dart` ("App starts without crashing") ซึ่งเช็กแค่ว่าหน้า Splash ขึ้นได้ ผ่านแล้วไม่ได้แปลว่าหน้าอื่นใช้ได้

## มือถือที่ใช้ทดสอบ

เจ้าของโปรเจคใช้ **Redmi Note 11** (Xiaomi, MIUI/HyperOS)

Xiaomi บล็อกการเปิดหน้าจอตอนจอดับไว้เป็นค่าเริ่มต้น ถ้าจะให้หน้าปลุกขึ้นทับหน้าล็อก ผู้ใช้ต้องเปิดเองในตั้งค่าของเครื่อง:

- ตั้งค่า → แอป → SleepWise AI → สิทธิ์อื่นๆ → เปิด "แสดงบนหน้าจอล็อก" และ "แสดงหน้าต่างป๊อปอัปขณะทำงานเบื้องหลัง"
- ประหยัดแบตเตอรี่ → "ไม่มีข้อจำกัด"
- เปิด "เริ่มอัตโนมัติ" (Autostart)

แอปแสดงคำแนะนำนี้ครั้งเดียวหลังตั้งปลุกสำเร็จบนเครื่อง Xiaomi/Redmi/POCO พร้อมปุ่มพาไปหน้าสิทธิ์ (`_maybeShowXiaomiTip` ใน `alarm_list_screen.dart`)

**สถานะ:** เรื่องหน้าปลุกขึ้นเองตอนจอดับ ยังไม่เคยยืนยันบนเครื่องจริงว่าได้ผล เจ้าของโปรเจคตัดสินใจพักเรื่องนี้ไว้ ไม่ต้องหยิบมาแก้ต่อเองถ้าไม่ได้ถูกขอ

## เครื่องที่ใช้พัฒนา

- Windows 11, shell หลักคือ PowerShell 5.1 (มี Git Bash ด้วย)
- Flutter อยู่ที่ `C:\flutter`
- ไม่ได้ติดตั้ง `gh` (GitHub CLI) การเปิด PR ต้องทำบนเว็บ
- IP ของเครื่องเปลี่ยนตาม Wi-Fi อย่าฝัง IP ในเอกสารหรือโค้ด ถ้าต้องใช้ให้เช็กใหม่ด้วย `ipconfig`
