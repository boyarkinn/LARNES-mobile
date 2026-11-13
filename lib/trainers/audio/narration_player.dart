import 'dart:async';
import 'package:just_audio/just_audio.dart';

/// Long speech uses the media clock and native pitch-preserving playback speed.
class NarrationPlayer {
  AudioPlayer? _player;
  var _generation = 0;
  int positionMs = 0;
  Future<bool> play(
    String path, {
    required int fromMs,
    required int durationMs,
    required double rate,
    required void Function(int) onPosition,
  }) async {
    final token = ++_generation;
    final previous = _player;
    _player = null;
    if (previous != null) await previous.dispose();
    if (token != _generation) return false;
    final player = AudioPlayer();
    _player = player;
    positionMs = fromMs;
    var prepared = false;
    final updates = player.positionStream.listen((position) {
      if (token == _generation && prepared) {
        positionMs = position.inMilliseconds;
        onPosition(positionMs);
      }
    });
    try {
      final source =
          path.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(path)
          ? AudioSource.uri(Uri.file(path))
          : AudioSource.uri(Uri.parse(path));
      await player
          .setAudioSource(
            source,
            initialPosition: Duration(milliseconds: fromMs),
          )
          .timeout(const Duration(seconds: 15));
      await player.setSpeed(rate.clamp(0.5, 2).toDouble());
      if (token != _generation) return false;
      prepared = true;
      final remainingMs = ((durationMs - fromMs).clamp(0, durationMs) / rate)
          .ceil();
      await player.play().timeout(Duration(milliseconds: remainingMs + 15000));
      if (token != _generation) return false;
      positionMs = player.position.inMilliseconds;
      onPosition(positionMs);
      return player.processingState == ProcessingState.completed;
    } catch (_) {
      return false;
    } finally {
      await updates.cancel();
      if (identical(_player, player)) {
        _player = null;
        await player.dispose();
      }
    }
  }

  Future<void> stop() async {
    _generation++;
    final player = _player;
    _player = null;
    if (player != null) {
      positionMs = player.position.inMilliseconds;
      await player.dispose();
    }
  }
}
