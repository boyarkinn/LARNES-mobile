import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';
import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/audio/background_music.dart';

const catalogAudioPublicBase = 'https://audio.larnes.ru';
const catalogAudioTimeout = Duration(seconds: 10);
const catalogAudioMaxBytes = 48 * 1024 * 1024;
const catalogAudioConcurrency = 4;
const catalogStartupTimeout = Duration(seconds: 20);
const catalogCacheReadTimeout = Duration(milliseconds: 250);

enum CatalogPack { preparing, blocked, ready, missing }

enum CatalogInstruction { absent, fallback, ready }

enum CatalogFetchStop { cancelled, timedOut }

class CatalogStopped implements Exception {
  const CatalogStopped(this.reason);

  final CatalogFetchStop reason;
}

class CatalogAudioFailure implements Exception {
  const CatalogAudioFailure(this.code);
  final String code;
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

    for (final listener in List<void Function(CatalogFetchStop)>.of(
      _listeners,
    )) {
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

  Future<T> guard<T>(Future<T> work) {
    return Future.any<T>([
      work,
      stopped.then<T>((reason) => throw CatalogStopped(reason)),
    ]);
  }
}

typedef CatalogAudioFetch =
    Future<List<int>> Function(Uri url, CatalogSignal signal);

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
    this.primaryInstructionFailed = false,
    this.failureCodes = const [],
    this.failedSha256 = const [],
  });

  final bool aborted;
  final CatalogInstruction instruction;
  final String? instructionPath;
  final bool packReady;
  final Map<String, String> pathsByKey;
  final void Function() release;
  final bool stimuliReady;
  final List<String> stimulusPaths;
  final bool primaryInstructionFailed;
  final List<String> failureCodes;
  final List<String> failedSha256;
  bool get launchReady => stimuliReady && !primaryInstructionFailed && !aborted;

  String? pathFor(String semanticKey) => pathsByKey[semanticKey];
}

bool isCatalogInstructionKey(String semanticKey) =>
    semanticKey.startsWith('instruction:');

bool catalogExpectsStimuli(ExerciseAudioManifest? manifest) {
  if (manifest == null) {
    return false;
  }

  final publishedStimulus = manifest.clips.any(
    (clip) => catalogBindingRequired(clip.semanticKey, clip.isRequired),
  );
  final missingRequired = manifest.missing.any(
    (item) => catalogBindingRequired(item.semanticKey, item.required),
  );
  return publishedStimulus || missingRequired;
}

bool catalogBindingRequired(String key, bool? required) {
  if (required == false) return false;
  if (required == true) {
    return !isCatalogInstructionKey(key) && !isBackgroundMusicAudioKey(key);
  }
  return _isRequiredLaunchStimulus(key);
}

PublishedAudioClip? catalogPrimaryInstruction(ExerciseAudioManifest? manifest) {
  final clips =
      manifest?.clips
          .where((clip) => isCatalogInstructionKey(clip.semanticKey))
          .toList() ??
      [];
  if (clips.isEmpty) return null;
  return clips
          .where(
            (clip) => clip.semanticKey == 'instruction:${manifest?.trainerKey}',
          )
          .firstOrNull ??
      clips.where((clip) => clip.semanticKey.endsWith(':intro')).firstOrNull ??
      clips.first;
}

bool catalogNeedsPreparation(ExerciseAudioManifest? manifest) {
  final primary = catalogPrimaryInstruction(manifest);
  return catalogExpectsStimuli(manifest) ||
      primary != null && primary.isRequired != false ||
      (manifest?.missing.any(
            (item) =>
                isCatalogInstructionKey(item.semanticKey) &&
                item.required == true,
          ) ??
          false);
}

bool _isRequiredLaunchStimulus(String semanticKey) {
  return !isCatalogInstructionKey(semanticKey) &&
      !isBackgroundMusicAudioKey(semanticKey) &&
      !isSpokenCueAudioKey(semanticKey);
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
  return RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256) &&
      url == '$base/v1/$sha256.mp3';
}

