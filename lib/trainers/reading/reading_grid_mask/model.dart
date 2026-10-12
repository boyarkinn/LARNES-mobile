import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

const readingGridMaskInstructionText = 'Читай сквозь сетку';

String readingGridStep(Object? raw) => raw == 'fine' || raw == 'wide' ? raw.toString() : 'medium';

int readingGridStepPx(Object? raw) {
  final step = readingGridStep(raw);
  if (step == 'fine') return 16;
  if (step == 'wide') return 40;
  return 24;
}

String? validateReadingGridMaskRaw(Map<String, dynamic> raw) {
  return validatePassageAssignment(raw);
}
