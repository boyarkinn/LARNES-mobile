import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/catalog_playback_failure.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

void main() {
  tearDown(() => setRequiredCatalogPaths(const []));
  test(
    'only the active exercise required sound reports a blocking failure',
    () {
      final before = catalogPlaybackFailures.value;
      setRequiredCatalogPaths(['/cache/number.mp3']);
      expect(reportRequiredCatalogFailure(['/cache/instruction.mp3']), isFalse);
      expect(catalogPlaybackFailures.value, before);
      expect(reportRequiredCatalogFailure(['/cache/number.mp3']), isTrue);
      expect(catalogPlaybackFailures.value, before + 1);
      setRequiredCatalogPaths(const []);
      expect(reportRequiredCatalogFailure(['/cache/number.mp3']), isFalse);
    },
  );
  testWidgets('leaving an instruction cancels its fallback wait', (
    tester,
  ) async {
    final player = ClipPlayer();
    var finished = false;
    final waiting = player
        .waitForFallback(const Duration(seconds: 3))
        .then((_) => finished = true);
    await tester.pump();
    expect(finished, isFalse);
    await player.cancel();
    await waiting;
    expect(finished, isTrue);
    await tester.pump(const Duration(seconds: 4));
    await player.dispose();
  });
}
