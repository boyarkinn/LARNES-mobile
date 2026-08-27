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
}

