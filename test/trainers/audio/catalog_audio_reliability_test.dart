import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/audio/catalog_audio_cache.dart';
import 'package:larnes_mobile/trainers/audio/catalog_audio_store.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';

PublishedAudioClip clip(List<int> bytes, String key, {bool? required}) =>
    PublishedAudioClip(
      bytes: bytes.length,
      durationMs: 5317,
      locale: 'ru-RU',
      semanticKey: key,
      sha256: sha256.convert(bytes).toString(),
      url: '$catalogAudioPublicBase/v1/${sha256.convert(bytes)}.mp3',
      versionId: 'published',
      isRequired: required,
    );
ExerciseAudioManifest manifest(
  List<PublishedAudioClip> clips, {
  List<MissingAudioBinding> missing = const [],
}) => ExerciseAudioManifest(
  catalogRevision: 1,
  clips: clips,
  contentLocale: 'ru-RU',
  instructionLocale: 'ru-RU',
  missing: missing,
  trainerKey: 'flashcard-digit-match',
);
Future<Directory> cache() async {
  final directory = await Directory.systemTemp.createTemp(
    'larnes-audio-reliability-',
  );
  addTearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (await directory.exists()) await directory.delete(recursive: true);
  });
  return directory;
}

class NeverOpenStore extends CatalogAudioStore {
  NeverOpenStore() : super(directory: Directory('unused-audio-test'));
  @override
  Future<void> open() => Completer<void>().future;
}

class FailedInstructionStore extends CatalogAudioStore {
  FailedInstructionStore() : super(directory: Directory('unused-audio-test'));
  @override
  Future<CatalogLaunch> prepare(
    ExerciseAudioManifest? manifest, {
    CatalogSignal? signal,
    void Function(PublishedAudioClip, String)? onLoaded,
    void Function(PublishedAudioClip, String)? onOptionalIssue,
  }) async => CatalogLaunch(
    aborted: false,
    instruction: CatalogInstruction.fallback,
    instructionPath: null,
    packReady: false,
    pathsByKey: {},
    release: () {},
    stimuliReady: true,
    stimulusPaths: [],
    primaryInstructionFailed: true,
    failureCodes: ['http-503'],
    failedSha256: [manifest!.clips.first.sha256],
  );
}

