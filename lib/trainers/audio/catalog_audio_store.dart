import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';
import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/audio/background_music.dart';
import 'package:larnes_mobile/trainers/reading/shared/echo_fragment.dart';

const catalogAudioPublicBase = 'https://audio.larnes.ru';
const catalogAudioTimeout = Duration(seconds: 10);
const catalogAudioMaxBytes = 48 * 1024 * 1024;
const catalogAudioConcurrency = 4;

enum CatalogPack { preparing, blocked, ready, missing }

enum CatalogInstruction { absent, fallback, ready }

enum CatalogFetchStop { cancelled, timedOut }

class CatalogStopped implements Exception {
  const CatalogStopped(this.reason);

  final CatalogFetchStop reason;
}

class CatalogSignal {
  CatalogFetchStop? _reason;
  final List<void Function(CatalogFetchStop reason)> _listeners = [];

  CatalogFetchStop? get reason => _reason;
  bool get isStopped => _reason != null;

  void cancel() => stop(CatalogFetchStop.cancelled);

  void stop(CatalogFetchStop reason) {
    if (_reason != null) {
      return;
    }

    _reason = reason;

    for (final listener in List<void Function(CatalogFetchStop)>.of(_listeners)) {
      listener(reason);
    }
  }

  void listen(void Function(CatalogFetchStop reason) listener) {
    final reason = _reason;

    if (reason != null) {
      listener(reason);
      return;
    }

    _listeners.add(listener);
  }

  Future<CatalogFetchStop> get stopped {
    final reason = _reason;

    if (reason != null) {
      return Future<CatalogFetchStop>.value(reason);
    }

    final done = Completer<CatalogFetchStop>();
    listen(done.complete);
    return done.future;
  }
}

typedef CatalogAudioFetch = Future<List<int>> Function(Uri url, CatalogSignal signal);

typedef CatalogAudioRead = Future<List<int>> Function(File file);

typedef CatalogAudioWrite = Future<void> Function(File file, List<int> bytes);

class CatalogLaunch {
  CatalogLaunch({
    required this.aborted,
    required this.instruction,
    required this.instructionPath,
    required this.packReady,
    required this.pathsByKey,
    required this.release,
    required this.stimuliReady,
    required this.stimulusPaths,
  });

  final bool aborted;
  final CatalogInstruction instruction;
  final String? instructionPath;
  final bool packReady;
  final Map<String, String> pathsByKey;
  final void Function() release;
  final bool stimuliReady;
  final List<String> stimulusPaths;

  String? pathFor(String semanticKey) => pathsByKey[semanticKey];
}

bool isCatalogInstructionKey(String semanticKey) => semanticKey.startsWith('instruction:');

bool catalogExpectsStimuli(ExerciseAudioManifest? manifest) {
  if (manifest == null) {
    return false;
  }

  final publishedStimulus = manifest.clips.any(
    (clip) => !isCatalogInstructionKey(clip.semanticKey) && !isBackgroundMusicAudioKey(clip.semanticKey),
  );
  final missingRequired = manifest.missing.any((item) => _isRequiredLaunchStimulus(item.semanticKey));
  return publishedStimulus || missingRequired;
}

bool _isRequiredLaunchStimulus(String semanticKey) {
  return !isCatalogInstructionKey(semanticKey) &&
      !isBackgroundMusicAudioKey(semanticKey) &&
      !isNumberBankAudioKey(semanticKey) &&
      !isSpeechBankAudioKey(semanticKey) &&
      !isSpokenCueAudioKey(semanticKey) &&
      !isEchoFragmentAudioKey(semanticKey);
}

bool catalogTrainerMayStart(CatalogPack pack) {
  return pack == CatalogPack.ready || pack == CatalogPack.missing;
}

bool isCatalogClipUrl(
  String url,
  String sha256, {
  String publicBase = catalogAudioPublicBase,
}) {
  final base = publicBase.replaceAll(RegExp(r'/+$'), '');
  return RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256) && url == '$base/v1/$sha256.mp3';
}

class _IndexEntry {
  _IndexEntry({required this.bytes, required this.lastUsed, required this.sha256});

  final int bytes;
  int lastUsed;
  final String sha256;

  Map<String, Object> toJson() => {
        'bytes': bytes,
        'lastUsed': lastUsed,
        'sha256': sha256,
      };
}

class _Job {
  int consumers = 0;
  bool settled = false;
  bool timedOut = false;
  final signal = CatalogSignal();
  Timer? timer;
  late final Future<File?> task;
}

