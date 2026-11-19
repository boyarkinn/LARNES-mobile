import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/topic_chain_flash_audio.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'topic-chain-audio-test-',
    );
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('writes one WAV with exact cues, joins and pauses', () async {
    final renders = <String>[];
    final speech = TopicChainFlashAudio(
      temporaryDirectory: () async => directory,
      renderClip: (path, _) async {
        renders.add(path);
        final frames = path == 'six' ? 7000 : 25000;
        final bytes = ByteData(frames * 2);
        bytes.setInt16(0, path == 'six' ? 6000 : 1000, Endian.little);
        return bytes.buffer.asUint8List();
      },
    );
    final groups = [
      ['plus', 'six'],
      ['six'],
    ];
    final track = await speech.prepare(groups, pauseMs: 700, blankMs: 120);
    final file = File(track.path);
    final bytes = await file.readAsBytes();
    final view = ByteData.sublistView(bytes);
    const endOfSpeech = 25000 + 882 + 7000;
    const nextCue = endOfSpeech + 5292;
    const endOfTrack = nextCue + 30870;
    expect(track.cues, [
      (startFrame: 0, endFrame: endOfSpeech),
      (startFrame: nextCue, endFrame: endOfTrack),
    ]);
    expect(track.at(Duration.zero), (index: 0, visible: true));
    expect(track.at(const Duration(milliseconds: 760)), (
      index: 0,
      visible: false,
    ));
    expect(track.at(const Duration(milliseconds: 900)), (
      index: 1,
      visible: true,
    ));
    expect(track.at(track.duration), (index: 1, visible: false));
    expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
    expect(view.getUint32(4, Endian.little), bytes.length - 8);
    expect(view.getUint16(22, Endian.little), 1);
    expect(view.getUint32(24, Endian.little), 44100);
    expect(view.getUint32(40, Endian.little), endOfTrack * 2);
    expect(bytes.length, 44 + endOfTrack * 2);
    expect(view.getInt16(44, Endian.little), 1000);
    expect(view.getInt16(44 + 25000 * 2, Endian.little), 0);
    expect(view.getInt16(44 + (25000 + 882) * 2, Endian.little), 6000);
    expect(view.getInt16(44 + (nextCue - 1) * 2, Endian.little), 0);
    expect(view.getInt16(44 + nextCue * 2, Endian.little), 6000);
    expect(
      await speech.prepare(groups, pauseMs: 700, blankMs: 120),
      same(track),
    );
    await speech.prepare(
      [
        ['six'],
      ],
      pauseMs: 700,
      blankMs: 120,
    );
    expect(renders, ['plus', 'six']);
    expect(await file.exists(), false);
    await speech.dispose();
    expect(await directory.list().isEmpty, true);
  });

  test(
    'cleans a failed partial track and allows the same example to retry',
    () async {
      var fails = true;
      final renders = <String>[];
      final speech = TopicChainFlashAudio(
        temporaryDirectory: () async => directory,
        renderClip: (path, _) async {
          renders.add(path);
          if (fails && path == 'eight') throw const FormatException('bad clip');
          return Uint8List.fromList([1, 0]);
        },
      );
      final groups = [
        ['minus', 'eight'],
      ];
      await expectLater(
        speech.prepare(groups, pauseMs: 700, blankMs: 120),
        throwsFormatException,
      );
      expect(
        await directory
            .list(recursive: true)
            .where((file) => file is File)
            .isEmpty,
        true,
      );
      fails = false;
      final retry = await speech.prepare(groups, pauseMs: 700, blankMs: 120);
      expect(await File(retry.path).exists(), true);
      expect(renders, ['minus', 'eight', 'eight']);
      await speech.dispose();
    },
  );
}