void main() {
  test(
    'cold primary instruction waits for real verified bytes, using the app relay first',
    () async {
      final bytes = [0x49, 0x44, 0x33, 1, 2, 3], directory = await cache();
      final instruction = clip(bytes, 'instruction:flashcard-digit-match');
      var requests = 0;
      final store = track(
        CatalogAudioStore(
          directory: directory,
          fetch: (url, signal) async {
            requests++;
            expect(
              url.toString(),
              '${AppConfig.apiBaseUrl}/api/trainers/audio-fallback/${instruction.sha256}',
            );
            await Future<void>.delayed(const Duration(milliseconds: 900));
            return bytes;
          },
        ),
      );
      final launch = await store.prepare(manifest([instruction]));
      expect(launch.instruction, CatalogInstruction.ready);
      expect(launch.primaryInstructionFailed, false);
      expect(launch.launchReady, true);
      expect(await File(launch.instructionPath!).readAsBytes(), bytes);
      final warm = await store.prepare(manifest([instruction]));
      expect(requests, 1);
      expect(warm.instruction, CatalogInstruction.ready);
      launch.release();
      warm.release();
    },
  );
  test(
    'network timeout starts after a queued request receives its slot',
    () async {
      final directory = await cache(), bodies = <String, List<int>>{};
      final clips = [
        for (var i = 0; i < 3; i++) clip([i, 8, 9], 'number:$i'),
      ];
      for (var i = 0; i < clips.length; i++) {
        bodies[clips[i].sha256] = [i, 8, 9];
      }
      var active = 0, maxActive = 0;
      final store = track(
        CatalogAudioStore(
          directory: directory,
          concurrency: 1,
          timeout: const Duration(milliseconds: 200),
          fetch: (url, signal) async {
            active++;
            if (active > maxActive) maxActive = active;
            await Future<void>.delayed(const Duration(milliseconds: 120));
            active--;
            return bodies[url.pathSegments.last]!;
          },
        ),
      );
      final launch = await store.prepare(manifest(clips));
      expect(maxActive, 1);
      expect(launch.stimulusPaths.length, 3);
      expect(launch.launchReady, true);
      expect(launch.failureCodes, isEmpty);
      launch.release();
    },
  );
  test(
    'DTO retains required flags and optional speech cannot gate a launch',
    () async {
      final bytes = [1, 2, 3], directory = await cache();
      final optional = clip(bytes, 'word:ru:apple', required: false),
          requiredCue = clip(
            [4, 5, 6],
            'explanation:fly-track:up',
            required: true,
          );
      final parsed = ExerciseAudioManifest.fromJson({
        'trainerKey': 'flashcard-digit-match',
        'clips': [
          {
            'url': optional.url,
            'bytes': 3,
            'durationMs': 5317,
            'sha256': optional.sha256,
            'semanticKey': optional.semanticKey,
            'required': false,
          },
          {
            'url': requiredCue.url,
            'bytes': 3,
            'durationMs': 5317,
            'sha256': requiredCue.sha256,
            'semanticKey': requiredCue.semanticKey,
            'required': true,
          },
        ],
      })!;
      expect(parsed.clips.map((c) => c.isRequired), [false, true]);
      expect(catalogExpectsStimuli(manifest([optional])), false);
      expect(catalogExpectsStimuli(manifest([requiredCue])), true);
      final store = track(
        CatalogAudioStore(
          directory: directory,
          fetch: (url, signal) async =>
              throw const CatalogAudioFailure('http-503'),
        ),
      );
      final optionalLaunch = await store.prepare(manifest([optional]));
      expect(optionalLaunch.launchReady, true);
      final blocked = await store.prepare(manifest([requiredCue]));
      expect(blocked.launchReady, false);
      expect(blocked.failureCodes, contains('http-503'));
      optionalLaunch.release();
      blocked.release();
    },
  );
  test(
    'unpublished optional instruction remains text fallback; explicit required missing blocks',
    () async {
      final store = track(CatalogAudioStore(directory: await cache()));
      MissingAudioBinding missing(bool? required) => MissingAudioBinding(
        locale: 'ru-RU',
        reason: 'unpublished',
        semanticKey: 'instruction:flashcard-digit-match',
        required: required,
      );
      final optional = await store.prepare(
        manifest([], missing: [missing(null)]),
      );
      expect(optional.launchReady, true);
      expect(optional.failureCodes, contains('missing-publication'));
      final required = await store.prepare(
        manifest([], missing: [missing(true)]),
      );
      expect(required.launchReady, false);
      optional.release();
      required.release();
    },
  );
  test(
    'total startup bounds hung filesystem writes; cancelled late work cannot publish',
    () async {
      final directory = await cache(), gate = Completer<void>();
      final bytes = [9, 8, 7, 6];
      var writes = 0;
      final store = track(
        CatalogAudioStore(
          directory: directory,
          startupTimeout: const Duration(milliseconds: 80),
          fetch: (url, signal) async => bytes,
          writeBytes: (file, data) async {
            if (writes++ == 0) await gate.future;
            await file.writeAsBytes(data);
          },
        ),
      );
      final first = await store.prepare(manifest([clip(bytes, 'number:6')]));
      expect(first.launchReady, false);
      expect(first.aborted, false);
      expect(first.failureCodes, contains('timeout'));
      expect(first.pathsByKey, isEmpty);
      final retry = await store.prepare(manifest([clip(bytes, 'number:6')]));
      expect(retry.launchReady, true);
      gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(first.pathsByKey, isEmpty);
      expect(await File(retry.stimulusPaths.single).readAsBytes(), bytes);
      first.release();
      retry.release();
    },
  );
  test(
    'one cancellation leaves another consumer and the shared download alive',
    () async {
      final directory = await cache(),
          gate = Completer<List<int>>(),
          started = Completer<void>();
      final bytes = [7, 7, 7];
      var calls = 0;
      final store = track(
        CatalogAudioStore(
          directory: directory,
          fetch: (url, signal) {
            calls++;
            if (!started.isCompleted) started.complete();
            return gate.future;
          },
        ),
      );
      final signal = CatalogSignal(),
          first = store.prepare(
            manifest([clip(bytes, 'number:7')]),
            signal: signal,
          );
      final second = store.prepare(manifest([clip(bytes, 'number:7')]));
      await started.future;
      signal.cancel();
      gate.complete(bytes);
      final results = await Future.wait([first, second]);
      expect(calls, 1);
      expect(results[0].aborted, true);
      expect(results[1].launchReady, true);
      for (final result in results) {
        result.release();
      }
    },
  );
  for (final hangs in [true, false]) {
    testWidgets(
      hangs
          ? 'player exits startup when opening cache never completes'
          : 'published narration failure has retry and reports an issue',
      (tester) async {
        final store = hangs ? NeverOpenStore() : FailedInstructionStore();
        installCatalogAudioStoreForTests(store);
        final previous = trainerBuilders[TrainerKey.flashcardDigitMatch]!;
        var started = 0;
        final issues = <Map<String, Object?>>[];
        trainerBuilders[TrainerKey.flashcardDigitMatch] =
            ({required params, onComplete}) {
              started++;
              return const Text('READY');
            };
        addTearDown(() {
          trainerBuilders[TrainerKey.flashcardDigitMatch] = previous;
          installCatalogAudioStoreForTests(null);
        });
        final instruction = clip([
          1,
          2,
          3,
        ], 'instruction:flashcard-digit-match');
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TrainerPlayer(
                  trainerKey: 'flashcard-digit-match',
                  params: const {
                    'pairCount': 2,
                    'rounds': 1,
                    'topicId': 'simple-1',
                  },
                  l10n: AppLocalizations.of(context)!,
                  audioManifest: manifest([instruction]),
                  onAudioIssue: issues.add,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        if (hangs) {
          await tester.pump(const Duration(seconds: 21));
          await tester.pump();
        }
        expect(started, 0);
        expect(find.text('Звук упражнения ещё не готов'), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);
        expect(
          issues.map((issue) => issue['code']),
          contains(hangs ? 'AUDIO-TIMEOUT' : 'AUDIO-HTTP-503'),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
}

CatalogAudioStore track(CatalogAudioStore store) {
  addTearDown(store.waitForMaintenance);
  return store;
}
