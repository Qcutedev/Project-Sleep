import 'package:flutter/material.dart';
import '../services/sound_player_controller.dart';
import '../screens/now_playing_screen.dart';

/// แถบเล่นเพลงย่อ ลอยอยู่เหนือ bottom navigation bar เสมอเมื่อมีเสียงกำลังเล่น
/// กดแล้วเปิดหน้า Now Playing แบบเต็มจอ
class MiniPlayerBar extends StatelessWidget {
  final SoundPlayerController controller;
  const MiniPlayerBar({super.key, required this.controller});

  static const _accent = Color(0xFF6C5CE7);

  @override
  Widget build(BuildContext context) {
    final sound = controller.currentSound;
    if (sound == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NowPlayingScreen(controller: controller),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(sound.icon, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sound.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    controller.isPlaying ? 'Playing • looping' : 'Paused',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                controller.isFavorite(sound) ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => controller.toggleFavorite(sound),
            ),
            GestureDetector(
              onTap: () => controller.togglePlayPause(),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: Icon(
                  controller.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: _accent,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // ปุ่มกากบาท: ปิดเสียงปัจจุบันทิ้ง ทำให้ mini bar หายไปด้วย (currentSound == null)
            GestureDetector(
              onTap: () => controller.stopCurrentSound(),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
