import 'dart:async';
import 'dart:io';

import 'package:larnes_mobile/trainers/audio/catalog_audio_store.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';
import 'package:path_provider/path_provider.dart';

CatalogAudioStore? _installed;
Future<CatalogAudioStore>? _opening;

Future<CatalogAudioStore> sharedCatalogAudioStore() {
  final installed = _installed;

  if (installed != null) {
    return Future<CatalogAudioStore>.value(installed);
  }

  return _opening ??= _openSharedStore();
}

Future<CatalogAudioStore> _openSharedStore() async {
  final root = await getApplicationSupportDirectory();
  final store = CatalogAudioStore(
    directory: Directory('${root.path}${Platform.pathSeparator}trainer-audio-v1'),
  );
  await store.open();
  _installed = store;
  return store;
}

void installCatalogAudioStoreForTests(CatalogAudioStore? store) {
  _installed = store;
  _opening = store == null ? null : Future<CatalogAudioStore>.value(store);
}

/// Готовит уже выбранные упражнения до их старта. Пустой набор сеть не трогает.
Future<void> warmCatalogManifests(Iterable<ExerciseAudioManifest?> manifests) async {
  final pending = manifests
      .whereType<ExerciseAudioManifest>()
      .where((manifest) => manifest.clips.isNotEmpty)
      .toList();

  if (pending.isEmpty) {
    return;
  }

  try {
    final store = await sharedCatalogAudioStore();
    await Future.wait(pending.map((manifest) async {
      final launch = await store.prepare(manifest);
      launch.release();
    }));
  } catch (_) {}
}
