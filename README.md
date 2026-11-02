# SleepWise AI

แอป Android ที่ทำนายคุณภาพการนอนด้วยโมเดล machine learning จากการเช็กอินสั้นๆ ในแต่ละวัน พร้อมนาฬิกาปลุกตามรอบการนอนและเสียงกล่อมนอน เป็นโครงงานรายวิชา CPE310

> **ต้นแบบเพื่อการศึกษา ไม่ใช่เครื่องมือทางการแพทย์** ผลที่ได้เป็นการทำนายของโมเดล ไม่ใช่การวินิจฉัย และยังไม่ผ่านการตรวจสอบทางคลินิก

## ความสามารถ

- **ประเมินการนอน** กรอกข้อมูล 5 ค่า แล้วได้คะแนน 1–100 ระดับคุณภาพ ปัจจัยที่เกี่ยวข้อง และคำแนะนำทั่วไป
- **สถิติ** กราฟแนวโน้ม ข้อสังเกตจากข้อมูลของตัวเอง และคำแนะนำระยะยาว
- **นาฬิกาปลุก** แนะนำเวลาเข้านอนตามรอบการนอน ตั้งซ้ำรายวันและเลื่อนปลุกได้
- **เสียงกล่อมนอน** เสียงในแอป 4 เสียง และนำเข้าไฟล์เสียงเองได้
- **สองภาษา** ไทยและอังกฤษ พร้อมโหมดมืด

ประวัติและโปรไฟล์เก็บในเครื่องเท่านั้น ไม่มีบัญชีผู้ใช้ ค่าที่กรอกถูกส่งไปยังเซิร์ฟเวอร์เพื่อทำนายผลเท่านั้น

## สถาปัตยกรรม

```
แอป Flutter ──HTTPS──▶ FastAPI บน Render ──▶ โมเดล scikit-learn
     │                  POST /predict         (random forest)
     ▼
SharedPreferences (ประวัติ โปรไฟล์ ปลุก)
```

| ส่วน | เทคโนโลยี |
|---|---|
| แอป | Flutter 3.47, Dart 3.13, Android `minSdk 24` |
| Backend | Python, FastAPI, scikit-learn 1.9 |
| Deploy | Render |

## เริ่มใช้งาน

```bash
flutter pub get
flutter run --dart-define=SLEEP_API_BASE_URL=https://project-sleep.onrender.com
```

รัน backend ในเครื่อง:

```bash
cd backend
python -m pip install -r requirements.txt
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

## ตรวจคุณภาพโค้ด

```bash
flutter analyze
flutter test
```

## เอกสาร

| ไฟล์ | เนื้อหา |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | โครงสร้างโปรเจค หน้าจอ บริการ ข้อมูลที่เก็บ |
| [docs/MODEL_CARD.md](docs/MODEL_CARD.md) | ข้อมูลโมเดล พฤติกรรมที่วัดได้ และข้อจำกัด |
| [docs/CONVENTIONS.md](docs/CONVENTIONS.md) | แนวทางการเขียนโค้ดและ UI |
| [docs/BUILD.md](docs/BUILD.md) | การ build และการตรวจงาน |
| [docs/GITHUB.md](docs/GITHUB.md) | ขั้นตอนการใช้ git |
| [docs/STATUS.md](docs/STATUS.md) | สถานะงานและปัญหาที่รู้อยู่ |
