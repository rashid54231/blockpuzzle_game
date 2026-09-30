import 'package:audioplayers/audioplayers.dart';

abstract class AudioService {
  Future<void> init();
  Future<void> playSfx(
    String soundName, {
    double pitch = 1.0,
    double volume = 1.0,
  });
  Future<void> startMusic();
  Future<void> stopMusic();
  void setSfxEnabled(bool enabled);
  void setMusicEnabled(bool enabled);
  bool get isSfxEnabled;
  bool get isMusicEnabled;
  void dispose();
}

class AppAudioService implements AudioService {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _sfxEnabled = true;
  bool _musicEnabled = true;

  @override
  bool get isSfxEnabled => _sfxEnabled;

  @override
  bool get isMusicEnabled => _musicEnabled;

  @override
  Future<void> init() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.4);
    } catch (_) {
      // Audio fallback gracefully
    }
  }

  @override
  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  @override
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      _musicPlayer.stop();
    } else {
      startMusic();
    }
  }

  @override
  Future<void> playSfx(
    String soundName, {
    double pitch = 1.0,
    double volume = 1.0,
  }) async {
    if (!_sfxEnabled) return;
    try {
      final player = AudioPlayer();
      await player.setPlaybackRate(pitch.clamp(0.5, 2.0));
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.play(AssetSource('audio/$soundName.wav'));
      // dispose when finished
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (_) {
      // Silent failure if audio unavailable
    }
  }

  @override
  Future<void> startMusic() async {
    if (!_musicEnabled) return;
    try {
      if (_musicPlayer.state != PlayerState.playing) {
        await _musicPlayer.play(AssetSource('audio/bg_music.wav'));
      }
    } catch (_) {
      // Degrade gracefully
    }
  }

  @override
  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}
