bool isLegacyTrainerAudioPath(String path) {
  return path.contains('audio/ru/') ||
      path.contains('audio/background-music/') ||
      path.contains('audio/instructions/');
}
