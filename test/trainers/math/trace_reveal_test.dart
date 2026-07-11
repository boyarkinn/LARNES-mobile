import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';

void main() {
  group('trace-reveal', () {
    test('unlocks drawing after guide pop duration', () {
      expect(getTraceInteractionReadyMs(), traceGuidePopDurationMs);
    });
  });
}
