// 17 дорожек есть на сайте и отсутствуют в приложении.
// Без готового файла каталога музыка не запускается.

import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';

final _musicKey = RegExp(r'^music:background:(1[0-7]|[1-9])$');
final _musicListeners = <void Function()>[];

bool isBackgroundMusicAudioKey(String semanticKey) => _musicKey.hasMatch(semanticKey);

class BackgroundMusicFile {
  const BackgroundMusicFile({required this.path});

  final String path;
}

final Map<String, BackgroundMusicFile> _backgroundMusicFiles = {};

void setBackgroundMusicFiles(Map<String, BackgroundMusicFile> files) {
  _backgroundMusicFiles
    ..clear()
    ..addAll(files);
}

/// Готовый файл каталога. Старого файла в приложении нет, поэтому без него — null.
String? preparedBackgroundMusicPath(String semanticKey) {
  if (!isBackgroundMusicAudioKey(semanticKey)) {
    return null;
  }

  return _backgroundMusicFiles[semanticKey]?.path;
}

double backgroundMusicVolumeFor(TrainerDirection? direction) {
  final percent = direction == TrainerDirection.mental || direction == TrainerDirection.intel ? 2 : 5;
  return percent / 100;
}

void listenBackgroundMusic(void Function() listener) {
  _musicListeners.add(listener);
}

void unlistenBackgroundMusic(void Function() listener) {
  _musicListeners.remove(listener);
}

void rememberBackgroundMusicFile(String semanticKey, String path) {
  if (!isBackgroundMusicAudioKey(semanticKey) || path.isEmpty) {
    return;
  }

  _backgroundMusicFiles[semanticKey] = BackgroundMusicFile(path: path);

  for (final listener in List<void Function()>.of(_musicListeners)) {
    listener();
  }
}

String? pickPreparedBackgroundMusicPath(int Function(int length) randomIndex) {
  final ready = <String>[
    for (var number = 1; number <= 17; number++)
      if (preparedBackgroundMusicPath('music:background:$number') != null) 'music:background:$number',
  ];

  if (ready.isEmpty) {
    return null;
  }

  return preparedBackgroundMusicPath(ready[randomIndex(ready.length)]);
}
