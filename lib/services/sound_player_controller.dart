import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/sound_item.dart';
import 'sound_service.dart';

/// ตัวควบคุมการเล่นเสียงกลาง เก็บไว้ระดับ MainShell
/// เพื่อให้ mini-player bar และหน้า Now Playing เห็นสถานะเดียวกัน
/// ไม่ว่าจะสลับไปแท็บไหนก็ตาม
class SoundPlayerController extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  final SoundService soundService = SoundService();

  SoundItem? currentSound;
  bool isPlaying = false;
  bool repeatOne = true; // true = วนเพลงเดิมซ้ำ, false = จบแล้วเล่นเพลงถัดไปในคิวอัตโนมัติ
  Set<String> favoriteIds = {};

  /// คิวเพลงปัจจุบัน ใช้อ้างอิงตอนกดปุ่มย้อนกลับ/ถัดไป
  /// ถูกตั้งใหม่ทุกครั้งที่กดเล่นเสียงจากลิสต์หน้าไหนก็ตาม (เก็บ "บริบท" ของลิสต์นั้นไว้)
  List<SoundItem> playQueue = [];

  SoundPlayerController() {
    player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed && !repeatOne) {
        playNext();
      }
      notifyListeners();
    });
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    favoriteIds = await soundService.getFavoriteIds();
    notifyListeners();
  }

  bool isFavorite(SoundItem item) => favoriteIds.contains(item.id);

  Future<void> toggleFavorite(SoundItem item) async {
    if (favoriteIds.contains(item.id)) {
      favoriteIds.remove(item.id);
    } else {
      favoriteIds.add(item.id);
    }
    notifyListeners();
    await soundService.saveFavoriteIds(favoriteIds);
  }

  /// FIX: เดิมโค้ดเรียก `await player.play()` ก่อนจะตั้ง `currentSound` และ
  /// `notifyListeners()` แต่ Future ของ `play()` ใน just_audio จะไม่ resolve
  /// จนกว่าเพลงจะเล่นจบ/ถูก pause/ถูกโหลดซอร์สใหม่ทับ ถ้าเปิดโหมดวนซ้ำ
  /// (repeatOne = true) มันจะไม่มีวัน resolve เอง ทำให้ currentSound/mini bar
  /// ไม่อัปเดตจนกว่าจะกดเล่นเสียงอีกรอบ (ซึ่งไปโหลดซอร์สใหม่ทับของเดิม)
  /// วิธีแก้คือตั้งค่า currentSound + notifyListeners() ก่อนเรียก play()
  /// และไม่ await ตัว play() เอง (ปล่อยให้เล่นต่อเบื้องหลัง เพราะ isPlaying
  /// อัปเดตเองอยู่แล้วผ่าน playerStateStream ใน constructor)
  Future<void> playSound(SoundItem item, {List<SoundItem>? queue}) async {
    if (queue != null) playQueue = queue;

    if (currentSound?.id == item.id && isPlaying) {
      await player.pause();
      return;
    }
    if (currentSound?.id == item.id && !isPlaying) {
      player.play(); // ไม่ต้อง await
      return;
    }

    if (item.isImported) {
      await player.setFilePath(item.filePath!);
    } else {
      await player.setAsset(item.assetPath);
    }
    await player.setLoopMode(repeatOne ? LoopMode.one : LoopMode.off);

    // ตั้งค่าก่อนเล่น เพื่อให้ UI (mini bar, การ์ดในลิสต์) อัปเดตทันที
    currentSound = item;
    notifyListeners();

    // ไม่ await: ป้องกันการค้างเมื่อ loop mode เป็น LoopMode.one
    player.play();
  }

  Future<void> togglePlayPause() async {
    if (currentSound == null) return;
    if (isPlaying) {
      await player.pause();
    } else {
      player.play(); // ไม่ await ด้วยเหตุผลเดียวกัน
    }
  }

  Future<void> toggleRepeat() async {
    repeatOne = !repeatOne;
    await player.setLoopMode(repeatOne ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<void> playNext() async {
    if (playQueue.isEmpty || currentSound == null) return;
    final index = playQueue.indexWhere((e) => e.id == currentSound!.id);
    if (index == -1) return;
    final nextIndex = (index + 1) % playQueue.length;
    await playSound(playQueue[nextIndex]);
  }

  Future<void> playPrevious() async {
    if (playQueue.isEmpty || currentSound == null) return;
    final index = playQueue.indexWhere((e) => e.id == currentSound!.id);
    if (index == -1) return;
    final prevIndex = (index - 1 + playQueue.length) % playQueue.length;
    await playSound(playQueue[prevIndex]);
  }

  Future<void> stopCurrentSound() async {
    await player.stop();
    currentSound = null;
    notifyListeners();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
