import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

void main() {
  test('Mulberry32 stream matches Web runtime snapshot v1', () {
    final random = TrainerSnapshotRandom(123456);

    expect(
      List.generate(5, (_) => random.nextDouble()),
      equals([
        0.38233304349705577,
        0.7972629074938595,
        0.9965302373748273,
        0.16001168475486338,
        0.20857197884470224,
      ]),
    );
  });

  test('reads only matching versioned materialized snapshots', () {
    expect(
      readTrainerSnapshotSeed('fly-track', {
        '__runtimeSnapshot': {
          'version': 1,
          'trainerKey': 'fly-track',
          'mode': 'materialized',
          'payload': {'seed': 42},
        },
      }),
      42,
    );
    expect(
      readTrainerSnapshotSeed('digit-find-tap', {
        '__runtimeSnapshot': {
          'version': 1,
          'trainerKey': 'fly-track',
          'mode': 'materialized',
          'payload': {'seed': 42},
        },
      }),
      isNull,
    );
  });

  test('Mulberry32 keeps Web uint32 semantics when the intermediate sum carries', () {
    // Frozen vectors from Web createTrainerSnapshotRng, snapshot version 1.
    const vectors = {
      42: [
        2581720956, 1925393290, 3661312704, 2876485805,
        750819978, 2261697747, 1173505300, 2683257857,
        3717185310, 2028586305, 1073414265, 3788413843,
        3202918453, 1318561460, 847198783, 2150616774,
      ],
      123456: [
        1642107918, 3424218114, 4280064779, 687244953,
        895809828, 1000027720, 2040167411, 2611339366,
        1346086115, 2820032742, 1328815579, 780101124,
        1581451774, 3661800343, 3465109817, 4130232914,
      ],
    };
    for (final vector in vectors.entries) {
      final random = TrainerSnapshotRandom(vector.key);
      expect(
        List.generate(vector.value.length, (_) => (random.nextDouble() * 4294967296).toInt()),
        vector.value,
        reason: 'seed ${vector.key}',
      );
    }
  });
}

