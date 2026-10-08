import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// รูปโปรไฟล์มีได้ 3 แบบ: ยังไม่ตั้ง, อวตารสำเร็จรูป, รูปจากเครื่อง
enum AvatarType { none, preset, photo }

/// โปรไฟล์ของผู้ใช้ เก็บในเครื่องอย่างเดียว ไม่มีบัญชีและไม่ส่งขึ้นเซิร์ฟเวอร์
@immutable
class UserProfile {
  final String name;
  final String age; // เก็บเป็นข้อความตามที่พิมพ์ ('' = ยังไม่ตั้ง)
  final String gender; // '' = ยังไม่ตั้ง, 'male' / 'female'
  final AvatarType avatarType;

  /// id ของอวตาร (เมื่อเป็น preset) หรือ path ของไฟล์รูป (เมื่อเป็น photo)
  final String avatarValue;

  const UserProfile({
    this.name = '',
    this.age = '',
    this.gender = '',
    this.avatarType = AvatarType.none,
    this.avatarValue = '',
  });

  UserProfile copyWith({
    String? name,
    String? age,
    String? gender,
    AvatarType? avatarType,
    String? avatarValue,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      avatarType: avatarType ?? this.avatarType,
      avatarValue: avatarValue ?? this.avatarValue,
    );
  }
}

/// อ่าน/บันทึกโปรไฟล์ และแจ้งทุกหน้าที่แสดงโปรไฟล์ผ่าน [profile]
///
/// ชื่อ อายุ เพศ ใช้ key เดิมของหน้า Settings เพราะ `assessment_screen.dart`
/// อ่าน key พวกนี้ไปเติมฟอร์มประเมิน
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const _kName = 'settings_display_name';
  static const _kAge = 'settings_age';
  static const _kGender = 'settings_gender';
  static const _kAvatarType = 'profile_avatar_type';
  static const _kAvatarValue = 'profile_avatar_value';
  static const _photoFolder = 'profile';

  final ValueNotifier<UserProfile> profile =
      ValueNotifier<UserProfile>(const UserProfile());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    profile.value = UserProfile(
      name: prefs.getString(_kName) ?? '',
      age: prefs.getString(_kAge) ?? '',
      gender: prefs.getString(_kGender) ?? '',
      avatarType: AvatarType.values.firstWhere(
        (t) => t.name == prefs.getString(_kAvatarType),
        orElse: () => AvatarType.none,
      ),
      avatarValue: prefs.getString(_kAvatarValue) ?? '',
    );
  }

  Future<void> setName(String value) async {
    profile.value = profile.value.copyWith(name: value.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, value.trim());
  }

  Future<void> setAge(String value) async {
    profile.value = profile.value.copyWith(age: value.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAge, value.trim());
  }

  Future<void> setGender(String value) async {
    profile.value = profile.value.copyWith(gender: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGender, value);
  }

  Future<void> setPresetAvatar(String id) =>
      _setAvatar(AvatarType.preset, id);

  Future<void> removeAvatar() => _setAvatar(AvatarType.none, '');

  /// ให้ผู้ใช้เลือกรูปจากเครื่อง แล้วคัดลอกเข้าโฟลเดอร์ของแอป
  /// คืน false ถ้าผู้ใช้ยกเลิก และโยน exception ถ้าเลือกแล้วแต่ใช้ไฟล์ไม่ได้
  Future<bool> pickPhoto() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty || result.single.path == null) return false;

    final docsDir = await getApplicationDocumentsDirectory();
    final folder = Directory('${docsDir.path}/$_photoFolder');
    if (!await folder.exists()) await folder.create(recursive: true);

    final name = result.single.name;
    final dot = name.lastIndexOf('.');
    final extension = dot >= 0 ? name.substring(dot) : '';
    // ตั้งชื่อไฟล์ใหม่ทุกครั้ง ไม่อย่างนั้น Flutter จะแสดงรูปเก่าจาก cache
    final saved = await File(result.single.path!).copy(
      '${folder.path}/avatar_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    await _setAvatar(AvatarType.photo, saved.path);
    return true;
  }

  Future<void> _setAvatar(AvatarType type, String value) async {
    final old = profile.value;
    profile.value = old.copyWith(avatarType: type, avatarValue: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAvatarType, type.name);
    await prefs.setString(_kAvatarValue, value);
    if (old.avatarType == AvatarType.photo && old.avatarValue != value) {
      await _deleteFile(old.avatarValue);
    }
  }

  /// เรียกหลัง "รีเซ็ตข้อมูลทั้งหมด" ล้าง SharedPreferences แล้ว
  /// เพื่อลบไฟล์รูปที่ค้างอยู่และให้ทุกหน้ากลับเป็นโปรไฟล์ว่าง
  Future<void> clearAfterReset() async {
    final old = profile.value;
    profile.value = const UserProfile();
    if (old.avatarType == AvatarType.photo) await _deleteFile(old.avatarValue);
  }

  Future<void> _deleteFile(String path) async {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // ลบไม่ได้ก็ปล่อยไว้ ไฟล์อยู่ในโฟลเดอร์ของแอปและไม่มีที่ไหนอ้างถึงแล้ว
    }
  }
}
