import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/syllable_pair_connect/connection_geometry.dart';

void main() {
  test('circle connections touch the borders and stay outside the letters in every direction', () {
    const starts = [Offset.zero, Offset(25, 40), Offset.zero, Offset.zero, Offset(10, 200), Offset.zero];
    const ends = [Offset(200, 0), Offset(25, 140), Offset(61, 61), Offset(80.1, 0), Offset(210, 40), Offset(0.1, 16.5)];
    const radii = [20.0, 40.0, 40.0, 40.0, 25.0, 8.0];
    for (var index = 0; index < starts.length; index++) {
      final curve = buildPairCircleConnection(starts[index], ends[index], radii[index])!;
      final reverse = buildPairCircleConnection(ends[index], starts[index], radii[index])!;
      expect(curve.from, reverse.from);
      expect(curve.to, reverse.to);
      expect(curve.control1, reverse.control1);
      expect(curve.control2, reverse.control2);
      expect((curve.from - starts[index]).distance, closeTo(radii[index], 1e-8));
      expect((curve.to - ends[index]).distance, closeTo(radii[index], 1e-8));
      for (var step = 0; step <= 100; step++) {
        final t = step / 100, s = 1 - t;
        final point = curve.from * (s * s * s) + curve.control1 * (3 * s * s * t) + curve.control2 * (3 * s * t * t) + curve.to * (t * t * t);
        expect((point - starts[index]).distance, greaterThanOrEqualTo(radii[index] - 1e-8));
        expect((point - ends[index]).distance, greaterThanOrEqualTo(radii[index] - 1e-8));
      }
    }
  });

  test('overlapping circles have no backwards connection and small circles use a thinner border', () {
    expect(buildPairCircleConnection(Offset.zero, Offset.zero, 10), isNull);
    expect(buildPairCircleConnection(Offset.zero, const Offset(15, 0), 10), isNull);
    expect(pairCircleBorderWidth(80), 3);
    expect(pairCircleBorderWidth(20), 1);
  });
}
