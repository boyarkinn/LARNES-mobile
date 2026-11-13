import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retired first-word catalog and local image resolver are removed', () {
    expect(
      File('lib/trainers/shared/first_words/catalog.dart').existsSync(),
      isFalse,
    );
    expect(
      File(
        'lib/trainers/shared/first_words/resolve_first_word.dart',
      ).existsSync(),
      isFalse,
    );
  });
}
