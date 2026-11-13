import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';

const readingWordMazeInstructionText = 'Веди путь';
const readingWordMazeInstructionMs = 2400;
const readingMazeColumns = 3;
const readingMazeCells = 9;

String readingMazeMode(Object? raw) => raw == 'sentence' ? 'sentence' : 'group';

bool readingMazeNeighbors(int left, int right) {
  final leftRow = left ~/ readingMazeColumns;
  final leftColumn = left % readingMazeColumns;
  final rightRow = right ~/ readingMazeColumns;
  final rightColumn = right % readingMazeColumns;
  return (leftRow - rightRow).abs() + (leftColumn - rightColumn).abs() == 1;
}

String? validateReadingWordMazeRaw(Map<String, dynamic> raw) {
  return validateReadingContentSelection(raw);
}
