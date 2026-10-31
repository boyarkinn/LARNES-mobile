import 'dart:async';
import 'dart:io';

import 'package:larnes_mobile/trainers/audio/catalog_audio_store.dart';
import 'package:path_provider/path_provider.dart';

CatalogAudioStore? _installed;
Future<CatalogAudioStore>? _opening;

Future<CatalogAudioStore> sharedCatalogAudioStore() {
  final installed = _installed;

  if (installed != null) {
    return Future<CatalogAudioStore>.value(installed);
  }

  return _opening ??= _openSharedStore().catchError((
    Object error,
    StackTrace stack,
  ) {
    _opening = null;
    Error.throwWithStackTrace(error, stack);
  });
}

Future<CatalogAudioStore> _openSharedStore() async {
  final root = await getApplicationSupportDirectory().timeout(
    const Duration(seconds: 2),
  );
  final store = CatalogAudioStore(
    directory: Directory(
      '${root.path}${Platform.pathSeparator}trainer-audio-v1',
    ),
  );
  await store.open().timeout(const Duration(seconds: 2));
  _installed = store;
  return store;
}

void installCatalogAudioStoreForTests(CatalogAudioStore? store) {
  _installed = store;
  _opening = store == null ? null : Future<CatalogAudioStore>.value(store);
}
