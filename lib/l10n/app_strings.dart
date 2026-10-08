import 'package:flutter/widgets.dart';

/// ภาษาปัจจุบันของแอป ('en' | 'th') — ค่าเดียวกับที่หน้า Settings บันทึกไว้
/// เปลี่ยนค่าที่นี่แล้วทุกหน้าที่เรียก `S.of(context)` จะ rebuild เป็นภาษาใหม่ทันที
class AppLanguage {
  static const String prefsKey = 'settings_language';
  static final ValueNotifier<String> notifier = ValueNotifier('en');
}

/// ครอบทั้งแอปไว้ (ใน MaterialApp.builder) เพื่อให้หน้าที่เรียก `S.of(context)`
/// ถูก rebuild เองเมื่อผู้ใช้สลับภาษา โดยไม่ต้องรีสตาร์ทแอป
class LanguageScope extends InheritedNotifier<ValueNotifier<String>> {
  LanguageScope({super.key, required super.child})
      : super(notifier: AppLanguage.notifier);
}

/// ข้อความทั้งหมดของแอป รวมไว้ที่เดียวทั้งภาษาอังกฤษและภาษาไทย
///
/// - ใน build() ให้ใช้ `S.of(context)` (จะ rebuild ตามภาษา)
/// - นอก widget tree (model / service / callback) ให้ใช้ `S.current`
///
/// ข้อความภาษาไทยตั้งใจเขียนให้สั้นพอๆ กับภาษาอังกฤษ เพื่อไม่ให้ล้นกรอบ UI เดิม
class S {
  final bool isThai;
  const S._(this.isThai);

  static const S _en = S._(false);
  static const S _th = S._(true);

  static S get current => AppLanguage.notifier.value == 'th' ? _th : _en;

