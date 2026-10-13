import 'package:just_audio/just_audio.dart';

/// Локальные файлы для одного just_audio. Сетевой адрес каталога сюда не входит.
List<AudioSource> catalogFileSources(Iterable<String> paths) {
  final sources = <AudioSource>[];

  for (final path in paths) {
    final local = _localPath(path);

    if (local == null) {
      continue;
    }

    sources.add(AudioSource.file(local));
  }

  return sources;
}

String? _localPath(String path) {
  if (path.startsWith('file://')) {
    return Uri.parse(path).toFilePath();
  }

  if (path.contains('://')) {
    return null;
  }

  return path;
}

class CatalogClipPlayer {
  AudioPlayer? _player;

  Future<void> playFiles(List<String> paths) async {
    final sources = catalogFileSources(paths);

    if (sources.isEmpty) {
      return;
    }

    final player = _player ??= AudioPlayer();
    await player.setAudioSources(sources, preload: true);
    await player.seek(Duration.zero);
    await player.play();
  }

  Future<void> stop() async {
    final player = _player;

    if (player == null) {
      return;
    }

    await player.stop();
  }

  Future<void> dispose() async {
    final player = _player;
    _player = null;

    if (player == null) {
      return;
    }

    await player.dispose();
  }
}
