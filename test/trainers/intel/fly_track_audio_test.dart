import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_audio.dart';

void main() {
  group('fly-track audio', () {
    test('resolves the instruction audio at the agreed playback rate', () {
      expect(kFlyTrackAudioPlaybackRate, 1.5);
      expect(getFlyTrackInstructionAudioAsset(), '');
    });

    test('says “муха полетела” only on the first tracking step', () {
      setSpeechAudioFiles({
        'explanation:fly-track:moved': const SpeechAudioFile(path: 'moved'),
        'explanation:fly-track:by-4': const SpeechAudioFile(path: 'by4'),
        'explanation:fly-track:up': const SpeechAudioFile(path: 'up'),
        'explanation:fly-track:by-3': const SpeechAudioFile(path: 'by3'),
      });
      expect(
        getFlyTrackMoveAudioAssets('up', 4, includeFlyMoved: true),
        ['moved', 'by4', 'up'],
      );
      expect(
        getFlyTrackMoveAudioAssets('up', 3, includeFlyMoved: false),
        ['by3', 'up'],
      );
      setSpeechAudioFiles(const {});
    });

    test('replays with distance and direction but no movement phrase', () {
      expect(getFlyTrackReplayAudioAssets('left', 2), isEmpty);
    });

    test('resolves the answer call-to-action clip', () {
      expect(getFlyTrackAnswerAudioAsset(), '');
    });
  });
}
