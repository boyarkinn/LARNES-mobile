import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/board/lesson_board_scene.dart';

Map<String, dynamic> line(String id, int version, {int nonce = 1, bool deleted = false}) {
  return {'id': id, 'isDeleted': deleted, 'type': 'freedraw', 'version': version, 'versionNonce': nonce};
}

void main() {
  test('keeps the newer line and a stroke the other side has not seen', () {
    final merged = mergeBoardElements(
      [line('mine', 2), line('kept', 1)],
      [line('mine', 4), line('theirs', 1)],
    );

    expect(merged.map((element) => element['id']), ['mine', 'theirs', 'kept']);
    expect(merged.first['version'], 4);
  });

  test('marks a touched stroke deleted and leaves the rest', () {
    final stroke = freedrawElement(const [BoardPoint(0, 0), BoardPoint(20, 0)], '#1e1e1e');
    final other = freedrawElement(const [BoardPoint(0, 40), BoardPoint(20, 40)], '#1e1e1e');
    final erased = eraseBoardElements([stroke, other], const BoardPoint(10, 0), 8);

    expect(erased, isNotNull);
    expect(erased!.first['isDeleted'], isTrue);
    expect(erased.first['version'], 2);
    expect(erased.last['isDeleted'], isFalse);
    expect(eraseBoardElements([other], const BoardPoint(10, 0), 8), isNull);
  });
}