class _IndexEntry {
  _IndexEntry({
    required this.bytes,
    required this.lastUsed,
    required this.sha256,
  });

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
  String? failureCode;
  final nonce = '${DateTime.now().microsecondsSinceEpoch}-${_nextJob++}';
  static int _nextJob = 0;
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
    this.startupTimeout = catalogStartupTimeout,
    this.apiBase,
  });

  final Directory directory;
  final CatalogAudioFetch? fetch;
  final CatalogAudioRead? readBytes;
  final CatalogAudioWrite? writeBytes;
  final String publicBase;
  final int maxBytes;
  final int concurrency;
  final Duration timeout;
  final Duration startupTimeout;
  final String? apiBase;

  final Map<String, _IndexEntry> _index = {};
  final Map<String, int> _pins = {};
  final Map<String, _Job> _jobs = {};
  var _clock = 0;
  var _active = 0;
  final List<Completer<bool>> _waiters = [];
  var _opened = false;
  final _maintenance = <Future<void>>{};

  void _background(Future<void> work) {
    late final Future<void> pending;
    pending = work
        .catchError((Object _) {})
        .whenComplete(() => _maintenance.remove(pending));
    _maintenance.add(pending);
  }

  /// Flushes best-effort local bookkeeping when closing/testing a cache. Never used by startup.
  Future<void> waitForMaintenance() async {
    final until = DateTime.now().add(const Duration(seconds: 2));
    while (DateTime.now().isBefore(until)) {
      final index = _indexWrite;
      try {
        await Future.wait([
          ..._maintenance,
          index,
        ]).timeout(until.difference(DateTime.now()));
      } on TimeoutException {
        return;
      }
      if (_maintenance.isEmpty && identical(index, _indexWrite)) return;
    }
  }

  Future<void>? _opening;
  Future<void> open() => _opening ??= _open();

  Future<void> _open() async {
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

            _index[sha] = _IndexEntry(
              bytes: bytes,
              lastUsed: lastUsed,
              sha256: sha,
            );

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
    void Function(PublishedAudioClip clip, String path)? onLoaded,
    void Function(PublishedAudioClip clip, String code)? onOptionalIssue,
  }) async {
    final scope = CatalogSignal();
    signal?.listen(scope.stop);
    final clips = manifest?.clips ?? const <PublishedAudioClip>[];
    final hold = _retain([
      for (final clip in clips)
        if (isCatalogClipUrl(clip.url, clip.sha256, publicBase: publicBase))
          clip.sha256,
    ]);
    final timer = Timer(
      startupTimeout,
      () => scope.stop(CatalogFetchStop.timedOut),
    );
    CatalogLaunch stopped(CatalogFetchStop reason, [String? code]) {
      hold();
      return CatalogLaunch(
        aborted: reason == CatalogFetchStop.cancelled,
        instruction: catalogPrimaryInstruction(manifest) == null
            ? CatalogInstruction.absent
            : CatalogInstruction.fallback,
        instructionPath: null,
        packReady: false,
        pathsByKey: {},
        release: hold,
        stimuliReady: false,
        stimulusPaths: const [],
        primaryInstructionFailed: catalogPrimaryInstruction(manifest) != null,
        failureCodes: reason == CatalogFetchStop.cancelled
            ? const []
            : [code ?? 'timeout'],
        failedSha256: clips
            .where(
              (clip) =>
                  catalogBindingRequired(clip.semanticKey, clip.isRequired) ||
                  identical(clip, catalogPrimaryInstruction(manifest)),
            )
            .map((clip) => clip.sha256)
            .take(5)
            .toList(),
      );
    }

    try {
      return await Future.any<CatalogLaunch>([
        _prepareCatalog(manifest, scope, hold, onLoaded, onOptionalIssue),
        scope.stopped.then(stopped),
      ]);
    } on CatalogStopped catch (error) {
      return stopped(error.reason);
    } catch (_) {
      return stopped(CatalogFetchStop.timedOut, 'storage');
    } finally {
      timer.cancel();
    }
  }

  Future<CatalogLaunch> _prepareCatalog(
    ExerciseAudioManifest? manifest,
    CatalogSignal signal,
    void Function() hold,
    void Function(PublishedAudioClip clip, String path)? onLoaded,
    void Function(PublishedAudioClip clip, String code)? onOptionalIssue,
  ) async {
    final allClips = manifest?.clips ?? const <PublishedAudioClip>[];
    if (allClips.isNotEmpty) await signal.guard(open());
    if (signal.isStopped) throw CatalogStopped(signal.reason!);
    final musicCandidates = allClips
        .where((clip) => isBackgroundMusicAudioKey(clip.semanticKey))
        .toList();
    final selectedMusic = musicCandidates.isEmpty
        ? null
        : musicCandidates[Random().nextInt(musicCandidates.length)];
    final clips = allClips
        .where(
          (clip) =>
              !isBackgroundMusicAudioKey(clip.semanticKey) ||
              identical(clip, selectedMusic),
        )
        .toList();
    final primary = catalogPrimaryInstruction(manifest);
    final missing = manifest?.missing ?? const <MissingAudioBinding>[];
    final missingRequired = missing.any(
      (item) => catalogBindingRequired(item.semanticKey, item.required),
    );
    final missingInstruction = missing.any(
      (item) => isCatalogInstructionKey(item.semanticKey),
    );
    final missingInstructionRequired = missing.any(
      (item) =>
          isCatalogInstructionKey(item.semanticKey) && item.required == true,
    );
    final paths = <String, String>{};
    final codes = <String>{
      if (missingRequired || missingInstruction) 'missing-publication',
    };
    final failedSha = <String>{};
    final requiredClips = clips
        .where(
          (clip) =>
              catalogBindingRequired(clip.semanticKey, clip.isRequired) ||
              identical(clip, primary) && clip.isRequired != false,
        )
        .toList();

    Future<void> take(PublishedAudioClip clip, {bool optional = false}) async {
      void fail(String code) {
        if (signal.isStopped) return;
        if (optional) {
          if (!isBackgroundMusicAudioKey(clip.semanticKey)) {
            onOptionalIssue?.call(clip, code);
          }
        } else {
          codes.add(code);
          failedSha.add(clip.sha256);
        }
      }

      if (signal.isStopped) return;
      if (!isCatalogClipUrl(clip.url, clip.sha256, publicBase: publicBase)) {
        fail('invalid-url');
        return;
      }
      final result = await _acquire(clip, signal);
      if (signal.isStopped || result.cancelled) return;
      if (result.file == null) {
        fail(result.failureCode ?? 'network');
        return;
      }
      paths[clip.semanticKey] = result.file!.path;
      if (isBackgroundMusicAudioKey(clip.semanticKey)) {
        rememberBackgroundMusicFile(clip.semanticKey, result.file!.path);
      }
      onLoaded?.call(clip, result.file!.path);
    }

    // The current exercise owns foreground slots. Optional clips are scheduled only afterwards.
    await Future.wait(requiredClips.map((clip) => take(clip)));
    if (signal.isStopped) throw CatalogStopped(signal.reason!);
    final stimulusClips = clips
        .where(
          (clip) => catalogBindingRequired(clip.semanticKey, clip.isRequired),
        )
        .toList();
    final stimuliReady =
        !missingRequired &&
        stimulusClips.every((clip) => paths.containsKey(clip.semanticKey));
    final instructionPath = primary == null ? null : paths[primary.semanticKey];
    final primaryFailed =
        missingInstructionRequired ||
        primary != null &&
            primary.isRequired != false &&
            instructionPath == null;
    // Optional speech/music may fill the same launch map later, but never hold its start.
    final optional = clips
        .where((clip) => !requiredClips.contains(clip))
        .toList();
    if (optional.isNotEmpty) {
      _background(
        Future.wait(
          optional.map((clip) => take(clip, optional: true)),
        ).then((_) => _evict()),
      );
    } else {
      _background(_evict());
    }
    return CatalogLaunch(
      aborted: false,
      instruction: instructionPath != null
          ? CatalogInstruction.ready
          : primary != null || missingInstruction
          ? CatalogInstruction.fallback
          : CatalogInstruction.absent,
      instructionPath: instructionPath,
      packReady: stimuliReady && stimulusClips.isNotEmpty && !primaryFailed,
      pathsByKey: paths,
      release: hold,
      stimuliReady: stimuliReady,
      stimulusPaths: [
        for (final clip in stimulusClips)
          if (paths[clip.semanticKey] != null) paths[clip.semanticKey]!,
      ],
      primaryInstructionFailed: primaryFailed,
      failureCodes: codes.toList(),
      failedSha256: failedSha.take(5).toList(),
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

  Future<_AcquireResult> _acquire(
    PublishedAudioClip clip,
    CatalogSignal consumer,
  ) async {
    final prior = _jobs[clip.sha256];
    final job = prior != null && !prior.signal.isStopped ? prior : _start(clip);
    job.consumers++;
    final done = Completer<_AcquireResult>();
    void leave(CatalogFetchStop reason) {
      if (done.isCompleted) return;
      job.consumers--;
      if (job.consumers <= 0 && !job.settled) job.signal.stop(reason);
      done.complete(
        _AcquireResult(
          cancelled: reason == CatalogFetchStop.cancelled,
          failureCode: reason == CatalogFetchStop.timedOut ? 'timeout' : null,
        ),
      );
    }

    consumer.listen(leave);
    unawaited(
      job.task.then(
        (file) {
          if (done.isCompleted) return;
          job.consumers--;
          done.complete(
            _AcquireResult(
              file: file,
              cancelled: job.signal.reason == CatalogFetchStop.cancelled,
              failureCode: job.failureCode,
            ),
          );
        },
        onError: (Object _) {
          if (done.isCompleted) return;
          job.consumers--;
          done.complete(const _AcquireResult(failureCode: 'storage'));
        },
      ),
    );
    return done.future;
  }

  _Job _start(PublishedAudioClip clip) {
    final job = _Job();
    _jobs[clip.sha256] = job;
    job.task = _run(clip, job);
    return job;
  }

  Future<File?> _run(PublishedAudioClip clip, _Job job) async {
    try {
      final cacheSignal = CatalogSignal();
      job.signal.listen(cacheSignal.stop);
      final cacheTimer = Timer(
        catalogCacheReadTimeout,
        () => cacheSignal.stop(CatalogFetchStop.timedOut),
      );
      File? cached;
      try {
        cached = await cacheSignal.guard(_readReady(clip, cacheSignal));
      } on CatalogStopped {
        /* Optional cache must not hold a network request. */
      } finally {
        cacheTimer.cancel();
      }
      if (job.signal.isStopped) return null;
      if (cached != null) return cached;
      if (!await _acquireSlot(job.signal)) return null;
      try {
        if (job.signal.isStopped) return null;
        // Network time starts when this request actually has a slot.
        job.timer = Timer(timeout, () {
          job.timedOut = true;
          job.failureCode = 'timeout';
          job.signal.stop(CatalogFetchStop.timedOut);
        });
        final bytes = await _fetchUntilStop(_clipUri(clip), job.signal);
        if (bytes.length != clip.bytes ||
            sha256.convert(bytes).toString() != clip.sha256) {
          job.failureCode = 'integrity';
          return null;
        }
        return await _commit(clip, bytes, job);
      } finally {
        _releaseSlot();
      }
    } on CatalogStopped catch (error) {
      job.timedOut = error.reason == CatalogFetchStop.timedOut;
      if (job.timedOut) job.failureCode = 'timeout';
      return null;
    } on CatalogAudioFailure catch (error) {
      job.failureCode = error.code;
      return null;
    } on FileSystemException {
      job.failureCode = 'storage';
      return null;
    } catch (_) {
      job.failureCode = 'network';
      return null;
    } finally {
      job.settled = true;
      job.timer?.cancel();
      await _deleteQuiet(
        _partialFile(clip.sha256, job.nonce),
      ).timeout(catalogCacheReadTimeout, onTimeout: () {});
      if (identical(_jobs[clip.sha256], job)) _jobs.remove(clip.sha256);
    }
  }

  Future<List<int>> _fetchUntilStop(Uri url, CatalogSignal signal) =>
      signal.guard((fetch ?? _defaultFetch)(url, signal));

  Future<List<int>> _defaultFetch(Uri url, CatalogSignal signal) async {
    final client = HttpClient()..connectionTimeout = timeout;
    signal.listen((_) => client.close(force: true));
    try {
      if (signal.isStopped) throw CatalogStopped(signal.reason!);
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw CatalogAudioFailure('http-${response.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
        if (builder.length > catalogAudioMaxBytes) {
          throw const CatalogAudioFailure('memory');
        }
      }
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  Future<File?> _readReady(
    PublishedAudioClip clip,
    CatalogSignal signal,
  ) async {
    final file = _finalFile(clip.sha256);

    try {
      if (!await signal.guard(file.exists())) {
        _index.remove(clip.sha256);
        return null;
      }

      final bytes = await signal.guard((readBytes ?? _readFile)(file));

      if (bytes.length != clip.bytes ||
          sha256.convert(bytes).toString() != clip.sha256) {
        await signal.guard(_deleteQuiet(file));
        _index.remove(clip.sha256);
        return null;
      }

      final entry = _index[clip.sha256];

      if (entry == null) {
        _index[clip.sha256] = _IndexEntry(
          bytes: bytes.length,
          lastUsed: ++_clock,
          sha256: clip.sha256,
        );
      } else {
        entry.lastUsed = ++_clock;
      }

      unawaited(_saveIndex().catchError((Object _) {}));
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<File> _commit(
    PublishedAudioClip clip,
    List<int> bytes,
    _Job job,
  ) async {
    final signal = job.signal;
    final partial = _partialFile(clip.sha256, job.nonce);
    final writer = writeBytes ?? _writeFile;
    final writing = writer(partial, bytes);
    unawaited(
      writing.then((_) {
        if (signal.isStopped) unawaited(_deleteQuiet(partial));
      }, onError: (Object _) {}),
    );
    await signal.guard(writing);
    final verified = await signal.guard(partial.readAsBytes());

    if (verified.length != clip.bytes ||
        sha256.convert(verified).toString() != clip.sha256) {
      await _deleteQuiet(partial);
      throw const FileSystemException('catalog audio verify failed');
    }

    final target = _finalFile(clip.sha256);

    if (await signal.guard(target.exists())) {
      await signal.guard(_deleteQuiet(target));
    }

    await signal.guard(partial.rename(target.path));
    _index[clip.sha256] = _IndexEntry(
      bytes: bytes.length,
      lastUsed: ++_clock,
      sha256: clip.sha256,
    );
    unawaited(_saveIndex().catchError((Object _) {}));
    return target;
  }

  Future<List<int>> _readFile(File file) => file.readAsBytes();

  Future<void> _writeFile(File file, List<int> bytes) {
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> _evict() async {
    final entries = _index.values.toList()
      ..sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
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

  Future<bool> _acquireSlot(CatalogSignal signal) async {
    if (signal.isStopped) return false;
    if (_active < concurrency) {
      _active += 1;
      return true;
    }

    final waiter = Completer<bool>();
    _waiters.add(waiter);
    signal.listen((_) {
      if (!waiter.isCompleted && _waiters.remove(waiter)) {
        waiter.complete(false);
      }
    });
    return waiter.future;
  }

  void _releaseSlot() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete(true);
    } else {
      _active -= 1;
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
    final next = _indexWrite.then(
      (_) => _writeIndexSnapshot(partial, snapshot),
    );
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

  File _finalFile(String sha256) =>
      File('${directory.path}${Platform.pathSeparator}$sha256.mp3');

  File _partialFile(String sha256, String nonce) => File(
    '${directory.path}${Platform.pathSeparator}$sha256.$nonce.mp3.partial',
  );

  String get _indexPath =>
      '${directory.path}${Platform.pathSeparator}index.json';

  Uri _clipUri(PublishedAudioClip clip) => Uri.parse(
    apiBase ?? AppConfig.apiBaseUrl,
  ).resolve('/api/trainers/audio-fallback/${clip.sha256}');

  Future<void> _deleteQuiet(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

class _AcquireResult {
  const _AcquireResult({this.file, this.failureCode, this.cancelled = false});
  final File? file;
  final String? failureCode;
  final bool cancelled;
}
