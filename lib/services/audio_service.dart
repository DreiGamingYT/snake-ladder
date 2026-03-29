import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _bgm = AudioPlayer();
  final AudioPlayer _sfx = AudioPlayer();

  bool _musicEnabled = true;
  bool _sfxEnabled = true;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  Future<void> playBGM() async {
    if (!_musicEnabled) return;
    try {
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.play(AssetSource('sounds/bgm.mp3'));
    } catch (_) {}
  }

  Future<void> stopBGM() async => _bgm.stop();

  Future<void> _playSfx(String file) async {
    if (!_sfxEnabled) return;
    try { await _sfx.play(AssetSource('sounds/$file')); } catch (_) {}
  }

  Future<void> playDiceRoll() => _playSfx('dice_roll.mp3');
  Future<void> playMove() => _playSfx('move.mp3');
  Future<void> playSnake() => _playSfx('snake.mp3');
  Future<void> playLadder() => _playSfx('ladder.mp3');
  Future<void> playWin() => _playSfx('win.mp3');
  Future<void> playPowerUp() => _playSfx('powerup.mp3');
  Future<void> playSpecial() => _playSfx('special.mp3');

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) playBGM(); else stopBGM();
  }

  void toggleSFX() => _sfxEnabled = !_sfxEnabled;

  void dispose() { _bgm.dispose(); _sfx.dispose(); }
}