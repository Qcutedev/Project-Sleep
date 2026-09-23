import 'package:flutter/material.dart';
import '../services/sound_player_controller.dart';
import '../theme/app_theme.dart';

class NowPlayingScreen extends StatelessWidget {
  final SoundPlayerController controller;
  const NowPlayingScreen({super.key, required this.controller});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.isDark(context) ? AppTheme.primaryDark : AppTheme.primary;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final sound = controller.currentSound;
        if (sound == null) {
          Navigator.of(context).pop();
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text('Now playing',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(sound.icon, style: const TextStyle(fontSize: 72)),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sound.name,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(sound.isImported ? 'Your sound' : 'Built-in sound',
                                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.toggleRepeat(),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.repeat_one_rounded,
                            color: controller.repeatOne ? Colors.white : Colors.white.withValues(alpha: 0.4),
                            size: 22,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          controller.isFavorite(sound) ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () => controller.toggleFavorite(sound),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<Duration?>(
                    stream: controller.player.durationStream,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration>(
                        stream: controller.player.positionStream,
                        builder: (context, positionSnapshot) {
                          var position = positionSnapshot.data ?? Duration.zero;
                          if (position > duration) position = duration;
                          final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                          final posMs = position.inMilliseconds.toDouble().clamp(0, maxMs);

                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  min: 0,
                                  max: maxMs,
                                  value: posMs.toDouble(),
                                  onChanged: (value) {
                                    controller.seek(Duration(milliseconds: value.round()));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(position),
                                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                                    Text(_formatDuration(duration),
                                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => controller.playPrevious(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(Icons.skip_previous_rounded, color: Colors.white, size: 34),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.togglePlayPause(),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: Icon(
                            controller.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: bgColor,
                            size: 32,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.playNext(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(Icons.skip_next_rounded, color: Colors.white, size: 34),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}