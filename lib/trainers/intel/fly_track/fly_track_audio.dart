/// Web: `platform/src/trainers/intel/fly-track/audio.ts`

import 'package:larnes_mobile/trainers/intel/fly_track/model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

/// Asset paths relative to `assets/` (ClipPlayer prefixes `assets/`).
const kFlyTrackAudioAssetBase = 'audio/ru/intel/fly-track';

const kFlyTrackAudioPlaybackRate = 1.5;
const kFlyTrackInstructionDurationFallbackMs = 3888;

String flyTrackAssetPath(String fileName) => '$kFlyTrackAudioAssetBase/$fileName';

String getFlyTrackInstructionAudioAsset() => flyTrackAssetPath('instruction.mp3');

String getFlyTrackAnswerAudioAsset() => flyTrackAssetPath('tap.mp3');

List<String> getFlyTrackMoveAudioAssets(
  FlyDirection direction,
  FlyDistance distance, {
  required bool includeFlyMoved,
}) {
  final clips = [
    flyTrackAssetPath('by-$distance.mp3'),
    flyTrackAssetPath('$direction.mp3'),
  ];

  if (!includeFlyMoved) {
    return clips;
  }

  return [flyTrackAssetPath('fly-moved.mp3'), ...clips];
}

List<String> getFlyTrackReplayAudioAssets(
  FlyDirection direction,
  FlyDistance distance,
) {
  return [
    flyTrackAssetPath('by-$distance.mp3'),
    flyTrackAssetPath('$direction.mp3'),
  ];
}

Future<void> playFlyTrackAudio(
  List<String> assetPaths, {
  void Function()? onStarted,
}) {
  return getSharedClipPlayer().play(
    assetPaths,
    playbackRate: kFlyTrackAudioPlaybackRate,
    onStarted: onStarted,
  );
}

Future<void> cancelFlyTrackAudio() {
  return getSharedClipPlayer().cancel();
}