class CatalogAudioStore {
  CatalogAudioStore({
    required this.directory,
    this.fetch,
    this.readBytes,
    this.writeBytes,
    this.publicBase = catalogAudioPublicBase,
    this.maxBytes = catalogAudioMaxBytes,
    this.concurrency = catalogAudioConcurrency,
    this.timeout = catalogAudioTimeout,
  });

  final Directory directory;
  final CatalogAudioFetch? fetch;
  final CatalogAudioRead? readBytes;
  final CatalogAudioWrite? writeBytes;
  final String publicBase;
  final int maxBytes;
  final int concurrency;
  final Duration timeout;

  final Map<String, _IndexEntry> _index = {};
  final Map<String, int> _pins = {};
  final Map<String, _Job> _jobs = {};
  var _clock = 0;
  var _active = 0;
  final List<Completer<void>> _waiters = [];
  var _opened = false;

  Future<void> open() async {
    if (_opened) {
      return;
    }

    await directory.create(recursive: true);
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.partial')) {
        await _deleteQuiet(entity);
      }
    }

    final indexFile = File(_indexPath);

    if (await indexFile.exists()) {
      try {
        final raw = jsonDecode(await indexFile.readAsString());
        final entries = raw is Map ? raw['entries'] : null;

        if (entries is List) {
          for (final item in entries) {
            if (item is! Map) {
              continue;
            }

            final sha = item['sha256'];
            final bytes = item['bytes'];
            final lastUsed = item['lastUsed'];

            if (sha is! String || bytes is! int || lastUsed is! int) {
              continue;
            }

            if (!await _finalFile(sha).exists()) {
              continue;
            }

            _index[sha] = _IndexEntry(bytes: bytes, lastUsed: lastUsed, sha256: sha);

            if (lastUsed > _clock) {
              _clock = lastUsed;
            }
          }
        }
      } catch (_) {
        _index.clear();
      }
    }

    _opened = true;
  }

  Future<CatalogLaunch> prepare(
    ExerciseAudioManifest? manifest, {
    CatalogSignal? signal,
  }) async {
    await open();
    final clips = manifest?.clips ?? const <PublishedAudioClip>[];
    final missingRequired = manifest?.missing.any((item) => _isRequiredLaunchStimulus(item.semanticKey)) ?? false;
    final paths = <String, String>{};
    var aborted = false;
    var timedOut = false;
    final hold = _retain([
      for (final clip in clips)
        if (isCatalogClipUrl(clip.url, clip.sha256, publicBase: publicBase)) clip.sha256,
    ]);

    Future<void> take(PublishedAudioClip clip) async {
      if (signal?.isStopped == true) {
        aborted = signal?.reason == CatalogFetchStop.cancelled;
        timedOut = signal?.reason == CatalogFetchStop.timedOut;
        return;
      }

      if (!isCatalogClipUrl(clip.url, clip.sha256, publicBase: publicBase)) {
        return;
      }

      final outcome = await _acquire(clip, signal);

      if (outcome == _Outcome.aborted) {
        aborted = true;
        return;
      }

      if (outcome == _Outcome.timedOut) {
        timedOut = true;
        return;
      }

      final file = _index.containsKey(clip.sha256) ? _finalFile(clip.sha256) : null;

      if (file == null || !await file.exists()) {
        return;
      }

      paths[clip.semanticKey] = file.path;

      if (isBackgroundMusicAudioKey(clip.semanticKey)) {
        rememberBackgroundMusicFile(clip.semanticKey, file.path);
      }
    }

    final blocking = [
      for (final clip in clips)
        if (!isBackgroundMusicAudioKey(clip.semanticKey)) clip,
    ];
    final music = [
      for (final clip in clips)
        if (isBackgroundMusicAudioKey(clip.semanticKey)) clip,
    ];
    await Future.wait(blocking.map(take));
    unawaited(Future.wait(music.map(take)));

    if (!aborted) {
      await _evict();
    }

    final missingFiles = <String>[];

    for (final entry in paths.entries) {
      if (!await File(entry.value).exists()) {
        missingFiles.add(entry.key);
      }
    }

    for (final key in missingFiles) {
      paths.remove(key);
    }

    final stimulusPaths = <String>[];
    var stimuliReady = !missingRequired;

    for (final clip in clips) {
      if (isCatalogInstructionKey(clip.semanticKey) || isBackgroundMusicAudioKey(clip.semanticKey)) {
        continue;
      }

      final path = paths[clip.semanticKey];

      if (path == null) {
        stimuliReady = false;
        continue;
      }

      stimulusPaths.add(path);
    }

    PublishedAudioClip? instructionClip;

    for (final clip in clips) {
      if (isCatalogInstructionKey(clip.semanticKey)) {
        instructionClip = clip;
        break;
      }
    }
    final instructionMissing = manifest?.missing.any((item) => isCatalogInstructionKey(item.semanticKey)) ?? false;
    final instructionPath = instructionClip == null ? null : paths[instructionClip.semanticKey];
    final instruction = instructionPath != null
        ? CatalogInstruction.ready
        : instructionClip != null || instructionMissing
            ? CatalogInstruction.fallback
            : CatalogInstruction.absent;

    return CatalogLaunch(
      aborted: aborted && !timedOut,
      instruction: instruction,
      instructionPath: instructionPath,
      packReady: stimuliReady && stimulusPaths.isNotEmpty && !aborted && !timedOut,
      pathsByKey: paths,
      release: hold,
      stimuliReady: stimuliReady && !aborted,
      stimulusPaths: stimulusPaths,
    );
  }

  void Function() _retain(List<String> sha256s) {
    for (final sha in sha256s) {
      _pins[sha] = (_pins[sha] ?? 0) + 1;
    }

    var released = false;

    return () {
      if (released) {
        return;
      }

      released = true;

      for (final sha in sha256s) {
        final next = (_pins[sha] ?? 1) - 1;

        if (next <= 0) {
          _pins.remove(sha);
        } else {
          _pins[sha] = next;
        }
      }
    };
  }

  Future<_Outcome> _acquire(PublishedAudioClip clip, CatalogSignal? consumer) async {
    final job = _jobs[clip.sha256] ?? _start(clip);
    job.consumers += 1;
    final done = Completer<_Outcome>();

    void leave() {
      if (done.isCompleted) {
        return;
      }

      job.consumers -= 1;

      if (job.consumers <= 0 && !job.settled) {
        job.signal.stop(CatalogFetchStop.cancelled);
      }

      done.complete(_Outcome.aborted);
    }

    if (consumer?.isStopped == true) {
      leave();
      return done.future;
    }

    consumer?.listen((_) => leave());
    unawaited(job.task.then((file) {
      if (done.isCompleted) {
        return;
      }

      if (job.timedOut && file == null) {
        done.complete(_Outcome.timedOut);
        return;
      }

      done.complete(file == null ? _Outcome.failed : _Outcome.ready);
    }));
    return done.future;
  }

  _Job _start(PublishedAudioClip clip) {
    final job = _Job();
    _jobs[clip.sha256] = job;
    job.timer = Timer(timeout, () {
      job.timedOut = true;
      job.signal.stop(CatalogFetchStop.timedOut);
    });
    job.task = _run(clip, job);
    return job;
  }

  Future<File?> _run(PublishedAudioClip clip, _Job job) async {
    File? stored;

    try {
      stored = await _readReady(clip);

      if (stored != null || job.signal.isStopped) {
        job.timedOut = job.signal.reason == CatalogFetchStop.timedOut;
        return stored;
      }

      await _acquireSlot();

      try {
        for (var attempt = 0; attempt < 2; attempt++) {
          if (job.signal.reason == CatalogFetchStop.timedOut) {
            job.timedOut = true;
            return null;
          }

          if (job.signal.isStopped) {
            return null;
          }

          try {
            final bytes = await _fetchUntilStop(_clipUri(clip), job.signal);

            if (bytes.length != clip.bytes || sha256.convert(bytes).toString() != clip.sha256) {
              return null;
            }

            stored = await _commit(clip, bytes);
            return stored;
          } on CatalogStopped catch (error) {
            job.timedOut = error.reason == CatalogFetchStop.timedOut;
            return null;
          } catch (_) {
            if (attempt == 1) {
              return null;
            }
          }
        }
      } finally {
        _releaseSlot();
      }

      return null;
    } finally {
      job.settled = true;
      job.timer?.cancel();
      await _deleteQuiet(_partialFile(clip.sha256));

      if (identical(_jobs[clip.sha256], job)) {
        _jobs.remove(clip.sha256);
      }
    }
  }

  Future<List<int>> _fetchUntilStop(Uri url, CatalogSignal signal) async {
    if (signal.isStopped) {
      throw CatalogStopped(signal.reason!);
    }

    final loader = fetch ?? _defaultFetch;
    final result = await Future.any<Object>([
      loader(url, signal).then<Object>((bytes) => bytes),
      signal.stopped.then<Object>((reason) => reason),
    ]);

    if (result is CatalogFetchStop) {
      throw CatalogStopped(result);
    }

    return result as List<int>;
  }

  Future<List<int>> _defaultFetch(Uri url, CatalogSignal signal) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(url);
      signal.listen((_) => request.abort());

      if (signal.isStopped) {
        throw CatalogStopped(signal.reason!);
      }

      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException('catalog audio ${response.statusCode}', uri: url);
      }

      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }

      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  Future<File?> _readReady(PublishedAudioClip clip) async {
    final file = _finalFile(clip.sha256);

    try {
      if (!await file.exists()) {
        _index.remove(clip.sha256);
        return null;
      }

      final bytes = await (readBytes ?? _readFile)(file);

      if (bytes.length != clip.bytes || sha256.convert(bytes).toString() != clip.sha256) {
        await _deleteQuiet(file);
        _index.remove(clip.sha256);
        return null;
      }

      final entry = _index[clip.sha256];

      if (entry == null) {
        _index[clip.sha256] = _IndexEntry(bytes: bytes.length, lastUsed: ++_clock, sha256: clip.sha256);
      } else {
        entry.lastUsed = ++_clock;
      }

      await _saveIndex();
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<File> _commit(PublishedAudioClip clip, List<int> bytes) async {
    final partial = _partialFile(clip.sha256);
    final writer = writeBytes ?? _writeFile;
    await writer(partial, bytes);
    final verified = await partial.readAsBytes();

    if (verified.length != clip.bytes || sha256.convert(verified).toString() != clip.sha256) {
      await _deleteQuiet(partial);
      throw const FileSystemException('catalog audio verify failed');
    }

    final target = _finalFile(clip.sha256);

    if (await target.exists()) {
      await _deleteQuiet(target);
    }

    await partial.rename(target.path);
    _index[clip.sha256] = _IndexEntry(bytes: bytes.length, lastUsed: ++_clock, sha256: clip.sha256);
    await _saveIndex();
    return target;
  }

  Future<List<int>> _readFile(File file) => file.readAsBytes();

  Future<void> _writeFile(File file, List<int> bytes) {
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> _evict() async {
    final entries = _index.values.toList()..sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
    var total = entries.fold<int>(0, (sum, entry) => sum + entry.bytes);

    for (final entry in entries) {
      if (total <= maxBytes) {
        break;
      }

      if ((_pins[entry.sha256] ?? 0) > 0) {
        continue;
      }

      total -= entry.bytes;
      _index.remove(entry.sha256);
      await _deleteQuiet(_finalFile(entry.sha256));
    }

    await _saveIndex();
  }

  Future<void> _acquireSlot() async {
    if (_active < concurrency) {
      _active += 1;
      return;
    }

    final waiter = Completer<void>();
    _waiters.add(waiter);
    await waiter.future;
    _active += 1;
  }

  void _releaseSlot() {
    _active -= 1;

    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    }
  }

  Future<void> _indexWrite = Future<void>.value();

  Future<void> _saveIndex() {
    final snapshot = jsonEncode({
      'entries': _index.values.map((entry) => entry.toJson()).toList(),
    });
    final partial = File(
      '$_indexPath.${DateTime.now().microsecondsSinceEpoch}.${_indexWrite.hashCode}.partial',
    );
    final next = _indexWrite.then((_) => _writeIndexSnapshot(partial, snapshot));
    _indexWrite = next.catchError((Object _) {});
    return next;
  }

  Future<void> _writeIndexSnapshot(File partial, String payload) async {
    await partial.writeAsString(payload, flush: true);
    final target = File(_indexPath);

    if (await target.exists()) {
      await _deleteQuiet(target);
    }

    await partial.rename(target.path);
  }

  File _finalFile(String sha256) => File('${directory.path}${Platform.pathSeparator}$sha256.mp3');

  File _partialFile(String sha256) => File('${directory.path}${Platform.pathSeparator}$sha256.mp3.partial');

  String get _indexPath => '${directory.path}${Platform.pathSeparator}index.json';

  Uri _clipUri(PublishedAudioClip clip) => Uri.parse(clip.url);

  Future<void> _deleteQuiet(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

enum _Outcome { aborted, failed, ready, timedOut }
