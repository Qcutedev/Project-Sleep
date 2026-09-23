class SoundCategory {
  final String id;
  final String label;
  const SoundCategory({required this.id, required this.label});
}

class SoundTrack {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String categoryId;

  const SoundTrack({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.categoryId,
  });
}

const List<SoundCategory> soundCategories = [
  SoundCategory(id: 'nature', label: 'Nature'),
  SoundCategory(id: 'ambient', label: 'Ambient'),
  SoundCategory(id: 'music', label: 'Music'),
];

const List<SoundTrack> soundTracks = [
  SoundTrack(id: 'rain', name: 'Rain', description: 'Soft rainfall', emoji: '🌧️', categoryId: 'nature'),
  SoundTrack(id: 'thunder', name: 'Thunderstorm', description: 'Distant rolling thunder', emoji: '⛈️', categoryId: 'nature'),
  SoundTrack(id: 'ocean', name: 'Ocean Waves', description: 'Gentle ocean waves', emoji: '🌊', categoryId: 'nature'),
  SoundTrack(id: 'forest', name: 'Forest', description: 'Peaceful forest ambience', emoji: '🌲', categoryId: 'nature'),
  SoundTrack(id: 'fireplace', name: 'Fireplace', description: 'Warm crackling fire', emoji: '🔥', categoryId: 'ambient'),
  SoundTrack(id: 'wind', name: 'Wind', description: 'Soft blowing wind', emoji: '🍃', categoryId: 'ambient'),
  SoundTrack(id: 'whitenoise', name: 'White Noise', description: 'Steady background noise', emoji: '🤍', categoryId: 'ambient'),
  SoundTrack(id: 'piano', name: 'Piano', description: 'Slow gentle piano', emoji: '🎹', categoryId: 'music'),
  SoundTrack(id: 'ambientmusic', name: 'Ambient', description: 'Soft ambient textures', emoji: '🎧', categoryId: 'music'),
  SoundTrack(id: 'meditation', name: 'Meditation', description: 'Calm meditation tones', emoji: '🧘', categoryId: 'music'),
];