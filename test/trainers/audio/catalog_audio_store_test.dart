import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:larnes_mobile/trainers/audio/catalog_audio_store.dart';
import 'package:larnes_mobile/trainers/audio/catalog_playlist.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';

void main() {
  test('downloads a real recording once, reuses it, and keeps the open launch', () async {
    final current = List<int>.generate(64, (index) => index);
    final newer = List<int>.generate(64, (index) => 255 - index);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final base = 'http://${server.address.address}:${server.port}';
    final currentClip = _clip(current, 'number:8', base);
    final newerClip = _clip(newer, 'number:8', base);
    var serves = 0;
    var open = true;

    final hits = <String>[];
    server.listen((request) async {
      serves += 1;
      hits.add('${request.method} ${request.uri}');

      if (!open) {
        request.response.statusCode = HttpStatus.badGateway;
        await request.response.close();
        return;
      }

      final body = request.uri.path.endsWith('${newerClip.sha256}.mp3') ? newer : current;
      request.response.add(body);
      await request.response.close();
    });

    final directory = await Directory.systemTemp.createTemp('larnes-audio-');
    addTearDown(() async {
      open = false;
      await server.close(force: true);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final store = CatalogAudioStore(directory: directory, publicBase: base);
    final cold = await store.prepare(_manifest([currentClip], 4));
    final warm = CatalogAudioStore(directory: directory, publicBase: base);
    open = false;
    final cached = await warm.prepare(_manifest([currentClip], 4));
    expect(cached.packReady, isTrue, reason: hits.join(' | '));
    expect(serves, 1, reason: hits.join(' | '));
    open = true;
    final unreadable = CatalogAudioStore(
      directory: directory,
      publicBase: base,
      readBytes: (file) async {
        throw const FileSystemException('cache unreadable');
      },
    );
    final afterCacheFailure = await unreadable.prepare(_manifest([currentClip], 4));
    final held = await store.prepare(_manifest([currentClip], 4));
    final fresh = await store.prepare(_manifest([newerClip], 5));

    expect(cold.packReady, isTrue);
    expect(await File(cold.stimulusPaths.single).readAsBytes(), current);
    expect(afterCacheFailure.packReady, isTrue);
    expect(fresh.packReady, isTrue);
    expect(serves, 3, reason: hits.join(' | '));
    expect(await File(fresh.stimulusPaths.single).readAsBytes(), newer);
    expect(await File(held.pathFor('number:8')!).readAsBytes(), current);

    held.release();
    cold.release();
    cached.release();
    afterCacheFailure.release();
    fresh.release();
  });

  test('a cache read error still downloads, and one cancel leaves the other launch', () async {
    final bytes = [0x49, 0x44, 0x33, 7, 7, 7];
    final directory = await Directory.systemTemp.createTemp('larnes-audio-shared-');
    addTearDown(() => directory.delete(recursive: true));
    final clip = _clip(bytes, 'number:6', catalogAudioPublicBase);
    var fetches = 0;
    final started = Completer<void>();
    final gate = Completer<void>();
    final store = CatalogAudioStore(
      directory: directory,
      fetch: (url, signal) {
        fetches += 1;
        if (!started.isCompleted) {
          started.complete();
        }
        return gate.future.then((_) => bytes);
      },
    );
    final firstSignal = CatalogSignal();
    final first = store.prepare(_manifest([clip], 1), signal: firstSignal);
    final second = store.prepare(_manifest([clip], 1));
    await started.future;
    firstSignal.cancel();
    gate.complete();
    final results = await Future.wait([first, second]);

    expect(fetches, 1);
    expect(results[0].aborted, isTrue);
    expect(results[0].packReady, isFalse);
    expect(results[1].packReady, isTrue);
    expect(results[1].aborted, isFalse);
    expect(directory.listSync().where((entity) => entity.path.endsWith('.partial')), isEmpty);
    results[1].release();
  });

  test('a hung download times out without treating it as cancel', () async {
    final bytes = [0x49, 0x44, 0x33, 2];
    final directory = await Directory.systemTemp.createTemp('larnes-audio-timeout-');
    addTearDown(() => directory.delete(recursive: true));
    final store = CatalogAudioStore(
      directory: directory,
      timeout: const Duration(milliseconds: 40),
      fetch: (url, signal) => Completer<List<int>>().future,
    );
    final blocked = await store.prepare(_manifest([_clip(bytes, 'number:5', catalogAudioPublicBase)], 1));
    final spoken = await store.prepare(
      _manifest([_clip(bytes, 'instruction:digit-find-tap', catalogAudioPublicBase)], 1),
    );

    expect(blocked.aborted, isFalse);
    expect(blocked.packReady, isFalse);
    expect(blocked.stimuliReady, isFalse);
    expect(catalogTrainerMayStart(blocked.packReady ? CatalogPack.ready : CatalogPack.blocked), isFalse);
    expect(spoken.aborted, isFalse);
    expect(spoken.instruction, CatalogInstruction.fallback);
    expect(spoken.stimuliReady, isTrue);
    expect(spoken.packReady, isFalse);
    expect(catalogTrainerMayStart(CatalogPack.missing), isTrue);
  });

  test('full disk and a bad file do not become ready', () async {
    final bytes = [0x49, 0x44, 0x33, 9];
    final directory = await Directory.systemTemp.createTemp('larnes-audio-disk-');
    addTearDown(() => directory.delete(recursive: true));
    final clip = _clip(bytes, 'number:4', catalogAudioPublicBase);
    final full = CatalogAudioStore(
      directory: directory,
      writeBytes: (file, data) async {
        throw const FileSystemException('disk full');
      },
      fetch: (url, signal) async => bytes,
    );
    final blocked = await full.prepare(_manifest([clip], 1));
    final damaged = CatalogAudioStore(
      directory: directory,
      fetch: (url, signal) async => [0, 1, 2],
    );
    final rejected = await damaged.prepare(_manifest([clip], 1));

    expect(blocked.packReady, isFalse);
    expect(rejected.packReady, isFalse);
    expect(directory.listSync().where((entity) => entity.path.endsWith('.mp3') || entity.path.endsWith('.partial')), isEmpty);
  });

  test('keeps every clip and limits simultaneous downloads', () async {
    final directory = await Directory.systemTemp.createTemp('larnes-audio-chunk-');
    addTearDown(() => directory.delete(recursive: true));
    final clips = <PublishedAudioClip>[];
    final bodies = <String, List<int>>{};

    for (var index = 0; index < 41; index++) {
      final bytes = [index, 3, 1];
      final clip = _clip(bytes, 'number:$index', catalogAudioPublicBase);
      clips.add(clip);
      bodies[clip.sha256] = bytes;
    }

    var active = 0;
    var maxActive = 0;
    final store = CatalogAudioStore(
      directory: directory,
      concurrency: 2,
      fetch: (url, signal) async {
        active += 1;
        if (active > maxActive) {
          maxActive = active;
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active -= 1;
        final sha = url.pathSegments.last.replaceFirst('.mp3', '');
        return bodies[sha]!;
      },
    );
    final launch = await store.prepare(_manifest(clips, 2));

    expect(launch.packReady, isTrue);
    expect(launch.stimulusPaths, hasLength(41));
    expect(maxActive, lessThanOrEqualTo(2));
    launch.release();
  });

  test('a pinned file survives the next version and a network url is not a playlist item', () async {
    final first = [0x49, 0x44, 0x33, 1];
    final second = [0x49, 0x44, 0x33, 2, 2];
    final directory = await Directory.systemTemp.createTemp('larnes-audio-pin-');
    addTearDown(() => directory.delete(recursive: true));
    final older = _clip(first, 'number:1', catalogAudioPublicBase);
    final newer = _clip(second, 'number:1', catalogAudioPublicBase);
    final store = CatalogAudioStore(
      directory: directory,
      maxBytes: first.length,
      fetch: (url, signal) async => url.path.endsWith('${newer.sha256}.mp3') ? second : first,
    );
    final held = await store.prepare(_manifest([older], 3));
    final next = await store.prepare(_manifest([newer], 4));
    final sources = catalogFileSources([
      held.stimulusPaths.single,
      'https://audio.larnes.ru/v1/${newer.sha256}.mp3',
      next.stimulusPaths.single,
    ]);

    expect(await File(held.stimulusPaths.single).exists(), isTrue);
    expect(sources, hasLength(2));

    for (final source in sources) {
      expect(source, isA<UriAudioSource>());
      expect((source as UriAudioSource).uri.isScheme('file'), isTrue);
    }

    held.release();
    final third = _clip([9, 9, 9, 9], 'number:3', catalogAudioPublicBase);
    final storeAfter = CatalogAudioStore(
      directory: directory,
      maxBytes: first.length,
      fetch: (url, signal) async => url.path.endsWith('${third.sha256}.mp3') ? [9, 9, 9, 9] : second,
    );
    final displaced = await storeAfter.prepare(_manifest([third], 5));

    expect(await File(held.stimulusPaths.single).exists(), isFalse);
    expect(displaced.packReady, isTrue);
    next.release();
    displaced.release();
  });

  test('a file stays while another set is still loading', () async {
    final first = [1, 2, 3, 4];
    final second = [5, 6, 7, 8, 9];
    final intruder = [9, 9, 9, 9, 9, 9];
    final directory = await Directory.systemTemp.createTemp('larnes-audio-hold-');
    addTearDown(() => directory.delete(recursive: true));
    final kept = _clip(first, 'number:1', catalogAudioPublicBase);
    final delayed = _clip(second, 'number:2', catalogAudioPublicBase);
    final other = _clip(intruder, 'number:3', catalogAudioPublicBase);
    final gate = Completer<void>();
    final store = CatalogAudioStore(
      directory: directory,
      maxBytes: first.length,
      fetch: (url, signal) async {
        if (url.path.endsWith('${delayed.sha256}.mp3')) {
          await gate.future;
          return second;
        }

        if (url.path.endsWith('${other.sha256}.mp3')) {
          return intruder;
        }

        return first;
      },
    );
    final pending = store.prepare(_manifest([kept, delayed], 1));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final rival = await store.prepare(_manifest([other], 2));
    gate.complete();
    final launch = await pending;

    expect(launch.packReady, isTrue);
    expect(await File(launch.pathsByKey['number:1']!).exists(), isTrue);
    rival.release();
    launch.release();
  });

  test('parallel index writes keep both recordings', () async {
    final left = [1, 1, 1];
    final right = [2, 2, 2, 2];
    final directory = await Directory.systemTemp.createTemp('larnes-audio-index-');
    addTearDown(() => directory.delete(recursive: true));
    final first = _clip(left, 'number:1', catalogAudioPublicBase);
    final second = _clip(right, 'number:2', catalogAudioPublicBase);
    final store = CatalogAudioStore(
      directory: directory,
      fetch: (url, signal) async => url.path.endsWith('${second.sha256}.mp3') ? right : left,
    );
    final launches = await Future.wait([
      store.prepare(_manifest([first], 1)),
      store.prepare(_manifest([second], 2)),
    ]);
    final reopened = CatalogAudioStore(
      directory: directory,
      fetch: (url, signal) async => throw StateError('the index missed a file'),
    );
    final again = await reopened.prepare(_manifest([first, second], 3));

    expect(again.packReady, isTrue);
    expect(again.stimulusPaths, hasLength(2));

    for (final launch in launches) {
      launch.release();
    }

    again.release();
  });

  test('an unpublished required number blocks the launch', () {
    final clip = _clip([4, 4, 4], 'number:8', catalogAudioPublicBase);

    expect(catalogExpectsStimuli(_manifest([clip], 1)), isTrue);
    expect(
      catalogExpectsStimuli(ExerciseAudioManifest(
        catalogRevision: 1,
        clips: const [],
        contentLocale: 'ru-RU',
        instructionLocale: 'ru-RU',
        missing: const [
          MissingAudioBinding(locale: 'ru-RU', reason: 'unknown_slot', semanticKey: 'number:8'),
        ],
        trainerKey: 'digit-find-tap',
      )),
      isTrue,
    );
  });
}

PublishedAudioClip _clip(List<int> bytes, String semanticKey, String base) {
  final hash = sha256.convert(bytes).toString();

  return PublishedAudioClip(
    bytes: bytes.length,
    durationMs: 900,
    locale: 'ru-RU',
    semanticKey: semanticKey,
    sha256: hash,
    url: '$base/v1/$hash.mp3',
    versionId: hash.substring(0, 8),
  );
}

ExerciseAudioManifest _manifest(List<PublishedAudioClip> clips, int revision) {
  return ExerciseAudioManifest(
    catalogRevision: revision,
    clips: clips,
    contentLocale: 'ru-RU',
    instructionLocale: 'ru-RU',
    missing: const [],
    trainerKey: 'digit-find-tap',
  );
}
