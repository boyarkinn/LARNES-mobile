import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

class ReadingRereadAttempt {
  const ReadingRereadAttempt({required this.elapsedMs, required this.errors});

  final int elapsedMs;
  final int errors;
}

class ReadingRereadGap {
  const ReadingRereadGap({required this.time, required this.errors});

  final String time;
  final String errors;
}

String formatReadingRereadSeconds(int ms) {
  final clamped = ms < 0 ? 0 : ms;
  final whole = clamped ~/ 1000;
  final tenth = (clamped % 1000) ~/ 100;
  return '$whole,$tenth';
}

ReadingRereadGap describeReadingRereadGap(ReadingRereadAttempt first, ReadingRereadAttempt second) {
  final deltaMs = second.elapsedMs - first.elapsedMs;
  final deltaErrors = second.errors - first.errors;
  final time = deltaMs < 0
      ? 'быстрее на ${formatReadingRereadSeconds(-deltaMs)} с'
      : deltaMs > 0
          ? 'медленнее на ${formatReadingRereadSeconds(deltaMs)} с'
          : 'время то же';
  final errors = deltaErrors < 0
      ? 'меньше ошибок на ${-deltaErrors}'
      : deltaErrors > 0
          ? 'больше ошибок на $deltaErrors'
          : 'ошибок столько же';
  return ReadingRereadGap(time: time, errors: errors);
}

ReadingPassageQuestion? readingRereadQuestionFromPayload(Object? raw) {
  if (raw is! Map) return null;
  final prompt = raw['prompt']?.toString() ?? '';
  final choicesRaw = raw['choices'];
  final correct = raw['correctIndex'];
  if (prompt.isEmpty || choicesRaw is! List || choicesRaw.length != 3) return null;
  final index = correct is int ? correct : int.tryParse('$correct') ?? -1;
  if (index < 0 || index > 2) return null;
  return ReadingPassageQuestion(
    prompt: prompt,
    choices: choicesRaw.map((choice) => choice.toString()).toList(),
    correctIndex: index,
  );
}

String? validateReadingRereadRaw(Map<String, dynamic> raw) {
  return validatePassageAssignment(raw);
}
