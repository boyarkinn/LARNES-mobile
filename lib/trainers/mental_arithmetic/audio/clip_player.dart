/// Web: `platform/src/trainers/mental-arithmetic/audio/clip-player.ts`
///
/// Паузы plus → hundreds были из prepare следующего клипа после короткого plus.
/// Теперь: prepare всей очереди заранее → resume цепочкой, next стартует до stop текущего.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/flash_audio_tempo.dart';

class _PreparedClip {
  _PreparedClip({required this.player, required this.duration});

  final AudioPlayer player;
  final Duration? duration;
}

class ClipPlayer {
  ClipPlayer();

  var _generation = 0;
  var _playing = false;
  final List<AudioPlayer> _active = [];

  bool get isPlaying => _playing;

  Future<void> play(
    List<String> assetPaths, {
    double playbackRate = 1,
  }) async {
    await cancel();
    final runId = _generation;
    final rate =
        playbackRate.clamp(kAudioPlaybackRateMin, kAudioPlaybackRateMax).toDouble();
    final queue = assetPaths.where((path) => path.trim().isNotEmpty).toList();

    if (queue.isEmpty) {
      return;
    }

    _playing = true;
    final clips = <_PreparedClip>[];

    try {
      await AudioCache.instance.loadAll(queue);

      if (runId != _generation) {
        return;
      }

      final prepared = await Future.wait(
        queue.map((path) async {
          final player = AudioPlayer();
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setSource(AssetSource(path));
          await player.setPlaybackRate(rate);
          final duration = await player.getDuration();
          return _PreparedClip(player: player, duration: duration);
        }),
      );

      if (runId != _generation) {
        for (final clip in prepared) {
          await clip.player.dispose();
        }
        return;
      }

      clips.addAll(prepared);
      _active.addAll(prepared.map((clip) => clip.player));

      for (var index = 0; index < clips.length; index += 1) {
        if (runId != _generation) {
          return;
        }

        final clip = clips[index];
        final done = Completer<void>();
        final sub = clip.player.onPlayerComplete.listen((_) {
          if (!done.isCompleted) {
            done.complete();
          }
        });

        try {
          // index>0 уже запущен в конце предыдущего шага (стык без щели).
          if (index == 0) {
            await clip.player.resume();
          }

          final duration = clip.duration;
          if (duration != null && duration > Duration.zero) {
            final scaledMs = (duration.inMilliseconds / rate).round();
            final handoffMs = (scaledMs - 50).clamp(1, scaledMs);
            await Future.any<void>([
              done.future,
              Future<void>.delayed(Duration(milliseconds: handoffMs)),
            ]);
          } else {
            await done.future.timeout(
              const Duration(seconds: 15),
              onTimeout: () {},
            );
          }

          // Сначала next.resume, потом stop текущего — иначе пауза на teardown.
          final next = index + 1 < clips.length ? clips[index + 1].player : null;
          if (next != null && runId == _generation) {
            await next.resume();
          }
        } catch (_) {
          // skip broken clip
        } finally {
          await sub.cancel();
          try {
            await clip.player.stop();
          } catch (_) {}
        }
      }
    } finally {
      for (final clip in clips) {
        _active.remove(clip.player);
        try {
          await clip.player.dispose();
        } catch (_) {}
      }
      if (runId == _generation) {
        _playing = false;
      }
    }
  }

  Future<void> cancel() async {
    _generation += 1;
    _playing = false;
    final snapshot = List<AudioPlayer>.from(_active);
    _active.clear();
    for (final player in snapshot) {
      try {
        await player.stop();
      } catch (_) {}
      try {
        await player.dispose();
      } catch (_) {}
    }
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
