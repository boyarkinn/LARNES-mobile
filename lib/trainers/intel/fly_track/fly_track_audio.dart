/// Web: `platform/src/trainers/intel/fly-track/audio.ts`

import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const kFlyTrackAudioPlaybackRate = 1.5;
const kFlyTrackInstructionDurationFallbackMs = 3888;

String? _flyCue(String fileName) {
  final key = switch (fileName) {
    'instruction.mp3' => 'instruction:fly-track',
    'tap.mp3' => 'feedback:fly-track:tap',
    'fly-moved.mp3' => 'explanation:fly-track:moved',
    'up.mp3' => 'explanation:fly-track:up',
    'down.mp3' => 'explanation:fly-track:down',
    'left.mp3' => 'explanation:fly-track:left',
    'right.mp3' => 'explanation:fly-track:right',
    'by-1.mp3' => 'explanation:fly-track:by-1',
    'by-2.mp3' => 'explanation:fly-track:by-2',
    'by-3.mp3' => 'explanation:fly-track:by-3',
    'by-4.mp3' => 'explanation:fly-track:by-4',
    _ => null,
  };
  return key == null ? null : spokenCueAsset(key);
}

String getFlyTrackInstructionAudioAsset() => _flyCue('instruction.mp3') ?? '';

String getFlyTrackAnswerAudioAsset() => _flyCue('tap.mp3') ?? '';

List<String> getFlyTrackMoveAudioAssets(
  FlyDirection direction,
  FlyDistance distance, {
  required bool includeFlyMoved,
}) {
  final clips = [
    _flyCue('by-$distance.mp3'),
    _flyCue('$direction.mp3'),
  ];

  if (includeFlyMoved) {
    clips.insert(0, _flyCue('fly-moved.mp3'));
  }

  return clips.whereType<String>().toList();
}

List<String> getFlyTrackReplayAudioAssets(
  FlyDirection direction,
  FlyDistance distance,
) {
  return [
    _flyCue('by-$distance.mp3'),
    _flyCue('$direction.mp3'),
  ].whereType<String>().toList();
}

Future<void> playFlyTrackAudio(
  List<String> assetPaths, {
  void Function()? onStarted,
}) {
  if (assetPaths.isEmpty) {
    return Future<void>.value();
  }

  return getSharedClipPlayer().play(
    assetPaths,
    playbackRate: 1,
    onStarted: onStarted,
  );
}

Future<void> cancelFlyTrackAudio() {
  return getSharedClipPlayer().cancel();
}
