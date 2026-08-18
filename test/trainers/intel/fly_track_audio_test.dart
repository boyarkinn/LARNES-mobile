import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_audio.dart';

void main() {
  group('fly-track audio', () {
    test('resolves the instruction audio at the agreed playback rate', () {
      expect(kFlyTrackAudioPlaybackRate, 1.5);
      expect(
        getFlyTrackInstructionAudioAsset(),
        'audio/ru/intel/fly-track/instruction.mp3',
      );
    });

    test('says “муха полетела” only on the first tracking step', () {
      expect(
        getFlyTrackMoveAudioAssets('up', 4, includeFlyMoved: true),
        [
          'audio/ru/intel/fly-track/fly-moved.mp3',
          'audio/ru/intel/fly-track/by-4.mp3',
          'audio/ru/intel/fly-track/up.mp3',
        ],
      );
      expect(
        getFlyTrackMoveAudioAssets('up', 3, includeFlyMoved: false),
        [
          'audio/ru/intel/fly-track/by-3.mp3',
          'audio/ru/intel/fly-track/up.mp3',
        ],
      );
    });

    test('replays with distance and direction but no movement phrase', () {
      expect(
        getFlyTrackReplayAudioAssets('left', 2),
        [
          'audio/ru/intel/fly-track/by-2.mp3',
          'audio/ru/intel/fly-track/left.mp3',
        ],
      );
    });

    test('resolves the answer call-to-action clip', () {
      expect(
        getFlyTrackAnswerAudioAsset(),
        'audio/ru/intel/fly-track/tap.mp3',
      );
    });

    test('bundles all eleven mp3 clips', () {
      const expected = [
        'instruction.mp3',
        'fly-moved.mp3',
        'by-1.mp3',
        'by-2.mp3',
        'by-3.mp3',
        'by-4.mp3',
        'up.mp3',
        'down.mp3',
        'left.mp3',
        'right.mp3',
        'tap.mp3',
      ];

      for (final fileName in expected) {
        expect(
          File('assets/audio/ru/intel/fly-track/$fileName').existsSync(),
          isTrue,
          reason: fileName,
        );
      }
    });
  });
}
