import 'package:flutter/material.dart';
import '../models/sound_item.dart';
import '../services/sound_service.dart';
import '../services/sound_player_controller.dart';
import '../theme/app_theme.dart';

enum _SoundFilter { imported, builtIn, favorites }

class SoundsScreen extends StatefulWidget {
  final SoundPlayerController controller;
  const SoundsScreen({super.key, required this.controller});

  @override
  State<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<SoundsScreen> {
  final SoundService _soundService = SoundService();
  List<SoundItem> _importedSounds = [];
  bool _isLoading = false;
  _SoundFilter _filter = _SoundFilter.builtIn;

  Color _accent(BuildContext context) => AppTheme.primary;

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  Future<void> _loadSounds() async {
    final list = await _soundService.getImportedSounds();
    setState(() => _importedSounds = list);
  }

  Future<void> _importFromDevice() async {
    setState(() => _isLoading = true);
    try {
      final item = await _soundService.importSound();
      if (item != null) {
        setState(() => _importedSounds.add(item));
        _showSnack('Added "${item.name}"');
      }
    } catch (e) {
      _showSnack('Could not import file. Try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<SoundItem> _currentList() {
    switch (_filter) {
      case _SoundFilter.imported:
        return _importedSounds;
      case _SoundFilter.builtIn:
        return SoundService.builtInSounds;
      case _SoundFilter.favorites:
        final all = [..._importedSounds, ...SoundService.builtInSounds];
        return all.where((e) => widget.controller.isFavorite(e)).toList();
    }
  }

  String _sectionTitle() {
    switch (_filter) {
      case _SoundFilter.imported:
        return 'Imported sounds';
      case _SoundFilter.builtIn:
        return 'Built-in sounds';
      case _SoundFilter.favorites:
        return 'Favorite sounds';
    }
  }

  String _emptyMessage() {
    switch (_filter) {
      case _SoundFilter.imported:
        return 'No imported sounds yet';
      case _SoundFilter.builtIn:
        return 'No built-in sounds available';
      case _SoundFilter.favorites:
        return 'No favorites yet — tap the heart on a sound to add it here';
    }
  }

  Future<void> _playSound(SoundItem item, List<SoundItem> queue) async {
    try {
      await widget.controller.playSound(item, queue: queue);
    } catch (e) {
      _showSnack('Couldn\'t play this sound: $e');
    }
  }

  Future<void> _deleteSound(SoundItem item) async {
    if (widget.controller.currentSound?.id == item.id) {
      await widget.controller.stopCurrentSound();
    }
    await _soundService.deleteImportedSound(item);
    setState(() => _importedSounds.removeWhere((e) => e.id == item.id));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final list = _currentList();
        final accent = _accent(context);
        return Scaffold(
          backgroundColor: AppTheme.bg(context),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _buildHeader(context, accent),
                const SizedBox(height: 20),
                _buildFilterTabs(context, accent),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_sectionTitle(),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor(context))),
                    if (_filter == _SoundFilter.imported) _buildImportButton(context, accent),
                  ],
                ),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  _buildEmptyState(context)
                else
                  ...list.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSoundCard(context, item, list, accent),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.95),
            accent.withValues(alpha: 0.65),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sleep Sounds',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.controller.currentSound != null
                      ? 'Now playing: ${widget.controller.currentSound!.name}'
                      : 'Calming sounds to help you fall asleep',
                  style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, Color accent) {
    final options = [
      (_SoundFilter.imported, 'Imported'),
      (_SoundFilter.builtIn, 'Built-in'),
      (_SoundFilter.favorites, 'Favorites'),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: options.map((opt) {
          final selected = _filter == opt.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  opt.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textSecondaryColor(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImportButton(BuildContext context, Color accent) {
    return GestureDetector(
      onTap: _isLoading ? null : _importFromDevice,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: _isLoading
            ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('Add sound', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _accent(context).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.music_off_rounded, size: 34, color: _accent(context).withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Text(
            _emptyMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMutedColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundCard(
    BuildContext context,
    SoundItem item,
    List<SoundItem> queue,
    Color accent,
  ) {
    final controller = widget.controller;
    final isActive = controller.currentSound?.id == item.id;
    final isFav = controller.isFavorite(item);

    return InkWell(
      onTap: () => _playSound(item, queue),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? accent.withValues(alpha: 0.3) : Colors.transparent,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? accent.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isActive ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: isActive ? 0.9 : 0.14),
                    accent.withValues(alpha: isActive ? 0.6 : 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(item.icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isActive
                        ? (controller.isPlaying ? 'Playing now' : 'Paused')
                        : (item.isImported ? 'Your file' : 'Built-in sound'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isActive ? accent : AppTheme.textMutedColor(context),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? const Color(0xFFD4537E) : AppTheme.textMutedColor(context),
                size: 20,
              ),
              onPressed: () => controller.toggleFavorite(item),
            ),
            if (item.isImported)
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppTheme.textMutedColor(context), size: 20),
                onPressed: () => _deleteSound(item),
              ),
            const SizedBox(width: 4),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isActive ? accent : accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Icon(
                isActive && controller.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isActive ? Colors.white : accent,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}