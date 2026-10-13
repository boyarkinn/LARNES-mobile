import 'dart:async';
import 'dart:math';

import 'package:just_audio/just_audio.dart';
import 'package:larnes_mobile/trainers/audio/background_music.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';

class TrainerBackgroundMusic {
  TrainerBackgroundMusic({this.startFile, Random? random}) : _random = random ?? Random();

  final Future<void> Function(String path, double volume)? startFile;
  final Random _random;
  AudioPlayer? _player;
  var _disposed = false;
  var _started = false;
  var _volume = 0.05;

  void bind(TrainerDirection? direction) {
    _volume = backgroundMusicVolumeFor(direction);
    listenBackgroundMusic(_onReady);
    _onReady();
  }

  void _onReady() {
    if (_disposed || _started) {
      return;
    }

    final path = pickPreparedBackgroundMusicPath(_random.nextInt);

    if (path == null) {
      return;
    }

    _started = true;
    unawaited(startFile?.call(path, _volume) ?? _play(path));
  }

  Future<void> _play(String path) async {
    final player = AudioPlayer();

    if (_disposed) {
      await player.dispose();
      return;
    }

    _player = player;

    try {
      await player.setAudioSource(AudioSource.file(path));
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(_volume);

      if (_disposed) {
        return;
      }

      await player.play();
    } catch (_) {
      _started = false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    unlistenBackgroundMusic(_onReady);
    final player = _player;
    _player = null;

    if (player == null) {
      return;
    }

    try {
      await player.stop();
    } catch (_) {}

    try {
      await player.dispose();
    } catch (_) {}
  }
}
