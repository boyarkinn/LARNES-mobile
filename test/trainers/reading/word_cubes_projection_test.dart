import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/word_cubes/cube_projection.dart';

void main() {
  test('solid cube stays inside the same viewport at every turn without mirrored text', () {
    for (var step = 0; step <= 500; step++) {
      final cube = projectWordCube(step / 50);
      expect(cube.surfaces.length, inInclusiveRange(2, 3));
      for (final point in cube.silhouette) {
        expect(point.dx, inExclusiveRange(0, 112)); expect(point.dy, inExclusiveRange(0, 112));
      }
      for (final surface in cube.surfaces) {
        final m = surface.textMatrix;
        expect(m[0] * m[3] - m[1] * m[2], greaterThan(0));
      }
    }
  });
  test('a quarter turn exposes the adjacent side and preserves the outline', () {
    final start = projectWordCube(0), end = projectWordCube(1);
    expect(start.surfaces.map((face) => face.id).toSet(), {0, 1, 4});
    expect(end.surfaces.map((face) => face.id).toSet(), {1, 2, 4});
    for (var i = 0; i < start.silhouette.length; i++) {
      expect((start.silhouette[i] - end.silhouette[i]).distance, lessThan(1e-8));
    }
    const faces = ['РЬ', 'РЯ', 'РЁ', 'РЮ', 'РИ', 'РЕ'];
    expect(cubeSideText(faces, 'РЕ', 0, 0, true), 'РЕ');
    expect(cubeSideText(faces, 'РЕ', 1, 0, true), 'РЬ');
    expect(cubeSideText(faces, 'РЬ', 1, 1, false), 'РЬ');
  });
}
