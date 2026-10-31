// Web: `platform/src/trainers/mental-arithmetic/audio/clip-player.ts`
//
// Вся очередь отдаётся одному нативному player как gapless playlist.

import 'dart:async';
import 'package:larnes_mobile/trainers/audio/catalog_playback_failure.dart';

import 'package:just_audio/just_audio.dart';
import 'package:larnes_mobile/trainers/audio/legacy_audio_path.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/flash_audio_tempo.dart';

class ClipPlayer {
  ClipPlayer();

  var _generation = 0;
  var _playing = false;
  AudioPlayer? _active;
  Timer? _fallbackTimer;
  Completer<void>? _fallbackDone;

  bool get isPlaying => _playing;
  int get generation => _generation;

  Future<void> play(
    List<String> assetPaths, {
    double playbackRate = 1,
    void Function()? onStarted,
  }) async {
    final expectedRun = _generation + 1;
    await cancel();
    if (_generation != expectedRun) return;
    final runId = _generation;
    final rate = playbackRate
        .clamp(kAudioPlaybackRateMin, kAudioPlaybackRateMax)
        .toDouble();
    final queue = assetPaths
        .where(
          (path) => path.trim().isNotEmpty && !isLegacyTrainerAudioPath(path),
        )
        .toList();
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
      await player
          .setAudioSources(
            queue.map(_sourceFor).toList(growable: false),
            preload: true,
          )
          .timeout(const Duration(seconds: 3));
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
        if (runId != _generation) return;
        if (!player.playing ||
            player.processingState != ProcessingState.ready) {
          if (reportRequiredCatalogFailure(queue)) return;
        }
      }
      notifyStarted();
      await playback;
    } catch (_) {
      // Required playback failure blocks the exercise instead of starting its timer.
      if (runId == _generation && !reportRequiredCatalogFailure(queue)) {
        notifyStarted();
      }
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

  Future<void> waitForFallback(Duration duration) async {
    final expectedRun = _generation + 1;
    await cancel();
    if (_generation != expectedRun) return;
    final done = Completer<void>();
    _fallbackDone = done;
    _fallbackTimer = Timer(duration, () {
      _fallbackTimer = null;
      _fallbackDone = null;
      if (!done.isCompleted) done.complete();
    });
    await done.future;
  }

  Future<void> cancel() async {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    final fallback = _fallbackDone;
    _fallbackDone = null;
    if (fallback != null && !fallback.isCompleted) fallback.complete();
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

AudioSource _sourceFor(String path) {
  if (path.startsWith('/') ||
      path.contains(r':\') ||
      path.startsWith('file://')) {
    final local = path.startsWith('file://')
        ? Uri.parse(path).toFilePath()
        : path;
    return AudioSource.file(local);
  }

  return AudioSource.asset('assets/$path');
}

Future<void> resetSharedClipPlayerForTests() async {
  await _shared?.dispose();
  _shared = null;
}
