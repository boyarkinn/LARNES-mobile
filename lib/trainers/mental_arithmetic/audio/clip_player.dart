/// Web: `platform/src/trainers/mental-arithmetic/audio/clip-player.ts`
/// Локальные mp3 через [AssetSource].

import 'package:audioplayers/audioplayers.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/flash_audio_tempo.dart';

class ClipPlayer {
  ClipPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  var _generation = 0;
  var _playing = false;

  bool get isPlaying => _playing;

  Future<void> play(
    List<String> assetPaths, {
    double playbackRate = 1,
  }) async {
    await cancel();
    final runId = _generation;
    final rate = playbackRate.clamp(kAudioPlaybackRateMin, kAudioPlaybackRateMax);
    final queue = assetPaths.where((path) => path.trim().isNotEmpty).toList();

    if (queue.isEmpty) {
      return;
    }

    _playing = true;

    try {
      for (final path in queue) {
        if (runId != _generation) {
          return;
        }

        try {
          await _player.setPlaybackRate(rate);
          await _player.play(AssetSource(path));
          await _player.onPlayerComplete.first.timeout(
            const Duration(seconds: 15),
            onTimeout: () {},
          );
        } catch (_) {
          // Ошибка клипа — skip, очередь не зависает.
          continue;
        }
      }
    } finally {
      if (runId == _generation) {
        _playing = false;
      }
    }
  }

  Future<void> cancel() async {
    _generation += 1;
    _playing = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await cancel();
    await _player.dispose();
  }
}

ClipPlayer? _shared;

ClipPlayer getSharedClipPlayer() {
  return _shared ??= ClipPlayer();
}

Future<void> resetSharedClipPlayerForTests() async {
  await _shared?.dispose();
  _shared = null;
}
