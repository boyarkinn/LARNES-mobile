// Web: `platform/src/trainers/mental-arithmetic/audio/clip-player.ts`
//
// Вся очередь отдаётся одному нативному player как gapless playlist.

import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/flash_audio_tempo.dart';

class ClipPlayer {
  ClipPlayer();

  var _generation = 0;
  var _playing = false;
  AudioPlayer? _active;

  bool get isPlaying => _playing;

  Future<void> play(
    List<String> assetPaths, {
    double playbackRate = 1,
    void Function()? onStarted,
  }) async {
    await cancel();
    final runId = _generation;
    final rate = playbackRate
        .clamp(kAudioPlaybackRateMin, kAudioPlaybackRateMax)
        .toDouble();
    final queue = assetPaths.where((path) => path.trim().isNotEmpty).toList();
    var startNotified = false;

    void notifyStarted() {
      if (startNotified || runId != _generation) {
        return;
      }
      startNotified = true;
      onStarted?.call();
    }

    if (queue.isEmpty) {
      notifyStarted();
      return;
    }

    _playing = true;
    final player = AudioPlayer();
    _active = player;

    try {
      await player.setAudioSources(
        queue
            .map((path) => AudioSource.asset('assets/$path'))
            .toList(growable: false),
        preload: true,
      );
      await player.setSpeed(rate);

      if (runId != _generation) {
        return;
      }

      final playback = player.play();
      try {
        await player.positionStream
            .firstWhere((position) => position > Duration.zero)
            .timeout(const Duration(seconds: 1));
      } catch (_) {
        // На части платформ первый position event может прийти с задержкой.
      }
      notifyStarted();
      await playback;
    } catch (_) {
      // Не блокируем flash-таймер, даже если подготовка аудио не удалась.
      notifyStarted();
    } finally {
      if (identical(_active, player)) {
        _active = null;
        await player.dispose();
      }
      if (runId == _generation) {
        _playing = false;
      }
    }
  }

  Future<void> cancel() async {
    _generation += 1;
    _playing = false;
    final player = _active;
    _active = null;
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

  Future<void> dispose() async {
    await cancel();
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