  static S of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    return current;
  }

  String _t(String en, String th) => isThai ? th : en;

  // ---------- ใช้ร่วมกันหลายหน้า ----------
  String get cancel => _t('Cancel', 'ยกเลิก');
  String get delete => _t('Delete', 'ลบ');
  String get ok => _t('OK', 'ตกลง');
  String get home => _t('Home', 'หน้าหลัก');
  String get settings => _t('Settings', 'การตั้งค่า');
  String get about => _t('About', 'เกี่ยวกับ');
  String get gender => _t('Gender', 'เพศ');
  String get male => _t('Male', 'ชาย');
  String get female => _t('Female', 'หญิง');
  String get age => _t('Age', 'อายุ');
  String get paused => _t('Paused', 'หยุดชั่วคราว');
  String get builtInSound => _t('Built-in sound', 'เสียงในแอป');
  String minutesShort(int m) => _t('$m min', '$m นาที');

  /// แปลงป้ายคุณภาพการนอนจากโมเดล ('Good' | 'Fair' | 'Poor') เป็นข้อความที่แสดง
  String quality(String raw) {
    switch (raw.toLowerCase()) {
      case 'good':
        return _t('Good', 'ดี');
      case 'fair':
        return _t('Fair', 'พอใช้');
      case 'poor':
        return _t('Poor', 'ไม่ดี');
      default:
        return raw;
    }
  }

  // 1 = Mon ... 7 = Sun (ตรงกับ DateTime.weekday)
  List<String> get dayLetters => isThai
      ? const ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา']
      : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  List<String> get dayNamesShort => isThai
      ? const ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา']
      : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ---------- Splash ----------
  String get splashSubtitle => _t('Understand your sleep', 'เข้าใจการนอนของคุณ');

  // ---------- Bottom navigation ----------
  String get navAlarm => _t('Alarm', 'นาฬิกาปลุก');
  String get navSounds => _t('Sounds', 'เสียง');

  // ---------- Home ----------
  String get goodMorning => _t('Good morning', 'สวัสดีตอนเช้า');
  String get goodAfternoon => _t('Good afternoon', 'สวัสดีตอนบ่าย');
  String get goodEvening => _t('Good evening', 'สวัสดีตอนเย็น');
  String get menu => _t('Menu', 'เมนู');
  String get readyForCheck =>
      _t("Ready for tonight's check?", 'พร้อมเช็กการนอนคืนนี้ไหม?');
  String get startAssessment =>
      _t('Start sleep assessment', 'เริ่มประเมินการนอน');
  String get fullHistory => _t('Full history', 'ประวัติทั้งหมด');
  String get avgDuration => _t('Avg duration', 'นอนเฉลี่ย');
  String avgDurationValue(String hours) => _t('${hours}h', '$hours ชม.');
  String get streak => _t('Streak', 'ต่อเนื่อง');
  String streakDays(int n) => _t('$n day${n == 1 ? '' : 's'}', '$n วัน');
  String get lastQuality => _t('Last quality', 'คุณภาพล่าสุด');
  String get sleepTrend => _t('Sleep trend', 'แนวโน้มการนอน');
  String get range7Days => _t('This week', 'สัปดาห์นี้');
  String get range1Month => _t('1 Month', '1 เดือน');
  String get recentCheckIns => _t('Recent check-ins', 'การเช็กอินล่าสุด');
  String get showMore => _t('Show more', 'ดูเพิ่มเติม');
  String get showLess => _t('Show less', 'แสดงน้อยลง');
  String get noCheckInsYet => _t('No check-ins yet', 'ยังไม่มีการเช็กอิน');
  String get noCheckInsHint => _t(
        'Start your first sleep assessment to see your trend here.',
        'เริ่มประเมินการนอนครั้งแรกเพื่อดูแนวโน้มของคุณที่นี่',
      );
  String get deleteCheckInTitle =>
      _t('Delete this check-in?', 'ลบการเช็กอินนี้?');
  String deleteCheckInBody(String quality, String date) => _t(
        'Remove the $quality result from $date? This cannot be undone.',
        'ลบผล "$quality" ของ$dateใช่ไหม? การลบนี้ไม่สามารถย้อนกลับได้',
      );
  String get checkedInToday =>
      _t("You've checked in today", 'วันนี้ประเมินแล้ว');
  String get reassess => _t('Re-assess', 'ประเมินใหม่');
  String get viewResult => _t('View result', 'ดูผล');
  String get alreadyCheckedInTitle =>
      _t('Already checked in today', 'วันนี้ประเมินแล้ว');
  String alreadyCheckedInBody(String quality, int score) => _t(
        "Today's result: $quality ($score/100). "
            "Re-assessing replaces today's result.",
        'ผลวันนี้: $quality ($score/100) '
            'ถ้าประเมินใหม่ ผลเดิมของวันนี้จะถูกแทนที่',
      );
  String get today => _t('Today', 'วันนี้');
  String get yesterday => _t('Yesterday', 'เมื่อวาน');
  String daysAgo(int n) => _t('$n days ago', '$n วันก่อน');

  /// วันที่แบบอ่านง่าย: วันนี้ / เมื่อวาน / n วันก่อน / วัน/เดือน/ปี
  String relativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(dt.year, dt.month, dt.day))
        .inDays;
    if (diff == 0) return today;
    if (diff == 1) return yesterday;
    if (diff > 1 && diff < 7) return daysAgo(diff);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ---------- Assessment ----------
  String get assessmentTitle => _t('Sleep assessment', 'ประเมินการนอน');
  String get sleepDuration => _t('Sleep duration', 'ระยะเวลาการนอน');
  String get sleepDurationHint => _t(
        'How many hours did you sleep last night?',
        'เมื่อคืนคุณนอนกี่ชั่วโมง?',
      );
  String hoursValue(String h) => _t('$h hrs', '$h ชม.');
  String get stressLevel => _t('Stress level', 'ระดับความเครียด');
  String get stressLevelHint =>
      _t('How stressed have you felt today?', 'วันนี้คุณเครียดแค่ไหน?');
  String get physicalActivity => _t('Physical activity', 'กิจกรรมทางกาย');
  String get physicalActivityHint =>
      _t('Minutes of activity today', 'จำนวนนาทีที่ขยับร่างกายวันนี้');
  String get ageHint => _t('Your age in years', 'อายุของคุณ (ปี)');
  String yearsValue(int y) => _t('$y yrs', '$y ปี');
  String get analyze => _t('Analyze', 'วิเคราะห์');
  String get assessmentDisclaimer => _t(
        'This is an educational prototype. Not a medical diagnosis.',
        'แอปนี้เป็นต้นแบบเพื่อการศึกษา ไม่ใช่การวินิจฉัยทางการแพทย์',
      );

  // ---------- Loading ----------
  String get analyzingPattern =>
      _t('Analyzing your sleep pattern', 'กำลังวิเคราะห์รูปแบบการนอนของคุณ');
  String get somethingWentWrong => _t(
        'Something went wrong. Please try again.',
        'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง',
      );
  String get tryAgain => _t('Try again', 'ลองอีกครั้ง');

  // ---------- Result ----------
  String get result => _t('Result', 'ผลลัพธ์');
  String get sleepQualityLabel => _t('Sleep quality', 'คุณภาพการนอน');
  String get yourInputs => _t('Your inputs', 'ข้อมูลที่กรอก');
  String get inputSleep => _t('Sleep', 'ชั่วโมงนอน');
  String get inputStress => _t('Stress', 'ความเครียด');
  String get inputActivity => _t('Activity', 'กิจกรรม');
  String get factorsTitle => _t(
        'Factors associated with this result',
        'ปัจจัยที่เกี่ยวข้องกับผลลัพธ์นี้',
      );
  String get generalRecommendation =>
      _t('General recommendation', 'คำแนะนำทั่วไป');
  String get resultDisclaimer => _t(
        'This is a model prediction from an educational prototype, not a medical diagnosis.',
        'ผลนี้เป็นการทำนายของโมเดลจากต้นแบบเพื่อการศึกษา ไม่ใช่การวินิจฉัยทางการแพทย์',
      );
  String get backToHome => _t('Back to home', 'กลับหน้าหลัก');

  // ข้อความ factors / recommendation มาจาก backend เป็นภาษาอังกฤษ (และถูกเก็บใน
  // ประวัติเป็นภาษาอังกฤษด้วย) จึงแปลตอนแสดงผล ข้อความที่ไม่รู้จักจะแสดงตามเดิม
  static const Map<String, String> _factorsTh = {
    'Short sleep duration': 'นอนน้อย',
    'High stress level': 'ความเครียดสูง',
    'Low physical activity': 'ขยับร่างกายน้อย',
    'No major risk factors found': 'ไม่พบปัจจัยเสี่ยงหลัก',
  };

  static const Map<String, String> _recommendationsTh = {
    'Keep up your current routine — consistency is what helps most.':
        'รักษากิจวัตรปัจจุบันไว้ ความสม่ำเสมอคือสิ่งที่ช่วยได้มากที่สุด',
    'Try winding down screens 30 minutes before bed to help you fall asleep faster.':
        'ลองงดใช้หน้าจอ 30 นาทีก่อนเข้านอน จะช่วยให้หลับได้เร็วขึ้น',
    'Consider an earlier, more consistent bedtime and a short walk during the day.':
        'ลองเข้านอนให้เร็วขึ้นและเป็นเวลา พร้อมเดินเล่นสั้นๆ ระหว่างวัน',
    'Try keeping a consistent sleep schedule.':
        'ลองเข้านอนและตื่นให้เป็นเวลาสม่ำเสมอ',
  };

  String factor(String raw) => isThai ? (_factorsTh[raw] ?? raw) : raw;
  String recommendation(String raw) =>
      isThai ? (_recommendationsTh[raw] ?? raw) : raw;

  // ---------- Sleep stats ----------
  String get sleepStats => _t('Sleep stats', 'สถิติการนอน');
  String get range3Months => _t('3 Months', '3 เดือน');
  String get rangeAll => _t('All', 'ทั้งหมด');
  String get averageScore => _t('Average score', 'คะแนนเฉลี่ย');
  String changeUp(int n) =>
      _t('Up $n vs previous period', 'ดีขึ้น $n จากช่วงก่อน');
  String changeDown(int n) =>
      _t('Down $n vs previous period', 'ลดลง $n จากช่วงก่อน');
  String get changeNone =>
      _t('Same as previous period', 'เท่ากับช่วงก่อน');
  String get metricScore => _t('Score', 'คะแนน');
  String get metricSleep => _t('Sleep', 'ชม.นอน');
  String get metricStress => _t('Stress', 'เครียด');
  String get metricActivity => _t('Activity', 'กิจกรรม');
  String get highest => _t('Highest', 'สูงสุด');
  String get lowest => _t('Lowest', 'ต่ำสุด');
  String get checkIns => _t('Check-ins', 'เช็กอิน');
  String timesCount(int n) => _t('$n×', '$n ครั้ง');
  String get qualityBreakdown =>
      _t('Sleep quality breakdown', 'สัดส่วนคุณภาพการนอน');
  String get commonFactors => _t('Most common factors', 'ปัจจัยที่พบบ่อย');
  String get noRiskFactorsInRange => _t(
        'No risk factors found in this period',
        'ไม่พบปัจจัยเสี่ยงในช่วงนี้',
      );
  String get scoreByWeekday =>
      _t('Average score by day', 'คะแนนเฉลี่ยตามวัน');
  String get insightsTitle =>
      _t('Patterns in your data', 'ข้อสังเกตจากข้อมูลของคุณ');
  String get insightSleepHigh => _t('6.5 hrs or more', '6.5 ชม. ขึ้นไป');
  String get insightSleepLow => _t('Under 6.5 hrs', 'น้อยกว่า 6.5 ชม.');
  String get insightStressHigh => _t('Level 7 or higher', 'ระดับ 7 ขึ้นไป');
  String get insightStressLow => _t('Below level 7', 'ต่ำกว่าระดับ 7');
  String get insightActivityHigh => _t('20 min or more', '20 นาทีขึ้นไป');
  String get insightActivityLow => _t('Under 20 min', 'น้อยกว่า 20 นาที');
  String get insightsNote => _t(
        'These are associations in your own data, not causes or a diagnosis.',
        'เป็นความสัมพันธ์ในข้อมูลของคุณ ไม่ใช่สาเหตุหรือการวินิจฉัย',
      );
  String get insightsLocked => _t(
        'Keep checking in — patterns from your data will appear here.',
        'เช็กอินต่อไปอีกสักหน่อย แล้วข้อสังเกตจากข้อมูลของคุณจะแสดงที่นี่',
      );
  String get checkInsInRange =>
      _t('Check-ins in this period', 'การเช็กอินในช่วงนี้');
  String get noDataInRange =>
      _t('No check-ins in this period', 'ไม่มีการเช็กอินในช่วงนี้');

  // ---------- About ----------
  String get aboutTitle => _t('About SleepWise AI', 'เกี่ยวกับ SleepWise AI');
  String get aboutBody => _t(
        'SleepWise AI is an educational prototype built for a CPE310 '
            'course project. It estimates sleep quality (Good, Fair, or Poor) '
            'from lifestyle inputs such as sleep duration, stress level, '
            'physical activity, and screen time, using a machine learning '
            'model trained by the project team.',
        'SleepWise AI เป็นต้นแบบเพื่อการศึกษาที่จัดทำขึ้นสำหรับโครงงานรายวิชา '
            'CPE310 แอปจะประเมินคุณภาพการนอน (ดี พอใช้ หรือไม่ดี) '
            'จากข้อมูลการใช้ชีวิต เช่น ระยะเวลาการนอน ระดับความเครียด '
            'กิจกรรมทางกาย และเวลาที่ใช้หน้าจอ โดยใช้โมเดล machine learning '
            'ที่ทีมผู้จัดทำเป็นผู้ฝึก',
      );
  String get aboutDisclaimer => _t(
        'This application is an educational prototype. It is not '
            'intended to diagnose, treat, or substitute advice from a '
            'qualified healthcare professional.',
        'แอปพลิเคชันนี้เป็นต้นแบบเพื่อการศึกษา ไม่ได้มีวัตถุประสงค์เพื่อ'
            'วินิจฉัย รักษา หรือใช้แทนคำแนะนำจากบุคลากรทางการแพทย์',
      );

  // ---------- Settings ----------
  String get profile => _t('Profile', 'โปรไฟล์');
  String get profileNote => _t(
        'This info is used to auto-fill your Sleep Assessment',
        'ข้อมูลนี้ใช้เติมในแบบประเมินการนอนให้อัตโนมัติ',
      );
  String greetingWithName(String greeting, String name) =>
      _t('$greeting, $name', '$greeting $name');
  String get viewProfile => _t('View profile', 'ดูโปรไฟล์');
  String get setUpProfile => _t('Set up your profile', 'ตั้งค่าโปรไฟล์');
  String get profileSettingsSubtitle =>
      _t('Name, picture, age, gender', 'ชื่อ รูป อายุ เพศ');
  String get noNameYet => _t('No name yet', 'ยังไม่ได้ตั้งชื่อ');
  String ageYears(int n) => _t('$n years old', 'อายุ $n ปี');
  String get profileCheckIns => _t('Check-ins', 'เช็กอิน');
  String get profilePicture => _t('Profile picture', 'รูปโปรไฟล์');
  String get choosePhoto => _t('Choose from device', 'เลือกรูปจากเครื่อง');
  String get removePhoto => _t('Remove', 'ลบรูป');
  String get chooseAvatar => _t('Or pick an avatar', 'หรือเลือกอวตาร');
  String get photoPickFailed =>
      _t("Couldn't use that picture", 'ใช้รูปนี้ไม่ได้');
  String get yourDetails => _t('Your details', 'ข้อมูลของคุณ');
  String get profileStoredLocally => _t(
        'Your profile stays on this device only.',
        'โปรไฟล์เก็บไว้ในเครื่องนี้เท่านั้น',
      );
  String get displayName => _t('Display name', 'ชื่อที่แสดง');
  String get displayNameHint => _t('e.g. Alex', 'เช่น อเล็กซ์');
  String get ageSettingsHint => _t(
        'Used to auto-fill your sleep assessment',
        'ใช้เติมในแบบประเมินอัตโนมัติ',
      );
  String get assessmentPreferences =>
      _t('Sleep Assessment Preferences', 'การตั้งค่าแบบประเมินการนอน');
  String get durationUnit => _t('Sleep duration unit', 'หน่วยระยะเวลาการนอน');
  String get hours => _t('Hours', 'ชั่วโมง');
  String get minutes => _t('Minutes', 'นาที');
  String get notifications => _t('Notifications', 'การแจ้งเตือน');
  String get sleepReminder => _t('Sleep reminder', 'เตือนเข้านอน');
  String get sleepReminderSubtitle => _t(
        'Reminds you to go to bed every day at 10:00 PM',
        'เตือนให้เข้านอนทุกวัน เวลา 22:00 น.',
      );
  String get sleepReminderNotifTitle =>
      _t('Time to sleep 🌙', 'ได้เวลานอนแล้ว 🌙');
  String get sleepReminderNotifBody => _t(
        'Head to bed now for better sleep quality tonight.',
        'เข้านอนตอนนี้เพื่อคุณภาพการนอนที่ดีขึ้นในคืนนี้',
      );
  String get dailyReminder => _t('Daily reminder', 'เตือนประจำวัน');
  String get dailyReminderSubtitle => _t(
        'Reminds you to complete your sleep assessment every day at 8:00 AM',
        'เตือนให้ทำแบบประเมินการนอนทุกวัน เวลา 08:00 น.',
      );
  String get dailyReminderNotifTitle =>
      _t('Check in on your sleep 📝', 'เช็กอินการนอนของคุณ 📝');
  String get dailyReminderNotifBody => _t(
        'Complete today\'s sleep assessment — it only takes a minute.',
        'ทำแบบประเมินการนอนของวันนี้ ใช้เวลาเพียงหนึ่งนาที',
      );
  String get appearance => _t('Appearance', 'การแสดงผล');
  String get light => _t('Light', 'สว่าง');
  String get dark => _t('Dark', 'มืด');
  String get systemDefault => _t('System default', 'ตามระบบ');
  String get language => _t('Language', 'ภาษา');
  String get privacy => _t('Privacy', 'ความเป็นส่วนตัว');
  String get privacyLine1 => _t(
        'Data you enter is used only to run the sleep assessment.',
        'ข้อมูลที่คุณกรอกจะใช้เพื่อประเมินการนอนเท่านั้น',
      );
  String get privacyLine2 => _t(
        'This app is an educational prototype.',
        'แอปนี้เป็นต้นแบบเพื่อการศึกษา',
      );
  String get privacyLine3 => _t(
        'It is not a medical diagnostic system.',
        'ไม่ใช่ระบบวินิจฉัยทางการแพทย์',
      );
  String versionLabel(String v) => _t('Version $v', 'เวอร์ชัน $v');
  String get projectName =>
      _t('CPE310 — Healthcare AI Project', 'CPE310 — โครงงาน AI ด้านสุขภาพ');
  String get projectDescription => _t(
        'A prototype mobile app that estimates sleep quality from a short '
            'daily check-in, built as a class project to explore how a simple '
            'ML model can be paired with a friendly, easy-to-use interface.',
        'แอปมือถือต้นแบบที่ประเมินคุณภาพการนอนจากการเช็กอินสั้นๆ ในแต่ละวัน '
            'จัดทำเป็นโครงงานในรายวิชาเพื่อศึกษาการนำโมเดล ML อย่างง่าย'
            'มาใช้ร่วมกับหน้าจอที่เป็นมิตรและใช้งานง่าย',
      );
  String get resetAppData => _t('Reset App Data', 'รีเซ็ตข้อมูลแอป');
  String get resetAllData => _t('Reset All Data', 'รีเซ็ตข้อมูลทั้งหมด');
  String get resetAllDataSubtitle => _t(
        'Deletes settings and all saved check-ins from this device',
        'ลบการตั้งค่าและการเช็กอินทั้งหมดที่บันทึกไว้ในเครื่องนี้',
      );
  String get resetDialogTitle => _t('Reset all data?', 'รีเซ็ตข้อมูลทั้งหมด?');
  String get resetDialogBody => _t(
        'This will delete all your settings and assessment history. '
            'This action cannot be undone.',
        'การตั้งค่าและประวัติการประเมินทั้งหมดของคุณจะถูกลบ '
            'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
      );
  String get resetDone =>
      _t('All app data has been reset', 'รีเซ็ตข้อมูลแอปทั้งหมดแล้ว');
  String get appInformation => _t('App Information', 'ข้อมูลแอป');
  String get appNameLabel => _t('App name', 'ชื่อแอป');
  String get version => _t('Version', 'เวอร์ชัน');
  String get developerTeam => _t('Developer / Team', 'ผู้พัฒนา / ทีม');
  String get course => _t('Course', 'รายวิชา');

  // ---------- Alarm ----------
  String get sleepCycleAlarm => _t('Sleep Cycle Alarm', 'ปลุกตามรอบการนอน');
  String get noAlarmsSet => _t('No alarms set', 'ยังไม่ได้ตั้งปลุก');
  String alarmsActive(int active, int total) =>
      _t('$active of $total active', 'เปิดอยู่ $active จาก $total รายการ');
  String get aboutSleepCycleAlarm =>
      _t('About Sleep Cycle Alarm', 'เกี่ยวกับการปลุกตามรอบการนอน');
  String get sleepCycleInfo1 => _t(
        'This feature helps you plan your bedtime and wake-up time '
            'using the sleep cycle concept as a guideline, so you wake up '
            'when your body is more likely to feel ready. It does not '
            'replace or change the app\'s AI sleep quality prediction '
            'system in any way.',
        'ฟีเจอร์นี้ช่วยวางแผนเวลาเข้านอนและเวลาตื่น โดยใช้แนวคิดรอบการนอน'
            'เป็นแนวทาง เพื่อให้คุณตื่นในช่วงที่ร่างกายมีแนวโน้มพร้อมมากกว่า '
            'ฟีเจอร์นี้ไม่ได้แทนที่หรือเปลี่ยนแปลงระบบทำนายคุณภาพการนอน'
            'ด้วย AI ของแอปแต่อย่างใด',
      );
  String get sleepCycleInfo2 => _t(
        'A sleep cycle includes Light Sleep, Deep Sleep, and REM, '
            'and typically lasts around 90 minutes. This is only an '
            'estimate for planning purposes, not a fixed number — '
            'getting enough sleep still matters more than trying to '
            'wake up at an exact cycle boundary.',
        'รอบการนอนหนึ่งรอบประกอบด้วยช่วงหลับตื้น หลับลึก และ REM '
            'โดยทั่วไปใช้เวลาประมาณ 90 นาที ตัวเลขนี้เป็นเพียงค่าประมาณ'
            'เพื่อการวางแผน ไม่ใช่ค่าตายตัว การนอนให้เพียงพอยังสำคัญกว่า'
            'การพยายามตื่นให้ตรงกับจุดสิ้นสุดของรอบพอดี',
      );
  String get noAlarmsYet => _t('No alarms yet', 'ยังไม่มีนาฬิกาปลุก');
  String get noAlarmsHint => _t(
        'Tap the + button to set your first sleep alarm',
        'แตะปุ่ม + เพื่อตั้งนาฬิกาปลุกแรกของคุณ',
      );
  String get deleteAlarmTitle => _t('Delete this alarm?', 'ลบนาฬิกาปลุกนี้?');
  String get repeatOnce => _t('Once', 'ครั้งเดียว');
  String get repeatEveryDay => _t('Every day', 'ทุกวัน');
  String get repeatWeekdays => _t('Weekdays', 'จ-ศ');
  String get repeatWeekends => _t('Weekends', 'ส-อา');
  String sleepDurationLabel(int h, int m) {
    if (m == 0) return _t('${h}h sleep', 'นอน $h ชม.');
    return _t('${h}h ${m}m sleep', 'นอน $h ชม. $m นาที');
  }

  String get editAlarm => _t('Edit Alarm', 'แก้ไขนาฬิกาปลุก');
  String get newAlarm => _t('New Alarm', 'ตั้งปลุกใหม่');
  String get whenToWake =>
      _t('When do you want to wake up?', 'คุณต้องการตื่นกี่โมง?');
  String get change => _t('Change', 'เปลี่ยน');
  String get selectTime => _t('Select time', 'เลือกเวลา');
  String get recommendedBedtime =>
      _t('Recommended bedtime', 'เวลาเข้านอนที่แนะนำ');
  String get best => _t('Best', 'แนะนำ');
  String get repeat => _t('Repeat', 'ทำซ้ำ');
  String get noDaysSelected => _t(
        'No days selected = one-time alarm only',
        'ไม่เลือกวัน = ปลุกครั้งเดียว',
      );
  String get snooze => _t('Snooze', 'เลื่อนปลุก');
  String get saveChanges => _t('Save Changes', 'บันทึกการเปลี่ยนแปลง');
  String get setAlarm => _t('Set Alarm', 'ตั้งปลุก');
  String get deleteAlarm => _t('Delete Alarm', 'ลบนาฬิกาปลุก');
  String get selectBedtimeFirst => _t(
        'Please select a bedtime before saving',
        'กรุณาเลือกเวลาเข้านอนก่อนบันทึก',
      );
  String get alarmScheduleFailed => _t(
        'Could not set the alarm on this device. Allow alarm and notification permissions, then turn it on again.',
        'ตั้งปลุกบนเครื่องไม่สำเร็จ กรุณาอนุญาตสิทธิ์นาฬิกาปลุกและการแจ้งเตือน แล้วเปิดปลุกอีกครั้ง',
      );
  String get xiaomiTipTitle =>
      _t('Make the alarm show on the lock screen', 'ให้ปลุกขึ้นหน้าจอตอนล็อกเครื่อง');
  String get xiaomiTipBody => _t(
        'On Xiaomi / Redmi phones, please turn these on for SleepWise AI so the alarm screen opens by itself when the screen is off:',
        'มือถือ Xiaomi / Redmi ต้องเปิดสิทธิ์เหล่านี้ให้ SleepWise AI เพื่อให้หน้าปลุกเปิดขึ้นเองตอนจอดับ:',
      );
  String get xiaomiTipStep1 =>
      _t('Show on Lock screen', 'แสดงบนหน้าจอล็อก (Show on Lock screen)');
  String get xiaomiTipStep2 => _t(
        'Display pop-up windows while running in the background',
        'แสดงหน้าต่างป๊อปอัปขณะทำงานเบื้องหลัง',
      );
  String get xiaomiTipStep3 => _t(
        'Also set Battery saver to "No restrictions" and turn on Autostart',
        'และตั้งตัวประหยัดแบตเป็น "ไม่มีข้อจำกัด" พร้อมเปิดเริ่มอัตโนมัติ (Autostart)',
      );
  String get openSettings => _t('Open settings', 'เปิดการตั้งค่า');
  String get later => _t('Later', 'ไว้ทีหลัง');
  String get timeToWakeUp => _t('Time to wake up', 'ได้เวลาตื่นแล้ว');
  String get stop => _t('Stop', 'หยุด');
  String snoozeFor(int m) => _t('Snooze $m min', 'เลื่อนปลุก $m นาที');

  // ข้อความใน notification ของนาฬิกาปลุก
  String get alarmSetNotifTitle => _t('⏰ Alarm set', '⏰ ตั้งปลุกแล้ว');
  String nextAlarmAt(String time) =>
      _t('Next alarm at $time', 'ปลุกครั้งถัดไป $time น.');
  String nextAlarmAtWithCount(String time, int count) => _t(
        'Next alarm at $time • $count alarms active',
        'ปลุกครั้งถัดไป $time น. • เปิดอยู่ $count รายการ',
      );
  String snoozedUntil(String time) =>
      _t('Snoozed until $time', 'เลื่อนปลุกถึง $time น.');
  String get alarmRingNotifBody => _t('Time to wake up!', 'ได้เวลาตื่นแล้ว!');

  // ---------- Sounds ----------
  String get sleepSounds => _t('Sleep Sounds', 'เสียงกล่อมนอน');
  String nowPlayingName(String name) =>
      _t('Now playing: $name', 'กำลังเล่น: $name');
  String get soundsSubtitle => _t(
        'Calming sounds to help you fall asleep',
        'เสียงผ่อนคลายช่วยให้หลับง่ายขึ้น',
      );
  String get filterImported => _t('Imported', 'นำเข้า');
  String get filterBuiltIn => _t('Built-in', 'ในแอป');
  String get filterFavorites => _t('Favorites', 'รายการโปรด');
  String get importedSounds => _t('Imported sounds', 'เสียงที่นำเข้า');
  String get builtInSounds => _t('Built-in sounds', 'เสียงในแอป');
  String get favoriteSounds => _t('Favorite sounds', 'เสียงโปรด');
  String get noImportedSounds =>
      _t('No imported sounds yet', 'ยังไม่มีเสียงที่นำเข้า');
  String get noBuiltInSounds =>
      _t('No built-in sounds available', 'ไม่มีเสียงในแอป');
  String get noFavorites => _t(
        'No favorites yet — tap the heart on a sound to add it here',
        'ยังไม่มีรายการโปรด — แตะรูปหัวใจที่เสียงเพื่อเพิ่มไว้ที่นี่',
      );
  String soundAdded(String name) => _t('Added "$name"', 'เพิ่ม "$name" แล้ว');
  String get importFailed => _t(
        'Could not import file. Try again.',
        'นำเข้าไฟล์ไม่สำเร็จ ลองอีกครั้ง',
      );
  String cannotPlay(Object error) =>
      _t('Couldn\'t play this sound: $error', 'เล่นเสียงนี้ไม่ได้: $error');
  String get addSound => _t('Add sound', 'เพิ่มเสียง');
  String get playingNow => _t('Playing now', 'กำลังเล่น');
  String get yourFile => _t('Your file', 'ไฟล์ของคุณ');
  String get nowPlaying => _t('Now playing', 'กำลังเล่น');
  String get yourSound => _t('Your sound', 'เสียงของคุณ');
  String get playingLooping => _t('Playing • looping', 'กำลังเล่น • วนซ้ำ');

  static const Map<String, String> _builtInSoundNamesTh = {
    'rain': 'ฝนตก',
    'ocean': 'คลื่นทะเล',
    'forest': 'ป่าไม้',
    'whitenoise': 'ไวท์นอยส์',
  };

  /// ชื่อเสียงที่ใช้แสดงผล — เสียงที่ติดมากับแอปจะแปลตาม id
  /// ส่วนเสียงที่ผู้ใช้นำเข้าเองใช้ชื่อไฟล์ตามเดิม
  String soundName({
    required String id,
    required String name,
    required bool isImported,
  }) {
    if (isImported || !isThai) return name;
    return _builtInSoundNamesTh[id] ?? name;
  }
}
