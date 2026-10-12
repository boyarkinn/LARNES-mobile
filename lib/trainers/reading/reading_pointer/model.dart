import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

bool isPointerLetter(VanishUnit unit, int hiddenOrder) {
  return unit.order == hiddenOrder + 1 && isLetterGrapheme(unit.grapheme);
}
