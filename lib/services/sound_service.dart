import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sound_item.dart';

class SoundService {
  static const _prefsKey = 'imported_sounds';
  static const _favKey = 'favorite_sound_ids';

  // เสียงพื้นฐาน (ต้องมีไฟล์จริงใน assets/sounds/ ก่อนถึงจะเล่นได้)
  static final List<SoundItem> builtInSounds = [
    SoundItem(id: 'rain', name: 'Rain', icon: '🌧️', assetPath: 'assets/sounds/rain.mp3'),
    SoundItem(id: 'ocean', name: 'Ocean Waves', icon: '🌊', assetPath: 'assets/sounds/ocean.mp3'),
    SoundItem(id: 'forest', name: 'Forest', icon: '🌲', assetPath: 'assets/sounds/forest.mp3'),
    SoundItem(id: 'whitenoise', name: 'White Noise', icon: '🌫️', assetPath: 'assets/sounds/white_noise.mp3'),
];

  Future<SoundItem?> importSound() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav'],
    );
    if (result.isEmpty || result.single.path == null) return null;

    final pickedFile = File(result.single.path!);
    final originalName = result.single.name;
    final docsDir = await getApplicationDocumentsDirectory();
    final soundsDir = Directory('${docsDir.path}/imported_sounds');
    if (!await soundsDir.exists()) await soundsDir.create(recursive: true);

    final newPath = '${soundsDir.path}/${DateTime.now().millisecondsSinceEpoch}_$originalName';
    final savedFile = await pickedFile.copy(newPath);

    final item = SoundItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: originalName.replaceAll(RegExp(r'\.(mp3|m4a|wav)$', caseSensitive: false), ''),
      icon: '🎵',
      filePath: savedFile.path,
      isImported: true,
    );

    await _saveImportedSound(item);
    return item;
  }

  Future<void> _saveImportedSound(SoundItem item) async {
    final list = await getImportedSounds();
    list.add(item);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<List<SoundItem>> getImportedSounds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString == null) return [];
    final List decoded = jsonDecode(jsonString);
    return decoded.map((e) => SoundItem.fromJson(e)).toList();
  }

  Future<void> deleteImportedSound(SoundItem item) async {
    final list = await getImportedSounds();
    list.removeWhere((e) => e.id == item.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(list.map((e) => e.toJson()).toList()));

    if (item.filePath != null) {
      final file = File(item.filePath!);
      if (await file.exists()) await file.delete();
    }
  }

  // ---- Favorite sounds (ใช้ได้ทั้งเสียง built-in และเสียงที่ import) ----
  // เก็บแค่ id ของเสียงที่ถูกกดหัวใจไว้ แยกจากตัวไฟล์เสียงเอง
  // เพราะ built-in sounds เป็น static list เปลี่ยนแปลงตัว object ไม่ได้โดยตรง

  Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_favKey) ?? []).toSet();
  }

  Future<void> saveFavoriteIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favKey, ids.toList());
  }
}