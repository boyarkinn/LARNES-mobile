import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:larnes_mobile/trainers/mental_arithmetic/audio/topic_chain_speech_renderer.dart';
import 'package:path_provider/path_provider.dart';

const topicChainSampleRate = 44_100;
const _betweenClipsFrames = 882; // 40 ms of input padding at ×2, like web.
const _speechBudget = Duration(seconds: 20);
const _maxCachedBytes = 8 * 1024 * 1024;

typedef TopicChainRenderClip = Future<Uint8List> Function(String, Duration);

class PreparedTopicChainSpeech {
  const PreparedTopicChainSpeech(this.path, this.cues);

  final String path;
  final List<({int startFrame, int endFrame})> cues;

  Duration get duration => Duration(
    microseconds: (cues.last.endFrame * 1000000 / topicChainSampleRate).ceil(),
  );

  ({int index, bool visible}) at(Duration position) {
    final frame = position.inMicroseconds * topicChainSampleRate ~/ 1000000;
    for (var index = cues.length - 1; index >= 0; index--) {
      final cue = cues[index];
      if (frame >= cue.startFrame) {
        return (index: index, visible: frame < cue.endFrame);
      }
    }
    return (index: -1, visible: false);
  }
}

/// One private cache per trainer. Prepared clips are keyed by the verified
/// catalog paths (which include the source SHA); only the current WAV is kept.
class TopicChainFlashAudio {
  TopicChainFlashAudio({
    TopicChainRenderClip? renderClip,
    Future<Directory> Function()? temporaryDirectory,
  }) : _renderOverride = renderClip,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final TopicChainRenderClip? _renderOverride;
  final Future<Directory> Function() _temporaryDirectory;
  final _renderer = TopicChainSpeechRenderer();
  final _clips = <String, Uint8List>{};
  var _cachedBytes = 0;
  var _generation = 0;
  bool _disposed = false;
  Directory? _directory;
  File? _currentTrack;
  String? _requestKey;
  Future<PreparedTopicChainSpeech>? _request;
  Future<void> _tail = Future<void>.value();

  Future<PreparedTopicChainSpeech> prepare(
    List<List<String>> groups, {
    required int pauseMs,
    required int blankMs,
  }) {
    final key = jsonEncode([pauseMs, blankMs, groups]);
    if (_requestKey == key) return _request!;
    final generation = ++_generation;
    final pending = _tail.then(
      (_) => _prepare(generation, groups, pauseMs, blankMs),
    );
    _requestKey = key;
    _request = pending;
    _tail = pending.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {
        if (_generation == generation) {
          _requestKey = null;
          _request = null;
        }
      },
    );
    return pending;
  }

  Future<PreparedTopicChainSpeech> _prepare(
    int generation,
    List<List<String>> groups,
    int pauseMs,
    int blankMs,
  ) async {
    _checkCurrent(generation);
    if (groups.isEmpty || groups.any((group) => group.isEmpty)) {
      throw const FormatException('Missing action speech');
    }
    final stopwatch = Stopwatch()..start();
    final directory = _directory ??= await (await _temporaryDirectory())
        .createTemp('larnes-topic-chain-');
    _checkCurrent(generation);
    final track = File(
      '${directory.path}${Platform.pathSeparator}$generation.wav',
    );
    try {
      final out = await track.open(mode: FileMode.write);
      final cues = <({int startFrame, int endFrame})>[];
      var cursor = 0;
      try {
        final pauseFrames = _frames(pauseMs);
        final blankFrames = _frames(blankMs);
        for (var index = 0; index < groups.length; index++) {
          final start = cursor;
          final group = groups[index];
          for (var part = 0; part < group.length; part++) {
            if (part > 0) cursor += _betweenClipsFrames;
            final clip = await _clip(group[part], stopwatch, generation);
            await out.setPosition(44 + cursor * 2);
            await out.writeFrom(clip);
            cursor += clip.length ~/ 2;
          }
          // Keep the chosen interval when speech fits. On the shortest audible
          // intervals a longer command must finish before the next cue.
          cursor = math.max(cursor, start + pauseFrames);
          cues.add((startFrame: start, endFrame: cursor));
          if (index + 1 < groups.length) cursor += blankFrames;
        }
        await out.truncate(44 + cursor * 2);
        await out.setPosition(0);
        await out.writeFrom(_wavHeader(cursor));
      } finally {
        await out.close();
      }
      _checkCurrent(generation);
      final previous = _currentTrack;
      _currentTrack = track;
      await _delete(previous);
      return PreparedTopicChainSpeech(track.path, List.unmodifiable(cues));
    } catch (_) {
      await _delete(track);
      rethrow;
    }
  }

  Future<Uint8List> _clip(
    String path,
    Stopwatch stopwatch,
    int generation,
  ) async {
    _checkCurrent(generation);
    final remaining = _speechBudget - stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      throw TimeoutException('Speech preparation');
    }
    final cached = _clips.remove(path);
    if (cached != null) {
      _clips[path] = cached;
      return cached;
    }
    final fresh = await (_renderOverride ?? _renderer.render)(path, remaining);
    _checkCurrent(generation);
    if (fresh.isEmpty || fresh.length.isOdd || fresh.length > _maxCachedBytes) {
      throw const FormatException('Invalid speech samples');
    }
    while (_cachedBytes + fresh.length > _maxCachedBytes) {
      _cachedBytes -= _clips.remove(_clips.keys.first)!.length;
    }
    _clips[path] = fresh;
    _cachedBytes += fresh.length;
    return fresh;
  }

  void _checkCurrent(int generation) {
    if (_disposed || generation != _generation) {
      throw StateError('Speech preparation superseded');
    }
  }

  static Future<void> _delete(File? file) async {
    try {
      await file?.delete();
    } on FileSystemException {
      // The private renderer directory is cleaned when the trainer closes.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _renderer.dispose();
    await _tail;
    _clips.clear();
    try {
      await _directory?.delete(recursive: true);
    } on FileSystemException {
      // The OS can clean up its temporary directory.
    }
  }

  void discardTrack() {
    _generation += 1;
    _requestKey = null;
    _request = null;
  }
}

int _frames(int milliseconds) =>
    (milliseconds * topicChainSampleRate / 1000).round();

Uint8List _wavHeader(int frames) {
  final bytes = Uint8List(44);
  final view = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, 'RIFF'.codeUnits);
  view.setUint32(4, 36 + frames * 2, Endian.little);
  bytes.setRange(8, 16, 'WAVEfmt '.codeUnits);
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, 1, Endian.little); // PCM
  view.setUint16(22, 1, Endian.little); // Mono
  view.setUint32(24, topicChainSampleRate, Endian.little);
  view.setUint32(28, topicChainSampleRate * 2, Endian.little);
  view.setUint16(32, 2, Endian.little);
  view.setUint16(34, 16, Endian.little);
  bytes.setRange(36, 40, 'data'.codeUnits);
  view.setUint32(40, frames * 2, Endian.little);
  return bytes;
}
